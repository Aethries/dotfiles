# Bifrost

Bifrost is an optional provider-sidecar. It is never a client endpoint and is
disabled by default. OmniRoute remains the only client gateway.

The pinned Docker image uses the release tag plus an architecture-specific
digest from the registry manifest. `./scripts/ai.sh bifrost enable` requires
an explicit user action and either `~/.config/bifrost/config.json` or a
`BIFROST_API_KEY` environment variable before it changes the OmniRoute
environment. The user config is mounted read-only into Bifrost's `/app/data`.

OmniRoute 3.8.50 documents the integration through `BIFROST_ENABLED`,
`BIFROST_BASE_URL`, and `OMNIROUTE_RELAY_BACKEND=auto`; no client is pointed
directly at Bifrost.
