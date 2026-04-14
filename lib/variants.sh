#!/usr/bin/env bash
# Variant discovery and metadata helpers.
# Sourced by install.sh and by tests.

# Usage: list_variants /path/to/variants
# Prints one variant name per line, sorted, for every subdir containing workspace.env.
list_variants() {
    local variants_dir="$1"
    [ -d "$variants_dir" ] || return 0
    local entry
    for entry in "$variants_dir"/*/; do
        [ -f "${entry}workspace.env" ] || continue
        basename "${entry%/}"
    done | sort
}

# Usage: get_variant_field /path/to/workspace.env key
# Prints the value of `key=value` in the env file. Empty if not present.
get_variant_field() {
    local file="$1" key="$2"
    [ -f "$file" ] || return 0
    local line value
    while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        case "$line" in
            \#*) continue ;;
        esac
        if [ "${line%%=*}" = "$key" ]; then
            value="${line#*=}"
            value="${value%\"}"
            value="${value#\"}"
            printf '%s\n' "$value"
            return 0
        fi
    done < "$file"
}

# Usage: variant_image_tag <name>
variant_image_tag() {
    printf 'ccbox:%s\n' "$1"
}

# Usage: variant_container_name <name>
variant_container_name() {
    printf 'ccbox-%s\n' "$1"
}

# ---------- Registry helpers (~/.ccbox/workspaces.json) ----------
# Schema: {"installed": ["name", ...], "default": "name"}
# We produce canonical JSON ourselves and parse it with sed — no jq dependency.

# Usage: registry_write <file> <default> [installed...]
registry_write() {
    local file="$1" default="$2"; shift 2
    local installed=("$@")
    local dir; dir="$(dirname "$file")"
    mkdir -p "$dir"
    {
        printf '{\n'
        printf '  "installed": ['
        local first=1 v
        for v in "${installed[@]}"; do
            if [ "$first" -eq 1 ]; then first=0; else printf ', '; fi
            printf '"%s"' "$v"
        done
        printf '],\n'
        printf '  "default": "%s"\n' "$default"
        printf '}\n'
    } > "$file"
}

# Loads the installed list into REGISTRY_INSTALLED (array) and REGISTRY_DEFAULT (string).
# Creates an empty registry-state if the file doesn't exist.
registry_load() {
    local file="$1"
    REGISTRY_INSTALLED=()
    REGISTRY_DEFAULT=""
    if [ ! -f "$file" ]; then
        return 0
    fi
    local installed_line
    installed_line="$(sed -n 's/.*"installed": *\[\([^]]*\)\].*/\1/p' "$file")"
    if [ -n "$installed_line" ]; then
        local IFS=','
        local raw
        for raw in $installed_line; do
            raw="${raw// /}"
            raw="${raw//\"/}"
            [ -n "$raw" ] && REGISTRY_INSTALLED+=("$raw")
        done
    fi
    REGISTRY_DEFAULT="$(sed -n 's/.*"default": *"\([^"]*\)".*/\1/p' "$file")"
}

registry_is_installed() {
    local file="$1" name="$2"
    registry_load "$file"
    local v
    for v in "${REGISTRY_INSTALLED[@]}"; do
        [ "$v" = "$name" ] && return 0
    done
    return 1
}

registry_add() {
    local file="$1" name="$2"
    registry_load "$file"
    if registry_is_installed "$file" "$name"; then
        return 0
    fi
    REGISTRY_INSTALLED+=("$name")
    local default="${REGISTRY_DEFAULT:-$name}"
    registry_write "$file" "$default" "${REGISTRY_INSTALLED[@]}"
}

registry_remove() {
    local file="$1" name="$2"
    registry_load "$file"
    local new=() v
    for v in "${REGISTRY_INSTALLED[@]}"; do
        [ "$v" != "$name" ] && new+=("$v")
    done
    local default="$REGISTRY_DEFAULT"
    if [ "$default" = "$name" ]; then
        default="${new[0]:-}"
    fi
    registry_write "$file" "$default" "${new[@]}"
}
