# ==============================================================================
# ccbox-base — shared foundation for all ccbox variants
# Each variant extends this image via variants/<name>/Dockerfile.
# Build: docker build -t ccbox-base:latest .
# ==============================================================================

FROM node:22-bookworm-slim

LABEL org.opencontainers.image.source=https://github.com/martin-koenig/ccbox
LABEL org.opencontainers.image.description="ccbox base image — foundation for all variants"
LABEL org.opencontainers.image.licenses="MIT"

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# ---------- Minimal system packages (shared by every variant) ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    locales \
    git \
    curl \
    jq \
    sudo \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ---------- Locale ----------
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

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

# ---------- Python symlink ----------
RUN ln -sf /usr/bin/python3 /usr/bin/python

# ---------- code-server (used by any variant that offers web mode) ----------
RUN curl -fsSL https://code-server.dev/install.sh | sh

# ---------- Normalize /home/claude ownership ----------
RUN chown -R claude:claude /home/claude

# ---------- Copy shared entrypoint and settings ----------
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY settings.json /opt/ccbox/settings.json
COPY code-server-settings.json /opt/ccbox/code-server-settings.json
RUN chmod +x /usr/local/bin/entrypoint.sh

# ---------- Smoke test (base only) ----------
RUN claude --version && \
    code-server --version && \
    python3 --version && \
    node --version

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["claude"]
