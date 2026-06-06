#!/bin/bash
set -e

# =============================================================================
# Odysseus Home Assistant OS Add-on — Startup Script
# =============================================================================
# Maps HA Supervisor options to the environment variables Odysseus reads
# via python-dotenv (app.py). See README.md for variable documentation.
# =============================================================================

ENV_FILE="/app/.env"
DATA_DIR="${ODYSSEUS_DATA_DIR:-/data/odysseus}"

echo "[odysseus] Initializing Odysseus AI Assistant..."
echo "[odysseus] Data directory: ${DATA_DIR}"

# Ensure data directories exist
mkdir -p "${DATA_DIR}"
mkdir -p /app/data
mkdir -p /app/logs

# ---- Symlink /app/data -> /data/odysseus for persistence ----
if [ ! -L /app/data ] || [ "$(readlink /app/data)" != "${DATA_DIR}" ]; then
    if [ -d /app/data ] && [ ! -L /app/data ]; then
        echo "[odysseus] Migrating existing /app/data to ${DATA_DIR}..."
        cp -a /app/data/. "${DATA_DIR}/" 2>/dev/null || true
        rm -rf /app/data
    fi
    ln -sfn "${DATA_DIR}" /app/data
    echo "[odysseus] Symlinked /app/data -> ${DATA_DIR}"
fi

# ---- Determine Ollama URL ----
OLLAMA_URL="${OLLAMA_BASE_URL}"
if echo "${OLLAMA_URL}" | grep -qE "localhost|127\.0\.0\.1"; then
    for slug in local_ollama core_ollama a0d7b954_ollama; do
        if curl -s --max-time 2 "http://${slug}:11434/api/tags" >/dev/null 2>&1; then
            OLLAMA_URL="http://${slug}:11434"
            echo "[odysseus] Detected Ollama at ${slug}:11434"
            break
        fi
    done
fi

# ---- Determine SearXNG URL ----
SEARXNG_URL="${SEARXNG_BASE_URL}"
if echo "${SEARXNG_URL}" | grep -qE "localhost|127\.0\.0\.1"; then
    for slug in searxng local_searxng a0d7b954_searxng; do
        if curl -s --max-time 2 "http://${slug}:8080" >/dev/null 2>&1; then
            SEARXNG_URL="http://${slug}:8080"
            echo "[odysseus] Detected SearXNG at ${slug}:8080"
            break
        fi
    done
fi

# ---- Determine ChromaDB host ----
CHROMADB_HOST_VAL="${CHROMA_HOST}"
if [ "${CHROMADB_HOST_VAL}" = "localhost" ] || [ "${CHROMADB_HOST_VAL}" = "127.0.0.1" ]; then
    for slug in chromadb local_chromadb a0d7b954_chromadb; do
        if curl -s --max-time 2 "http://${slug}:8000/api/v2/heartbeat" >/dev/null 2>&1; then
            CHROMADB_HOST_VAL="${slug}"
            echo "[odysseus] Detected ChromaDB at ${slug}:8000"
            break
        fi
    done
fi

# ---- First-time setup (safe to re-run) ----
if [ ! -f /app/data/app.db ]; then
    echo "[odysseus] Running first-time setup..."
    gosu odysseus:odysseus python setup.py 2>/dev/null || true
fi

# ---- Build .env file from HA Supervisor options ----
# Maps HA option names to the variable names Odysseus actually reads.
cat > "${ENV_FILE}" <<'DOTENV'
# Auto-generated .env for Odysseus HA Add-on
# Do not edit manually - changes are overwritten at add-on startup.
# Configure values via HA Supervisor -> Add-ons -> Odysseus -> Configuration.

# LLM
OLLAMA_BASE_URL=${OLLAMA_URL}
LLM_MODEL=${LLM_MODEL:-qwen2.5:7b}

# Search
SEARXNG_INSTANCE=${SEARXNG_URL}

# Vector DB / Memory (leave CHROMADB_HOST empty to use local fastembed)
CHROMADB_HOST=${CHROMADB_HOST_VAL}
CHROMADB_PORT=${CHROMA_PORT:-8000}

# Embedding
EMBEDDING_MODEL=${EMBEDDING_MODEL:-BAAI/bge-small-en-v1.5}

# Data & runtime
ODYSSEUS_DATA_DIR=/data/odysseus
LOG_LEVEL=${LOG_LEVEL:-info}

# HA Ingress - Odysseus runs behind the HA auth proxy.
# Disable its own auth layer and trust the proxy headers.
AUTH_ENABLED=false
LOCALHOST_BYPASS=true

# Bind to all interfaces (Ingress connects via internal Docker network)
APP_BIND=0.0.0.0
APP_PORT=7000

# In-process task scheduler
ODYSSEUS_INPROCESS_TASKS=${ODYSSEUS_INPROCESS_TASKS:-1}

# CORS origins
ALLOWED_ORIGINS=$ALLOWED_ORIGINS
DOTENV

echo "[odysseus] Environment file written to ${ENV_FILE}"

# ---- Fix ownership (container may start as root) ----
chown -R odysseus:odysseus /app /data/odysseus 2>/dev/null || true

# ---- Forward signal handling ----
_cleanup() {
    echo "[odysseus] Received shutdown signal - stopping Odysseus..."
    if [ -n "${_PID}" ]; then
        kill -TERM "${_PID}" 2>/dev/null || true
        wait "${_PID}" 2>/dev/null || true
    fi
    echo "[odysseus] Odysseus stopped."
    exit 0
}
trap _cleanup SIGTERM SIGINT SIGHUP

# ---- Start Odysseus ----
echo "[odysseus] Starting Odysseus on port 7000..."
echo "[odysseus] Ollama:     ${OLLAMA_URL}"
echo "[odysseus] SearXNG:    ${SEARXNG_URL}"
echo "[odysseus] ChromaDB:   ${CHROMADB_HOST_VAL}:${CHROMA_PORT:-8000}"
echo "[odysseus] LLM Model:  ${LLM_MODEL}"
echo "[odysseus] Log Level:  ${LOG_LEVEL}"

# gosu drops to the non-privileged user. Run in background so the shell traps signals.
gosu odysseus:odysseus uvicorn app:app \
    --host 0.0.0.0 \
    --port 7000 \
    --log-level "${LOG_LEVEL:-info}" \
    --timeout-keep-alive 120 \
    &

_PID=$!
echo "[odysseus] Odysseus started (PID ${_PID})"
wait "${_PID}"
