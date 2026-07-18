# RAG Chat frontend (React + Vite)

A minimal chat page that talks to your n8n RAG workflow over a **webhook**. One input box,
one `fetch` POST, renders the answer, and keeps a **chat history** at the bottom. The whole point
is to show that once n8n exposes a webhook, *any* app can use your RAG pipeline.

> This is a **reference answer**. The exercise (in your course instructions) is to build your own
> version by prompting your AI IDE — come here only if you get stuck.

> **No Docker needed:** this runs on your laptop via Node/Vite and just calls n8n's webhook over
> HTTP. No new container images or dependencies.

## Run it
```bash
cd frontend
npm install
npm run dev
```
Open the URL it prints (default <http://localhost:5173>).

## Connect it to n8n
1. Build the webhook workflow in n8n (covered in your course instructions).
2. Copy the Webhook node's URL and paste it into `WEBHOOK_URL` at the top of `src/App.jsx`.
3. Make sure the n8n Webhook node's **Allowed Origins (CORS)** allows `http://localhost:5173`
   (or `*` for class).

## How it works
- The page POSTs `{ "question": "..." }` to the n8n webhook.
- n8n runs the RAG chain and the **Respond to Webhook** node returns `{ "answer": "..." }`.
- The page displays `data.answer`.

That's the webhook concept: a URL n8n listens on, that any frontend can call.
