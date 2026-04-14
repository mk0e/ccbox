#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."
fail() { echo "FAIL: $1" >&2; exit 1; }
ok()   { echo "PASS: $1"; }

TMPHOME="$(mktemp -d)"
TMPCWD="$(mktemp -d)"
trap 'rm -rf "$TMPHOME" "$TMPCWD"' EXIT
export HOME="$TMPHOME"

# --- Seed registry + snapshots from the REAL workspace.env files in the repo ---
mkdir -p "$HOME/.ccbox/variants"
cat > "$HOME/.ccbox/workspaces.json" <<EOF
{"installed": ["docs", "diy-news-collector"], "default": "docs"}
EOF
for v in docs diy-news-collector; do
    cp "$REPO_ROOT/variants/$v/workspace.env" "$HOME/.ccbox/variants/$v.env"
done

# --- Docker shim on PATH so command -v docker finds it ---
DOCKER_LOG="$TMPHOME/docker.log"
mkdir -p "$TMPHOME/bin"
cat > "$TMPHOME/bin/docker" <<STUB
#!/usr/bin/env bash
echo "\$*" >> "$DOCKER_LOG"
exit 0
STUB
chmod +x "$TMPHOME/bin/docker"
export PATH="$TMPHOME/bin:$PATH"

# --- Extract the ccbox shell function from install.sh ---
# install.sh contains TWO heredocs (fish + bash) that begin with the same
# marker. Take the second occurrence — that's the bash one.
awk '/^# >>> ccbox >>>$/{count++} count==2 && /^# >>> ccbox >>>$/,/^# <<< ccbox <<<$/' \
    "$REPO_ROOT/install.sh" > "$TMPHOME/ccbox_fn.sh"

# shellcheck disable=SC1090
source "$TMPHOME/ccbox_fn.sh"

cd "$TMPCWD"

# --- Default: docs variant, CWD mount ---
: > "$DOCKER_LOG"
ccbox || true
grep -q 'ccbox:docs' "$DOCKER_LOG" || fail "default should use docs image. log: $(cat "$DOCKER_LOG")"
grep -q -- "$TMPCWD:/workspace" "$DOCKER_LOG" || fail "docs mount should be CWD. log: $(cat "$DOCKER_LOG")"
ok "default dispatches to docs with CWD mount"

# --- Diy variant: subfolder mount + diy image ---
: > "$DOCKER_LOG"
ccbox diy-news-collector || true
test -d "$TMPCWD/diy-news-collector" || fail "diy subfolder should have been created"
grep -q -- "$TMPCWD/diy-news-collector" "$DOCKER_LOG" || fail "diy mount should be the subfolder. log: $(cat "$DOCKER_LOG")"
grep -q 'ccbox:diy-news-collector' "$DOCKER_LOG" || fail "diy image wrong. log: $(cat "$DOCKER_LOG")"
ok "diy dispatches with subfolder mount"

# --- Web mode uses declared port 8081 ---
: > "$DOCKER_LOG"
ccbox diy-news-collector web || true
grep -q '127.0.0.1:8081:8080' "$DOCKER_LOG" || fail "diy web should use port 8081. log: $(cat "$DOCKER_LOG")"
ok "diy web uses declared port 8081"

# --- Container names per-variant ---
grep -q -- '--name ccbox-diy-news-collector' "$DOCKER_LOG" || fail "diy container name wrong. log: $(cat "$DOCKER_LOG")"
ok "container name is per-variant"

echo "All smoke tests passed."
