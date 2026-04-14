#!/bin/bash
set -e

# ==============================================================================
# ccbox installer
# Installs the ccbox command and configures authentication.
# Run again anytime to change settings or uninstall.
#
# Usage:
#   ./install.sh
#   curl -fsSL https://unitedunicorns.org/gitlab/techboard/ccbox/-/raw/main/install.sh | bash
# ==============================================================================

CCBOX_DATA="$HOME/.ccbox"
CCBOX_CONFIG="$HOME/.config/ccbox"
AUTH_ENV="$CCBOX_CONFIG/auth.env"

# ---------- Arg parsing ----------
BUILD_LOCAL=false
for arg in "$@"; do
    case "$arg" in
        --build) BUILD_LOCAL=true ;;
        *) printf "Unknown option: %s\n" "$arg" >&2; exit 1 ;;
    esac
done

# ---------- Terminal I/O ----------
# Read from /dev/tty so prompts work even when piped via curl | bash
prompt() {
    printf "%s" "$1" > /dev/tty
    read -r REPLY < /dev/tty
}

prompt_secret() {
    printf "%s" "$1" > /dev/tty
    read -rs REPLY < /dev/tty
    printf "\n" > /dev/tty
}

info() { printf "%s\n" "$1" > /dev/tty; }

# ---------- Container runtime ----------
detect_runtime() {
    if command -v docker &>/dev/null; then
        RUNTIME="docker"
    elif command -v podman &>/dev/null; then
        RUNTIME="podman"
    else
        info ""
        info "Docker is required but not installed."
        info "Get it at: https://docs.docker.com/get-docker/"
        exit 1
    fi

    if ! "$RUNTIME" info &>/dev/null; then
        info ""
        info "Docker is installed but not running. Start Docker and try again."
        exit 1
    fi
}

# ---------- Shell detection ----------
detect_shell() {
    CURRENT_SHELL="$(basename "$SHELL")"
    case "$CURRENT_SHELL" in
        bash) RC_FILE="$HOME/.bashrc" ;;
        zsh)  RC_FILE="$HOME/.zshrc" ;;
        fish) RC_FILE="$HOME/.config/fish/functions/ccbox.fish" ;;
        *)
            info ""
            info "Unsupported shell: $CURRENT_SHELL"
            info "Supported: bash, zsh, fish"
            exit 1
            ;;
    esac
}

# ---------- Platform-aware sed -i ----------
sed_inplace() {
    if sed --version &>/dev/null 2>&1; then
        sed -i "$@"
    else
        sed -i '' "$@"
    fi
}

# ---------- Auth state ----------
auth_label() {
    if [ -f "$AUTH_ENV" ]; then
        echo "API key"
    else
        echo "Claude account"
    fi
}

# ---------- Auth.env read/write ----------
write_auth_env() {
    local api_key="$1"
    local base_url="$2"
    mkdir -p "$CCBOX_CONFIG"
    local tmpfile
    tmpfile="$(mktemp)"
    echo "ANTHROPIC_API_KEY=$api_key" > "$tmpfile"
    [ -n "$base_url" ] && echo "ANTHROPIC_BASE_URL=$base_url" >> "$tmpfile"
    mv "$tmpfile" "$AUTH_ENV"
    chmod 600 "$AUTH_ENV"
}

remove_auth_env() {
    rm -f "$AUTH_ENV"
}

# ---------- Check for existing ccbox (not ours) ----------
check_existing_ccbox() {
    if [ "$CURRENT_SHELL" = "fish" ]; then
        if [ -f "$RC_FILE" ] && ! grep -q '# >>> ccbox >>>' "$RC_FILE" 2>/dev/null; then
            info ""
            info "An existing ccbox command was found at $RC_FILE."
            prompt "Overwrite? [y/N] "
            case "$REPLY" in
                [yY]*) return 0 ;;
                *) info "Aborted."; exit 0 ;;
            esac
        fi
        return 0
    fi

    if [ -f "$RC_FILE" ]; then
        if grep -q 'ccbox' "$RC_FILE" 2>/dev/null && ! grep -q '# >>> ccbox >>>' "$RC_FILE" 2>/dev/null; then
            info ""
            info "An existing ccbox command was found in $RC_FILE."
            prompt "Overwrite? [y/N] "
            case "$REPLY" in
                [yY]*) return 0 ;;
                *) info "Aborted."; exit 0 ;;
            esac
        fi
    fi
}

# ---------- Write ccbox function to shell rc ----------
install_function() {
    if [ "$CURRENT_SHELL" = "fish" ]; then
        mkdir -p "$(dirname "$RC_FILE")"
        cat > "$RC_FILE" << 'FISH_FUNC'
# >>> ccbox >>>
function ccbox --description "Run ccbox container"
    set -l runtime
    if command -q docker
        set runtime docker
    else if command -q podman
        set runtime podman
    else
        echo "ccbox: docker or podman is required but not found." >&2
        return 1
    end
    set -l api_key "$ANTHROPIC_API_KEY"
    set -l base_url "$ANTHROPIC_BASE_URL"
    if test -z "$api_key"; and test -f "$HOME/.config/ccbox/auth.env"
        while read -l line
            test -z "$line"; and continue
            string match -q '#*' -- $line; and continue
            set -l key (string replace -r '=.*' '' -- $line)
            set -l value (string replace -r '^[^=]*=' '' -- $line)
            switch $key
                case ANTHROPIC_API_KEY
                    set api_key $value
                case ANTHROPIC_BASE_URL
                    set base_url $value
            end
        end < "$HOME/.config/ccbox/auth.env"
    end
    if test (count $argv) -ge 1; and test "$argv[1]" = "stop"
        set -l cids ($runtime ps -q --filter ancestor=ghcr.io/moritzbutzmann/ccbox:latest 2>/dev/null)
        if test -n "$cids"
            $runtime stop $cids >/dev/null 2>&1
            echo "ccbox stopped."
        else
            echo "No running ccbox containers found."
        end
        return
    end
    if test (count $argv) -ge 1; and test "$argv[1]" = "web"
        set -e argv[1]
        set -l port 8080
        if test (count $argv) -ge 1; and string match -qr '^\d+$' -- $argv[1]
            set port $argv[1]
            set -e argv[1]
        end
        set -l existing ($runtime ps -q --filter ancestor=ghcr.io/moritzbutzmann/ccbox:latest 2>/dev/null)
        if test -n "$existing"
            echo "ccbox is already running. Open http://localhost:$port or run: ccbox stop"
            return
        end
        set -l args run --rm -p "127.0.0.1:$port:8080" \
            -v (pwd):/workspace \
            -v $HOME/.ccbox:/home/claude/.claude
        test -n "$api_key";  and set -a args -e "ANTHROPIC_API_KEY=$api_key"
        test -n "$base_url"; and set -a args -e "ANTHROPIC_BASE_URL=$base_url"
        echo "ccbox is running at http://localhost:$port"
        echo "Press Ctrl+C to stop."
        $runtime $args ghcr.io/moritzbutzmann/ccbox:latest web $argv
        return
    end
    set -l args run -it --rm \
        -v (pwd):/workspace \
        -v $HOME/.ccbox:/home/claude/.claude
    test -n "$api_key";  and set -a args -e "ANTHROPIC_API_KEY=$api_key"
    test -n "$base_url"; and set -a args -e "ANTHROPIC_BASE_URL=$base_url"
    $runtime $args ghcr.io/moritzbutzmann/ccbox:latest $argv
end
# <<< ccbox <<<
FISH_FUNC
        return
    fi

    # For bash/zsh: remove old version if present, then append
    if [ -f "$RC_FILE" ] && grep -q '# >>> ccbox >>>' "$RC_FILE" 2>/dev/null; then
        sed_inplace '/# >>> ccbox >>>/,/# <<< ccbox <<</d' "$RC_FILE"
    fi

    cat >> "$RC_FILE" << 'SHELL_FUNC'

# >>> ccbox >>>
ccbox() {
    local runtime
    if command -v docker &>/dev/null; then
        runtime=docker
    elif command -v podman &>/dev/null; then
        runtime=podman
    else
        echo "ccbox: docker or podman is required but not found." >&2
        return 1
    fi
    local base_url="${ANTHROPIC_BASE_URL:-}"
    local api_key="${ANTHROPIC_API_KEY:-}"
    if [ -z "$api_key" ] && [ -f "$HOME/.config/ccbox/auth.env" ]; then
        while read -r line; do
            [[ -z "$line" || "$line" =~ ^# ]] && continue
            local key="${line%%=*}"
            local value="${line#*=}"
            case "$key" in
                ANTHROPIC_API_KEY)  api_key="$value" ;;
                ANTHROPIC_BASE_URL) base_url="$value" ;;
            esac
        done < "$HOME/.config/ccbox/auth.env"
    fi
    if [ "$1" = "stop" ]; then
        local cids
        cids="$("$runtime" ps -q --filter ancestor=ghcr.io/moritzbutzmann/ccbox:latest 2>/dev/null)"
        if [ -n "$cids" ]; then
            "$runtime" stop $cids >/dev/null 2>&1
            echo "ccbox stopped."
        else
            echo "No running ccbox containers found."
        fi
        return
    fi
    if [ "$1" = "web" ]; then
        shift
        local port=8080
        if [ $# -gt 0 ] && [[ "$1" =~ ^[0-9]+$ ]]; then
            port="$1"
            shift
        fi
        local existing
        existing="$("$runtime" ps -q --filter ancestor=ghcr.io/moritzbutzmann/ccbox:latest 2>/dev/null)"
        if [ -n "$existing" ]; then
            echo "ccbox is already running. Open http://localhost:$port or run: ccbox stop"
            return
        fi
        local args=(run --rm -p "127.0.0.1:$port:8080"
            -v "$(pwd)":/workspace
            -v "$HOME/.ccbox":/home/claude/.claude
        )
        [ -n "$api_key" ]  && args+=(-e "ANTHROPIC_API_KEY=$api_key")
        [ -n "$base_url" ] && args+=(-e "ANTHROPIC_BASE_URL=$base_url")
        echo "ccbox is running at http://localhost:$port"
        echo "Press Ctrl+C to stop."
        "$runtime" "${args[@]}" ghcr.io/moritzbutzmann/ccbox:latest web "$@"
        return
    fi
    local args=(run -it --rm
        -v "$(pwd)":/workspace
        -v "$HOME/.ccbox":/home/claude/.claude
    )
    [ -n "$api_key" ]  && args+=(-e "ANTHROPIC_API_KEY=$api_key")
    [ -n "$base_url" ] && args+=(-e "ANTHROPIC_BASE_URL=$base_url")
    "$runtime" "${args[@]}" ghcr.io/moritzbutzmann/ccbox:latest "$@"
}
# <<< ccbox <<<
SHELL_FUNC
}

# ---------- Remove ccbox function from shell rc ----------
remove_function() {
    if [ "$CURRENT_SHELL" = "fish" ]; then
        rm -f "$RC_FILE"
        return
    fi

    if [ -f "$RC_FILE" ] && grep -q '# >>> ccbox >>>' "$RC_FILE" 2>/dev/null; then
        sed_inplace '/# >>> ccbox >>>/,/# <<< ccbox <<</d' "$RC_FILE"
    fi
}

# ---------- Auth configuration ----------
configure_auth() {
    info ""
    info "How do you want to use ccbox?"
    info "  1) API key"
    info "  2) Claude account (Pro, Team, Enterprise, or free)"
    info ""
    prompt "> "

    case "$REPLY" in
        1)
            info ""
            prompt_secret "API key: "
            local api_key="$REPLY"
            if [ -z "$api_key" ]; then
                info "No API key entered. Aborted."
                exit 1
            fi
            prompt "API URL (leave empty unless you use a custom endpoint): "
            local base_url="$REPLY"
            write_auth_env "$api_key" "$base_url"
            AUTH_HINT=""
            ;;
        2)
            remove_auth_env
            AUTH_HINT="You'll be asked to log in on first launch."
            ;;
        *)
            info "Invalid choice."
            exit 1
            ;;
    esac
}

# ---------- Build local image ----------
build_local_image() {
    if [ ! -f "Dockerfile" ]; then
        info ""
        info "--build requires a Dockerfile in the current directory."
        info "Run ./install.sh --build from the ccbox repo checkout."
        exit 1
    fi
    info "Building ccbox image locally..."
    "$RUNTIME" build -t ghcr.io/moritzbutzmann/ccbox:latest .
    info "Build complete."
}

# ---------- Uninstall ----------
do_uninstall() {
    info ""
    prompt "Remove saved sessions and settings too? [y/N] "
    remove_function
    case "$REPLY" in
        [yY]*)
            rm -rf "$CCBOX_DATA" "$CCBOX_CONFIG"
            ;;
    esac
    info ""
    info "ccbox removed. Close this terminal and open a new one."
}

# ---------- Already installed ----------
do_already_installed() {
    info ""
    info "ccbox is already set up."
    info "Auth: $(auth_label)"
    info ""
    info "  1) Update ccbox command"
    info "  2) Change how I log in"
    info "  3) Remove ccbox"
    info ""
    prompt "> "

    case "$REPLY" in
        1)
            install_function
            info ""
            info "ccbox command updated. Close this terminal and open a new one."
            ;;
        2)
            configure_auth
            install_function
            info ""
            info "Done! Close this terminal, open a new one, then run: ccbox"
            [ -n "${AUTH_HINT:-}" ] && info "$AUTH_HINT"
            ;;
        3)
            do_uninstall
            ;;
        *)
            info "Invalid choice."
            exit 1
            ;;
    esac
}

# ---------- First run ----------
do_first_run() {
    info "Installing ccbox..."

    configure_auth
    install_function

    info ""
    info "ccbox is ready! Close this terminal, open a new one, then run: ccbox"
    [ -n "${AUTH_HINT:-}" ] && info "$AUTH_HINT"
}

# ==============================================================================
# Main
# ==============================================================================

detect_runtime
detect_shell

$BUILD_LOCAL && build_local_image

is_installed=false
if [ "$CURRENT_SHELL" = "fish" ]; then
    [ -f "$RC_FILE" ] && grep -q '# >>> ccbox >>>' "$RC_FILE" 2>/dev/null && is_installed=true
else
    [ -f "$RC_FILE" ] && grep -q '# >>> ccbox >>>' "$RC_FILE" 2>/dev/null && is_installed=true
fi

if $is_installed; then
    # Always update the function silently
    check_existing_ccbox
    install_function
    do_already_installed
else
    check_existing_ccbox
    mkdir -p "$CCBOX_DATA"
    do_first_run
fi
