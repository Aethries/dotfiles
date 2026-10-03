# CodeGraph AST Workflow & Tool Reference

## Workflow

```text
1. Task Arrival
   ↓
2. Query CodeGraph MCP (search_graph / query_graph)
   ↓
3. Inspect Target AST node (get_code_snippet / get_file_outline)
   ↓
4. Implement Smallest Correct Diff
   ↓
5. Update CodeGraph (detect_changes / index_repository)
   ↓
6. Verify Index Status (index_status)
```

## Available MCP Tools

| Tool | Purpose | When to Use |
| :--- | :--- | :--- |
| `search_graph` | Search symbols across codebase | Looking for a function, class, or type definition |
| `query_graph` | Query relationships (callers/callees/deps) | Finding where a function is called before changing its signature |
| `trace_path` | Trace call path from A to B | Tracing request flow from route handler to database |
| `get_code_snippet` | Extract specific AST node snippet | Reading targeted function without reading full file |
| `get_file_outline` | Get structural outline of a file | Understanding file layout before making edits |
| `detect_changes` | Sync incremental file changes | Immediately after editing or creating files |
| `index_repository` | Build or refresh full AST index | Initial setup or after switching Git branches |
| `index_status` | Check index freshness and node count | Verifying graph accuracy before deep refactors |
