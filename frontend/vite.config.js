import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// Minimal Vite config. Dev server runs on http://localhost:5173 by default.
export default defineConfig({
  plugins: [react()],
})
