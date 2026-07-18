-- Chat log table for the RAG app (Step 7).
-- Stores every question/answer the chat workflow produces, mirroring the
-- 'interactions' table from the FastAPI course.
-- Apply once:  docker exec <postgres-container> psql -U root -d n8n -f - < sql/001_create_rag_chat_log.sql
--   (or paste into an n8n Postgres "Execute Query" node)
CREATE TABLE IF NOT EXISTS rag_chat_log (
  id         SERIAL PRIMARY KEY,
  question   TEXT NOT NULL,
  answer     TEXT NOT NULL,
  model      TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
