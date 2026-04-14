# ccbox

You are running inside ccbox — a containerized Claude Code workstation for document generation.

## What you can do

You have skills and tools installed for creating and editing office documents. Use the built-in skills when the user asks you to work with documents:

- **/pdf** — Create, edit, merge, split, OCR PDF documents
- **/xlsx** — Create and edit Excel spreadsheets with formulas and formatting
- **/pptx** — Create and edit PowerPoint presentations
- **/docx** — Create and edit Word documents with tracked changes
- **/doc-coauthoring** — Structured workflow for co-authoring documentation
- **/internal-comms** — Templates for status reports, newsletters, 3P updates
- **/theme-factory** — Apply consistent themes to slides, docs, reports
- **/canvas-design** — Create visual art, posters, infographics as PDF/PNG
- **/brand-guidelines** — Apply consistent brand identity to documents
- **/skill-creator** — Create new custom skills

System tools available: LibreOffice (use `--headless` flag), Pandoc, Tesseract OCR, qpdf, pdftk, ImageMagick.

## Templates (IMPORTANT)

**ALWAYS check for templates before creating any document.** Look in these locations:
1. `/workspace/` — template files directly in the workspace root
2. `/workspace/templates/` — dedicated templates folder
3. `~/.claude/templates/` — shared templates available in all sessions

If a template exists for the document type being created (e.g. any `.pptx` file when creating a presentation, any `.docx` when creating a Word document), you MUST use it. Do NOT create from scratch when a template is available. Always follow the skill's documented workflow exactly — do not use alternative libraries or shortcuts that bypass the skill's approach.

## File organization

Follow these rules strictly:

1. **Final output** → `/workspace/`. Only the document the user asked for. Nothing else.
   - User asks for a PPTX → one `.pptx` in `/workspace/`
   - User asks for a PDF → one `.pdf` in `/workspace/`
   - No preview PDFs, no thumbnail images, no intermediate files

2. **Working files** → `/workspace/.ccbox/`. Everything that isn't the final output:
   - Generation scripts (Python/Node)
   - Intermediate files (unpacked XML, temp conversions)
   - QA files (preview PDFs, thumbnail images)

3. **Cleanup** → When done, delete the contents of `/workspace/.ccbox/` (keep the folder). The user's workspace should contain only the final document(s) they requested.

## Your Preferences

Add your personal preferences below. This section persists across container restarts.

```
# Example:
# - Always use TypeScript for Node scripts
# - Prefer reportlab for PDF generation
```
