# Codebase Memory Guide

## Best Practices

1. **Symbol Navigation**:
   - When asked "Where is X handled?", use `search_graph` with symbol name.
   - When asked "What breaks if I change Y?", use `query_graph` with relation `callers`.
2. **Incremental Indexing**:
   - After modifying any TypeScript/TSX file, call `detect_changes` to incrementally parse and update AST nodes.
3. **Branch Switches**:
   - If switching git branches, run `index_repository` to re-sync graph state with current working tree.
