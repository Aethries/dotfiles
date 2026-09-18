# CodeGraph

CodeGraph server 0.20.1 is supplied by a checksum-verified Nix package. The
MCP wrapper indexes only the current Git workspace (or an explicitly supplied
workspace), never `$HOME`, `/`, Downloads, or Documents.

The `core` MCP profile is used by default to keep the client tool schema small.
Persistent graph/memory state stays outside Git. `ai.sh codegraph status` keeps
the workspace path, Git HEAD, tool version, config hash, and watcher state.
