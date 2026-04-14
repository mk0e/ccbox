# ==============================================================================
# ccbox:diy-news-collector — AI news collector learning workshop variant
# Build: docker build -t ccbox:diy-news-collector -f variants/diy-news-collector/Dockerfile .
# Requires ccbox-base:latest to be built first.
# ==============================================================================

ARG BASE_IMAGE=ccbox-base:latest
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.description="ccbox variant: DIY AI news collector learning workshop"

# ---------- Workshop toolchain ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
    sqlite3 \
    libsqlite3-dev \
    chromium \
    fonts-liberation2 \
    fonts-noto-core \
    && rm -rf /var/lib/apt/lists/*

# Playwright with Chromium (system chromium above covers most deps;
# playwright install still fetches matching browser binaries).
RUN npm i -g playwright@latest \
    && PLAYWRIGHT_BROWSERS_PATH=/opt/playwright npx playwright install chromium \
    && chmod -R a+rX /opt/playwright
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/playwright

# Python packages common to the workshop (LLM clients + scraping)
RUN pip install --no-cache-dir --break-system-packages \
    anthropic \
    openai \
    httpx \
    beautifulsoup4 \
    requests \
    fastapi \
    uvicorn \
    sqlalchemy

# ---------- Superpowers plugin ----------
# Bake the plugin into the image so the workshop's isolated env has no
# network dependency on first launch.
RUN mkdir -p /opt/ccbox/plugins \
    && (git clone --depth 1 https://github.com/obra/superpowers.git /opt/ccbox/plugins/superpowers \
        || echo "Warning: could not clone superpowers at build time; participants may install it themselves.")

# ---------- VS Code extensions (workshop targets the web flow too) ----------
RUN for i in 1 2 3; do \
      code-server --extensions-dir /opt/ccbox/code-server-extensions \
        --install-extension Anthropic.claude-code \
      && exit 0 || { echo "Attempt $i failed, retrying in 5s..."; sleep 5; }; \
    done; exit 1
RUN chmod -R a+rX /opt/ccbox/code-server-extensions

# ---------- Variant-specific CLAUDE.md and seed ----------
COPY variants/diy-news-collector/CLAUDE.md /opt/ccbox/CLAUDE.md
COPY variants/diy-news-collector/seed      /opt/ccbox/seed

# ---------- Smoke test ----------
RUN node --version && \
    python3 --version && \
    sqlite3 --version && \
    npx playwright --version && \
    python3 -c "import anthropic, httpx, bs4, fastapi, sqlalchemy"
