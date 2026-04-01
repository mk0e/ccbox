#!/usr/bin/env fish

# ==============================================================================
# ccbox installer for fish shell
# Adds a `ccbox` function to ~/.config/fish/functions/ccbox.fish
# ==============================================================================

set CCBOX_HOME "$HOME/.ccbox"

# ---------- Detect container runtime ----------
set RUNTIME ""
if command -q docker
    set RUNTIME docker
else if command -q podman
    set RUNTIME podman
else
    echo "Error: No container runtime found."
    echo "Install one of:"
    echo "  Docker:  https://docs.docker.com/get-docker/"
    echo "  Podman:  https://podman.io/getting-started/installation"
    exit 1
end
echo "Found container runtime: $RUNTIME"

# ---------- Create persistent config dir ----------
mkdir -p "$CCBOX_HOME"
echo "Created $CCBOX_HOME for persistent config."

# ---------- Install fish function ----------
set -l func_dir "$HOME/.config/fish/functions"
mkdir -p "$func_dir"

set -l func_file "$func_dir/ccbox.fish"

printf '%s\n' \
    '# >>> ccbox >>>' \
    'function ccbox --description "Run ccbox container"' \
    "    set -l args run -it --rm -v (pwd):/workspace -v \$HOME/.ccbox:/home/claude/.claude" \
    '    if set -q ANTHROPIC_API_KEY; and test -n "$ANTHROPIC_API_KEY"' \
    '        set -a args -e "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY"' \
    '    end' \
    '    if set -q ANTHROPIC_BASE_URL; and test -n "$ANTHROPIC_BASE_URL"' \
    '        set -a args -e "ANTHROPIC_BASE_URL=$ANTHROPIC_BASE_URL"' \
    '    end' \
    "    $RUNTIME \$args ccbox:latest \$argv" \
    'end' \
    '# <<< ccbox <<<' \
    > "$func_file"

echo "Added ccbox function to $func_file"

echo ""
echo "ccbox installed!"
echo ""
if not $RUNTIME image exists ccbox:latest 2>/dev/null; and not $RUNTIME inspect ccbox:latest &>/dev/null
    echo "Next: build the image, then run:"
    echo "  $RUNTIME build -t ccbox ."
    echo "  ccbox"
else
    echo "Image found. Run:"
    echo "  ccbox"
end
echo ""
