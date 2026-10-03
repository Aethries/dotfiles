---
name: mcp-server-author
description: "Model Context Protocol (MCP) server development: tool definitions, resource providers, prompt templates, stdio/SSE transports, and error envelopes across TypeScript and Python. Use when building or debugging custom MCP servers for AI agents."
---

# Model Context Protocol (MCP) Server Engineering

Standards for authoring robust, schema-compliant MCP servers connecting AI agents to local tools, APIs, and data sources.

## Core Rules

1. **Strict Tool Schemas (JSON Schema / Zod)**:
   - Every tool must specify detailed argument descriptions and types. LLMs rely strictly on tool docstrings and parameter descriptions to decide when and how to call tools.
   - Design tools to be narrow and atomic; avoid "kitchen sink" tools with ambiguous flag combinations.
   - Return structured text or JSON content within MCP standard response envelopes (`{ content: [{ type: "text", text: ... }] }`).

2. **Error Handling & Agent Feedback**:
   - Set `isError: true` on operational failures so the agent receives actionable error diagnostics rather than silent failures.
   - Provide clear recovery suggestions in error messages (e.g. `Invalid ID '123'. Must be UUID format like '...'`).

3. **Transport Selection**:
   - Use `stdio` transport for local CLI and desktop agent integrations (Antigravity, Claude Code, Codex).
   - Use Server-Sent Events (SSE) for remote, distributed, or multi-tenant web agent endpoints.
   - Never write debug logs to `stdout` in `stdio` servers; send logs exclusively to `stderr` to avoid corrupting the JSON-RPC stream.

4. **Idempotency & Guardrails**:
   - Mark state-mutating tools clearly.
   - Implement dry-run flags (`dryRun: boolean`) for destructive actions.
