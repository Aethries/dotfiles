# Bifrost AI Gateway

High-performance Go-based LLM gateway providing unified OpenAI-compatible routing, sub-millisecond adaptive load balancing, streaming token relay, and multi-provider failover chains.

## Co-Existence Architecture

| Service | Port | Role | Dashboard |
| :--- | :--- | :--- | :--- |
| **9Router** | `20128` | Multi-account OAuth, Antigravity tokens, credential lifecycle | `http://localhost:20128/dashboard` |
| **OmniRoute** | `20129` | Multi-client provider routing & sandbox profiles | `http://localhost:20129/dashboard` |
| **Bifrost** | `20130` | Ultra-fast Go streaming relay, adaptive load balancer & fallbacks | `http://localhost:20130/` |

## CLI Commands

- `bifrost status`: Check systemd service status
- `bifrost restart`: Restart service
- `bifrost logs`: Follow journal logs
- `bifrost ui`: Open web dashboard in browser
- `init-bifrost`: Run idempotent setup and service reconciliation
