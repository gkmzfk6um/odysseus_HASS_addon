# Changelog — Odysseus AI Assistant HA Add-on

## 0.1.0 — Initial Release

- First Home Assistant OS add-on release
- Python 3.12-slim base with Node.js 20+ for vite frontend build
- Integrated web UI with Ingress support (no separate port forwarding needed)
- Configurable via HA Supervisor options:
  - Ollama base URL
  - SearXNG base URL
  - ChromaDB host/port
  - LLM model selection
  - Embedding model selection
  - Log level
- Auth disabled by default (runs behind HA Ingress auth)
- Persistent storage via `/data/odysseus` (survives add-on updates)
- Starts after ChromaDB and SearXNG services
- Non-root execution via gosu (UID 1000)
- Graceful shutdown on SIGTERM/SIGINT
- Supports aarch64 and amd64 architectures