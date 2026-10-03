---
name: codebase-memory
description: >-
  Persistent AST codebase memory and relationship index. Use to resolve call hierarchies, imports, interfaces, and dependencies without burning tokens on whole-file scans. Requires updating index when code changes.
---

# Codebase Memory MCP Skill

Codebase Memory maintains a local Tree-sitter SQLite graph representation of the project (`.codegraph/memory.sqlite`).

## Operational Rules

1. **Context Economy**:
   - Query the graph instead of ingesting dozens of source files into prompt context.
   - Use `get_code_snippet` to retrieve only the relevant lines of code.
2. **Mandatory Synchronization**:
   - Always run `detect_changes` after writing code to ensure the memory graph reflects recent modifications.
   - Run `check_index_coverage` when new folders or packages are introduced.
3. **Local Storage**:
   - Database is stored locally in `.codegraph/` and is strictly git-ignored.
4. **Reference Guide**:
   - See [memory-guide.md](./references/memory-guide.md) for full integration patterns.
