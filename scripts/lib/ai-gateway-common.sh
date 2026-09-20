#!/usr/bin/env bash
# ==============================================================================
# AI Gateway Common Library
#
# Shared validation, loopback isolation, port inspection, and engine checkers
# for 9Router and OmniRoute scripts.
# ==============================================================================

validate_omniroute_node_version() {
    command -v node >/dev/null 2>&1 || return 1
    local version
    version="$(node -p 'process.versions.node' 2>/dev/null || echo '')"
    [ -n "$version" ] || return 1

    local major minor patch
    major="$(echo "$version" | cut -d. -f1)"
    minor="$(echo "$version" | cut -d. -f2)"
    patch="$(echo "$version" | cut -d. -f3 | cut -d- -f1)"

    # OmniRoute 3.8.50 yêu cầu Node >=22.22.2 <23 hoặc >=24 <27
    if [ "$major" -eq 22 ]; then
        if [ "$minor" -gt 22 ]; then
            return 0
        elif [ "$minor" -eq 22 ] && [ "$patch" -ge 2 ]; then
            return 0
        fi
        return 1
    elif [ "$major" -ge 24 ] && [ "$major" -lt 27 ]; then
        return 0
    else
        return 1
    fi
}

get_port_listeners() {
    local port="$1"
    if command -v ss >/dev/null 2>&1; then
        ss -tlHn "sport = :$port" 2>/dev/null | awk '{print $4}' | grep -v '^$' || true # BEST_EFFORT: listener discovery is informational; an empty result means no process was found.
    elif command -v lsof >/dev/null 2>&1; then
        lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null | awk 'NR>1 {print $9}' | sed 's/->.*//' | grep -v '^$' || true # BEST_EFFORT: lsof is a secondary listener probe; no output does not change gateway correctness.
    fi
}

is_port_listening() {
    local port="$1"
    local listeners
    listeners="$(get_port_listeners "$port")"
    [ -n "$listeners" ]
}

is_port_loopback_only() {
    local port="$1"
    local listeners
    listeners="$(get_port_listeners "$port")"
    [ -n "$listeners" ] || return 1

    # Kiểm tra từng listener gắn với port: chỉ cho phép 127.0.0.1 hoặc ::1
    local count=0
    while read -r bind; do
        [ -n "$bind" ] || continue
        count=$((count + 1))
        case "$bind" in
            127.0.0.1:"$port"|"[::1]:$port"|"::1:$port")
                ;;
            *)
                # Tìm thấy listener công khai hoặc ngoài loopback (vd: 0.0.0.0, *, LAN IP)
                return 1
                ;;
        esac
    done <<< "$listeners"

    [ "$count" -gt 0 ] || return 1
    return 0
}

wait_for_port() {
    local port="$1"
    local timeout="${2:-15}"
    local elapsed=0
    while [ "$elapsed" -lt "$timeout" ]; do
        if is_port_listening "$port"; then
            return 0
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
    return 1
}
