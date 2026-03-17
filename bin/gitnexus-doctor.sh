#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-$PWD}"
REPO_NAME="${2:-$(basename "$ROOT_DIR")}"
SYMBOL="${3:-}"
GITNEXUS_BIN="${GITNEXUS_BIN:-$HOME/.local/bin/gitnexus-stable}"
CODEX_CONFIG="${CODEX_CONFIG:-$HOME/.codex/config.toml}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ ! -x "$GITNEXUS_BIN" ]]; then
  echo "ERROR: gitnexus stable wrapper not found: $GITNEXUS_BIN" >&2
  exit 1
fi

if [[ ! -d "$ROOT_DIR/.gitnexus" ]]; then
  echo "ERROR: .gitnexus not found under $ROOT_DIR" >&2
  exit 1
fi

stable_version="$("$GITNEXUS_BIN" --version)"
global_version="$(gitnexus --version 2>/dev/null || echo 'unavailable')"
config_summary="$(awk '
  $0 ~ /^\[mcp_servers\.gitnexus\]/ {in_block=1; print; next}
  in_block && $0 ~ /^\[/ {exit}
  in_block {print}
' "$CODEX_CONFIG" 2>/dev/null || true)"

echo "== GitNexus Doctor =="
echo "repo_root: $ROOT_DIR"
echo "repo_name: $REPO_NAME"
echo "stable_version: $stable_version"
echo "global_version: $global_version"
echo "storage:"
find "$ROOT_DIR/.gitnexus" -maxdepth 1 -type f | sort | sed 's/^/  - /'

if [[ -n "$config_summary" ]]; then
  echo "codex_gitnexus_mcp:"
  echo "$config_summary" | sed 's/^/  /'
else
  echo "codex_gitnexus_mcp: missing"
fi

if [[ -f "$ROOT_DIR/.gitnexus/kuzu" ]]; then
  echo "WARN: stale kuzu index still exists" >&2
fi

if [[ ! -f "$ROOT_DIR/.gitnexus/lbug" ]]; then
  echo "ERROR: lbug index is missing" >&2
  exit 2
fi

echo
echo "== Basic Checks =="
"$GITNEXUS_BIN" status --help >/dev/null
(cd "$ROOT_DIR" && "$GITNEXUS_BIN" status)
(cd "$ROOT_DIR" && "$GITNEXUS_BIN" list | sed -n '1,10p')

if [[ -n "$SYMBOL" ]]; then
  echo
  echo "== Symbol Checks: $SYMBOL =="
  (cd "$ROOT_DIR" && "$GITNEXUS_BIN" context --repo "$REPO_NAME" "$SYMBOL")
  (cd "$ROOT_DIR" && "$SCRIPT_DIR/gitnexus-safe-impact.sh" "$REPO_NAME" "$SYMBOL")
fi
