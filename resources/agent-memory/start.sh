#!/usr/bin/env bash

set -euo pipefail

# Keep the upstream package version explicit and repository-reviewable. The
# NixOS service supplies the Node.js and pinned iii-engine runtime; npx only
# resolves the official agentmemory package and its npm dependency tree.
AGENTMEMORY_PACKAGE_VERSION="${AGENTMEMORY_PACKAGE_VERSION:-0.9.29}"

exec npx --yes --prefer-offline "@agentmemory/agentmemory@${AGENTMEMORY_PACKAGE_VERSION}"
