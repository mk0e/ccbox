# ccbox

Create professional documents with AI (PDFs, presentations, spreadsheets, and Word documents) by describing what you need in plain language.

## What is ccbox?

ccbox is a **ready-to-use AI workstation for documents**, packaged as a Docker container.

Inside the container runs [Claude Code](https://docs.anthropic.com/en/docs/claude-code), Anthropic's AI coding assistant, together with everything it needs to produce polished office documents: LibreOffice, Pandoc, Tesseract OCR, plus Python and Node libraries for PDFs, Word, Excel, and PowerPoint. You describe what you want in plain English, and Claude writes and runs the code to build the file.

You don't install any of those tools on your own machine. You just install one small shell command (`ccbox`) that starts the container for you.

## Quick start

### 1. Install

```bash
curl -fsSL https://raw.githubusercontent.com/mk0e/ccbox/main/install.sh | bash
```

You'll need Docker (or Podman) installed and running first.

The installer is a small, local setup script. It does **not** install any heavy software on your machine. It:

- **Checks** that Docker or Podman is installed and running.
- **Adds a `ccbox` function** to your shell config (`.zshrc`, `.bashrc`, or fish functions). This is how typing `ccbox` works. It's a short shell wrapper that runs the container for you.
- **Asks how you want to sign in**, either with an Anthropic API key (stored locally in `~/.config/ccbox/auth.env`, `chmod 600`) or with your Claude account (Pro, Team, Enterprise, or free tier; you log in the first time you launch).
- **Creates `~/.ccbox/`** on your machine. This folder keeps your Claude sessions, settings, and shared templates across container restarts.

That's it. No system packages installed, no background services, no daemon. The container image itself is only downloaded the first time you actually run `ccbox`.

Run `./install.sh` again any time to update the command, change auth, or uninstall.

### 2. The workspace folder (the most important idea)

**ccbox always works on the folder you start it from.** That folder is called your *workspace*.

When you type `ccbox`, the current folder (`pwd`) is mounted into the container as `/workspace`. Anything Claude creates, edits, or reads happens in that folder on your real machine. Nothing outside it is visible to Claude.

Concrete example:

```bash
cd ~/Documents/q1-report     # go to the folder you want to work in
ccbox                        # this folder becomes Claude's workspace
```

Inside that session, if you say *"create a PDF summary of sales.xlsx"*, Claude reads `sales.xlsx` from `~/Documents/q1-report` and writes the new PDF right back into `~/Documents/q1-report`. When you exit, the files are simply there. No export step.

Rule of thumb: **`cd` into the folder where you want the finished document to end up, then run `ccbox`.**

### 3. Two ways to use it: browser or terminal

Both start the same container on the same workspace folder. The only difference is the interface you interact with. Pick whichever matches your comfort level.

**Browser mode: `ccbox web`** (recommended if you don't live in the terminal)

```bash
ccbox web
```

Opens a full **VS Code in your browser** at `http://localhost:8080`, with a file tree, editor, and a Claude Code chat panel side by side. This is the friendliest option. You can see your files, preview documents, and chat with Claude all in one window. No terminal experience needed beyond running the one command above.

Use a custom port if 8080 is taken:

```bash
ccbox web 3000
```

To end the session, press **Ctrl+C** in the terminal where you started it. (If you closed that terminal or the container got stuck, `ccbox stop` from any terminal will shut it down, but you usually won't need it.)

**Terminal mode: `ccbox`** (for users comfortable with the Claude Code CLI)

```bash
ccbox
```

Drops you straight into an interactive [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI session inside the container, the same interface you'd get running `claude` locally, just with document tools preinstalled. Type `/exit` inside the CLI to leave the session.

Typical requests:

```
> Create a PDF report with Q1 sales charts and an executive summary
> Make a 10-slide pitch deck for a startup called Acme AI
> Build an Excel budget tracker with monthly columns and formulas
```

**At a glance:**

| | Browser (`ccbox web`) | Terminal (`ccbox`) |
|---|---|---|
| **Audience** | Less technical users who want a visual interface | Users already comfortable with the Claude Code CLI |
| **Interface** | VS Code in the browser (editor, file tree, chat panel) | Claude Code CLI in your terminal |
| **Exit with** | Ctrl+C in the starting terminal | `/exit` inside the CLI |
| **Best for** | Previewing, tweaking, and iterating on files visually | Quick keyboard-driven requests or scripting |
| **Workspace** | The folder you ran `ccbox` in, mounted inside the container at `/workspace` | Same |
| **Auth** | Same login, configured once by the installer | Same |

**Dev server ports (optional):** `ccbox web` also forwards host ports `4200–4250` into the container, so if Claude spins up a frontend dev server (Vite, `ng serve`, etc.) you can open it at `http://localhost:4200`. Bind inside the container to `0.0.0.0` (e.g. `ng serve --host 0.0.0.0`). `localhost` alone isn't reachable from outside.

## What's inside the container

### Skills

ccbox ships with 10 built-in skills that Claude uses automatically:

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

Drop a `templates/` folder inside your workspace folder (the one you ran `ccbox` from):

```
templates/
├── company.pptx
└── report.docx
```

Claude picks these up automatically when creating new documents, so your branding, layouts, and styles are preserved.

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

To build the image locally from source instead of pulling from the registry (requires a repo checkout):

```bash
./install.sh --build
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

## Docker image

Pre-built multi-arch images are published to the GitHub Container Registry:

```
ghcr.io/mk0e/ccbox:latest          # latest stable build
ghcr.io/mk0e/ccbox:v1.2.3          # specific release
```

### Supported architectures

| Architecture | Tag suffix |
|---|---|
| `linux/amd64` | *(default)* |
| `linux/arm64` | *(auto-selected)* |

Docker pulls the correct variant automatically based on the host platform.

### Build pipeline

The image is built and pushed automatically on both GitHub and GitLab:

**GitHub** ([Build & Push workflow](.github/workflows/docker-build.yml)):

| Trigger | Tags pushed |
|---|---|
| Push to `main` | `latest` |
| Nightly schedule (02:00 UTC) | `latest` |
| New GitHub release (e.g. `v1.2.3`) | `v1.2.3`, `1.2.3`, `latest` |

**GitLab** ([`.gitlab-ci.yml`](.gitlab-ci.yml)):

| Trigger | Tags pushed |
|---|---|
| Push to `main` | `latest` |
| Scheduled pipeline | `latest` |
| New tag (e.g. `v1.2.3`) | `v1.2.3`, `latest` |

Builds use Docker Buildx with QEMU emulation for faster incremental builds.

## License

MIT
