# Sample documents (your corpus source)

These are the documents the RAG app ingests. `course-faq.txt` is the bundled demo.

## Use your own corpus
1. Put your files here (or anywhere you like).
2. Copy them into the n8n drop-zone before ingesting:
   ```bash
   cp sample-docs/*.txt self-hosted-ai-starter-kit/shared/corpus/
   # or a PDF:
   cp ~/my-handbook.pdf  self-hosted-ai-starter-kit/shared/corpus/
   ```
3. In the ingestion workflow's **Read Files from Disk** node, point the
   **File(s) Selector** at the corpus, e.g. `/data/shared/corpus/**/*`.

## Supported formats
| Format | Works? | How |
|---|---|---|
| `.txt`, `.md` | yes | Default Data Loader reads text directly |
| `.pdf` | yes | add an **Extract from File -> Extract From PDF** node (Step 5h) |
| `.csv`, `.xlsx`, `.xls`, `.html` | yes | **Extract from File** with the matching operation |
| `.docx` (Word) | no | save as PDF first, then ingest the PDF |

See STUDENT_GUIDE.md Step 5 (and 5h for PDFs/other formats).
