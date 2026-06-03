# Tuning Tips — getting better answers (fewer "I don't know")

If the chat keeps replying **"I don't know"** even though the document covers the question, it's
almost always one of three dials. The default setup is deliberately *conservative* (good against
hallucination, bad for confident answers), so you have to loosen it.

> Do all three below, then ask your question again. Order of impact: **Limit → prompt → num_ctx**.

---

## The three dials (in the **"Chat with docs"** workflow)

### 1. Retriever `Limit` → 8
More retrieved chunks = more context for the model, so a small model stops hedging.

- Click the **Vector Store Retriever** node → set **Limit** to `8` (default is `4`).

*Don't over-raise it — `6`–`8` is the sweet spot for a document this size; too high dilutes the
answer and slows it down.*

### 2. Ollama Chat Model context window (`num_ctx`) → 4096
This one is easy to miss. If the retrieved chunks + your question exceed the model's context window,
Ollama **truncates the prompt from the start** — often dropping your actual question — and you get
"I don't know."

- Click the **Ollama Chat Model** node → **Options** → **Add Option** → **Context Length** (this is
  Ollama's `num_ctx`) → set `4096` (or `8192`).
- *(While you're there: set **Sampling Temperature** to about `0.2` for focused, factual answers.)*
- *If your n8n version doesn't list "Context Length," skip it — dials 1 and 3 still help a lot.*

### 3. The Q&A Chain system prompt → replace it
The **Question and Answer Chain** ships with this default prompt:

> *"…If you don't know the answer, just say that you don't know, don't try to make up an answer."*

That line literally tells the model to refuse when unsure — a big reason for the "I don't know"s.
Replace it:

- Click the **Question and Answer Chain** node → find the prompt field (the "You are an assistant…"
  text) → replace it with the prompt below.
- **Keep `Context: {context}` exactly** — that placeholder is where n8n injects the retrieved chunks.

```
You are a precise assistant answering questions about the provided document.
Use ONLY the retrieved context below to answer. Be direct and include as much
relevant detail as the context supports. If the context partially answers the
question, give that partial answer rather than refusing. Only say you don't know
if the context contains no relevant information at all. Do not invent facts that
are not in the context.
----------------
Context: {context}
```

What this changes: it removes the reflexive "just say you don't know," tells the model to give a
partial answer rather than refuse, but **keeps it grounded** ("use ONLY the context", "don't invent
facts") so you don't trade refusals for hallucinations.

**Save the workflow → ask your question again.**

---

## Optional: a bigger model
A larger model follows instructions more confidently:

```bash
docker exec ollama ollama pull mistral
```

Then in the **Ollama Chat Model** node, set **Model** to `mistral` (7B) instead of `llama3.2` (3B)
and compare.

---

## Before you tune — three quick sanity checks
These *also* cause "I don't know," and no amount of tuning fixes them:

1. **Is the question actually answerable from the document?** If it isn't in the source, "I don't
   know" is the *correct* answer.
2. **Did ingestion populate Qdrant?** The collection must have vectors (you should see a few hundred):
   ```bash
   curl -s http://localhost:6333/collections/documents | grep -o '"points_count":[0-9]*'
   ```
   If it's `0`, re-run the ingestion workflow first.
3. **Same embedding model on both sides?** The retriever's **Embeddings Ollama** must be
   `nomic-embed-text` — the *same* model used at ingestion — or the query vector won't match the
   stored vectors and retrieval returns nothing useful.
