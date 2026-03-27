# ccbox

A minimal Docker container with Claude Code and document-generation skills (PDF, XLSX, PPTX, DOCX, and more).

## Build

**Prerequisites:** [Docker](https://docs.docker.com/get-docker/) or [Podman](https://podman.io/getting-started/installation)

```bash
git clone https://github.com/martin-koenig/ccbox.git
cd ccbox
docker build -t ccbox .
```

## Run

### With install script (recommended)

The install script adds a `ccbox` command to your shell:

```bash
./install.sh
source ~/.zshrc  # or ~/.bashrc
```

Then from any project directory:

```bash
ccbox
```

### Without install script

```bash
mkdir -p ~/.ccbox
docker run -it --rm \
  -v "$(pwd)":/workspace \
  -v ~/.ccbox:/home/claude/.claude \
  ccbox
```

Both methods mount your current directory as the workspace and `~/.ccbox` for persistent config.

## Authenticate

Type `/login` inside Claude Code and follow the prompts. Credentials persist in `~/.ccbox/` across sessions.

## Resume a session

Sessions persist in `~/.ccbox/` between runs. To continue where you left off:

```bash
# With install script:
ccbox claude --continue

# With plain Docker:
docker run -it --rm \
  -v "$(pwd)":/workspace \
  -v ~/.ccbox:/home/claude/.claude \
  ccbox claude --continue
```

To resume a specific session by ID:

```bash
ccbox claude --resume <session-id>
```

## One-shot mode

Run a single prompt without the interactive UI:

```bash
# With install script:
ccbox claude --print "Create a PDF report summarizing Q1 sales"

# With plain Docker:
docker run --rm \
  -e ANTHROPIC_API_KEY \
  -v "$(pwd)":/workspace \
  -v ~/.ccbox:/home/claude/.claude \
  ccbox claude --print "Create a PDF report summarizing Q1 sales"
```

## What's inside

### Built-in Skills

| Skill | Purpose |
|-------|---------|
| pdf | Create, edit, merge, split, OCR PDF documents |
| xlsx | Create and edit Excel spreadsheets with formulas |
| pptx | Create and edit PowerPoint presentations |
| docx | Create and edit Word documents with tracked changes |
| doc-coauthoring | Structured co-authoring workflow |
| internal-comms | Templates for status reports, newsletters |
| theme-factory | Apply consistent themes to documents |
| canvas-design | Create visual art, posters, infographics |
| brand-guidelines | Apply consistent brand identity |
| skill-creator | Create new custom skills |

### System Tools

LibreOffice, Pandoc, Tesseract OCR, qpdf, pdftk, ImageMagick

### Packages

**Python:** reportlab, pdfplumber, pypdf, python-pptx, python-docx, openpyxl, pandas, Pillow, and more

**Node:** pptxgenjs, docx, pdf-lib, pdfjs-dist

## Templates

Place company templates in one of two locations:

**Per-project** (in your workspace):
```
my-project/
├── templates/
│   ├── company.pptx
│   └── report.docx
```

**Shared** (available in all sessions):
```
~/.ccbox/templates/
├── company.pptx
└── report.docx
```

When you ask Claude to create a document, it checks both locations and uses matching templates to preserve your branding, layouts, and styles.

## Custom Skills

Add skills to your workspace (project-specific):

```
my-project/.claude/skills/my-skill/SKILL.md
```

Or to `~/.ccbox/skills/` (available in all sessions).

## Configuration

Environment variables passed to the container:

| Variable | Default | Description |
|----------|---------|-------------|
| `ANTHROPIC_API_KEY` | — | Anthropic API key |
| `PUID` / `PGID` | `1000` | Match container user to your host UID/GID |
| `GIT_USER_NAME` | `Claude` | Git author name inside container |
| `GIT_USER_EMAIL` | `claude@ccbox` | Git author email inside container |

## License

MIT
