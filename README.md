# ccbox

Containerized Claude Code workstations for focused, reproducible workflows. Each **variant** is a self-contained Docker image pre-loaded with the tools and skills for one purpose — document generation today, the DIY AI news collector workshop tomorrow, whatever you add next.

## Quick start

**Install:**

```bash
curl -fsSL https://raw.githubusercontent.com/mk0e/ccbox/main/install.sh | bash
```

The installer walks you through auth and asks which workspaces you want:

```
Which workspaces do you want installed?
  [x] 1) docs                 — document generation (PDFs, PPTX, XLSX, DOCX)
  [ ] 2) diy-news-collector   — AI news collector learning workshop
```

You can re-run `install.sh` any time to add, remove, or update workspaces. Non-interactive shortcuts:

```bash
./install.sh --add diy-news-collector      # add a variant
./install.sh --remove diy-news-collector   # remove a variant
./install.sh --update                       # update all installed variants
./install.sh --build                        # build locally instead of pulling
```

**Use from terminal:**

```bash
ccbox                        # starts the default variant (docs, unless you changed it)
ccbox diy-news-collector     # starts the workshop variant
```

**Use from browser:**

```bash
ccbox web                          # docs at http://localhost:8080
ccbox diy-news-collector web       # workshop at http://localhost:8081
```

Each variant runs as its own container (`ccbox-docs`, `ccbox-diy-news-collector`, …) and can run concurrently with the others. They see only their own `/workspace`.

**Stop:**

```bash
ccbox stop                         # stops all running ccbox containers
```

## Shipped variants

### `docs` — document generation

Mounts your current directory directly at `/workspace`. Pre-loaded with LibreOffice, Pandoc, Tesseract, ImageMagick, Python doc libs, and Anthropic's document-generation skills (`/pdf`, `/xlsx`, `/pptx`, `/docx`, `/canvas-design`, etc.).

```bash
cd ~/clients/acme/q1-report
ccbox
> Create a PDF with our Q1 revenue chart and an executive summary
```

### `diy-news-collector` — AI news collector workshop

Mounts `./diy-news-collector/` under your current directory. Pre-seeded with the step-by-step workshop guide, sample requirements, and environment file. Pre-loaded with Node, Python, Playwright (with Chromium), FastAPI, SQLite, the superpowers plugin, and a Haiku-ready Anthropic client.

```bash
mkdir ~/learning && cd ~/learning
ccbox diy-news-collector web
# Open http://localhost:8081, follow GUIDE.md inside the workspace
```

Workshop participants get a clean isolated environment with everything pre-installed and the guide right in `/workspace/GUIDE.md`.

## How variants work

Each variant lives under `variants/<name>/` in this repo:

```
variants/<name>/
├── Dockerfile        # FROM ccbox-base; layers variant-specific tools
├── workspace.env     # name, image, mount, web_port, description
├── CLAUDE.md         # system instructions baked into the image
└── seed/             # files copied into /workspace on first launch
```

The `ccbox-base` image (`Dockerfile` at the repo root) provides the shared foundation: Claude Code CLI, Node 22, Python 3, locale, the `claude` user, code-server, and the entrypoint. Every variant `FROM`s this base and adds its own layers.

Per-variant state:

- **Container name:** `ccbox-<variant>` (so multiple variants run concurrently)
- **Claude home:** `~/.ccbox/home/<variant>/` on the host (isolates `.claude/` per variant)
- **Workspace mount:** from `workspace.env`'s `mount` field, resolved against your CWD
- **System CLAUDE.md:** baked into the image at `/opt/ccbox/CLAUDE.md`, copied to `~/.claude/CLAUDE.md` on first boot — you can edit that copy freely
- **Seed files:** from `/opt/ccbox/seed/`, copied into `/workspace/` only on first launch if the workspace is empty

## Adding a new variant

1. **Create the folder:**

   ```bash
   mkdir -p variants/my-variant/seed
   ```

2. **Write `variants/my-variant/workspace.env`:**

   ```bash
   name=my-variant
   description=Short one-line description
   image=ghcr.io/mk0e/ccbox:my-variant
   mount=./my-variant/      # "." mounts CWD directly; anything else creates a subfolder
   web_port=8082            # unique port so multiple variants can run concurrently
   ```

3. **Write `variants/my-variant/CLAUDE.md`** with the system instructions for this variant. Reference the variant's purpose, the files it ships, and any tools that are baked in. Keep this short — the user's editable CLAUDE.md layers on top.

4. **Write `variants/my-variant/Dockerfile`:**

   ```dockerfile
   ARG BASE_IMAGE=ccbox-base:latest
   FROM ${BASE_IMAGE}

   LABEL org.opencontainers.image.description="My variant"

   # Install your tools
   RUN apt-get update && apt-get install -y --no-install-recommends \
       <packages> \
       && rm -rf /var/lib/apt/lists/*

   # Copy variant config
   COPY variants/my-variant/CLAUDE.md /opt/ccbox/CLAUDE.md
   COPY variants/my-variant/seed      /opt/ccbox/seed

   # Smoke test
   RUN <check your tools are installed>
   ```

5. **Populate `seed/`** with any starter files you want dropped into the user's workspace on first launch (templates, guides, `.env` samples, etc.). Use an empty `seed/.gitkeep` if nothing.

6. **Build and test locally:**

   ```bash
   docker build -t ccbox-base:latest .
   ./install.sh --build --add my-variant
   mkdir /tmp/my-variant-test && cd /tmp/my-variant-test
   ccbox my-variant
   ```

7. **Submit upstream** (optional): open a PR against this repo. The CI matrix auto-discovers any variant under `variants/*/` and builds it.

## File layout

```
ccbox/
├── Dockerfile                   # ccbox-base
├── entrypoint.sh                # shared entrypoint
├── install.sh                   # variant-aware installer
├── lib/variants.sh              # discovery + registry helpers
├── tests/                       # bash test scripts
├── variants/
│   ├── docs/
│   │   ├── Dockerfile
│   │   ├── workspace.env
│   │   ├── CLAUDE.md
│   │   └── seed/
│   └── diy-news-collector/
│       ├── Dockerfile
│       ├── workspace.env
│       ├── CLAUDE.md
│       └── seed/
└── docs/superpowers/
    ├── specs/
    └── plans/
```

## Docker images

Pre-built multi-arch images are published to the GitHub Container Registry:

```
ghcr.io/mk0e/ccbox-base:latest            # shared foundation
ghcr.io/mk0e/ccbox:docs                   # document generation variant
ghcr.io/mk0e/ccbox:diy-news-collector     # workshop variant
ghcr.io/mk0e/ccbox:latest                 # alias for ccbox:docs (backwards compat)
```

Supported architectures: `linux/amd64`, `linux/arm64`.

## License

MIT
