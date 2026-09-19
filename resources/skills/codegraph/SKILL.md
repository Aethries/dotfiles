---
name: codegraph
description: >-
  Mandatory AST knowledge graph navigation using CodeGraph / Codebase Memory MCP. Prohibits brute-force file scanning and requires updating the graph after file mutations to avoid context drift and token waste.
---

# CodeGraph MCP Skill

This skill enforces AST knowledge graph queries over blind text searches to minimize token consumption and maintain precise architectural context.

## Mandatory Rules

1. **Graph Queries First**:
   - Never run unbounded `grep` or read entire file hierarchies when looking for callers, callees, definitions, or imports.
   - Always query the CodeGraph MCP server first using:
     - `search_graph`: find symbols, functions, classes, and types by name.
     - `query_graph`: inspect relationships (`callers`, `callees`, `dependencies`, `imports`).
     - `trace_path`: trace execution paths between components.
     - `get_file_outline`: inspect structure before reading file contents.
2. **Auto-Update On File Changes**:
   - Whenever you create, modify, or delete source files, you MUST update the graph:
     - Call MCP tool `detect_changes` or `index_repository`.
     - Verify status using `index_status`.
   - Never leave the AST graph stale after a code modification.
3. **Reference Guide**:
   - For detailed MCP tool signatures and query patterns, see [ast-workflow.md](./references/ast-workflow.md).
