#!/usr/bin/env bash

repair_managed_ownership() {
    [ -n "${SUDO_USER:-}" ] || return 0

    # Callers pass only exact symlinks/files created or replaced by this repository.
    local managed_path
    for managed_path in "$@"; do
        [ -e "$managed_path" ] || [ -L "$managed_path" ] || continue
        chown -h "$SUDO_USER:" "$managed_path"
    done
}
