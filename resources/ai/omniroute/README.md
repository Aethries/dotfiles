# OmniRoute

OmniRoute 3.8.50 is the only default client gateway. The pinned Nix package
uses the exact npm release artifact and its lockfile; it never runs an npm
global installer during bootstrap.

The service binds `OMNIROUTE_SERVER_HOST=127.0.0.1` and uses port `20128`.
Provider credentials and OmniRoute's encrypted SQLite state live under
`~/.local/state/omniroute`; they are runtime state and are not tracked here.

The template records the upstream environment contract. It is not an upstream
database/config file and must not be replaced with `omniroute configure` output.
