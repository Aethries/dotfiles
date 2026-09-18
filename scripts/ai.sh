#!/usr/bin/env bash

# Control plane duy nhất cho AI stack. Mọi state runtime nằm ngoài Git; mọi
# quyết định về version, endpoint, package và config canonical nằm trong repo.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$REPO_ROOT/resources/ai/manifest.json"
GENERATED_DIR="$REPO_ROOT/resources/ai/generated"
SHARED_MCP="$REPO_ROOT/resources/ai/shared/mcp/servers.json"
SYSTEMD_SOURCE="$REPO_ROOT/resources/systemd/user"
AI_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/ai"
OMNI_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/omniroute"
CODEGRAPH_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/codegraph"

log() { printf '\n==> %s\n' "$1"; }
ok() { printf '✓ %s\n' "$1"; }
warn() { printf '! %s\n' "$1" >&2; }
die() { printf '✗ %s\n' "$1" >&2; exit 1; }

manifest() {
    jq -r "$1" "$MANIFEST"
}

omni_version() { manifest '.tools.omniroute.version'; }
rtk_version() { manifest '.tools.rtk.version'; }
codegraph_version() { manifest '.tools.codegraph.version'; }
caveman_version() { manifest '.tools.caveman.version'; }
bifrost_version() { manifest '.tools.bifrost.version'; }

usage() {
    cat <<'EOF'
Usage: ./scripts/ai.sh <command>

Commands:
  bootstrap                 Validate, generate, sync, start, and verify AI stack
  sync [--adopt <client>]  Strictly link generated client configuration
  generate                 Generate deterministic client files
  start|stop|restart       Control managed user services
  status                   Show service and tool state
  doctor                   Inspect AI stack without changing anything
  test [--smoke]           Run deterministic tests, optionally live smoke test
  migrate-9router --dry-run|--apply
  cleanup-9router --dry-run|--apply-system-cleanup
  codegraph index|reindex|status|clear [workspace] [--yes]
  bifrost enable|disable|status
EOF
}

require_tools() {
    local tool
    for tool in jq sha256sum find sort awk sed git; do
        command -v "$tool" >/dev/null 2>&1 || die "Required command not found: $tool"
    done
}

validate_manifest() {
    require_tools
    jq empty "$MANIFEST" || die "AI manifest is not valid JSON: $MANIFEST"
    jq empty "$REPO_ROOT/resources/ai/schema/manifest.schema.json" \
        || die "AI manifest schema is not valid JSON"

    jq -e '
      .schemaVersion == 1
      and .gateway == "omniroute"
      and .endpoint == "http://127.0.0.1:20128"
      and .apiEndpoint == "http://127.0.0.1:20128/v1"
      and (.tools | keys | sort) == ["bifrost", "caveman", "codegraph", "omniroute", "rtk"]
      and (.tools | to_entries | all(.value.version | test("^[0-9]+\\.[0-9]+\\.[0-9]+$")))
      and (.tools | to_entries | all(.value.release | test("^v[0-9]+\\.[0-9]+\\.[0-9]+$")))
      and .tools.omniroute.autostart == true
      and .tools.omniroute.host == "127.0.0.1"
      and .tools.omniroute.port == 20128
      and .tools.bifrost.enabled == false
      and (.tools.bifrost.imageDigest | to_entries | all(.value | test("^sha256:[0-9a-f]{64}$")))
      and (.clients == ["codex", "gemini", "antigravity"])
      and ([.tools[].version] | all(. != "latest" and . != "main" and . != "master" and . != "nightly" and . != "next"))
    ' "$MANIFEST" >/dev/null || die "AI manifest violates pinned version or gateway policy"
    ok "AI manifest validated"
}

assert_no_floating_dependencies() {
    local matches
    matches="$(rg -n -i '(npm|pnpm|yarn)[^\n]*@(latest|main|master|nightly|next)|curl[^\n]*\|[^\n]*(sh|bash)|wget[^\n]*\|[^\n]*(sh|bash)|sed[[:space:]]+-i[^\n]*node_modules|loginctl[[:space:]]+enable-linger' \
        "$REPO_ROOT/scripts" "$REPO_ROOT/pkgs" "$REPO_ROOT/resources/ai" \
        -g '!ai.sh' 2>/dev/null || true)"
    [ -z "$matches" ] || die "AI security policy violation:\n$matches"
}

render_mcp() {
    local destination="$1"
    local temporary
    temporary="$(mktemp)"
    # Merge the old checked-in Gemini file as the compatibility input. Existing
    # server-specific args/env win on collision; the canonical source adds any
    # new server IDs without deleting Godot settings.
    jq -S -s '
      .[0] as $canonical
      | .[1] as $existing
      | $canonical * {mcpServers: ($canonical.mcpServers * ($existing.mcpServers // {}))}
    ' "$SHARED_MCP" "$REPO_ROOT/resources/gemini/mcp_config.json" > "$temporary" || {
        rm -f "$temporary"
        die "Shared MCP source is invalid JSON"
    }
    mv "$temporary" "$destination"
}

generate() {
    validate_manifest
    mkdir -p "$GENERATED_DIR/codex" "$GENERATED_DIR/gemini" "$GENERATED_DIR/antigravity"

    cp "$REPO_ROOT/resources/ai/clients/codex/config.toml" "$GENERATED_DIR/codex/config.toml"
    render_mcp "$GENERATED_DIR/gemini/mcp_config.json"
    render_mcp "$GENERATED_DIR/antigravity/mcp_config.json"

    # JSON output is sorted to make repeated generation byte-for-byte stable.
    jq -S . "$GENERATED_DIR/gemini/mcp_config.json" > "$GENERATED_DIR/gemini/mcp_config.json.tmp"
    mv "$GENERATED_DIR/gemini/mcp_config.json.tmp" "$GENERATED_DIR/gemini/mcp_config.json"
    cp "$GENERATED_DIR/gemini/mcp_config.json" "$GENERATED_DIR/antigravity/mcp_config.json"

    while IFS= read -r file; do
        sha256sum "$file"
    done < <(find "$GENERATED_DIR" -type f ! -name manifest.sha256 -print | sort) \
        | sed "s#  $REPO_ROOT/#  #" > "$GENERATED_DIR/manifest.sha256"
    ok "Generated deterministic Codex, Gemini, and Antigravity AI config"
}

strict_repo_link() {
    local source="$1"
    local destination="$2"
    mkdir -p "$(dirname "$destination")" || die "Cannot create config parent: $(dirname "$destination")"

    if [ -L "$destination" ]; then
        if [ "$(readlink "$destination")" = "$source" ]; then
            return 0
        fi
        die "$destination is a symlink to another target; no files were modified. Inspect it and rerun with an explicit migration plan."
    fi
    if [ -e "$destination" ]; then
        die "$destination already exists and is not managed by dotfiles. No files were modified. Rerun: ./scripts/ai.sh sync --adopt <client>"
    fi
    ln -s "$source" "$destination"
}

adopt_repo_link() {
    local source="$1"
    local destination="$2"
    mkdir -p "$(dirname "$destination")" || die "Cannot create config parent: $(dirname "$destination")"
    if [ -L "$destination" ]; then
        [ "$(readlink "$destination")" = "$source" ] || die "$destination is a conflicting symlink"
        return 0
    fi
    if [ -e "$destination" ]; then
        local backup
        backup="${destination}.pre-ai.$(date +%Y%m%d%H%M%S)"
        # Chỉ move khi user truyền --adopt. Backup giữ nguyên cấu hình cũ để rollback.
        mv -- "$destination" "$backup" || die "Could not back up $destination"
        warn "Adopted $destination; previous file is preserved at $backup"
    fi
    ln -s "$source" "$destination"
}

sync_client_links() {
    local adopt_client="${1:-}"
    generate >/dev/null

    local link_fn=strict_repo_link
    [ -n "$adopt_client" ] && link_fn=adopt_repo_link

    case "$adopt_client" in
        ""|codex|gemini|antigravity) ;;
        *) die "Unknown client for --adopt: $adopt_client" ;;
    esac

    if [ -z "$adopt_client" ] || [ "$adopt_client" = codex ]; then
        "$link_fn" "$GENERATED_DIR/codex/config.toml" "$HOME/.codex/config.toml"
    fi
    if [ -z "$adopt_client" ] || [ "$adopt_client" = gemini ]; then
        "$link_fn" "$GENERATED_DIR/gemini/mcp_config.json" "$HOME/.gemini/config/mcp_config.json"
        "$link_fn" "$GENERATED_DIR/gemini/mcp_config.json" "$HOME/.gemini/antigravity/mcp_config.json"
    fi
    if [ -z "$adopt_client" ] || [ "$adopt_client" = antigravity ]; then
        "$link_fn" "$GENERATED_DIR/antigravity/mcp_config.json" "$HOME/.antigravity-ide/mcp_config.json"
    fi

    # Skills are repo-owned symlinks; no upstream installer is allowed to mutate clients.
    "$link_fn" "$REPO_ROOT/resources/ai/shared/skills/caveman/SKILL.md" \
        "$HOME/.codex/skills/caveman/SKILL.md"
    "$link_fn" "$REPO_ROOT/resources/ai/shared/skills/caveman/SKILL.md" \
        "$HOME/.gemini/skills/caveman/SKILL.md"
    "$link_fn" "$REPO_ROOT/resources/ai/shared/skills/caveman/SKILL.md" \
        "$HOME/.antigravity-ide/skills/caveman.md"

    "$link_fn" "$REPO_ROOT/scripts/codegraph-mcp.sh" "$HOME/.local/bin/codegraph-mcp"
    "$link_fn" "$REPO_ROOT/scripts/bifrost-container.sh" "$HOME/.local/bin/bifrost-container"
    "$link_fn" "$SYSTEMD_SOURCE/omniroute.service" "$HOME/.config/systemd/user/omniroute.service"
    "$link_fn" "$SYSTEMD_SOURCE/bifrost.service" "$HOME/.config/systemd/user/bifrost.service"
    ok "AI client configuration and shared skills synchronized"
}

verify_package_availability() {
    local missing=0
    for tool in omniroute rtk codegraph-server; do
        if command -v "$tool" >/dev/null 2>&1; then
            ok "$tool is available"
        else
            warn "$tool is not available in PATH; run the NixOS rebuild before AI bootstrap"
            missing=1
        fi
    done
    return "$missing"
}

service_action() {
    local action="$1"
    command -v systemctl >/dev/null 2>&1 || die "systemctl is required for AI service lifecycle"
    case "$action" in
        start|restart)
            systemctl --user daemon-reload
            systemctl --user enable --now omniroute.service || die "Could not start omniroute.service"
            [ "$action" = restart ] && systemctl --user restart omniroute.service
            ;;
        stop) systemctl --user stop omniroute.service ;;
        *) die "Unknown service action: $action" ;;
    esac
}

health_probe() {
    command -v curl >/dev/null 2>&1 || die "curl is required for the OmniRoute health probe"
    curl --fail --silent --show-error --max-time 5 \
        "$(manifest '.endpoint')/api/health/ping" >/dev/null \
        || die "OmniRoute health probe failed at $(manifest '.endpoint')/api/health/ping"
    ok "OmniRoute API responds on loopback"
}

bootstrap() {
    log "Validating AI stack"
    validate_manifest
    assert_no_floating_dependencies
    verify_package_availability || die "AI package availability check failed"
    generate >/dev/null
    sync_client_links
    mkdir -p "$OMNI_STATE_DIR" "$AI_STATE_DIR"
    chmod 700 "$OMNI_STATE_DIR" "$AI_STATE_DIR"
    service_action start
    health_probe

    local expected_rtk expected_codegraph
    expected_rtk="$(rtk_version)"
    expected_codegraph="$(codegraph_version)"
    if [ "$(rtk --version 2>/dev/null || true)" != "rtk $expected_rtk" ]; then
        die "RTK version mismatch; expected $expected_rtk"
    fi
    if [ "$(codegraph-server --version 2>/dev/null || true)" != "codegraph-server $expected_codegraph" ]; then
        die "CodeGraph version mismatch; expected $expected_codegraph"
    fi
    rtk gain --format text >/dev/null 2>&1 || die "RTK identity/health check failed"
    ok "RTK and CodeGraph verified"
    ok "Caveman $(caveman_version) shared skill is repo-owned"
    ok "Bifrost is disabled by default"
    run_tests || die "AI deterministic tests failed during bootstrap"
}

status() {
    printf 'gateway: %s\n' "$(manifest '.gateway')"
    printf 'endpoint: %s\n' "$(manifest '.endpoint')"
    printf 'versions: OmniRoute %s, RTK %s, Caveman %s, CodeGraph %s, Bifrost %s\n' \
        "$(omni_version)" "$(rtk_version)" "$(caveman_version)" "$(codegraph_version)" "$(bifrost_version)"
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user is-enabled omniroute.service 2>/dev/null || true
        systemctl --user is-active omniroute.service 2>/dev/null || true
        systemctl --user is-active bifrost.service 2>/dev/null || true
    fi
}

doctor_check() {
    local description="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        ok "$description"
        return 0
    fi
    warn "$description\n    Fix: ./scripts/ai.sh doctor --help or run the relevant remediation"
    return 1
}

doctor() {
    local failures=0
    log "AI Assistant Stack"
    validate_manifest >/dev/null 2>&1 || { warn "AI manifest schema/policy invalid"; failures=$((failures + 1)); }
    assert_no_floating_dependencies || failures=$((failures + 1))
    if command -v omniroute >/dev/null 2>&1 && [ "$(omniroute --version 2>/dev/null || true)" = "$(omni_version)" ]; then
        ok "OmniRoute $(omni_version)"
    else
        warn "OmniRoute version mismatch\n    Fix: ./scripts/build.sh switch"
        failures=$((failures + 1))
    fi
    if command -v systemctl >/dev/null 2>&1; then
        doctor_check "OmniRoute service enabled" systemctl --user is-enabled omniroute.service || failures=$((failures + 1))
        doctor_check "OmniRoute service active" systemctl --user is-active omniroute.service || failures=$((failures + 1))
    else
        warn "systemctl is not available"
        failures=$((failures + 1))
    fi
    if command -v curl >/dev/null 2>&1 && curl --fail --silent --max-time 3 "$(manifest '.endpoint')/api/health/ping" >/dev/null 2>&1; then
        ok "OmniRoute API listening on loopback :20128"
    else
        warn "OmniRoute API is not healthy\n    Fix: ./scripts/ai.sh restart"
        failures=$((failures + 1))
    fi
    if [ "$(rtk --version 2>/dev/null || true)" = "rtk $(rtk_version)" ]; then
        ok "RTK $(rtk_version)"
    else
        warn "RTK version/identity mismatch\n    Fix: ./scripts/build.sh switch"
        failures=$((failures + 1))
    fi
    if [ "$(codegraph-server --version 2>/dev/null || true)" = "codegraph-server $(codegraph_version)" ]; then
        ok "CodeGraph $(codegraph_version)"
    else
        warn "CodeGraph version mismatch\n    Fix: ./scripts/build.sh switch"
        failures=$((failures + 1))
    fi
    if [ -f "$REPO_ROOT/resources/ai/codegraph/excludes.txt" ]; then
        ok "CodeGraph secret exclusions configured"
    else
        warn "CodeGraph exclusions missing"
        failures=$((failures + 1))
    fi
    if generated_files_current; then
        ok "Shared AI MCP configuration synchronized"
    else
        warn "Generated AI MCP configuration is stale\n    Fix: ./scripts/ai.sh generate"
        failures=$((failures + 1))
    fi
    if client_links_current; then
        ok "Codex, Gemini, and Antigravity AI links synchronized"
    else
        warn "One or more AI client links are stale or unmanaged\n    Fix: ./scripts/ai.sh sync"
        failures=$((failures + 1))
    fi
    if codegraph_doctor; then
        ok "CodeGraph index metadata is current"
    else
        failures=$((failures + 1))
    fi
    if systemctl --user is-active --quiet bifrost.service 2>/dev/null; then
        warn "Bifrost is active by explicit opt-in"
    else
        ok "Bifrost disabled by configuration"
    fi
    if rg -n -i '9router|\.9router|9router-init|init-9router|cloudcode-pa|9Router MITM' \
        "$REPO_ROOT/modules" "$REPO_ROOT/resources/systemd" "$REPO_ROOT/scripts/bootstrap.sh" \
        "$REPO_ROOT/scripts/doctor.sh" "$REPO_ROOT/scripts/vault.sh" "$REPO_ROOT/scripts/secrets.sh" >/dev/null 2>&1; then
        warn "Legacy 9router runtime references remain\n    Fix: ./scripts/ai.sh migrate-9router --dry-run"
        failures=$((failures + 1))
    else
        ok "No active 9router integration"
    fi
    [ "$failures" -eq 0 ]
}

generated_files_current() {
    local actual
    [ -f "$GENERATED_DIR/manifest.sha256" ] || return 1
    actual="$(
        cd "$REPO_ROOT" || exit 1
        while IFS= read -r file; do
            sha256sum "$file"
        done < <(find "$GENERATED_DIR" -type f ! -name manifest.sha256 -print | sort)
    )"
    actual="$(printf '%s\n' "$actual" | sed "s#  $REPO_ROOT/#  #")"
    cmp -s <(printf '%s\n' "$actual") "$GENERATED_DIR/manifest.sha256"
}

client_links_current() {
    local expected actual
    for expected in \
        "$GENERATED_DIR/codex/config.toml:$HOME/.codex/config.toml" \
        "$GENERATED_DIR/gemini/mcp_config.json:$HOME/.gemini/config/mcp_config.json" \
        "$GENERATED_DIR/gemini/mcp_config.json:$HOME/.gemini/antigravity/mcp_config.json" \
        "$GENERATED_DIR/antigravity/mcp_config.json:$HOME/.antigravity-ide/mcp_config.json"; do
        actual="${expected#*:}"
        expected="${expected%%:*}"
        [ -L "$actual" ] && [ "$(readlink "$actual")" = "$expected" ] || return 1
    done
    return 0
}

codegraph_doctor() {
    local metadata workspace expected_head expected_hash expected_version pid
    local failures=0
    while IFS= read -r metadata; do
        workspace="$(jq -r '.workspace // empty' "$metadata" 2>/dev/null || true)"
        if [ -z "$workspace" ] || [ ! -d "$workspace" ]; then
            warn "CodeGraph workspace metadata is invalid: $metadata"
            failures=$((failures + 1))
            continue
        fi
        expected_head="$(git -C "$workspace" rev-parse HEAD 2>/dev/null || true)"
        expected_hash="$(sha256sum "$REPO_ROOT/resources/ai/codegraph/excludes.txt" | awk '{print $1}')"
        expected_version="$(codegraph_version)"
        if [ "$(jq -r '.gitHead // empty' "$metadata")" != "$expected_head" ]; then
            warn "CodeGraph index is stale for $workspace (Git HEAD changed)"
            failures=$((failures + 1))
        fi
        if [ "$(jq -r '.configHash // empty' "$metadata")" != "$expected_hash" ]; then
            warn "CodeGraph index exclusions changed for $workspace"
            failures=$((failures + 1))
        fi
        if [ "$(jq -r '.codegraphVersion // empty' "$metadata")" != "$expected_version" ]; then
            warn "CodeGraph index version is stale for $workspace"
            failures=$((failures + 1))
        fi
        pid="$(jq -r '.pid // empty' "$metadata")"
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            continue
        fi
        warn "CodeGraph watcher is not active for $workspace"
        failures=$((failures + 1))
    done < <(find "$CODEGRAPH_STATE_DIR" -type f -name metadata.json -print 2>/dev/null | sort)
    return "$failures"
}

legacy_inventory() {
    printf '%s\n' "Legacy 9router state inventory (read-only):"
    for path in "$HOME/.9router" "$HOME/.local/bin/init-9router" "$HOME/.local/bin/9router-init" \
        "$HOME/.config/systemd/user/9router.service" "/usr/local/share/ca-certificates/9router-root-ca.crt"; do
        if [ -e "$path" ] || [ -L "$path" ]; then
            printf '  would inspect: %s\n' "$path"
        else
            printf '  absent: %s\n' "$path"
        fi
    done
}

migrate_9router() {
    case "${1:-}" in
        --dry-run)
            legacy_inventory
            printf '%s\n' 'No files were modified. OmniRoute remains the managed gateway.'
            ;;
        --apply)
            legacy_inventory
            if command -v systemctl >/dev/null 2>&1; then
                systemctl --user disable --now 9router.service 2>/dev/null || true
            fi
            service_action start
            health_probe
            printf '%s\n' 'Legacy user state was left untouched; cleanup requires a separate explicit command.'
            ;;
        *) die "Usage: ./scripts/ai.sh migrate-9router --dry-run|--apply" ;;
    esac
}

cleanup_9router() {
    case "${1:-}" in
        --dry-run)
            legacy_inventory
            printf '%s\n' 'Would stop and disable legacy service; would move home state to a dated backup; would leave credentials and system trust untouched.'
            ;;
        --apply-system-cleanup)
            local backup
            backup="$AI_STATE_DIR/legacy-9router-backup/$(date +%Y%m%d%H%M%S)"
            mkdir -p "$backup"
            if command -v systemctl >/dev/null 2>&1; then
                systemctl --user disable --now 9router.service 2>/dev/null || true
            fi
            for path in "$HOME/.9router" "$HOME/.local/bin/init-9router" "$HOME/.local/bin/9router-init" "$HOME/.config/systemd/user/9router.service"; do
                if [ -e "$path" ] || [ -L "$path" ]; then
                    mkdir -p "$backup/$(dirname "${path#"$HOME/"}")"
                    mv -- "$path" "$backup/${path#"$HOME/"}"
                fi
            done
            printf 'Legacy state moved to %s\n' "$backup"
            ;;
        *) die "Usage: ./scripts/ai.sh cleanup-9router --dry-run|--apply-system-cleanup" ;;
    esac
}

codegraph_workspace() {
    local requested="${1:-$PWD}"
    local workspace
    workspace="$(realpath "$requested" 2>/dev/null || true)"
    [ -n "$workspace" ] && [ -d "$workspace" ] || die "CodeGraph workspace does not exist: $requested"
    case "$workspace" in
        "$HOME"|/|"$HOME/Downloads"|"$HOME/Downloads/"*|"$HOME/Documents"|"$HOME/Documents/"*|/Downloads|/Downloads/*|/Documents|/Documents/*)
            [ -n "${CODEGRAPH_ALLOW_NONWORKSPACE:-}" ] || die "CodeGraph accepts only an explicit Git workspace, not HOME/root/Downloads/Documents"
            ;;
    esac
    git -C "$workspace" rev-parse --show-toplevel >/dev/null 2>&1 \
        || die "CodeGraph workspace must be a Git repository: $workspace"
    git -C "$workspace" rev-parse --show-toplevel
}

codegraph_metadata_path() {
    local workspace="$1"
    local key
    key="$(printf '%s' "$workspace" | sha256sum | awk '{print $1}')"
    printf '%s/%s/metadata.json\n' "$CODEGRAPH_STATE_DIR" "$key"
}

codegraph_index() {
    local workspace
    workspace="$(codegraph_workspace "${1:-$PWD}")"
    local metadata
    local state_dir
    metadata="$(codegraph_metadata_path "$workspace")"
    state_dir="$(dirname "$metadata")"
    mkdir -p "$state_dir"
    if [ -f "$metadata" ] && [ "${2:-}" != reindex ]; then
        warn "CodeGraph index metadata already exists; use reindex to restart it"
        return 0
    fi
    if [ -f "$metadata" ]; then
        local old_pid
        old_pid="$(jq -r '.pid // empty' "$metadata")"
        [ -n "$old_pid" ] && kill "$old_pid" 2>/dev/null || true
    fi
    local args=(--workspace "$workspace" --profile "$(manifest '.tools.codegraph.mcpProfile')")
    while IFS= read -r exclusion; do
        [ -n "$exclusion" ] || continue
        args+=(--exclude "$exclusion")
    done < "$REPO_ROOT/resources/ai/codegraph/excludes.txt"
    mkdir -p "$state_dir/logs"
    # Chạy watcher nền để graph/memory sống qua client restart; metadata giúp doctor
    # phát hiện workspace, HEAD, version hoặc config đã thay đổi.
    codegraph-server "${args[@]}" --watch > "$state_dir/logs/codegraph.log" 2>&1 &
    local pid=$!
    jq -n \
        --arg workspace "$workspace" \
        --arg head "$(git -C "$workspace" rev-parse HEAD)" \
        --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg version "$(codegraph_version)" \
        --arg configHash "$(sha256sum "$REPO_ROOT/resources/ai/codegraph/excludes.txt" | awk '{print $1}')" \
        --argjson pid "$pid" \
        '{workspace:$workspace,gitHead:$head,timestamp:$timestamp,codegraphVersion:$version,configHash:$configHash,pid:$pid}' \
        > "$metadata"
    ok "CodeGraph watcher started for $workspace"
}

codegraph_command() {
    local command="${1:-}"
    shift || true
    case "$command" in
        index) codegraph_index "${1:-$PWD}" ;;
        reindex) codegraph_index "${1:-$PWD}" reindex ;;
        status)
            local workspace
            local metadata
            workspace="$(codegraph_workspace "${1:-$PWD}")"
            metadata="$(codegraph_metadata_path "$workspace")"
            if [ -f "$metadata" ]; then
                jq . "$metadata"
                local pid
                pid="$(jq -r '.pid // empty' "$metadata")"
                if kill -0 "$pid" 2>/dev/null; then
                    ok "CodeGraph watcher active"
                else
                    warn "CodeGraph metadata exists but watcher is not active"
                fi
            else
                warn "No CodeGraph index metadata for $workspace"
                return 1
            fi
            ;;
        clear)
            local workspace
            workspace="$(codegraph_workspace "${1:-$PWD}")"
            [ "${2:-}" = --yes ] || die "CodeGraph clear is destructive; rerun with: codegraph clear <workspace> --yes"
            local metadata
            local state_dir
            metadata="$(codegraph_metadata_path "$workspace")"
            state_dir="$(dirname "$metadata")"
            if [ -f "$metadata" ]; then
                local pid
                pid="$(jq -r '.pid // empty' "$metadata")"
                [ -n "$pid" ] && kill "$pid" 2>/dev/null || true
            fi
            rm -rf -- "$state_dir"
            ok "CodeGraph metadata and watcher state cleared for $workspace"
            ;;
        *) die "Usage: ./scripts/ai.sh codegraph index|reindex|status|clear [workspace] [--yes]" ;;
    esac
}

bifrost_command() {
    local action="${1:-}"
    mkdir -p "$AI_STATE_DIR"
    local bifrost_env_file="$AI_STATE_DIR/bifrost.env"
    local omni_env_file="$AI_STATE_DIR/omniroute.env"
    case "$action" in
        enable)
            command -v docker >/dev/null 2>&1 || die "Docker is required for optional Bifrost"
            local bifrost_config="$HOME/.config/bifrost/config.json"
            if [ -f "$bifrost_config" ]; then
                jq empty "$bifrost_config" || die "Bifrost config is not valid JSON: $bifrost_config"
            elif [ -z "${BIFROST_API_KEY:-}" ]; then
                die "Bifrost credentials/config are missing. Set BIFROST_API_KEY for this explicit opt-in or provide ~/.config/bifrost/config.json."
            fi
            umask 077
            {
                printf 'BIFROST_ENABLED=1\n'
                printf 'BIFROST_BASE_URL=http://127.0.0.1:8080\n'
                printf 'OMNIROUTE_RELAY_BACKEND=auto\n'
                [ -n "${BIFROST_API_KEY:-}" ] && printf 'BIFROST_API_KEY=%s\n' "$BIFROST_API_KEY"
            } > "$bifrost_env_file"
            cp "$bifrost_env_file" "$omni_env_file"
            chmod 600 "$bifrost_env_file" "$omni_env_file"
            systemctl --user daemon-reload
            systemctl --user enable --now bifrost.service || die "Could not start Bifrost"
            curl --fail --silent --max-time 10 http://127.0.0.1:8080/v1/models >/dev/null \
                || die "Bifrost health check failed; OmniRoute configuration was not changed"
            systemctl --user restart omniroute.service || die "Bifrost started but OmniRoute could not reload its optional upstream"
            health_probe
            ok "Bifrost enabled as an optional OmniRoute upstream"
            ;;
        disable)
            systemctl --user disable --now bifrost.service 2>/dev/null || true
            : > "$bifrost_env_file"
            : > "$omni_env_file"
            chmod 600 "$bifrost_env_file" "$omni_env_file"
            systemctl --user restart omniroute.service || die "Could not restart OmniRoute after Bifrost disable"
            health_probe
            ok "Bifrost disabled; direct OmniRoute routing remains active"
            ;;
        status)
            systemctl --user is-active bifrost.service 2>/dev/null || true
            [ -s "$omni_env_file" ] && printf 'configured=enabled\n' || printf 'configured=disabled\n'
            ;;
        *) die "Usage: ./scripts/ai.sh bifrost enable|disable|status" ;;
    esac
}

run_tests() {
    local smoke=false
    [ "${1:-}" = --smoke ] && smoke=true
    local test
    for test in "$REPO_ROOT"/tests/ai/*_test.sh; do
        [ -f "$test" ] || continue
        [ "$(basename "$test")" = smoke_test.sh ] && continue
        bash "$test" || return 1
    done
    if [ "$smoke" = true ]; then
        bash "$REPO_ROOT/tests/ai/smoke_test.sh" || return 1
    fi
    ok "AI tests passed"
}

main() {
    local command="${1:-}"
    shift || true
    case "$command" in
        bootstrap) bootstrap ;;
        sync)
            local adopt=""
            if [ "${1:-}" = --adopt ]; then
                [ -n "${2:-}" ] || die "Usage: ./scripts/ai.sh sync --adopt codex|gemini|antigravity"
                adopt="$2"
            fi
            sync_client_links "$adopt"
            ;;
        generate) generate ;;
        start|stop|restart) service_action "$command" ;;
        status) status ;;
        doctor) doctor ;;
        test) run_tests "${1:-}" ;;
        migrate-9router) migrate_9router "${1:-}" ;;
        cleanup-9router) cleanup_9router "${1:-}" ;;
        codegraph) codegraph_command "$@" ;;
        bifrost) bifrost_command "$@" ;;
        -h|--help|help|"") usage ;;
        *) usage; die "Unknown AI command: $command" ;;
    esac
}

main "$@"
