# Troubleshooting — when something isn't working

Something not behaving? Find your symptom in the list below and follow the steps for it. These are the
problems people hit most often, each with the exact fix.

A few things that apply throughout:

- **On Windows, use the WSL2 (Ubuntu) terminal** — not PowerShell. Your prompt should look like
  `you@PC:~$`. On **Mac**, use the built-in **Terminal**.
- **Run terminal commands from inside the `self-hosted-ai-starter-kit` folder** unless a step says
  otherwise. (`docker ps` and `docker exec` work from any folder.)
- Restarting or recreating a container is safe — your work lives in Docker volumes. Only
  `docker compose down -v` deletes your data.

**Find your symptom:**

1. [Read File says "Access to the file is not allowed"](#1-read-file-says-access-to-the-file-is-not-allowed)
2. [Read File says "No file(s) found"](#2-read-file-says-no-files-found)
3. [A node spins on "Executing node…" forever, with no error](#3-a-node-spins-on-executing-node-forever-with-no-error)
4. [The embeddings model isn't in the dropdown](#4-the-embeddings-model-isnt-in-the-dropdown)
5. ["npm run dev" says "vite: command not found"](#5-npm-run-dev-says-vite-command-not-found)
6. [Your web page says "I don't know" or shows no answer](#6-your-web-page-says-i-dont-know-or-shows-no-answer)
7. [Your chat answers are weak or say "I don't know"](#7-your-chat-answers-are-weak-or-say-i-dont-know)

---

## 1. Read File says "Access to the file is not allowed"

**What's happening:** n8n only reads files from one allowed folder, and the setting that points it at
`/data/shared` isn't active in your running n8n. Usually it's missing from your `.env`, n8n was
started before the setting was added, or (on Windows) your `.env` picked up Windows-style line endings.

Work through these in order.

First, check the setting is in your `.env`. In your terminal, run:
```
grep N8N_RESTRICT .env
```
If nothing prints, add it. In your terminal, run:
```
printf '\nN8N_RESTRICT_FILE_ACCESS_TO=/data/shared\nN8N_BLOCK_FILE_ACCESS_TO_N8N_FILES=false\n' >> .env
```
Don't run `cp .env.example .env` if you've already set things up — that overwrites your encryption key
and database password, which breaks the credentials you created.

Now restart n8n so it picks up the setting (a setting in `.env` only takes effect when the container
starts). In your terminal, run:
```
docker compose --profile cpu up -d --force-recreate n8n
```
Check the setting is now active. In your terminal, run:
```
docker exec n8n printenv N8N_RESTRICT_FILE_ACCESS_TO
```
It should print `/data/shared`.

**On Windows, also check for Windows line endings.** In your terminal, run:
```
docker exec n8n printenv N8N_RESTRICT_FILE_ACCESS_TO | cat -A
```
If you see `/data/shared^M$`, that `^M` is a Windows carriage return — it sneaks in when `.env` is
edited in a Windows editor. Remove it, then restart n8n. In your terminal, run:
```
sed -i 's/\r$//' .env
```
Then run:
```
docker compose --profile cpu up -d --force-recreate n8n
```

---

## 2. Read File says "No file(s) found"

**What's happening:** you gave n8n your computer's path. n8n runs inside Docker and only sees
`/data/shared/...`.

In the Read File node's **File(s) Selector**, use the path n8n sees:
```
/data/shared/corpus/nvidia-10k.pdf
```
Never use `/Users/...` (Mac), `C:\...` or `/mnt/c/...` (Windows).

Check the file is actually inside the container. In your terminal, run:
```
docker exec n8n ls /data/shared/corpus/
```
If it's not listed, copy it in. From inside `self-hosted-ai-starter-kit`, run:
```
cp ../sample-docs/nvidia-10k.pdf shared/corpus/
```

---

## 3. A node spins on "Executing node…" forever, with no error

**What's happening:** the n8n container is stuck — this isn't your workflow. Reading a small file is
instant, so a long spin with no progress means the container needs a restart.

To confirm: in your terminal, run:
```
docker exec n8n ls
```
If `docker ps` works but that command **hangs**, the container is stuck.

To fix it:

1. Click the whale icon in your menu bar → **Quit Docker Desktop** (Force Quit if it won't close).
2. Reopen Docker Desktop and wait until the whale icon stops moving.
3. Bring the stack back. In your terminal, run:
   ```
   docker compose --profile cpu up -d
   ```
4. Reload `http://localhost:5678` in your browser and run your workflow again.

**Is it actually stuck, or just slow?** During ingestion the spinner is normal **as long as** your
CPU is busy and the Qdrant count is climbing — a 131-page PDF takes a few minutes. Stuck means no
activity at all for a minute or two.

---

## 4. The embeddings model isn't in the dropdown

**What's happening:** in the **Embeddings Ollama** node, the Model dropdown shows only `llama3.2`, not
`nomic-embed-text`. The dropdown lists only the models that are actually downloaded into Ollama — and
the embeddings model hasn't been pulled yet.

See which models you have. In your terminal, run:
```
docker exec ollama ollama list
```
Pull the embeddings model. In your terminal, run:
```
docker exec ollama ollama pull nomic-embed-text
```
Wait for it to print **success**, then check both are now there. In your terminal, run:
```
docker exec ollama ollama list
```
Back in n8n, reopen the **Embeddings Ollama** node (or refresh the browser tab). `nomic-embed-text`
now appears in the Model dropdown — select it.

The Embeddings node must use `nomic-embed-text`, not `llama3.2` — they do different jobs, and the
embeddings model must match the one used when you ingested the document.

---

## 5. "npm run dev" says "vite: command not found"

**What's happening:** the page's packages aren't installed yet. A fresh copy of the repo has no
`node_modules` folder, so you have to install once before you can run the page.

In the `frontend` folder, install the packages. In your terminal, run:
```
npm install
```
Then start the page. In your terminal, run:
```
npm run dev
```
It prints a local address — open `http://localhost:5173` in your browser.

**If `node` or `npm` is missing** (you get `command not found`), or `node -v` shows a version below 18,
install Node first:

- **Mac** — in your terminal, run:
  ```
  brew install node
  ```
- **Windows (WSL2)** — install Node with nvm. In your terminal, run:
  ```
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  ```
  then run:
  ```
  exec $SHELL
  ```
  then run:
  ```
  nvm install --lts
  ```

Check it worked — `node -v` should show v18 or higher — then run `npm install` and `npm run dev` again.

---

## 6. Your web page says "I don't know" or shows no answer

If the page shows *anything* back — even "I don't know" — your webhook is working. The publish step,
CORS, and the URL are all fine. The issue is the answer itself. There are two separate causes.

**6a. The question isn't reaching the workflow.**

Test the webhook directly. In your terminal, run:
```
curl -s -X POST http://localhost:5678/webhook/rag-chat -H 'Content-Type: application/json' -d '{"question":"What are NVIDIA'"'"'s main risk factors?"}'
```
If the answer says something like *"no question provided"*, the question isn't wired into the chain.
In the **RAG webhook** workflow, open the **Question and Answer Chain** node and check:

- **Source for Prompt (User Message)** is set to **Define below**.
- **Prompt (User Message)** is in **Expression** mode and reads `{{ $json.body.question }}`.
- The grey preview under that field shows your actual question, not a blank.

**6b. The question gets through, but the answer is weak ("I don't know").**

The **RAG webhook** workflow has its **own** nodes — tuning your chat workflow doesn't change them. Apply
the same three settings here (see [some-tuning-tips.md](some-tuning-tips.md)): set the Retriever
**Limit** to 8, set the Ollama Chat Model's **Context Length** to 4096, and replace the chain's default
**System Prompt Template**.

Also check: the workflow is **Active** (published), and the Webhook node's **Allowed Origins (CORS)**
is set to `*`. If the workflow isn't Active, the page gets "Failed to fetch".

---

## 7. Your chat answers are weak or say "I don't know"

Small models hold back, and the chain's default prompt actually tells them to. Three settings fix
this — the full walkthrough is in **[some-tuning-tips.md](some-tuning-tips.md)**:

1. **Vector Store Retriever → Limit → 8.** The default of 4 fetches too little context.
2. **Ollama Chat Model → Options → Context Length → 4096.** This makes room for the retrieved text
   plus your question. If it's too small, Ollama cuts the start of the prompt — sometimes your question
   — and the model answers blind.
3. **Question and Answer Chain → System Prompt Template.** Replace the default *"…just say that you
   don't know"* with a prompt that answers from the context and only says it doesn't know when the
   context truly has nothing.

Before changing settings, check three things: is your question actually answered in the document; did
ingestion fill Qdrant (the collection should have a few hundred points); and is the retriever's
embedding model `nomic-embed-text` — the same one you used to ingest.
