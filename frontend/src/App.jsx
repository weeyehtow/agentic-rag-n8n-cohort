import React, { useState } from 'react'

// ─────────────────────────────────────────────────────────────────────────────
// PASTE YOUR n8n WEBHOOK URL HERE.
// In n8n, open the Webhook node and copy its *Production* URL (after you Publish
// the workflow). It looks like: http://localhost:5678/webhook/<some-id>/chat
// While testing before publishing, use the *Test* URL instead (and click
// "Listen for test event" in n8n before each send).
const WEBHOOK_URL = 'http://localhost:5678/webhook/rag-chat'
// ─────────────────────────────────────────────────────────────────────────────

export default function App() {
  const [question, setQuestion] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  // Chat history: a list of { question, answer } exchanges, newest shown last.
  const [history, setHistory] = useState([])

  async function ask(e) {
    e.preventDefault()
    if (!question.trim()) return
    const asked = question
    setQuestion('')
    setLoading(true)
    setError('')
    try {
      // Send the question to n8n as JSON.
      const res = await fetch(WEBHOOK_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ question: asked }),
      })
      if (!res.ok) throw new Error(`Webhook returned ${res.status}`)
      const data = await res.json()
      // n8n's "Respond to Webhook" node returns our JSON. We read the "answer" field.
      const answer = data.answer ?? JSON.stringify(data, null, 2)
      setHistory((h) => [...h, { question: asked, answer }])
    } catch (err) {
      setError(
        `${err.message}. Check: (1) the workflow is active/published, ` +
        `(2) the Webhook URL above is correct, (3) CORS "Allowed Origins" is set in n8n.`
      )
    } finally {
      setLoading(false)
    }
  }

  return (
    <div style={styles.page}>
      <div style={styles.card}>
        <h1 style={styles.h1}>Chat with the NVIDIA 10-K</h1>
        <p style={styles.sub}>Ask a question — answered by your local RAG pipeline via n8n.</p>

        <form onSubmit={ask} style={styles.form}>
          <input
            style={styles.input}
            value={question}
            onChange={(e) => setQuestion(e.target.value)}
            placeholder="e.g. What are NVIDIA's main risk factors?"
          />
          <button style={styles.button} disabled={loading}>
            {loading ? 'Thinking…' : 'Ask'}
          </button>
        </form>

        {error && <div style={styles.error}>{error}</div>}

        {/* Chat history — every past exchange, oldest first */}
        <div style={styles.history}>
          {history.map((turn, i) => (
            <div key={i} style={styles.turn}>
              <div style={styles.q}>You: {turn.question}</div>
              <div style={styles.a}>{turn.answer}</div>
            </div>
          ))}
          {history.length === 0 && !loading && (
            <p style={styles.empty}>Your conversation will appear here.</p>
          )}
        </div>
      </div>
    </div>
  )
}

const styles = {
  page: { fontFamily: 'system-ui, sans-serif', background: '#0f1115', minHeight: '100vh', display: 'flex', justifyContent: 'center', alignItems: 'flex-start', padding: '48px 16px', color: '#e6e6e6' },
  card: { width: '100%', maxWidth: 640, background: '#1a1d24', borderRadius: 12, padding: 28, boxShadow: '0 8px 30px rgba(0,0,0,.4)' },
  h1: { margin: 0, fontSize: 22 },
  sub: { color: '#9aa0aa', marginTop: 6, marginBottom: 20, fontSize: 14 },
  form: { display: 'flex', gap: 8 },
  input: { flex: 1, padding: '12px 14px', borderRadius: 8, border: '1px solid #333', background: '#0f1115', color: '#e6e6e6', fontSize: 15 },
  button: { padding: '12px 20px', borderRadius: 8, border: 'none', background: '#f59e0b', color: '#111', fontWeight: 600, cursor: 'pointer', fontSize: 15 },
  error: { marginTop: 16, padding: 12, borderRadius: 8, background: '#3a1d1d', color: '#ffb4b4', fontSize: 13, lineHeight: 1.5 },
  history: { marginTop: 24, display: 'flex', flexDirection: 'column', gap: 16 },
  turn: { borderTop: '1px solid #2a2e37', paddingTop: 16 },
  q: { color: '#9aa0aa', fontSize: 14, marginBottom: 8 },
  a: { whiteSpace: 'pre-wrap', background: '#11261b', border: '1px solid #1f5133', borderRadius: 8, padding: 14, fontSize: 15, lineHeight: 1.55 },
  empty: { color: '#6b7280', fontSize: 13, fontStyle: 'italic' },
}
