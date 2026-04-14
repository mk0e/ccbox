#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."
# shellcheck disable=SC1091
source "$REPO_ROOT/lib/variants.sh"

fail() { echo "FAIL: $1" >&2; exit 1; }
ok()   { echo "PASS: $1"; }

TMPHOME="$(mktemp -d)"
trap 'rm -rf "$TMPHOME"' EXIT

REGISTRY="$TMPHOME/.ccbox/workspaces.json"
mkdir -p "$(dirname "$REGISTRY")"

# --- registry_write creates a valid JSON file ---
registry_write "$REGISTRY" "docs" "docs"
grep -q '"installed"' "$REGISTRY" || fail "registry_write missing installed"
grep -q '"default"'   "$REGISTRY" || fail "registry_write missing default"
ok "registry_write produces JSON"

# --- registry_is_installed reads correctly ---
registry_is_installed "$REGISTRY" docs || fail "docs should be installed"
! registry_is_installed "$REGISTRY" diy-news-collector || fail "diy should NOT be installed"
ok "registry_is_installed"

# --- registry_add appends a variant ---
registry_add "$REGISTRY" diy-news-collector
registry_is_installed "$REGISTRY" diy-news-collector || fail "after add, diy should be installed"
ok "registry_add"

# --- registry_add is idempotent ---
registry_add "$REGISTRY" diy-news-collector
count=$(grep -o 'diy-news-collector' "$REGISTRY" | wc -l)
[ "$count" -eq 1 ] || fail "expected 1 occurrence, got $count"
ok "registry_add is idempotent"

# --- registry_remove removes a variant ---
registry_remove "$REGISTRY" diy-news-collector
! registry_is_installed "$REGISTRY" diy-news-collector || fail "after remove, diy should not be installed"
ok "registry_remove"

echo "All tests passed."
