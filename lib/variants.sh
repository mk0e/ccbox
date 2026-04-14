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
