# Local RAG with n8n — Cohort Starter

The starter code for building a **fully local, self-hosted Retrieval-Augmented Generation (RAG)**
app on your own machine: **n8n** (workflow engine) + **PostgreSQL** + **Qdrant** (vector store) +
**Ollama** (local LLM & embeddings) — all in Docker. No cloud, no API keys.

> 📘 **The full step-by-step build (wiring n8n, ingesting, chatting) is walked through in class.**
> This repo is the code you build *on top of* — it gives you the pinned stack, helper scripts,
> sample documents, and a reference frontend. The setup, troubleshooting, and tuning guides you need
> alongside class are in [`docs/`](docs/) — see below.

## Guides in this repo

These live in [`docs/`](docs/). Each is provided as a **PDF** and an **HTML** page (with per-command
Copy buttons) — use one of those to copy commands cleanly, rather than the raw `.md`. On Windows,
every command in these guides is meant to be run from your **WSL2 Ubuntu terminal** (open the Ubuntu
app from the Start menu), not PowerShell or Command Prompt.

| Guide | What it's for | Read it |
|---|---|---|
| **Setup — step by step** | Gets the whole stack running from scratch: install Docker, start the stack, pull the models, and verify it all works. Start here on day one. | [PDF](docs/simplified-step-by-step-instruction-for-setup.pdf) · [HTML](docs/simplified-step-by-step-instruction-for-setup.html) |
| **Common student issues** | Troubleshooting handout for the problems people actually hit — the n8n node that spins forever, "Access to the file is not allowed", a missing embeddings model, `vite: command not found`, and webhook errors. | [PDF](docs/common-student-issues.pdf) · [HTML](docs/common-student-issues.html) |
| **Some tuning tips** | What to do when the chatbot keeps answering "I don't know": raise the retriever limit, raise the model's context length, and replace the default system prompt. | [PDF](docs/some-tuning-tips.pdf) · [HTML](docs/some-tuning-tips.html) |

## What's in here

| Path | What it is |
|---|---|
| `self-hosted-ai-starter-kit/` | The pinned n8n stack (Docker Compose). You run everything from here. |
| `scripts/` | `preflight.sh` (checks your environment) · `verify_setup.sh` (checks the running stack) |
| `sample-docs/` | A sample document to ingest (`machine-learning-yearning.pdf`) plus notes on supported formats |
| `sql/` | `001_create_rag_chat_log.sql` — the table for logging questions & answers |
| `frontend/` | A minimal React + Vite chat page (reference) that talks to your n8n webhook |

## Quick start

You only need **Docker Desktop** (on Windows: with WSL2 integration on). You do **not** clone
anything else, and you do **not** build any Docker images — `docker compose up` pulls pre-built
public images on first run.

```bash
# 1. Check your environment
bash scripts/preflight.sh

# 2. Start the stack + create your .env + pull the models
cd self-hosted-ai-starter-kit
cp .env.example .env
docker compose --profile cpu up -d          # or --profile gpu-nvidia if you have an NVIDIA GPU
docker exec ollama ollama pull llama3.2
docker exec ollama ollama pull nomic-embed-text
cd ..

# 3. Verify
bash scripts/verify_setup.sh
```

Then open n8n at <http://localhost:5678> and follow your course instructions.

> 🛈 Inside n8n, address services by their **container name** (`http://ollama:11434`,
> `http://qdrant:6333`, `postgres:5432`) — not `localhost`. `localhost` only works in your browser.

## License

[PolyForm Noncommercial License 1.0.0](LICENSE.md) — free to use, modify, and share for
**non-commercial** purposes (learning, teaching, personal, research).
