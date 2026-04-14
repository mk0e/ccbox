#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."
# shellcheck disable=SC1091
source "$REPO_ROOT/lib/variants.sh"

fail() { echo "FAIL: $1" >&2; exit 1; }
ok()   { echo "PASS: $1"; }

# --- list_variants discovers all variants with a workspace.env ---
result="$(list_variants "$REPO_ROOT/variants")"
echo "$result" | grep -qx "docs" || fail "list_variants should include 'docs'"
ok "list_variants discovers docs"

# --- get_variant_field reads name ---
name="$(get_variant_field "$REPO_ROOT/variants/docs/workspace.env" name)"
[ "$name" = "docs" ] || fail "expected name=docs, got $name"
ok "get_variant_field reads name"

# --- get_variant_field reads mount ---
mount="$(get_variant_field "$REPO_ROOT/variants/docs/workspace.env" mount)"
[ "$mount" = "." ] || fail "expected mount=., got $mount"
ok "get_variant_field reads mount"

# --- get_variant_field reads web_port ---
port="$(get_variant_field "$REPO_ROOT/variants/docs/workspace.env" web_port)"
[ "$port" = "8080" ] || fail "expected web_port=8080, got $port"
ok "get_variant_field reads web_port"

# --- get_variant_field returns empty for missing key ---
missing="$(get_variant_field "$REPO_ROOT/variants/docs/workspace.env" nonexistent)"
[ -z "$missing" ] || fail "expected empty for missing key, got $missing"
ok "get_variant_field handles missing keys"

echo "All tests passed."
