#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"

bash -n scripts/*.sh
bash -n resources/zellij/scripts/*.sh
shellcheck scripts/*.sh resources/zellij/scripts/*.sh

mapfile -t nix_files < <(find . -name '*.nix' -not -path './.machine/*' -print)
nixfmt --check "${nix_files[@]}"
# Use a path flake so newly created files are evaluated before they are staged.
nix flake check "path:$PWD" --no-build

jq empty \
    resources/antigravity/product.json \
    resources/antigravity/extensions.lock.json \
    resources/gemini/mcp_config.json \
    resources/static/default.code-profile
jq -e '
    .extensions
    | all(
        .id != null
        and .version != null
        and (.sha256 | test("^[0-9a-f]{64}$"))
        and (.download_url | startswith("https://marketplace.visualstudio.com/"))
    )
' resources/antigravity/extensions.lock.json >/dev/null
# Validate unit structure without requiring optional per-user runtime binaries
# (for example ~/.local/bin/9router) to exist on the checking machine.
service_check_dir="$(mktemp -d -t dotfiles-systemd-check-XXXXXX)"
trap 'rm -rf "$service_check_dir"' EXIT
for service in resources/systemd/user/*.service; do
    sed \
        -e 's|^ExecStartPre=.*|ExecStartPre=/run/current-system/sw/bin/true|' \
        -e 's|^ExecStart=.*|ExecStart=/run/current-system/sw/bin/true|' \
        "$service" > "$service_check_dir/$(basename "$service")"
done
systemd-analyze verify "$service_check_dir"/*.service

if command -v noctalia >/dev/null; then
    noctalia config validate resources/noctalia/config.toml
fi
if command -v niri >/dev/null; then
    niri validate -c resources/niri/config.kdl
fi
if command -v kitty >/dev/null; then
    kitty +runpy 'import sys; from kitty.config import load_config; bad = []; load_config(sys.argv[1], accumulate_bad_lines=bad); print("\n".join(map(str, bad))); raise SystemExit(bool(bad))' "$PWD/resources/kitty/kitty.conf"
fi
if command -v zellij >/dev/null; then
    ZELLIJ_CONFIG_FILE="$PWD/resources/zellij/config.kdl" zellij setup --check >/dev/null
    ZELLIJ_CONFIG_DIR="$PWD/resources/zellij" zellij setup --dump-layout default >/dev/null
    ZELLIJ_CONFIG_DIR="$PWD/resources/zellij" zellij setup --dump-layout dotfiles >/dev/null
    ZELLIJ_CONFIG_DIR="$PWD/resources/zellij" zellij setup --dump-layout compact >/dev/null
    ZELLIJ_CONFIG_DIR="$PWD/resources/zellij" zellij setup --dump-layout work >/dev/null
fi

echo "All checks passed."
