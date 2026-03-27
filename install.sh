#!/bin/bash
set -e

# ==============================================================================
# ccbox installer
# Adds a `ccbox` shell function to your shell rc file.
# ==============================================================================

CCBOX_HOME="$HOME/.ccbox"

# ---------- Detect container runtime ----------
RUNTIME=""
if command -v docker &>/dev/null; then
    RUNTIME="docker"
elif command -v podman &>/dev/null; then
    RUNTIME="podman"
else
    echo "Error: No container runtime found."
    echo "Install one of:"
    echo "  Docker:  https://docs.docker.com/get-docker/"
    echo "  Podman:  https://podman.io/getting-started/installation"
    exit 1
fi
echo "Found container runtime: $RUNTIME"

# ---------- Create persistent config dir ----------
mkdir -p "$CCBOX_HOME"
echo "Created $CCBOX_HOME for persistent config."

# ---------- Detect shell and rc file ----------
CURRENT_SHELL="$(basename "$SHELL")"

add_function() {
    local rcfile="$1"

    # Remove old version if present
    if grep -q '# >>> ccbox >>>' "$rcfile" 2>/dev/null; then
        sed -i.bak '/# >>> ccbox >>>/,/# <<< ccbox <<</d' "$rcfile"
        rm -f "${rcfile}.bak"
    fi

    cat >> "$rcfile" << SHELL_FUNC

# >>> ccbox >>>
ccbox() {
    local args=(
        run -it --rm
        -v "\$(pwd)":/workspace
        -v "\$HOME/.ccbox":/home/claude/.claude
    )
    [ -n "\$ANTHROPIC_API_KEY" ] && args+=(-e "ANTHROPIC_API_KEY=\$ANTHROPIC_API_KEY")
    $RUNTIME "\${args[@]}" ccbox:latest "\$@"
}
# <<< ccbox <<<
SHELL_FUNC

    echo "Added ccbox function to $rcfile"
}

case "$CURRENT_SHELL" in
    bash)
        add_function "$HOME/.bashrc"
        ;;
    zsh)
        add_function "$HOME/.zshrc"
        ;;
    *)
        echo ""
        echo "Unsupported shell: $CURRENT_SHELL"
        echo "Add this function to your shell config manually:"
        echo ""
        echo "  ccbox() {"
        echo "    $RUNTIME run -it --rm -v \"\\\$(pwd)\":/workspace -v \"\\\$HOME/.ccbox\":/home/claude/.claude ccbox:latest \"\\\$@\""
        echo "  }"
        exit 0
        ;;
esac

echo ""
echo "ccbox installed!"
echo ""
if ! $RUNTIME image exists ccbox:latest 2>/dev/null && ! $RUNTIME inspect ccbox:latest &>/dev/null; then
    echo "Next: build the image, then reload your shell:"
    echo "  $RUNTIME build -t ccbox ."
    echo "  source ~/.${CURRENT_SHELL}rc"
else
    echo "Image found. Reload your shell and run:"
    echo "  source ~/.${CURRENT_SHELL}rc"
fi
echo "  ccbox"
echo ""
