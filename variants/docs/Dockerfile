# ==============================================================================
# ccbox:docs — document generation variant
# Build: docker build -t ccbox:docs -f variants/docs/Dockerfile .
# Requires ccbox-base:latest to be built first.
# ==============================================================================

# ---------- Stage 1: Clone skills ----------
FROM docker.io/alpine/git:latest AS skills
ARG SKILLS_REF=main
RUN git clone --depth 1 --branch ${SKILLS_REF} \
    https://github.com/anthropics/skills.git /tmp/skills

# ---------- Stage 2: Layer doc tools onto the base ----------
ARG BASE_IMAGE=ccbox-base:latest
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.description="ccbox variant: document generation (PDF, PPTX, XLSX, DOCX)"

# ---------- Document-generation system packages ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
    libreoffice \
    poppler-utils \
    qpdf \
    pdftk \
    pandoc \
    tesseract-ocr \
    imagemagick \
    fonts-liberation2 \
    fonts-dejavu-core \
    fonts-noto-core \
    fonts-noto-color-emoji \
    fonts-inter \
    && rm -rf /var/lib/apt/lists/*

# ---------- Python packages ----------
RUN pip install --no-cache-dir --break-system-packages \
    pypdf \
    pdfplumber \
    reportlab \
    pypdfium2 \
    pytesseract \
    pdf2image \
    pandas \
    openpyxl \
    Pillow \
    python-pptx \
    python-docx \
    lxml \
    defusedxml \
    matplotlib \
    "markitdown[pptx]"

# ---------- Node packages ----------
RUN npm i -g \
    pptxgenjs \
    pdf-lib \
    pdfjs-dist \
    docx \
    react \
    react-dom \
    react-icons \
    sharp

ENV NODE_PATH=/usr/local/lib/node_modules
RUN echo 'process.env.NODE_PATH = process.env.NODE_PATH || "/usr/local/lib/node_modules"; require("module").Module._initPaths();' \
    > /usr/local/lib/node_path_fix.js
ENV NODE_OPTIONS="--require=/usr/local/lib/node_path_fix.js"

# ---------- Copy skills ----------
COPY --from=skills /tmp/skills/skills/pdf              /opt/ccbox/skills/pdf
COPY --from=skills /tmp/skills/skills/xlsx             /opt/ccbox/skills/xlsx
COPY --from=skills /tmp/skills/skills/pptx             /opt/ccbox/skills/pptx
COPY --from=skills /tmp/skills/skills/docx             /opt/ccbox/skills/docx
COPY --from=skills /tmp/skills/skills/doc-coauthoring  /opt/ccbox/skills/doc-coauthoring
COPY --from=skills /tmp/skills/skills/internal-comms   /opt/ccbox/skills/internal-comms
COPY --from=skills /tmp/skills/skills/theme-factory    /opt/ccbox/skills/theme-factory
COPY --from=skills /tmp/skills/skills/canvas-design    /opt/ccbox/skills/canvas-design
COPY --from=skills /tmp/skills/skills/brand-guidelines /opt/ccbox/skills/brand-guidelines
COPY --from=skills /tmp/skills/skills/skill-creator    /opt/ccbox/skills/skill-creator

# ---------- VS Code extensions ----------
RUN for i in 1 2 3; do \
      code-server --extensions-dir /opt/ccbox/code-server-extensions \
        --install-extension Anthropic.claude-code \
        --install-extension cweijan.vscode-office \
      && exit 0 || { echo "Attempt $i failed, retrying in 5s..."; sleep 5; }; \
    done; exit 1

COPY welcome-extension /tmp/welcome-extension
RUN cd /tmp/welcome-extension && npx --yes @vscode/vsce package --allow-missing-repository -o /tmp/ccbox-welcome.vsix \
    && code-server --extensions-dir /opt/ccbox/code-server-extensions --install-extension /tmp/ccbox-welcome.vsix \
    && rm -rf /tmp/welcome-extension /tmp/ccbox-welcome.vsix
RUN chmod -R a+rX /opt/ccbox/code-server-extensions

# ---------- Variant-specific CLAUDE.md and seed ----------
COPY variants/docs/CLAUDE.md /opt/ccbox/CLAUDE.md
COPY variants/docs/seed      /opt/ccbox/seed

# ---------- Smoke test ----------
RUN libreoffice --version && \
    tesseract --version && \
    qpdf --version && \
    pandoc --version && \
    pdftk --version && \
    python3 -c "import pypdf, pdfplumber, reportlab, pypdfium2, pytesseract, pdf2image, pandas, openpyxl, PIL, pptx, docx, lxml, defusedxml, markitdown, matplotlib" && \
    node -e "require('pptxgenjs'); require('pdf-lib'); require('docx'); require('sharp'); require('react'); require('react-dom')"
