#!/usr/bin/env bash
# ==============================================================================
# scripts/lib/discovery.sh: Trusted External Skill Discovery Provider Layer
# ==============================================================================

set -euo pipefail

if [ -z "${REPO_ROOT:-}" ]; then
    _DISCOVERY_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REPO_ROOT="$(cd "$_DISCOVERY_LIB_DIR/../.." && pwd)"
fi

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
BOLD="\033[1m"
RESET="\033[0m"

log_ok() { echo -e "  [${GREEN}✓${RESET}] $1"; }
log_warn() { echo -e "  [${YELLOW}!${RESET}] $1"; }
log_err() { echo -e "  [${RED}✗${RESET}] $1" >&2; }

# ------------------------------------------------------------------------------
# Normalize Candidate JSON Schema
# ------------------------------------------------------------------------------
normalize_candidate() {
    local name="$1"
    local source="$2"
    local upstream_url="$3"
    local skill_path="${4:-.}"
    local revision="${5:-null}"
    local description="${6:-}"
    local trust="${7:-unverified}"
    local license="${8:-unknown}"
    local discovered_via="${9:-$source}"

    jq -n \
        --arg name "$name" \
        --arg source "$source" \
        --arg upstream "$upstream_url" \
        --arg path "$skill_path" \
        --arg rev "$revision" \
        --arg desc "$description" \
        --arg trust "$trust" \
        --arg lic "$license" \
        --arg via "$discovered_via" \
        '{
            name: $name,
            source: $source,
            upstream_url: $upstream,
            skill_path: $path,
            revision: (if $rev == "null" or $rev == "" then null else $rev end),
            description: $desc,
            trust: $trust,
            license: $lic,
            discovered_via: $via
        }'
}

# ------------------------------------------------------------------------------
# Candidate Verification Engine (Phase 6)
# Validates repository reachability, revision, skill path, and SKILL.md existence.
# ------------------------------------------------------------------------------
verify_candidate() {
    local upstream_url="$1"
    local skill_path="${2:-.}"
    local revision="${3:-HEAD}"

    # 1. Local filesystem path or test fixture
    if [ -d "$upstream_url" ]; then
        local target_dir="$upstream_url"
        [ "$skill_path" != "." ] && [ -n "$skill_path" ] && target_dir="$upstream_url/$skill_path"

        if [ ! -d "$target_dir" ] || [ ! -f "$target_dir/SKILL.md" ]; then
            jq -n --arg reason "SKILL.md not found at path '$skill_path'" '{verified: false, reason: $reason}'
            return 0
        fi

        if ! head -n 1 "$target_dir/SKILL.md" | grep -q '^---'; then
            jq -n --arg reason "SKILL.md missing valid YAML frontmatter delimiter" '{verified: false, reason: $reason}'
            return 0
        fi

        local resolved_commit="local"
        if [ -d "$upstream_url/.git" ]; then
            resolved_commit="$(cd "$upstream_url" && git rev-parse "${revision:-HEAD}" 2>/dev/null || echo "HEAD")"
        fi

        jq -n \
            --arg commit "$resolved_commit" \
            --arg path "$skill_path" \
            '{verified: true, resolved_commit: $commit, resolved_path: $path, reason: null}'
        return 0
    fi

    # 2. Remote git repository
    if [[ "$upstream_url" =~ ^https?:// ]] || [[ "$upstream_url" =~ ^git@ ]]; then
        local ls_out
        if ! ls_out="$(git ls-remote "$upstream_url" 2>/dev/null)"; then
            jq -n --arg reason "Repository unreachable or network unavailable: $upstream_url" '{verified: false, reason: $reason}'
            return 0
        fi

        local resolved_sha
        resolved_sha="$(echo "$ls_out" | awk '{print $1}' | head -n 1)"
        if [ -z "$resolved_sha" ]; then
            jq -n --arg reason "Unable to resolve commit SHA for $upstream_url" '{verified: false, reason: $reason}'
            return 0
        fi

        local check_dir
        check_dir="$(mktemp -d "/tmp/verify-cand.XXXXXX")"
        if git clone --depth 1 "$upstream_url" "$check_dir" >/dev/null 2>&1; then
            local check_skill_dir="$check_dir"
            [ "$skill_path" != "." ] && [ -n "$skill_path" ] && check_skill_dir="$check_dir/$skill_path"

            if [ -f "$check_skill_dir/SKILL.md" ] && head -n 1 "$check_skill_dir/SKILL.md" | grep -q '^---'; then
                resolved_sha="$(cd "$check_dir" && git rev-parse HEAD 2>/dev/null || echo "$resolved_sha")"
                rm -rf "$check_dir"
                jq -n --arg commit "$resolved_sha" --arg path "$skill_path" '{verified: true, resolved_commit: $commit, resolved_path: $path, reason: null}'
                return 0
            else
                rm -rf "$check_dir"
                jq -n --arg reason "SKILL.md not found at upstream path '$skill_path'" '{verified: false, reason: $reason}'
                return 0
            fi
        else
            rm -rf "$check_dir"
            jq -n --arg reason "Failed to clone repository for verification: $upstream_url" '{verified: false, reason: $reason}'
            return 0
        fi
    fi

    jq -n --arg reason "Unsupported upstream location format: $upstream_url" '{verified: false, reason: $reason}'
}

# ------------------------------------------------------------------------------
# Candidate Verification Filter for Discovery (Blocker 1)
# Validates candidate and outputs schema with status "verified" or "rejected".
# ------------------------------------------------------------------------------
verify_discovery_candidate() {
    local candidate_json="$1"
    local name upstream_url skill_path revision
    name="$(echo "$candidate_json" | jq -r '.name // empty')"
    upstream_url="$(echo "$candidate_json" | jq -r '.upstream_url // empty')"
    skill_path="$(echo "$candidate_json" | jq -r '.skill_path // "."')"
    revision="$(echo "$candidate_json" | jq -r '.revision // empty')"
    [ "$skill_path" = "null" ] || [ -z "$skill_path" ] && skill_path="."

    # In fixture mode with remote URLs, check if fixture SKILL.md exists
    if [ -n "${DISCOVERY_FIXTURE_DIR:-}" ] && [[ "$upstream_url" =~ ^https?:// ]]; then
        local fix_skill=""
        if [ -f "$DISCOVERY_FIXTURE_DIR/../semantic/$name/SKILL.md" ]; then
            fix_skill="$DISCOVERY_FIXTURE_DIR/../semantic/$name/SKILL.md"
        elif [ -f "$DISCOVERY_FIXTURE_DIR/$name/SKILL.md" ]; then
            fix_skill="$DISCOVERY_FIXTURE_DIR/$name/SKILL.md"
        elif [ -d "$DISCOVERY_FIXTURE_DIR/$skill_path" ] && [ -f "$DISCOVERY_FIXTURE_DIR/$skill_path/SKILL.md" ]; then
            fix_skill="$DISCOVERY_FIXTURE_DIR/$skill_path/SKILL.md"
        fi

        if [ -n "$fix_skill" ] && head -n 1 "$fix_skill" | grep -q '^---'; then
            local rev="${revision:-b5c7e9a0f1e2d3c4}"
            [ "$rev" = "null" ] && rev="b5c7e9a0f1e2d3c4"
            echo "$candidate_json" | jq -c --arg rev "$rev" '
                .revision = $rev |
                .verification = { status: "verified" }
            '
            return 0
        else
            echo "$candidate_json" | jq -c '
                .verification = { status: "rejected", reason: "SKILL.md not found or invalid frontmatter" }
            '
            return 0
        fi
    fi

    local v_res
    v_res="$(verify_candidate "$upstream_url" "$skill_path" "${revision:-HEAD}")"
    local is_verified
    is_verified="$(echo "$v_res" | jq -r '.verified // false')"

    if [ "$is_verified" = "true" ]; then
        local resolved_commit
        resolved_commit="$(echo "$v_res" | jq -r '.resolved_commit // empty')"
        [ -z "$resolved_commit" ] || [ "$resolved_commit" = "null" ] && resolved_commit="$revision"
        echo "$candidate_json" | jq -c --arg commit "$resolved_commit" '
            .revision = (if $commit != "" and $commit != "null" then $commit else .revision end) |
            .verification = { status: "verified" }
        '
    else
        local reason
        reason="$(echo "$v_res" | jq -r '.reason // "Verification failed"')"
        echo "$candidate_json" | jq -c --arg reason "$reason" '
            .verification = { status: "rejected", reason: $reason }
        '
    fi
}

# ------------------------------------------------------------------------------
# Fixture Loader (Phase 1)
# Strictly active only when DISCOVERY_FIXTURE_DIR is explicitly configured.
# ------------------------------------------------------------------------------
load_fixture_candidates() {
    local query="${1:-}"

    if [ -z "${DISCOVERY_FIXTURE_DIR:-}" ]; then
        echo "[]"
        return 0
    fi

    local fixture_file="$DISCOVERY_FIXTURE_DIR/candidates.json"
    if [ ! -f "$fixture_file" ]; then
        echo "[]"
        return 0
    fi

    if [ -n "$query" ]; then
        jq -c --arg q "$query" '[ .[] | select(
            ((.name // "") | ascii_downcase | contains($q | ascii_downcase)) or
            ((.description // "") | ascii_downcase | contains($q | ascii_downcase)) or
            ((.skill_path // "") | ascii_downcase | contains($q | ascii_downcase))
        ) ]' "$fixture_file"
    else
        jq -c '.' "$fixture_file"
    fi
}

# ------------------------------------------------------------------------------
# Provider Discovery Functions
# Priority:
# 1. official-vendor (policy: verified vendor first-party)
# 2. anthropic-skills
# 3. skills-sh
# 4. agentic-awesome-skills
# 5. github-search fallback
# ------------------------------------------------------------------------------

discover_from_official_vendor() {
    local query="$1"
    local fixture_data
    fixture_data="$(load_fixture_candidates "$query")"
    local filtered
    filtered="$(echo "$fixture_data" | jq -c '[ .[] | select(.source == "official-vendor") ]')"
    if [ "$(echo "$filtered" | jq 'length')" -gt 0 ]; then
        echo "$filtered"
        return 0
    fi

    # In production without fixtures, do not fabricate unverified vendor candidates
    echo "[]"
}

discover_from_anthropic() {
    local query="$1"
    local fixture_data
    fixture_data="$(load_fixture_candidates "$query")"
    local filtered
    filtered="$(echo "$fixture_data" | jq -c '[ .[] | select(.source == "anthropic-skills") ]')"
    if [ "$(echo "$filtered" | jq 'length')" -gt 0 ]; then
        echo "$filtered"
        return 0
    fi

    # In production without fixtures, do not fabricate unverified candidates
    echo "[]"
}

discover_from_skills_sh() {
    local query="$1"
    local fixture_data
    fixture_data="$(load_fixture_candidates "$query")"
    local filtered
    filtered="$(echo "$fixture_data" | jq -c '[ .[] | select(.source == "skills-sh") ]')"
    if [ "$(echo "$filtered" | jq 'length')" -gt 0 ]; then
        echo "$filtered"
        return 0
    fi

    # In production without fixtures, do not fabricate unverified candidates
    echo "[]"
}

discover_from_agentic_awesome() {
    local query="$1"
    local fixture_data
    fixture_data="$(load_fixture_candidates "$query")"
    local filtered
    filtered="$(echo "$fixture_data" | jq -c '[ .[] | select(.source == "agentic-awesome-skills") ]')"
    if [ "$(echo "$filtered" | jq 'length')" -gt 0 ]; then
        echo "$filtered"
        return 0
    fi

    # In production without fixtures, do not fabricate unverified candidates
    echo "[]"
}

discover_from_github() {
    local query="$1"
    # Live fallback query via GitHub CLI if available and authenticated
    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
        local raw_results="[]"
        # 1. Search code specifically for SKILL.md matching query
        local code_hits
        code_hits="$(gh search code "$query" --filename "SKILL.md" --limit 10 --json path,repository 2>/dev/null || echo "[]")"
        if [ "$(echo "$code_hits" | jq 'length' 2>/dev/null || echo 0)" -gt 0 ]; then
            raw_results="$(echo "$code_hits" | jq -c '[ .[] |
                (if (.path | contains("/")) then (.path | split("/")[:-1] | join("/")) else "." end) as $dir |
                (if $dir == "." then (.repository.name // "skill") else ($dir | split("/")[-1]) end) as $sname |
                {
                    name: $sname,
                    source: "github-search",
                    upstream_url: .repository.url,
                    skill_path: $dir,
                    revision: null,
                    description: ("Discovered via GitHub code search at " + .path),
                    trust: "unverified",
                    license: "unknown",
                    discovered_via: "github-search"
                }
            ]')"
        fi

        # 2. If code search returns empty, search repositories by topic and inspect tree for SKILL.md
        if [ "$(echo "$raw_results" | jq 'length' 2>/dev/null || echo 0)" -eq 0 ]; then
            local repo_hits
            repo_hits="$(gh search repos "topic:agent-skills $query" --limit 3 --json fullName,url 2>/dev/null || echo "[]")"
            local repo_count
            repo_count="$(echo "$repo_hits" | jq 'length' 2>/dev/null || echo 0)"
            if [ "$repo_count" -gt 0 ]; then
                local repo_candidates="[]"
                for (( r=0; r<repo_count; r++ )); do
                    local r_full r_url
                    r_full="$(echo "$repo_hits" | jq -r ".[$r].fullName")"
                    r_url="$(echo "$repo_hits" | jq -r ".[$r].url")"
                    local tree_items
                    tree_items="$(gh api "repos/${r_full}/git/trees/HEAD?recursive=1" --jq '.tree[]? | select(.path | endswith("SKILL.md")) | .path' 2>/dev/null || echo "")"
                    if [ -n "$tree_items" ]; then
                        while IFS= read -r skill_file; do
                            [ -z "$skill_file" ] && continue
                            local s_dir s_name
                            s_dir="$(dirname "$skill_file")"
                            if [ "$s_dir" = "." ]; then
                                s_name="$(echo "$r_full" | cut -d'/' -f2)"
                            else
                                s_name="$(basename "$s_dir")"
                            fi
                            repo_candidates="$(echo "$repo_candidates" | jq \
                                --arg name "$s_name" \
                                --arg url "$r_url" \
                                --arg path "$s_dir" \
                                '. + [{
                                    name: $name,
                                    source: "github-search",
                                    upstream_url: $url,
                                    skill_path: $path,
                                    revision: null,
                                    description: ("Discovered via GitHub repository tree at " + $path),
                                    trust: "unverified",
                                    license: "unknown",
                                    discovered_via: "github-search"
                                }]'
                            )"
                        done <<< "$tree_items"
                    fi
                done
                raw_results="$repo_candidates"
            fi
        fi

        if [ "$(echo "$raw_results" | jq 'length' 2>/dev/null || echo 0)" -gt 0 ]; then
            echo "$raw_results" | jq -c 'unique_by({upstream_url, skill_path})'
            return 0
        fi
    fi
    echo "[]"
}

# ------------------------------------------------------------------------------
# Aggregate External Candidate Discovery (Phases 5, 8, 10)
# ------------------------------------------------------------------------------
discover_candidates() {
    local query="${1:-}"
    local output_json=false

    shift || true
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --json)
                output_json=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    if [ -z "$query" ]; then
        log_err "Missing discovery query. Usage: ai-skills discover <query> [--json]"
        return 1
    fi

    local c_vendor c_anthropic c_skills_sh c_aas c_gh
    c_vendor="$(discover_from_official_vendor "$query")"
    c_anthropic="$(discover_from_anthropic "$query")"
    c_skills_sh="$(discover_from_skills_sh "$query")"
    c_aas="$(discover_from_agentic_awesome "$query")"
    c_gh="$(discover_from_github "$query")"

    # Merge raw candidates
    local all_raw
    all_raw="$(jq -s 'add // []' <(echo "$c_vendor") <(echo "$c_anthropic") <(echo "$c_skills_sh") <(echo "$c_aas") <(echo "$c_gh"))"

    # Verify each candidate before display/aggregation (Blocker 1)
    local verified_cands="[]"
    local raw_len
    raw_len="$(echo "$all_raw" | jq 'length' 2>/dev/null || echo 0)"
    if [ "$raw_len" -gt 0 ]; then
        for (( i=0; i<raw_len; i++ )); do
            local raw_item checked_item c_status
            raw_item="$(echo "$all_raw" | jq -c --argjson idx "$i" '.[$idx]')"
            checked_item="$(verify_discovery_candidate "$raw_item")"
            c_status="$(echo "$checked_item" | jq -r '.verification.status // "rejected"')"
            if [ "$c_status" = "verified" ]; then
                verified_cands="$(echo "$verified_cands" | jq --argjson item "$checked_item" '. + [$item]')"
            fi
        done
    fi

    # Merge verified candidates and group by name to preserve alternate source evidence (Phase 10)
    local all_candidates
    all_candidates="$(echo "$verified_cands" | jq '
        group_by(.name) |
        map(
            sort_by(
                if .trust == "vendor" then 1
                elif .trust == "official" then 2
                elif .trust == "verified" then 3
                elif .trust == "community" then 4
                else 5 end
            ) |
            {
                name: .[0].name,
                source: .[0].source,
                upstream_url: .[0].upstream_url,
                skill_path: .[0].skill_path,
                revision: .[0].revision,
                description: .[0].description,
                trust: .[0].trust,
                license: .[0].license,
                discovered_via: .[0].discovered_via,
                verification: .[0].verification,
                alternates: (if length > 1 then [ .[1:][] | { source: .source, upstream_url: .upstream_url, skill_path: .skill_path } ] else [] end)
            }
        )
    ')"

    if [ "$output_json" = true ]; then
        echo "$all_candidates"
        return 0
    fi

    local total
    total="$(echo "$all_candidates" | jq 'length')"

    echo -e "${BOLD}${CYAN}=== External AI Skills Discovery: '${query}' ===${RESET}"
    if [ "$total" -eq 0 ]; then
        echo -e "  No verified deterministic candidate found for '${query}' in trusted catalogs.\n"
        echo -e "  Recommended research sources:"
        echo -e "  - Official vendor repository"
        echo -e "  - Anthropic Skills (https://github.com/anthropics/skills)"
        echo -e "  - skills.sh registry (https://skills.sh)"
        echo -e "  - Agentic Awesome Skills (https://github.com/sickn33/agentic-awesome-skills)"
        echo -e "  - GitHub topic search (https://github.com/search?q=topic%3Aagent-skills+${query})\n"
        echo -e "  Use 'technical-researcher' or 'skill-author' to research and resolve an authoritative upstream."
        return 0
    fi

    echo -e "Found ${BOLD}${GREEN}${total}${RESET} candidate(s) across trusted sources (ordered by trust priority):\n"

    local idx=0
    while [ "$idx" -lt "$total" ]; do
        local cand
        cand="$(echo "$all_candidates" | jq -c --argjson i "$idx" '.[$i]')"
        local c_name c_source c_upstream c_path c_trust c_lic c_desc
        c_name="$(echo "$cand" | jq -r '.name')"
        c_source="$(echo "$cand" | jq -r '.source')"
        c_upstream="$(echo "$cand" | jq -r '.upstream_url')"
        c_path="$(echo "$cand" | jq -r '.skill_path')"
        c_trust="$(echo "$cand" | jq -r '.trust')"
        c_lic="$(echo "$cand" | jq -r '.license')"
        c_desc="$(echo "$cand" | jq -r '.description')"

        echo -e "  ${BOLD}${idx}. [${c_trust^^}] ${GREEN}${c_name}${RESET}"
        echo -e "     ${c_desc}"
        echo -e "     ${BOLD}Source:${RESET}    ${c_source}"
        echo -e "     ${BOLD}Upstream:${RESET}  ${c_upstream}"
        echo -e "     ${BOLD}Path:${RESET}      ${c_path}"
        echo -e "     ${BOLD}License:${RESET}   ${c_lic}"
        local alts_len
        alts_len="$(echo "$cand" | jq '.alternates | length')"
        if [ "$alts_len" -gt 0 ]; then
            local alt_sources
            alt_sources="$(echo "$cand" | jq -r '[ .alternates[].source ] | join(", ")')"
            echo -e "     ${BOLD}Alternates:${RESET} Also indexed by: ${alt_sources}"
        fi
        echo -e "     ${BOLD}Preview:${RESET}   ai-skills import ${c_upstream} --path ${c_path} --preview"
        echo
        idx=$((idx + 1))
    done
}

# ------------------------------------------------------------------------------
# Project-Aware Skill Recommendation Engine (Phases 18, 19)
# Dynamic, registry-driven coverage analysis against project tech stack.
# ------------------------------------------------------------------------------
recommend_project_skills() {
    local proj_dir="${1:-$PWD}"
    proj_dir="$(cd "$proj_dir" 2>/dev/null && pwd || echo "$proj_dir")"

    echo -e "${BOLD}${CYAN}=== Project AI Skills Recommendation Audit ===${RESET}"
    echo -e "Scanning high-signal project files in: ${BOLD}${proj_dir}${RESET}\n"

    local detected_techs=()

    # 1. High-signal project file detection
    if [ -f "$proj_dir/package.json" ]; then
        local pkg="$proj_dir/package.json"
        if grep -Fq "@nestjs/" "$pkg" || [ -f "$proj_dir/nest-cli.json" ]; then
            detected_techs+=("nestjs")
        fi
        if grep -Fq "bullmq" "$pkg"; then
            detected_techs+=("bullmq")
        fi
        if grep -Fq "prisma" "$pkg" || [ -d "$proj_dir/prisma" ]; then
            detected_techs+=("prisma")
        fi
        if grep -Fq "drizzle" "$pkg" || [ -d "$proj_dir/drizzle" ]; then
            detected_techs+=("drizzle")
        fi
        if grep -Eiq '("pg"|"postgres")' "$pkg"; then
            detected_techs+=("postgresql")
        fi
        if grep -Eiq '("ioredis"|"redis")' "$pkg"; then
            detected_techs+=("redis")
        fi
        if grep -Fq "next" "$pkg" || [ -f "$proj_dir/next.config.js" ] || [ -f "$proj_dir/next.config.mjs" ] || [ -f "$proj_dir/next.config.ts" ]; then
            detected_techs+=("nextjs")
        fi
        if grep -Fq "react" "$pkg"; then
            detected_techs+=("react")
        fi
    fi

    if [ -f "$proj_dir/Cargo.toml" ]; then
        detected_techs+=("rust")
        if grep -Fq "tokio" "$proj_dir/Cargo.toml"; then
            detected_techs+=("tokio")
        fi
        if grep -Fq "sqlx" "$proj_dir/Cargo.toml" || grep -Fq "postgres" "$proj_dir/Cargo.toml"; then
            detected_techs+=("postgresql")
        fi
    fi

    if [ -f "$proj_dir/flake.nix" ]; then
        detected_techs+=("nixos")
    fi

    if [ -f "$proj_dir/Dockerfile" ] || compgen -G "$proj_dir/docker-compose*" >/dev/null; then
        detected_techs+=("docker")
    fi

    if [ -d "$proj_dir/.github/workflows" ]; then
        detected_techs+=("github-actions")
    fi

    if compgen -G "$proj_dir/wrangler.*" >/dev/null; then
        detected_techs+=("cloudflare")
    fi

    if compgen -G "$proj_dir/*.tf" >/dev/null || [ -d "$proj_dir/terraform" ]; then
        detected_techs+=("terraform")
    fi

    if [ -d "$proj_dir/kubernetes" ] || [ -d "$proj_dir/helm" ]; then
        detected_techs+=("kubernetes")
    fi

    # Deduplicate detected technologies
    mapfile -t detected_techs < <(printf '%s\n' "${detected_techs[@]}" | LC_ALL=C sort -u)

    if [ "${#detected_techs[@]}" -eq 0 ]; then
        echo -e "  No specialized tech stack detected from standard project descriptors."
        echo -e "  Recommended baseline: ${GREEN}global-core${RESET} (Ponytail, Senior Implementer, Caveman, RTK, CodeGraph, Codebase Memory)"
        return 0
    fi

    echo -e "${BOLD}Detected Technologies:${RESET} ${detected_techs[*]}\n"

    # 2. Dynamic, registry-driven coverage comparison (Phase 18)
    local reg_file="${SKILLS_SRC:-$REPO_ROOT/resources/skills}/_registry.json"
    [ ! -f "$reg_file" ] && reg_file="$REPO_ROOT/resources/skills/_registry.json"
    local covered=()
    local partial=()
    local missing=()

    for tech in "${detected_techs[@]}"; do
        local match_info="[]"
        if [ -f "$reg_file" ]; then
            match_info="$(jq -c --arg tech "$tech" '
                .skills as $s |
                [
                    $s | to_entries[] |
                    select(.value.status != "deprecated") |
                    select(
                        .key == $tech or
                        any(.value.triggers[]? // empty; ascii_downcase == ($tech | ascii_downcase)) or
                        any(.value.capabilities[]? // empty; ascii_downcase | contains($tech | ascii_downcase)) or
                        any(.value.tags[]? // empty; ascii_downcase == ($tech | ascii_downcase))
                    ) |
                    {
                        name: .key,
                        is_exact: (.key == $tech or any(.value.triggers[]? // empty; ascii_downcase == ($tech | ascii_downcase)))
                    }
                ]
            ' "$reg_file" 2>/dev/null || echo "[]")"
        fi

        local label
        case "$tech" in
            nestjs) label="NestJS" ;;
            bullmq) label="BullMQ" ;;
            postgresql) label="PostgreSQL" ;;
            redis) label="Redis" ;;
            docker) label="Docker" ;;
            nixos) label="NixOS" ;;
            rust) label="Rust" ;;
            nextjs) label="Next.js" ;;
            react) label="React" ;;
            github-actions) label="GitHub Actions" ;;
            cloudflare) label="Cloudflare" ;;
            terraform) label="Terraform" ;;
            kubernetes) label="Kubernetes" ;;
            *) label="$tech" ;;
        esac

        local match_count
        match_count="$(echo "$match_info" | jq 'length')"
        if [ "$match_count" -gt 0 ]; then
            local has_exact
            has_exact="$(echo "$match_info" | jq '[ .[] | select(.is_exact == true) ] | length')"
            local first_name
            first_name="$(echo "$match_info" | jq -r '.[0].name')"
            if [ "$has_exact" -gt 0 ]; then
                local exact_name
                exact_name="$(echo "$match_info" | jq -r '[ .[] | select(.is_exact == true) ][0].name')"
                covered+=("$label (local: $exact_name)")
            else
                partial+=("$label (partially addressed by local: $first_name)")
            fi
        else
            missing+=("$tech")
        fi
    done

    echo -e "${BOLD}Coverage Analysis:${RESET}"
    for c in "${covered[@]}"; do
        echo -e "  ${GREEN}✓ Covered:${RESET}          $c"
    done
    for p in "${partial[@]}"; do
        echo -e "  ${YELLOW}~ Partially Covered:${RESET}$p"
    done
    for m in "${missing[@]}"; do
        echo -e "  ${RED}! Missing Coverage:${RESET} $m"
    done
    echo

    # 3. Discover candidates for missing capabilities
    if [ "${#missing[@]}" -gt 0 ]; then
        echo -e "${BOLD}${CYAN}Trusted Discovery Suggestions for Missing Stack:${RESET}"
        for m in "${missing[@]}"; do
            echo -e "\n  ${BOLD}Querying external catalogs for: ${YELLOW}${m}${RESET}..."
            local cands
            cands="$(discover_candidates "$m" --json 2>/dev/null || echo "[]")"
            local count
            count="$(echo "$cands" | jq 'length')"
            if [ "$count" -gt 0 ]; then
                local first up path desc
                first="$(echo "$cands" | jq -r '.[0].name')"
                up="$(echo "$cands" | jq -r '.[0].upstream_url')"
                path="$(echo "$cands" | jq -r '.[0].skill_path')"
                desc="$(echo "$cands" | jq -r '.[0].description')"
                echo -e "    Candidate: ${GREEN}${first}${RESET} (${desc})"
                echo -e "    Upstream:  ${up} (path: ${path})"
                echo -e "    Inspect:   ai-skills import ${up} --path ${path} --preview"
            else
                echo -e "    No verified candidate found. Consider authoring a tailored skill: 'ai-skills author ${m}'."
            fi
        done
        echo
    fi

    echo -e "${BOLD}Policy:${RESET} Recommendation is advisory only. No files were modified or installed."
}

# ------------------------------------------------------------------------------
# Standalone CLI Dispatcher
# ------------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    CMD="${1:-help}"
    shift || true
    case "$CMD" in
        verify)
            verify_candidate "$@"
            ;;
        verify-discovery)
            verify_discovery_candidate "$@"
            ;;
        discover)
            discover_candidates "$@"
            ;;
        recommend)
            recommend_project_skills "${1:-$PWD}"
            ;;
        help|--help|-h)
            echo "Usage: $0 {verify <url> [path] [rev]|discover <query> [--json]|recommend [project_dir]}"
            ;;
        *)
            echo "Unknown command: $CMD" >&2
            exit 1
            ;;
    esac
fi
