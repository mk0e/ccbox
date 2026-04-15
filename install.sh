#!/bin/bash
set -e

# ==============================================================================
# ccbox installer
# Installs the ccbox command and configures authentication.
# Run again anytime to change settings or uninstall.
#
# Usage:
#   ./install.sh
#   curl -fsSL https://raw.githubusercontent.com/mk0e/ccbox/main/install.sh | bash
# ==============================================================================

# ---------- Variant helpers ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/variants.sh"

CCBOX_DATA="$HOME/.ccbox"
CCBOX_CONFIG="$HOME/.config/ccbox"
AUTH_ENV="$CCBOX_CONFIG/auth.env"
REGISTRY_FILE="$CCBOX_DATA/workspaces.json"

# ---------- Arg parsing ----------
BUILD_LOCAL=false
ACTION_ADD=""
ACTION_REMOVE=""
ACTION_UPDATE=false
while [ $# -gt 0 ]; do
    case "$1" in
        --build)  BUILD_LOCAL=true; shift ;;
        --add)    ACTION_ADD="$2";    shift 2 ;;
        --remove) ACTION_REMOVE="$2"; shift 2 ;;
        --update) ACTION_UPDATE=true; shift ;;
        *) printf "Unknown option: %s\n" "$1" >&2; exit 1 ;;
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
    # Rootless Podman needs --userns=keep-id so the host user maps to the
    # in-container claude user (UID 1000). Detect: podman + non-root invoker.
    set -l userns_args
    set -l uidgid_args -e "PUID="(id -u) -e "PGID="(id -g)
    if test "$runtime" = "podman"; and test (id -u) != "0"
        set userns_args --userns=keep-id:uid=1000,gid=1000
        set uidgid_args
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
        set -l cids ($runtime ps -q --filter ancestor=ghcr.io/mk0e/ccbox:latest 2>/dev/null)
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
        set -l existing ($runtime ps -q --filter ancestor=ghcr.io/mk0e/ccbox:latest 2>/dev/null)
        if test -n "$existing"
            echo "ccbox is already running. Open http://localhost:$port or run: ccbox stop"
            return
        end
        set -l args run --rm -p "127.0.0.1:$port:8080" \
            $userns_args \
            -v (pwd):/workspace \
            -v $HOME/.ccbox:/home/claude/.claude \
            $uidgid_args
        test -n "$api_key";  and set -a args -e "ANTHROPIC_API_KEY=$api_key"
        test -n "$base_url"; and set -a args -e "ANTHROPIC_BASE_URL=$base_url"
        echo "ccbox is running at http://localhost:$port"
        echo "Press Ctrl+C to stop."
        $runtime $args ghcr.io/mk0e/ccbox:latest web $argv
        return
    end
    set -l args run -it --rm \
        $userns_args \
        -v (pwd):/workspace \
        -v $HOME/.ccbox:/home/claude/.claude \
        $uidgid_args
    test -n "$api_key";  and set -a args -e "ANTHROPIC_API_KEY=$api_key"
    test -n "$base_url"; and set -a args -e "ANTHROPIC_BASE_URL=$base_url"
    $runtime $args ghcr.io/mk0e/ccbox:latest $argv
end
# <<< ccbox <<<
FISH_FUNC
        info ""
        info "NOTE: the fish ccbox function is not yet variant-aware."
        info "      It always runs ghcr.io/mk0e/ccbox:latest (the docs variant)."
        info "      Multi-variant dispatch (including diy-news-collector) is"
        info "      available today in bash and zsh. Fish support is a"
        info "      tracked follow-up."
        info ""
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

    local ccbox_data="$HOME/.ccbox"
    local registry="$ccbox_data/workspaces.json"
    local variants_dir="$ccbox_data/variants"

    # --- Resolve which variant to use ---
    local registry_default=""
    if [ -f "$registry" ]; then
        registry_default="$(sed -n 's/.*"default": *"\([^"]*\)".*/\1/p' "$registry")"
    fi

    # First arg disambiguation:
    #   - known variant name          → consume as variant
    #   - 'web' or 'stop'              → subcommand, don't consume
    #   - starts with '-' or empty     → claude passthrough, don't consume
    #   - anything else                → assume mistyped variant, error out
    local variant=""
    local first_arg="${1:-}"
    if [ -n "$first_arg" ] && [ -f "$variants_dir/$first_arg.env" ]; then
        variant="$first_arg"
        shift
    elif [ -n "$first_arg" ] \
         && [ "$first_arg" != "web" ] \
         && [ "$first_arg" != "stop" ] \
         && [ "${first_arg:0:1}" != "-" ]; then
        echo "ccbox: variant '$first_arg' is not installed." >&2
        if [ -d "$variants_dir" ]; then
            local available=""
            local envfile
            for envfile in "$variants_dir"/*.env; do
                [ -f "$envfile" ] || continue
                available="$available  $(basename "${envfile%.env}")\n"
            done
            if [ -n "$available" ]; then
                echo "Available variants:" >&2
                printf "$available" >&2
            fi
        fi
        echo "Install with: ./install.sh --add $first_arg" >&2
        return 1
    fi
    if [ -z "$variant" ]; then
        variant="${registry_default:-docs}"
    fi

    local var_env="$variants_dir/$variant.env"
    if [ ! -f "$var_env" ]; then
        echo "ccbox: variant '$variant' is not installed." >&2
        echo "Run ./install.sh --add $variant to install it." >&2
        return 1
    fi

    # --- Read variant fields ---
    local v_name v_mount v_image v_webport
    v_name="$(sed -n 's/^name=//p'        "$var_env")"
    v_mount="$(sed -n 's/^mount=//p'      "$var_env")"
    v_image="$(sed -n 's/^image=//p'      "$var_env")"
    v_webport="$(sed -n 's/^web_port=//p' "$var_env")"
    [ -z "$v_image" ]   && v_image="ghcr.io/mk0e/ccbox:$v_name"
    [ -z "$v_mount" ]   && v_mount="."
    [ -z "$v_webport" ] && v_webport=8080

    local container_name="ccbox-$v_name"

    # --- Resolve host mount path ---
    local mount_abs
    if [ "$v_mount" = "." ]; then
        mount_abs="$(pwd)"
    else
        mount_abs="$(pwd)/${v_mount#./}"
        mkdir -p "$mount_abs"
    fi

    # --- Seed files on first launch (empty target dir only) ---
    if [ "$v_mount" != "." ] && [ -z "$(ls -A "$mount_abs" 2>/dev/null)" ]; then
        "$runtime" run --rm -v "$mount_abs":/target "$v_image" \
            sh -c 'cp -rn /opt/ccbox/seed/. /target/ 2>/dev/null || true' \
            >/dev/null 2>&1 || true
    fi

    # --- Handle stop (all) ---
    if [ "$1" = "stop" ]; then
        local stopped=0
        local envfile
        for envfile in "$variants_dir"/*.env; do
            [ -f "$envfile" ] || continue
            local nm; nm="$(sed -n 's/^name=//p' "$envfile")"
            local cname="ccbox-$nm"
            if "$runtime" ps --filter "name=^${cname}$" --format '{{.Names}}' | grep -qx "$cname"; then
                "$runtime" stop "$cname" >/dev/null 2>&1
                echo "Stopped $cname."
                stopped=$((stopped+1))
            fi
        done
        [ "$stopped" -eq 0 ] && echo "No running ccbox containers found."
        return
    fi

    # --- Podman userns + uid mapping ---
    local userns_args=()
    local uidgid_args=(-e "PUID=$(id -u)" -e "PGID=$(id -g)")
    if [ "$runtime" = "podman" ] && [ "$(id -u)" != "0" ]; then
        userns_args=(--userns=keep-id:uid=1000,gid=1000)
        uidgid_args=()
    fi

    # --- Auth env ---
    local base_url="${ANTHROPIC_BASE_URL:-}"
    local api_key="${ANTHROPIC_API_KEY:-}"
    if [ -z "$api_key" ] && [ -f "$HOME/.config/ccbox/auth.env" ]; then
        while read -r line; do
            [[ -z "$line" || "$line" =~ ^# ]] && continue
            local key="${line%%=*}" value="${line#*=}"
            case "$key" in
                ANTHROPIC_API_KEY)  api_key="$value" ;;
                ANTHROPIC_BASE_URL) base_url="$value" ;;
            esac
        done < "$HOME/.config/ccbox/auth.env"
    fi

    mkdir -p "$HOME/.ccbox/home/$v_name"

    # --- Web mode ---
    if [ "$1" = "web" ]; then
        shift
        local port="$v_webport"
        if [ $# -gt 0 ] && [[ "$1" =~ ^[0-9]+$ ]]; then
            port="$1"; shift
        fi
        if "$runtime" ps --filter "name=^${container_name}$" --format '{{.Names}}' | grep -qx "$container_name"; then
            echo "$container_name is already running. Open http://localhost:$port or run: ccbox $v_name stop"
            return
        fi
        local args=(run --rm --name "$container_name" -p "127.0.0.1:$port:8080"
            "${userns_args[@]}"
            -v "$mount_abs":/workspace
            -v "$HOME/.ccbox/home/$v_name":/home/claude/.claude
            "${uidgid_args[@]}"
        )
        [ -n "$api_key" ]  && args+=(-e "ANTHROPIC_API_KEY=$api_key")
        [ -n "$base_url" ] && args+=(-e "ANTHROPIC_BASE_URL=$base_url")
        echo "ccbox ($v_name) is running at http://localhost:$port"
        echo "Press Ctrl+C to stop."
        "$runtime" "${args[@]}" "$v_image" web "$@"
        return
    fi

    # --- Interactive mode ---
    local args=(run -it --rm --name "$container_name"
        "${userns_args[@]}"
        -v "$mount_abs":/workspace
        -v "$HOME/.ccbox/home/$v_name":/home/claude/.claude
        "${uidgid_args[@]}"
    )
    [ -n "$api_key" ]  && args+=(-e "ANTHROPIC_API_KEY=$api_key")
    [ -n "$base_url" ] && args+=(-e "ANTHROPIC_BASE_URL=$base_url")
    "$runtime" "${args[@]}" "$v_image" "$@"
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

# ---------- Variant selection ----------
select_variants() {
    WANTED_VARIANTS=()
    local available=()
    while IFS= read -r __v; do
        available+=("$__v")
    done < <(list_variants "$SCRIPT_DIR/variants")
    if [ "${#available[@]}" -eq 0 ]; then
        info "No variants found under variants/ — aborting."
        exit 1
    fi

    registry_load "$REGISTRY_FILE"
    local preselected=("${REGISTRY_INSTALLED[@]}")
    if [ "${#preselected[@]}" -eq 0 ]; then
        preselected=("docs")
    fi

    info ""
    info "Which workspaces do you want installed?"
    info "Enter comma-separated numbers. Current selection is shown in [ ]."
    local i=1 name desc marker
    local index_to_name=()
    for name in "${available[@]}"; do
        desc="$(get_variant_field "$SCRIPT_DIR/variants/$name/workspace.env" description)"
        marker=" "
        local p
        for p in "${preselected[@]}"; do
            [ "$p" = "$name" ] && marker="x"
        done
        info "  [$marker] $i) $name — $desc"
        index_to_name[$i]="$name"
        i=$((i + 1))
    done
    info ""
    prompt "> "

    if [ -z "$REPLY" ]; then
        WANTED_VARIANTS=("${preselected[@]}")
        return 0
    fi

    local IFS=','
    local token
    for token in $REPLY; do
        token="${token// /}"
        if [ -n "${index_to_name[$token]:-}" ]; then
            WANTED_VARIANTS+=("${index_to_name[$token]}")
        else
            info "Ignoring invalid selection: $token"
        fi
    done
}

# ---------- Per-variant image operations ----------
variant_image() { printf 'ghcr.io/mk0e/ccbox:%s\n' "$1"; }

pull_variant() {
    local name="$1"
    local image; image="$(variant_image "$name")"
    if "$RUNTIME" image inspect "$image" &>/dev/null; then
        return 0
    fi
    info ""
    info "Pulling $image ..."
    if "$RUNTIME" pull "$image" > /dev/tty 2>&1; then
        info "Pulled $image."
    else
        info "Warning: could not pull $image. It will be pulled on first use."
    fi
}

force_pull_variant() {
    local name="$1"
    local image; image="$(variant_image "$name")"
    info ""
    info "Pulling $image from remote..."
    if ! "$RUNTIME" pull "$image" > /dev/tty 2>&1; then
        info "Error: could not pull $image."
        exit 1
    fi
    info "Updated $image."
}

build_variant() {
    local name="$1"
    local dockerfile="$SCRIPT_DIR/variants/$name/Dockerfile"
    local image; image="$(variant_image "$name")"
    if [ ! -f "$dockerfile" ]; then
        info "No Dockerfile found for variant '$name' at $dockerfile — skipping."
        return 1
    fi
    info "Building $image locally..."
    "$RUNTIME" build -t ccbox-base:latest "$SCRIPT_DIR"
    "$RUNTIME" build -t "$image" -f "$dockerfile" "$SCRIPT_DIR"
    info "Built $image."
}

apply_variant_selection() {
    local previously=()
    registry_load "$REGISTRY_FILE"
    previously=("${REGISTRY_INSTALLED[@]}")

    local name
    for name in "${WANTED_VARIANTS[@]}"; do
        if $BUILD_LOCAL; then
            build_variant "$name" || continue
        else
            pull_variant "$name"
        fi
        registry_add "$REGISTRY_FILE" "$name"
    done

    for name in "${previously[@]}"; do
        local keep=false p
        for p in "${WANTED_VARIANTS[@]}"; do
            [ "$p" = "$name" ] && keep=true
        done
        if ! $keep; then
            registry_remove "$REGISTRY_FILE" "$name"
            info "Removed $name from registry."
        fi
    done

    registry_load "$REGISTRY_FILE"
    local new_default="${REGISTRY_INSTALLED[0]:-}"
    local n
    for n in "${REGISTRY_INSTALLED[@]}"; do
        [ "$n" = "docs" ] && new_default="docs"
    done
    if [ -n "$new_default" ]; then
        registry_write "$REGISTRY_FILE" "$new_default" "${REGISTRY_INSTALLED[@]}"
    fi

    # Snapshot each installed variant's workspace.env into ~/.ccbox/variants/
    # so the shell function can read metadata without sourcing lib/variants.sh.
    mkdir -p "$CCBOX_DATA/variants"
    registry_load "$REGISTRY_FILE"
    for n in "${REGISTRY_INSTALLED[@]}"; do
        if [ -f "$SCRIPT_DIR/variants/$n/workspace.env" ]; then
            cp "$SCRIPT_DIR/variants/$n/workspace.env" "$CCBOX_DATA/variants/$n.env"
        fi
    done
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
    "$RUNTIME" build -t ghcr.io/mk0e/ccbox:latest .
    info "Build complete."
}

# ---------- Pre-pull image (skip if already present) ----------
pre_pull_image() {
    if "$RUNTIME" image inspect ghcr.io/mk0e/ccbox:latest &>/dev/null; then
        return 0
    fi
    info ""
    info "Pulling ccbox image (one-time, ~4 GB)..."
    if "$RUNTIME" pull ghcr.io/mk0e/ccbox:latest > /dev/tty 2>&1; then
        info "Image pulled."
    else
        info ""
        info "Warning: could not pull ccbox image (offline or registry unavailable)."
        info "Install will continue. The image will be pulled on first 'ccbox' run."
    fi
}

# ---------- Force pull image (always hits the registry) ----------
force_pull_image() {
    info ""
    info "Pulling ccbox image from remote..."
    if "$RUNTIME" pull ghcr.io/mk0e/ccbox:latest > /dev/tty 2>&1; then
        info "Image updated."
    else
        info ""
        info "Error: could not pull ccbox image (offline or registry unavailable)."
        exit 1
    fi
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
    if "$RUNTIME" image inspect ghcr.io/mk0e/ccbox:latest &>/dev/null; then
        info ""
        prompt "Remove the local ccbox container image too? [y/N] "
        case "$REPLY" in
            [yY]*)
                "$RUNTIME" rmi ghcr.io/mk0e/ccbox:latest >/dev/null 2>&1 \
                    && info "Image removed." \
                    || info "Could not remove image (it may be in use)."
                ;;
        esac
    fi
    info ""
    info "ccbox removed. Close this terminal and open a new one."
}

# ---------- Already installed ----------
do_already_installed() {
    info ""
    info "ccbox is already set up."
    info "Auth: $(auth_label)"
    registry_load "$REGISTRY_FILE"
    info "Installed workspaces: ${REGISTRY_INSTALLED[*]:-none}"
    info ""
    info "  1) Update ccbox command"
    info "  2) Update installed images (pull from remote)"
    info "  3) Update installed images (build from source)"
    info "  4) Add or remove workspaces"
    info "  5) Change how I log in"
    info "  6) Remove ccbox"
    info ""
    prompt "> "

    case "$REPLY" in
        1)
            install_function
            info "ccbox command updated. Close this terminal and open a new one."
            ;;
        2)
            registry_load "$REGISTRY_FILE"
            for name in "${REGISTRY_INSTALLED[@]}"; do
                force_pull_variant "$name"
            done
            ;;
        3)
            BUILD_LOCAL=true
            registry_load "$REGISTRY_FILE"
            WANTED_VARIANTS=("${REGISTRY_INSTALLED[@]}")
            apply_variant_selection
            ;;
        4)
            select_variants
            apply_variant_selection
            install_function
            ;;
        5)
            configure_auth
            install_function
            info "Done! Close this terminal, open a new one, then run: ccbox"
            [ -n "${AUTH_HINT:-}" ] && info "$AUTH_HINT"
            ;;
        6)
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

    if $BUILD_LOCAL; then
        build_local_image
    else
        pre_pull_image
    fi

    info ""
    info "ccbox is ready! Close this terminal, open a new one, then run: ccbox"
    [ -n "${AUTH_HINT:-}" ] && info "$AUTH_HINT"
}

# ==============================================================================
# Main
# ==============================================================================

detect_runtime
detect_shell

# Non-interactive shortcuts
if [ -n "$ACTION_ADD" ]; then
    if [ ! -d "$SCRIPT_DIR/variants/$ACTION_ADD" ]; then
        info "Unknown variant: $ACTION_ADD"
        info "Available variants:"
        list_variants "$SCRIPT_DIR/variants" | sed 's/^/  /'
        exit 1
    fi
    registry_load "$REGISTRY_FILE"
    WANTED_VARIANTS=("${REGISTRY_INSTALLED[@]}" "$ACTION_ADD")
    apply_variant_selection
    install_function
    info "Added $ACTION_ADD."
    exit 0
fi

if [ -n "$ACTION_REMOVE" ]; then
    registry_load "$REGISTRY_FILE"
    WANTED_VARIANTS=()
    for v in "${REGISTRY_INSTALLED[@]}"; do
        [ "$v" != "$ACTION_REMOVE" ] && WANTED_VARIANTS+=("$v")
    done
    apply_variant_selection
    install_function
    info "Removed $ACTION_REMOVE."
    exit 0
fi

if $ACTION_UPDATE; then
    registry_load "$REGISTRY_FILE"
    for name in "${REGISTRY_INSTALLED[@]}"; do
        force_pull_variant "$name"
    done
    install_function
    info "Update complete."
    exit 0
fi

# Interactive flow
is_installed=false
[ -f "$RC_FILE" ] && grep -q '# >>> ccbox >>>' "$RC_FILE" 2>/dev/null && is_installed=true

if $is_installed; then
    check_existing_ccbox
    install_function
    do_already_installed
else
    check_existing_ccbox
    mkdir -p "$CCBOX_DATA"
    configure_auth
    select_variants
    apply_variant_selection
    install_function
    info ""
    info "ccbox is ready! Close this terminal, open a new one, then run: ccbox"
    [ -n "${AUTH_HINT:-}" ] && info "$AUTH_HINT"
fi
