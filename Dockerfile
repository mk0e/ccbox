# ==============================================================================
# ccbox — Claude Code with document-generation skills
# Build: docker build -t ccbox .
# ==============================================================================

# ---------- Stage 1: Clone skills ----------
FROM docker.io/alpine/git:latest AS skills
ARG SKILLS_REF=main
RUN git clone --depth 1 --branch ${SKILLS_REF} \
    https://github.com/anthropics/skills.git /tmp/skills

# ---------- Stage 2: Build the image ----------
FROM node:22-bookworm-slim

LABEL org.opencontainers.image.source=https://github.com/martin-koenig/ccbox
LABEL org.opencontainers.image.description="Claude Code with document-generation skills"
LABEL org.opencontainers.image.licenses="MIT"

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# ---------- System packages ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Document generation
    libreoffice \
    poppler-utils \
    qpdf \
    pdftk \
    pandoc \
    tesseract-ocr \
    imagemagick \
    # Python
    python3 \
    python3-pip \
    # Fonts
    fonts-liberation2 \
    fonts-dejavu-core \
    fonts-noto-core \
    fonts-noto-color-emoji \
    fonts-inter \
    # Locale
    locales \
    # Core tools
    git \
    curl \
    jq \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# ---------- Locale ----------
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

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

# ---------- Rename node user to claude ----------
RUN usermod -l claude -d /home/claude -m node && \
    groupmod -n claude node && \
    echo "claude ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/claude && \
    chmod 0440 /etc/sudoers.d/claude

# ---------- Claude Code CLI ----------
RUN curl -fsSL https://claude.ai/install.sh | bash \
    && cp /root/.local/bin/claude /usr/local/bin/claude \
    && cp -r /root/.local/share/claude /usr/local/share/claude \
    && mkdir -p /home/claude/.local/bin \
    && ln -sf /usr/local/bin/claude /home/claude/.local/bin/claude

# ---------- Node packages (global) ----------
RUN npm i -g \
    pptxgenjs \
    pdf-lib \
    pdfjs-dist \
    docx \
    react \
    react-dom \
    react-icons \
    sharp

# Global Node module resolution
ENV NODE_PATH=/usr/local/lib/node_modules
RUN echo 'process.env.NODE_PATH = process.env.NODE_PATH || "/usr/local/lib/node_modules"; require("module").Module._initPaths();' \
    > /usr/local/lib/node_path_fix.js
ENV NODE_OPTIONS="--require=/usr/local/lib/node_path_fix.js"

# ---------- Python symlink ----------
RUN ln -sf /usr/bin/python3 /usr/bin/python

# ---------- Copy skills from stage 1 ----------
COPY --from=skills /tmp/skills/skills/pdf            /opt/ccbox/skills/pdf
COPY --from=skills /tmp/skills/skills/xlsx           /opt/ccbox/skills/xlsx
COPY --from=skills /tmp/skills/skills/pptx           /opt/ccbox/skills/pptx
COPY --from=skills /tmp/skills/skills/docx           /opt/ccbox/skills/docx
COPY --from=skills /tmp/skills/skills/doc-coauthoring /opt/ccbox/skills/doc-coauthoring
COPY --from=skills /tmp/skills/skills/internal-comms /opt/ccbox/skills/internal-comms
COPY --from=skills /tmp/skills/skills/theme-factory  /opt/ccbox/skills/theme-factory
COPY --from=skills /tmp/skills/skills/canvas-design  /opt/ccbox/skills/canvas-design
COPY --from=skills /tmp/skills/skills/brand-guidelines /opt/ccbox/skills/brand-guidelines
COPY --from=skills /tmp/skills/skills/skill-creator  /opt/ccbox/skills/skill-creator

# ---------- code-server ----------
RUN curl -fsSL https://code-server.dev/install.sh | sh

# ---------- VS Code extensions (via code-server) ----------
RUN code-server --extensions-dir /opt/ccbox/code-server-extensions \
    --install-extension Anthropic.claude-code \
    --install-extension cweijan.vscode-office

# ---------- ccbox welcome extension ----------
COPY welcome-extension /tmp/welcome-extension
RUN cd /tmp/welcome-extension && npx --yes @vscode/vsce package --allow-missing-repository -o /tmp/ccbox-welcome.vsix \
    && code-server --extensions-dir /opt/ccbox/code-server-extensions --install-extension /tmp/ccbox-welcome.vsix \
    && rm -rf /tmp/welcome-extension /tmp/ccbox-welcome.vsix
RUN chmod -R a+rX /opt/ccbox/code-server-extensions

# ---------- Copy config ----------
COPY CLAUDE.md     /opt/ccbox/CLAUDE.md
COPY settings.json /opt/ccbox/settings.json
COPY code-server-settings.json /opt/ccbox/code-server-settings.json
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# ---------- Smoke test ----------
RUN libreoffice --version && \
    tesseract --version && \
    qpdf --version && \
    pandoc --version && \
    pdftk --version && \
    python3 -c "import pypdf, pdfplumber, reportlab, pypdfium2, pytesseract, pdf2image, pandas, openpyxl, PIL, pptx, docx, lxml, defusedxml, markitdown, matplotlib" && \
    node -e "require('pptxgenjs'); require('pdf-lib'); require('docx'); require('sharp'); require('react'); require('react-dom')" && \
    claude --version && \
    code-server --version

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["claude"]
