# Home Assistant Add-on: Odysseus AI Assistant

A Python-based AI Assistant WebUI with local LLM and RAG support.  
Connects to **Ollama**, **SearXNG**, and optionally **ChromaDB** for a full local AI stack.

## Requirements

| Service   | Add-on / Source                                      | Required | Notes                                                                            |
|-----------|------------------------------------------------------|----------|----------------------------------------------------------------------------------|
| Ollama    | [HA Add-on](https://github.com/home-assistant/addons/tree/master/ollama)          | yes      | Needs GPU or CPU-only model; set OLLAMA_BASE_URL accordingly.                    |
| SearXNG   | [HA Add-on](https://github.com/home-assistant/addons/tree/master/searxng)         | yes      | Web search provider for Deep Research and agent tools.                           |
| ChromaDB  | [chromadb-ha-addon](https://github.com/zopanix/chromadb-ha-addon) by **zopanix** | optional | Vector memory store. If omitted, Odysseus falls back to local fastembed (ONNX).  |

## Installation

1. Copy this `addon/` folder into your Home Assistant `addons/local/odysseus/` directory.
2. In Home Assistant, go to **Settings -> Add-ons -> Add-on Store -> Local add-ons**.
3. Click **Odysseus AI Assistant** and install.
4. Configure the options (Ollama URL, SearXNG URL, ChromaDB host, model names, etc.) under the **Configuration** tab.
5. Start the add-on.

## Configuration

All options are set in the HA Supervisor UI under **Add-ons -> Odysseus -> Configuration**.

| Option              | Default                         | Description                                                     |
|---------------------|----------------------------------|-----------------------------------------------------------------|
| OLLAMA_BASE_URL     | http://localhost:11434           | Ollama API endpoint                                             |
| SEARXNG_BASE_URL    | http://localhost:8080            | SearXNG instance URL                                            |
| CHROMA_HOST         | localhost                        | ChromaDB host (leave on localhost to auto-detect or skip)       |
| CHROMA_PORT         | 8000                             | ChromaDB port                                                   |
| LLM_MODEL           | qwen2.5:7b                       | Default LLM model tag                                           |
| EMBEDDING_MODEL     | BAAI/bge-small-en-v1.5           | Embedding model for RAG and memory                              |
| ODYSSEUS_DATA_DIR   | /data/odysseus                   | Persistent data path                                            |
| LOG_LEVEL           | info                             | debug, info, warning, error, critical                           |

## Using without ChromaDB

If you do **not** install the ChromaDB add-on, Odysseus will automatically fall back to **fastembed** (ONNX) for local embeddings and vector memory.

- Leave CHROMA_HOST on `localhost` - the startup script will fail to detect a running ChromaDB and write an empty CHROMADB_HOST into .env, which causes Odysseus to use the local fallback.
- This is fine for single-user setups. For multi-service or memory-heavy use, install ChromaDB.

## ChromaDB Community Add-on

Install the community ChromaDB add-on from:  
**[zopanix/chromadb-ha-addon](https://github.com/zopanix/chromadb-ha-addon)**

This provides a dedicated vector database that survives independently of Odysseus and can be shared across multiple HA add-ons.

## Mount Points

- `/data` — Persistent storage (config, database, uploads, skills, gallery, backups).
- `/app/data` is symlinked to `/data/odysseus` at startup.

## Architecture Support

- amd64 (x86_64)
- aarch64 (ARM64, e.g. Raspberry Pi 4/5, Home Assistant Green/Yellow)

## Building Locally

```bash
cd addon
docker build -t local/odysseus-addon .
```

## License

Odysseus is MIT-licensed. This add-on packaging is provided under the same license.
