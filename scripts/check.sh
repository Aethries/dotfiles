#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"

bash -n scripts/*.sh scripts/lib/*.sh resources/zellij/scripts/*.sh tests/vault/*.sh tests/zellij/*.sh tests/ai/*.sh tests/kanata/*.sh
shellcheck scripts/*.sh scripts/lib/*.sh resources/zellij/scripts/*.sh tests/vault/*.sh tests/zellij/*.sh tests/ai/*.sh tests/kanata/*.sh

# Assert Kitty does not launch welcome layout directly
if grep -q "zellij -l welcome" resources/kitty/kitty.conf; then
    echo "Error: Kitty must not start zellij -l welcome directly" >&2
    exit 1
fi

# Assert launcher branches never invoke unnamed zellij
if grep -E 'exec zellij[[:space:]]*$' resources/zellij/scripts/launcher.sh; then
    echo "Error: launcher.sh contains unnamed zellij invocation" >&2
    exit 1
fi

# Assert equivalent layouts stay strictly synchronized
cmp resources/zellij/layouts/default.kdl resources/zellij/layouts/compact.kdl
cmp resources/zellij/layouts/default.kdl resources/zellij/layouts/dotfiles.kdl

# Run isolated unit test suites
bash tests/vault/vault_test.sh >/dev/null
bash tests/zellij/launcher_test.sh >/dev/null
bash tests/ai/omniroute_test.sh >/dev/null
bash tests/ai/skills_test.sh >/dev/null
bash tests/kanata/recovery_test.sh >/dev/null

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
SYSTEMD_UNIT_PATH="$service_check_dir:/nix/var/nix/profiles/system/etc/systemd/system:/run/current-system/sw/lib/systemd/system" systemd-analyze verify "$service_check_dir"/*.service

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
if command -v kanata >/dev/null; then
    kanata --check -c resources/kanata/kanata.kbd >/dev/null
    kanata --check -c resources/kanata/fallback.kbd >/dev/null
fi

echo "All checks passed."
