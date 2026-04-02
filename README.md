# ccbox

Create professional documents with AI — PDFs, presentations, spreadsheets, and Word documents — by describing what you need in plain language.

ccbox runs [Claude Code](https://docs.anthropic.com/en/docs/claude-code) inside a Docker container with all the tools pre-installed for document generation. No setup, no dependencies to install — just describe what you want and get polished documents back.

## Quick start

**Install:**

```bash
curl -fsSL https://raw.githubusercontent.com/mk0e/ccbox/main/install.sh | bash
```

The installer sets up the `ccbox` command and walks you through authentication. You'll need Docker (or Podman) running.

**Use from terminal:**

```bash
ccbox
```

Opens an interactive Claude Code session. Ask it to create documents:

```
> Create a PDF report with Q1 sales charts and an executive summary
> Make a 10-slide pitch deck for a startup called Acme AI
> Build an Excel budget tracker with monthly columns and formulas
```

**Use from browser:**

```bash
ccbox web
```

Opens a browser-based interface at `http://localhost:8080` with a visual editor, file explorer, and Claude Code chat panel. Same capabilities, more visual.

Use a custom port if 8080 is taken:

```bash
ccbox web 3000
```

**Stop the web interface:**

```bash
ccbox stop
```

## How it works

```
You describe a document
        ↓
Claude Code creates it using built-in skills and tools
        ↓
The finished file appears in your current directory
```

ccbox mounts your current directory into the container. Files Claude creates show up right where you ran the command.

## Two ways to interact

| | Terminal (`ccbox`) | Browser (`ccbox web`) |
|---|---|---|
| **Interface** | Claude Code CLI in your terminal | VS Code in browser with Claude Code extension |
| **Best for** | Quick tasks, scripting, power users | Visual work, previewing documents, casual users |
| **File access** | Current directory mounted at `/workspace` | Same — visible in the file explorer |
| **Auth** | API key or Claude account | Same — configured once via installer |

Both modes use the same container image and the same tools.

## What's inside

### Skills

ccbox comes with 10 built-in skills that Claude uses automatically:

| Skill | What it does |
|-------|-------------|
| `/pdf` | Create, edit, merge, split, OCR PDF documents |
| `/xlsx` | Create and edit Excel spreadsheets with formulas |
| `/pptx` | Create and edit PowerPoint presentations |
| `/docx` | Create and edit Word documents with tracked changes |
| `/doc-coauthoring` | Structured co-authoring workflow |
| `/internal-comms` | Templates for status reports, newsletters |
| `/theme-factory` | Apply consistent themes to documents |
| `/canvas-design` | Create visual art, posters, infographics |
| `/brand-guidelines` | Apply consistent brand identity |
| `/skill-creator` | Create new custom skills |

### Tools and libraries

**System:** LibreOffice, Pandoc, Tesseract OCR, qpdf, pdftk, ImageMagick

**Python:** reportlab, pdfplumber, pypdf, python-pptx, python-docx, openpyxl, pandas, Pillow, matplotlib

**Node:** pptxgenjs, docx, pdf-lib, pdfjs-dist, sharp

## Templates

Place your company templates so Claude uses them automatically:

**Per-project** (in your workspace):
```
my-project/templates/
├── company.pptx
└── report.docx
```

**Shared** (available in all sessions):
```
~/.ccbox/templates/
├── company.pptx
└── report.docx
```

When Claude creates a document, it checks both locations and uses matching templates to preserve your branding, layouts, and styles.

## Resume and one-shot

Resume your last session:

```bash
ccbox claude --continue
```

Run a single command without an interactive session:

```bash
ccbox claude --print "Create a PDF report summarizing Q1 sales"
```

## Managing ccbox

Run the installer again to update the command, change auth, or uninstall:

```bash
./install.sh
```

## Custom skills

Add project-specific skills:

```
my-project/.claude/skills/my-skill/SKILL.md
```

Or add globally (available in all sessions):

```
~/.ccbox/skills/my-skill/SKILL.md
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `PUID` / `PGID` | `1000` | Match container user to your host UID/GID |
| `GIT_USER_NAME` | `Claude` | Git author name inside container |
| `GIT_USER_EMAIL` | `claude@ccbox` | Git author email inside container |

## Requirements

- Docker or Podman
- An Anthropic API key or Claude account (Pro, Team, or Enterprise)

## License

MIT
