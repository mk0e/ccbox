#!/bin/bash
set -e

# ==============================================================================
# ccbox entrypoint
# ==============================================================================

CLAUDE_HOME="/home/claude"
PUID="${PUID:-1000}"
PGID="${PGID:-1000}"

# ---------- UID/GID remapping ----------
if [ "$(id -u claude)" != "$PUID" ] || [ "$(id -g claude)" != "$PGID" ]; then
    groupmod -o -g "$PGID" claude 2>/dev/null || true
    usermod -o -u "$PUID" claude 2>/dev/null || true
fi

# ---------- Ensure directories ----------
mkdir -p "$CLAUDE_HOME/.claude/skills" /workspace
chown "$PUID:$PGID" "$CLAUDE_HOME" "$CLAUDE_HOME/.claude" "$CLAUDE_HOME/.claude/skills" /workspace

# ---------- First-boot setup ----------
if [ ! -f "$CLAUDE_HOME/.claude/.ccbox-init" ]; then
    echo "[ccbox] First boot — setting up config..."

    cp -n /opt/ccbox/CLAUDE.md "$CLAUDE_HOME/.claude/CLAUDE.md" 2>/dev/null || true
    cp -n /opt/ccbox/settings.json "$CLAUDE_HOME/.claude/settings.json" 2>/dev/null || true

    su -s /bin/bash claude -c "
        git config --global --add safe.directory /workspace
        git config --global user.name '${GIT_USER_NAME:-Claude}'
        git config --global user.email '${GIT_USER_EMAIL:-claude@ccbox}'
    "

    touch "$CLAUDE_HOME/.claude/.ccbox-init"
    chown -R "$PUID:$PGID" "$CLAUDE_HOME"
    echo "[ccbox] First boot complete."
fi

# ---------- Sync skills (every boot, no-clobber) ----------
cp -rn /opt/ccbox/skills/* "$CLAUDE_HOME/.claude/skills/" 2>/dev/null || true
chown -R "$PUID:$PGID" "$CLAUDE_HOME/.claude/skills"

# ---------- Persist .claude.json ----------
# Claude Code stores auth state in ~/.claude.json (outside ~/.claude/).
# Symlink it into the mounted volume so it survives container restarts.
if [ ! -L "$CLAUDE_HOME/.claude.json" ]; then
    rm -f "$CLAUDE_HOME/.claude.json"
    [ ! -s "$CLAUDE_HOME/.claude/.claude.json" ] && echo '{}' > "$CLAUDE_HOME/.claude/.claude.json"
    ln -sf "$CLAUDE_HOME/.claude/.claude.json" "$CLAUDE_HOME/.claude.json"
    chown "$PUID:$PGID" "$CLAUDE_HOME/.claude/.claude.json"
fi

# ---------- code-server first-boot setup ----------
if [ "$1" = "web" ]; then
    CS_DATA="$CLAUDE_HOME/.local/share/code-server"
    CS_EXTENSIONS="$CS_DATA/extensions"
    CS_SETTINGS="$CS_DATA/User/settings.json"
    mkdir -p "$(dirname "$CS_SETTINGS")"
    # Always regenerate settings to inject current env vars
    cp /opt/ccbox/code-server-settings.json "$CS_SETTINGS"
    # Inject API key and base URL into VS Code settings for the Claude Code extension
    if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
        CLAUDE_HOME="$CLAUDE_HOME" python3 << 'PYEOF'
import json, os
settings_path = os.environ["CLAUDE_HOME"] + "/.local/share/code-server/User/settings.json"
with open(settings_path) as f:
    settings = json.load(f)
env_vars = [{"name": "ANTHROPIC_API_KEY", "value": os.environ["ANTHROPIC_API_KEY"]}]
base_url = os.environ.get("ANTHROPIC_BASE_URL", "")
if base_url:
    env_vars.append({"name": "ANTHROPIC_BASE_URL", "value": base_url})
settings["claudeCode.environmentVariables"] = env_vars
with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
PYEOF
    fi
    # Copy baked-in extensions to writable location
    if [ ! -d "$CS_EXTENSIONS" ]; then
        cp -r /opt/ccbox/code-server-extensions "$CS_EXTENSIONS"
    fi
    chown -R "$PUID:$PGID" "$CS_DATA"

    echo "[ccbox] Web UI running at http://localhost:8080"
    export HOME="$CLAUDE_HOME"
    cd /workspace
    exec sudo -u claude \
        --preserve-env=HOME,PATH,NODE_PATH,NODE_OPTIONS,ANTHROPIC_API_KEY,ANTHROPIC_BASE_URL,CLAUDE_CODE_USE_BEDROCK,AWS_PROFILE,AWS_REGION,CLAUDE_CODE_USE_VERTEX,GOOGLE_CLOUD_PROJECT \
        code-server \
        --bind-addr 0.0.0.0:8080 \
        --auth none \
        --disable-telemetry \
        --extensions-dir "$CS_DATA/extensions" \
        /workspace
fi

# ---------- Exec as claude user ----------
export HOME="$CLAUDE_HOME"
cd /workspace
exec sudo -u claude \
    --preserve-env=HOME,PATH,NODE_PATH,NODE_OPTIONS,ANTHROPIC_API_KEY,ANTHROPIC_BASE_URL,CLAUDE_CODE_USE_BEDROCK,AWS_PROFILE,AWS_REGION,CLAUDE_CODE_USE_VERTEX,GOOGLE_CLOUD_PROJECT \
    "$@"
