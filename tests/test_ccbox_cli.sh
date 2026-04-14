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

# Seed registry + variant snapshots
mkdir -p "$HOME/.ccbox/variants"
cat > "$HOME/.ccbox/workspaces.json" <<EOF
{"installed": ["docs", "diy-news-collector"], "default": "docs"}
EOF
cat > "$HOME/.ccbox/variants/docs.env" <<EOF
name=docs
description=Document generation
image=ghcr.io/mk0e/ccbox:docs
mount=.
web_port=8080
EOF
cat > "$HOME/.ccbox/variants/diy-news-collector.env" <<EOF
name=diy-news-collector
description=Workshop
image=ghcr.io/mk0e/ccbox:diy-news-collector
mount=./diy-news-collector/
web_port=8081
EOF

# Extract the bash ccbox function from install.sh (skip the fish heredoc, take the second occurrence).
awk '/^# >>> ccbox >>>$/{count++; if(count==2) found=1} found; /^# <<< ccbox <<<$/ && count==2{found=0}' \
    "$REPO_ROOT/install.sh" > "$TMPHOME/ccbox_fn.sh"

# Create a real docker shim so command -v docker finds it.
DOCKER_LOG="$TMPHOME/docker.log"
mkdir -p "$TMPHOME/bin"
cat > "$TMPHOME/bin/docker" <<STUB
#!/usr/bin/env bash
echo "\$*" >> "$DOCKER_LOG"
exit 0
STUB
chmod +x "$TMPHOME/bin/docker"
export PATH="$TMPHOME/bin:$PATH"
export DOCKER_LOG

# shellcheck disable=SC1090
source "$TMPHOME/ccbox_fn.sh"

cd "$TMPCWD"

# --- Default variant is docs ---
: > "$DOCKER_LOG"
ccbox || true
grep -q 'ghcr.io/mk0e/ccbox:docs' "$DOCKER_LOG" || fail "default should use docs image. log: $(cat "$DOCKER_LOG")"
ok "default variant is docs"

# --- Explicit variant dispatches ---
: > "$DOCKER_LOG"
ccbox diy-news-collector || true
grep -q 'ghcr.io/mk0e/ccbox:diy-news-collector' "$DOCKER_LOG" || fail "explicit diy should use diy image. log: $(cat "$DOCKER_LOG")"
ok "explicit variant dispatches"

# --- Container name is per-variant ---
grep -q -- '--name ccbox-diy-news-collector' "$DOCKER_LOG" || fail "container name should be ccbox-diy-news-collector. log: $(cat "$DOCKER_LOG")"
ok "container name is per-variant"

# --- Mount subfolder created for diy variant ---
test -d "$TMPCWD/diy-news-collector" || fail "mount subfolder should have been created"
ok "mount subfolder auto-created"

# --- Unknown variant errors ---
# Trigger by pointing the registry default at a variant whose .env is missing.
cat > "$HOME/.ccbox/workspaces.json" <<REOF
{"installed": [], "default": "nonexistent"}
REOF
set +e
output="$(cd "$TMPCWD" && ccbox 2>&1)"
rc=$?
set -e
[ "$rc" -ne 0 ] || fail "unknown variant should return nonzero, got rc=$rc"
echo "$output" | grep -q "not installed" || fail "unknown variant should print 'not installed'. output: $output"
ok "unknown variant errors"

echo "All tests passed."
