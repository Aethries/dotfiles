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
# Normalize Candidate JSON Schema (Section 4)
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
# Provider Discovery Functions
# Priority:
# 1. official-vendor
# 2. anthropic-skills
# 3. skills-sh
# 4. agentic-awesome-skills
# 5. github-search fallback
# ------------------------------------------------------------------------------

load_fixture_candidates() {
    local query="${1:-}"
    local fixture_file="${DISCOVERY_FIXTURE_DIR:-$REPO_ROOT/tests/ai/fixtures/discovery}/candidates.json"
    if [ -f "$fixture_file" ]; then
        if [ -n "$query" ]; then
            jq -c --arg q "$query" '[ .[] | select((.name | test($q; "i")) or (.description | test($q; "i")) or (.skill_path | test($q; "i"))) ]' "$fixture_file"
        else
            jq -c '.' "$fixture_file"
        fi
        return 0
    fi
    echo "[]"
}

discover_from_anthropic() {
    local query="$1"

    # 1. Check offline fixtures first
    local fixture_data
    fixture_data="$(load_fixture_candidates "$query")"
    local filtered
    filtered="$(echo "$fixture_data" | jq -c '[ .[] | select(.source == "anthropic-skills") ]')"
    if [ "$(echo "$filtered" | jq 'length')" -gt 0 ]; then
        echo "$filtered"
        return 0
    fi

    # 2. Known high-value Anthropic official skills catalog
    local known=(
        "github-actions:https://github.com/anthropics/skills:skills/github-actions:GitHub Actions CI/CD workflows:official:MIT"
        "browser-tools:https://github.com/anthropics/skills:skills/browser-tools:Browser automation and web testing:official:MIT"
    )
    local results=()
    for item in "${known[@]}"; do
        IFS=":" read -r k_name k_url k_path k_desc k_trust k_lic <<< "$item"
        if [[ "$k_name $k_desc $k_path" =~ $query ]]; then
            results+=("$(normalize_candidate "$k_name" "anthropic-skills" "$k_url" "$k_path" "HEAD" "$k_desc" "$k_trust" "$k_lic" "anthropic-skills")")
        fi
    done

    if [ "${#results[@]}" -gt 0 ]; then
        printf '%s\n' "${results[@]}" | jq -s .
    else
        echo "[]"
    fi
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

    # Curated known index for skills.sh
    local known=(
        "browser-debugging:https://github.com/puppeteer/puppeteer:skills/browser-debugging:Headless browser automation and DOM inspection:community:Apache-2.0"
        "nextjs-runtime-debugging:https://github.com/vercel/next.js:skills/nextjs-runtime-debugging:Next.js App Router and hydration debugging:community:MIT"
    )
    local results=()
    for item in "${known[@]}"; do
        IFS=":" read -r k_name k_url k_path k_desc k_trust k_lic <<< "$item"
        if [[ "$k_name $k_desc $k_path" =~ $query ]]; then
            results+=("$(normalize_candidate "$k_name" "skills-sh" "$k_url" "$k_path" "HEAD" "$k_desc" "$k_trust" "$k_lic" "skills-sh")")
        fi
    done

    if [ "${#results[@]}" -gt 0 ]; then
        printf '%s\n' "${results[@]}" | jq -s .
    else
        echo "[]"
    fi
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

    # Curated known index for agentic-awesome-skills
    local known=(
        "nestjs-database-transaction-best-practices:https://github.com/sickn33/agentic-awesome-skills:skills/backend/nestjs-database-transaction-best-practices:NestJS database transaction management and rollback patterns:community:MIT"
    )
    local results=()
    for item in "${known[@]}"; do
        IFS=":" read -r k_name k_url k_path k_desc k_trust k_lic <<< "$item"
        if [[ "$k_name $k_desc $k_path" =~ $query ]]; then
            results+=("$(normalize_candidate "$k_name" "agentic-awesome-skills" "$k_url" "$k_path" "HEAD" "$k_desc" "$k_trust" "$k_lic" "agentic-awesome-skills")")
        fi
    done

    if [ "${#results[@]}" -gt 0 ]; then
        printf '%s\n' "${results[@]}" | jq -s .
    else
        echo "[]"
    fi
}

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

    # Curated vendor first-party index
    local known=(
        "bullmq-worker:https://github.com/taskforcesh/bullmq:skills/bullmq-worker:Distributed job processing and concurrency patterns for BullMQ with Redis:vendor:MIT"
        "prisma-transactions:https://github.com/prisma/prisma:skills/prisma-transactions:Interactive transactions and concurrency locking with Prisma ORM:vendor:Apache-2.0"
    )
    local results=()
    for item in "${known[@]}"; do
        IFS=":" read -r k_name k_url k_path k_desc k_trust k_lic <<< "$item"
        if [[ "$k_name $k_desc $k_path" =~ $query ]]; then
            results+=("$(normalize_candidate "$k_name" "official-vendor" "$k_url" "$k_path" "HEAD" "$k_desc" "$k_trust" "$k_lic" "official-vendor")")
        fi
    done

    if [ "${#results[@]}" -gt 0 ]; then
        printf '%s\n' "${results[@]}" | jq -s .
    else
        echo "[]"
    fi
}

discover_from_github() {
    local query="$1"
    # General fallback instructions or search URL
    echo "[]"
}

# ------------------------------------------------------------------------------
# Aggregate External Candidate Discovery
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

    local c_vendor
    c_vendor="$(discover_from_official_vendor "$query")"
    local c_anthropic
    c_anthropic="$(discover_from_anthropic "$query")"
    local c_skills_sh
    c_skills_sh="$(discover_from_skills_sh "$query")"
    local c_aas
    c_aas="$(discover_from_agentic_awesome "$query")"
    local c_gh
    c_gh="$(discover_from_github "$query")"

    # Merge candidates in strict priority order and deduplicate by name
    local all_candidates
    all_candidates="$(jq -s 'add | unique_by(.name)' <(echo "$c_vendor") <(echo "$c_anthropic") <(echo "$c_skills_sh") <(echo "$c_aas") <(echo "$c_gh"))"

    if [ "$output_json" = true ]; then
        echo "$all_candidates"
        return 0
    fi

    local total
    total="$(echo "$all_candidates" | jq 'length')"

    echo -e "${BOLD}${CYAN}=== External AI Skills Discovery: '${query}' ===${RESET}"
    if [ "$total" -eq 0 ]; then
        echo -e "  No external candidates found for '${query}' in trusted catalogs."
        echo -e "  Search directly via GitHub topic: https://github.com/search?q=topic%3Aagent-skills+${query}"
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
        echo -e "     ${BOLD}Preview:${RESET}   ai-skills import ${c_upstream} --path ${c_path} --preview"
        echo
        idx=$((idx + 1))
    done
}

# ------------------------------------------------------------------------------
# Project-Aware Skill Recommendation (Section 11)
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
        echo -e "  Recommended baseline: ${GREEN}global-core${RESET} (Ponytail, Junior, Caveman, RTK, Senior Implementer)"
        return 0
    fi

    echo -e "${BOLD}Detected Technologies:${RESET} ${detected_techs[*]}\n"

    # 2. Compare against local canonical library
    local covered=()
    local partial=()
    local missing=()

    for tech in "${detected_techs[@]}"; do
        case "$tech" in
            nestjs)
                covered+=("NestJS (local: nestjs)")
                ;;
            bullmq)
                covered+=("BullMQ (local: bullmq)")
                ;;
            postgresql)
                covered+=("PostgreSQL (local: postgresql)")
                ;;
            redis)
                covered+=("Redis (local: redis)")
                ;;
            docker)
                covered+=("Docker (local: docker)")
                ;;
            nixos)
                covered+=("NixOS (local: nixos)")
                ;;
            rust)
                covered+=("Rust (local: rust)")
                ;;
            cloudflare|terraform|kubernetes)
                partial+=("$tech (partially addressed by local: cloud-infra)")
                ;;
            *)
                missing+=("$tech")
                ;;
        esac
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
                local first
                first="$(echo "$cands" | jq -r '.[0].name')"
                local up
                up="$(echo "$cands" | jq -r '.[0].upstream_url')"
                local path
                path="$(echo "$cands" | jq -r '.[0].skill_path')"
                local desc
                desc="$(echo "$cands" | jq -r '.[0].description')"
                echo -e "    Candidate: ${GREEN}${first}${RESET} (${desc})"
                echo -e "    Upstream:  ${up} (path: ${path})"
                echo -e "    Inspect:   ai-skills import ${up} --path ${path} --preview"
            else
                echo -e "    No immediate trusted catalog candidate. Consider authoring a tailored skill: 'ai-skills author ${m}'."
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
        discover)
            discover_candidates "$@"
            ;;
        recommend)
            recommend_project_skills "${1:-$PWD}"
            ;;
        help|--help|-h)
            echo "Usage: $0 {discover <query> [--json]|recommend [project_dir]}"
            ;;
        *)
            echo "Unknown command: $CMD" >&2
            exit 1
            ;;
    esac
fi
