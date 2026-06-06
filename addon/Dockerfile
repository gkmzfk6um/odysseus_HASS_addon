# Home Assistant OS Add-on Dockerfile for Odysseus
# Based on python:3.12-slim with Node.js 20+ for frontend build

FROM python:3.12-slim

# System dependencies (includes tmux for Cookbook background downloads)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    curl \
    git \
    gosu \
    ca-certificates \
    tmux \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.x for vite frontend build
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone Odysseus from the official repo (or your own fork)
ARG ODYSSEUS_REPO_URL=https://github.com/pewdiepie-archdaemon/odysseus.git
ARG ODYSSEUS_BRANCH=main
RUN git clone --branch ${ODYSSEUS_BRANCH} --depth 1 ${ODYSSEUS_REPO_URL} . \
    || echo "ERROR: Could not clone from ${ODYSSEUS_REPO_URL} — set your fork in build.yaml args"

# Install Python dependencies (requirements are in the cloned repo)
RUN pip install --no-cache-dir pip uv --upgrade
RUN pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir fastembed chromadb-client \
    && (pip install --no-cache-dir -r requirements-optional.txt 2>/dev/null || true)

# Install npm dependencies and build frontend with vite
RUN npm ci --prefer-offline --no-audit --no-fund 2>/dev/null || npm install \
    && npm run build 2>/dev/null || echo "Frontend build skipped (non-fatal)"

# First-time setup: creates data dirs, database, default settings
RUN python setup.py 2>/dev/null || echo "setup.py skipped (non-fatal, run.sh will re-run)"

# Copy the run script and make it executable
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Create non-root user "odysseus" (UID 1000)
RUN useradd --create-home --uid 1000 --shell /bin/bash odysseus \
    && mkdir -p /data/odysseus /app/data /app/logs \
    && chown -R odysseus:odysseus /app /data/odysseus

# Healthcheck on the existing /api/health endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:7000/api/health || exit 1

EXPOSE 7000

ENTRYPOINT ["/bin/bash", "/run.sh"]