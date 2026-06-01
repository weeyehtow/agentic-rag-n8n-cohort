#!/usr/bin/env bash
# preflight.sh — environment readiness check, run INSIDE your WSL2 terminal
# (Mac/Linux users can run it too). This is the gate you run BEFORE starting the
# stack; verify_setup.sh is the gate you run AFTER the stack is up.
#
# One-time installs this assumes are already done (see STUDENT_GUIDE.md):
#   - WSL2 installed (Windows:  wsl --install -d Ubuntu  then reboot)
#   - Docker Desktop installed with the WSL2 backend, and WSL Integration ON for your distro

set -u

ok()   { echo "✓ $1"; }
warn() { echo "! $1"; }
fail() { echo "✗ $1"; exit 1; }

# 0. Are we inside WSL2? (informational — Mac/Linux just skip the WSL-specific tips)
if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
    ok "Running inside WSL2"
    # 0a. Performance trap: working under the Windows-mounted filesystem.
    case "$PWD" in
        /mnt/*) warn "You are under $PWD (the Windows filesystem). Docker volumes here are MUCH slower. Clone and work from your WSL2 home, e.g. ~/agentic-rag." ;;
        *)      ok "Working inside the WSL2 filesystem (fast)" ;;
    esac
fi

# 1. Docker reachable from this shell (proves Docker Desktop's WSL integration is ON).
command -v docker >/dev/null 2>&1 \
    || fail "'docker' command not found here. In Docker Desktop: Settings -> Resources -> WSL Integration -> toggle ON your distro, Apply & Restart. (Windows install: https://www.docker.com/products/docker-desktop/)"
docker info >/dev/null 2>&1 \
    || fail "Docker daemon not responding. Start Docker Desktop and wait for the whale icon to stop animating, then re-run."
ok "Docker reachable ($(docker version --format '{{.Server.Version}}' 2>/dev/null))"

# 2. docker compose v2 available.
docker compose version >/dev/null 2>&1 \
    || fail "'docker compose' not available. Update Docker Desktop to a recent version."
ok "docker compose available"

# 3. End-to-end smoke test: pull + run a tiny image (daemon + registry + networking).
if docker run --rm hello-world >/dev/null 2>&1; then
    ok "docker run hello-world succeeded"
else
    fail "Could not run hello-world. Check your internet connection and that Docker Desktop is fully started."
fi

# 4. Disk space in the current filesystem (images + models need ~15 GB).
free_gb=$(df -Pg . 2>/dev/null | awk 'NR==2{print $4}')
if [ -n "${free_gb:-}" ]; then
    if [ "$free_gb" -lt 15 ]; then
        warn "Only ${free_gb} GB free here. The stack + models need ~15 GB. Free up space before class."
    else
        ok "${free_gb} GB free (enough for images + models)"
    fi
fi

echo
echo "Preflight passed. Next:"
echo "  1) clone the starter kit into your WSL2 home (NOT /mnt/c), then cd into it"
echo "  2) docker compose --profile gpu-nvidia up -d   (NVIDIA GPU)  OR  --profile cpu up -d"
echo "  3) docker exec ollama ollama pull llama3.2 && docker exec ollama ollama pull nomic-embed-text"
echo "  4) bash scripts/verify_setup.sh"
