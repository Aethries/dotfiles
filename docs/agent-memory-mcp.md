# Agent Memory MCP Design

Status: evaluated, not installed

## Purpose

Agent Memory MCP should preserve durable engineering context across Claude Code, Codex, and Antigravity without replacing repository evidence or the existing CodeGraph/Codebase Memory index.

## Memory layers

| Layer | Source of truth | Scope | Use |
| --- | --- | --- | --- |
| Code structure | CodeGraph / Codebase Memory MCP | One project | Symbols, imports, callers, dependencies, index coverage |
| Durable project knowledge | ADRs, specs, plans, `AGENTS.md`, existing project notes | One project or repository | Accepted architecture, conventions, constraints, handoffs |
| Cross-session memory | Agent Memory MCP | Explicitly scoped project/user | Verified decisions, failure lessons, recent handoff state |
| Codex native memory | Codex runtime | Codex-specific | User preferences and Codex session continuity; not a shared source |

Memory must never outrank current source behavior, tests, or explicit user requirements.

## Candidate evaluation

### Official `@modelcontextprotocol/server-memory`

The official reference server is a local knowledge graph with entities, relations, and observations. It is easy to launch with Node and can use an explicit `MEMORY_FILE_PATH`. It is a useful protocol smoke test, but it has no engineering-specific lifecycle, semantic retrieval, or strong project-memory hygiene by itself. Do not use its default package-cache storage path.

Source: <https://github.com/modelcontextprotocol/servers/tree/main/src/memory>

### Basic Memory

Basic Memory stores notes as Markdown and exposes local MCP tools such as `search_notes`, `read_note`, `write_note`, and `build_context`. It is human-inspectable and suitable for durable decisions, but requires Python 3.12+ and `uv`; neither is currently available in this environment.

Sources: <https://docs.basicmemory.com/start-here/quickstart-local>, <https://docs.basicmemory.com/local/mcp-tools-local>

### `agent-memory-mcp`

This is the strongest fit for the intended engineering workflow. It provides typed memory, source-aware document retrieval, project-bank views, session close/consolidation, export/import, and Codex/Claude configuration examples. It supports local-only embeddings through Ollama or llama.cpp, but that adds a binary and local embedding-runtime dependency. The project documents Claude/Codex directly; Antigravity integration is protocol-compatible but must be verified by exposing the stdio server through the existing Antigravity MCP config.

Source: <https://github.com/ipiton/agent-memory-mcp>

### Mem0 hosted MCP

Mem0 provides managed semantic memory and direct Claude/Codex integration, but the default service stores data remotely and requires authentication. It is not the default choice for private source or local-only project decisions.

Source: <https://github.com/mem0ai/mem0/blob/main/docs/platform/mem0-mcp.mdx>

## Recommended rollout

1. Keep `agent-memory-bootstrap` MCP-agnostic, with repository files as fallback.
2. Add a pinned local `agent-memory-mcp` package to the NixOS dotfiles rather than using an unpinned `npx` or `curl | sh` installer.
3. Run it on demand over stdio per agent; do not create a boot service yet.
4. Scope memory by project and index only `docs/`, ADRs, specs, plans, runbooks, changelogs, and explicit memory records. Exclude credentials, secrets, generated files, and source trees by default.
5. Use local-only embeddings. If the local embedding backend is unavailable, retain keyword/structured memory instead of silently falling back to a hosted provider.
6. Add the same server under the namespaced `agent_memory` MCP entry for Codex, Claude Code, and Antigravity. Verify each client can list tools before enabling lifecycle hooks.
7. Start with explicit start-of-session recall and end-of-task summary. Enable automatic capture only after reviewing a sample of stored records and confirming redaction, project scoping, deduplication, and supersession behavior.

## Acceptance test before installation is considered complete

- Store one synthetic architecture decision from Codex.
- Recall it from Claude Code in the same project scope.
- Recall it from Antigravity without exposing another project's records.
- Mark the decision superseded and confirm stale recall is not presented as current.
- Export and restore the memory store.
- Confirm no secret, raw source file, or full transcript was persisted.
