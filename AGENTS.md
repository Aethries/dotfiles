# Repository agent policy

This repository uses Agency as the task orchestrator and 9Router as the local
model gateway.

## Roles

- `think-*` agents are planning-only. They may inspect the worktree and run
  read-only checks, but must not edit files, commit, push, or merge.
- `implement-*` agents may edit only their Agency worktree and should leave
  commits and merges to the requested workflow.
- Model routing is selected by `scripts/agency-codex-agent.sh`; do not replace
  it with a direct provider URL or a hardcoded credential.

## Secrets and gateway

- Never print, commit, or embed `NINEROUTER_API_KEY`.
- The runtime endpoint is `http://127.0.0.1:20128/v1` and the key is supplied
  through the environment or the local vault-managed file
  `~/.config/9router/agency.env`.
- If the key is missing, stop and report the setup requirement; do not fall
  back to a direct external provider.
