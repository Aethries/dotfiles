# agentmemory.dev integration

This directory is the repository-synchronised configuration layer for
[`agentmemory.dev`](https://www.agent-memory.dev/). The canonical runtime is
`@agentmemory/agentmemory@0.9.29`, backed by `iii-engine` v0.11.2.

NixOS starts one loopback-only service named `agentmemory` on REST/MCP port
3111, viewer port 3113, streams port 3112, and iii port 49134. Mutable state is
kept in `/var/lib/agentmemory` through systemd `StateDirectory`; it is not
committed to the repository. The first service start may download the pinned
npm package and its dependencies into the primary user's npm cache.

All four configured agents use the official stdio shim
`@agentmemory/mcp`: Codex, Gemini/Antigravity CLI, Antigravity IDE, and Claude.
The shared `agent-memory-bootstrap` skill remains the repository-owned
workflow contract and treats live memory as context, never as proof.

Store only durable and verified project decisions, conventions, failure
lessons, and handoff notes in repository Markdown. Never store credentials,
private keys, raw source files, full transcripts, speculative notes, or noisy
command output.

## Verification

```sh
systemctl is-enabled agentmemory.service
systemctl is-active agentmemory.service
curl -fsS http://127.0.0.1:3111/agentmemory/health
curl -fsS http://127.0.0.1:3111/agentmemory/livez
```

The viewer is available at <http://127.0.0.1:3113> when the service is active.

## Git and Vault sync boundary

Commit this directory, the MCP files, skills, and reviewed Markdown to Git.
Keep mutable state and private settings outside Git, then create the encrypted
local snapshot with:

```sh
agentmemory-vault backup
```

The matching restore command is:

```sh
agentmemory-vault restore
```

The default file is `secrets.agentmemory.vault` and is ignored by Git. The
scope encrypts the service state and `~/.agentmemory` settings, including a
private `.env` if present, while omitting caches, logs, locks, sockets, and
downloaded binaries. The command refuses to run while the service/process is
downloaded binaries. The Zsh wrapper stops the service only when it was active,
restores it after the operation, and preserves the service's original state.
This is a local/manual encrypted backup, not automatic cloud or Vault-server
sync.
