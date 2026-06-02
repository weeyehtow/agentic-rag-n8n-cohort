#!/usr/bin/env bash
# verify_setup.sh — acceptance gate for the n8n RAG course (macOS / Linux / WSL2).
# Exits 0 only when the full Dockerized stack is up and both Ollama models are present.
#
# Windows: run this INSIDE your WSL2 terminal (where Docker Desktop's WSL
# integration makes the `docker` command available), not in PowerShell.
#
# Run it AFTER you have:
#   1) started Docker Desktop
#   2) cd into the self-hosted-ai-starter-kit folder
#   3) cp .env.example .env
#   4) docker compose --profile cpu up -d        (DEFAULT - any machine)
#      docker compose --profile gpu-nvidia up -d (ONLY with an NVIDIA GPU)
#   5) docker exec ollama ollama pull llama3.2
#   6) docker exec ollama ollama pull nomic-embed-text

set -u

ok()   { echo "✓ $1"; }
fail() { echo "✗ $1"; exit 1; }

# 1. Docker installed and the daemon is running.
command -v docker >/dev/null 2>&1 \
    || fail "Docker CLI not found. Install Docker Desktop. (Windows: also enable WSL2 integration, then run this inside WSL2.)"
docker info >/dev/null 2>&1 \
    || fail "Docker daemon not running. Start Docker Desktop and wait until the whale icon is steady."
ok "Docker is installed and running ($(docker version --format '{{.Server.Version}}' 2>/dev/null))"

# 2. docker compose v2 available.
docker compose version >/dev/null 2>&1 \
    || fail "'docker compose' not available. Update Docker Desktop to a recent version."
ok "docker compose available"

# 3. The four stack containers are running.
running() { docker ps --format '{{.Names}}' | grep -qi "$1"; }
running '^n8n$'      || fail "n8n container not running. Start the stack: docker compose --profile cpu up -d (or --profile gpu-nvidia)"
running '^ollama$'   || fail "ollama container not running. If 'up' failed partway (e.g. a 'ports are not available' / 'forwards/expose ... 500' message), run 'docker compose --profile cpu down' then 'docker compose --profile cpu up -d' again. If you instead saw 'port already allocated' on 11434, quit any native Ollama first."
running '^qdrant$'   || fail "qdrant container not running. Start the stack: docker compose --profile cpu up -d"
PG=$(docker ps --format '{{.Names}}' | grep -i postgres | head -n1)
[ -n "$PG" ] || fail "postgres container not running. Start the stack: docker compose --profile cpu up -d"
ok "All four containers running (n8n, ollama, qdrant, $PG)"

# 4. Postgres healthy.
docker exec "$PG" pg_isready -U root >/dev/null 2>&1 \
    || fail "Postgres not accepting connections yet. Give it ~30s after startup, then re-run."
ok "Postgres healthy (accepting connections)"

# 5. Ollama reachable from inside n8n (the address n8n will actually use).
docker exec n8n sh -c 'wget -qO- http://ollama:11434/api/tags' >/dev/null 2>&1 \
    || fail "n8n cannot reach Ollama at http://ollama:11434 on the internal network. Are all containers on the same compose project?"
ok "n8n can reach Ollama at http://ollama:11434"

# 6. Both models present in the CONTAINER Ollama (not your native one).
MODELS=$(docker exec ollama ollama list 2>/dev/null)
echo "$MODELS" | grep -q 'llama3.2' \
    || fail "Model 'llama3.2' not in the container Ollama. Pull it: docker exec ollama ollama pull llama3.2"
ok "llama3.2 present (chat model)"
echo "$MODELS" | grep -q 'nomic-embed-text' \
    || fail "Model 'nomic-embed-text' not in the container Ollama. Pull it: docker exec ollama ollama pull nomic-embed-text"
ok "nomic-embed-text present (embedding model)"

# 7. n8n can reach Qdrant.
docker exec n8n sh -c 'wget -qO- http://qdrant:6333/collections' >/dev/null 2>&1 \
    || fail "n8n cannot reach Qdrant at http://qdrant:6333 on the internal network."
ok "n8n can reach Qdrant at http://qdrant:6333"

# 8. n8n UI reachable from the host browser.
if command -v curl >/dev/null 2>&1; then
    curl -sf -o /dev/null http://localhost:5678 \
        || fail "n8n UI not responding at http://localhost:5678. Check 'docker ps' and container logs."
    ok "n8n UI reachable at http://localhost:5678"
fi

echo
echo "All checks passed. Your RAG stack is ready."
