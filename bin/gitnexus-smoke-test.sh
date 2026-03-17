#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "usage: $0 <repo_path> <repo_name> <symbol_name>" >&2
  exit 1
fi

REPO_PATH="$1"
REPO_NAME="$2"
SYMBOL_NAME="$3"
GITNEXUS_BIN="${GITNEXUS_BIN:-$HOME/.local/bin/gitnexus-stable}"
FORCE_REINDEX="${FORCE_REINDEX:-1}"
ALLOW_DIRTY_REINDEX="${ALLOW_DIRTY_REINDEX:-0}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ ! -x "$GITNEXUS_BIN" ]]; then
  echo "ERROR: gitnexus stable wrapper not found: $GITNEXUS_BIN" >&2
  exit 1
fi

embedding_flag_for_repo() {
  local repo_path="$1"
  local meta_path="$repo_path/.gitnexus/meta.json"
  if [[ ! -f "$meta_path" ]]; then
    return 0
  fi

  local embedding_count
  embedding_count="$(jq -r '.stats.embeddings // 0' "$meta_path" 2>/dev/null || echo 0)"
  if [[ "$embedding_count" =~ ^[0-9]+$ ]] && (( embedding_count > 0 )); then
    echo "--embeddings"
  fi
}

is_dirty_repo() {
  local repo_path="$1"
  [[ -d "$repo_path/.git" ]] || return 1
  [[ -n "$(git -C "$repo_path" status --porcelain --untracked-files=normal 2>/dev/null)" ]]
}

echo "== Smoke Test =="
echo "repo_path: $REPO_PATH"
echo "repo_name: $REPO_NAME"
echo "symbol_name: $SYMBOL_NAME"

if [[ "$FORCE_REINDEX" == "1" ]]; then
  if [[ "$ALLOW_DIRTY_REINDEX" != "1" ]] && is_dirty_repo "$REPO_PATH"; then
    echo "SKIP: analyze --force on dirty worktree $REPO_PATH (set ALLOW_DIRTY_REINDEX=1 to override)"
  else
    analyze_args=(analyze --force)
    embedding_flag="$(embedding_flag_for_repo "$REPO_PATH")"
    if [[ -n "$embedding_flag" ]]; then
      analyze_args+=("$embedding_flag")
    fi
    (cd "$REPO_PATH" && "$GITNEXUS_BIN" "${analyze_args[@]}" >/tmp/gitnexus-smoke-analyze.log 2>&1)
  fi
fi

(cd "$REPO_PATH" && "$GITNEXUS_BIN" status | tee /tmp/gitnexus-smoke-status.log)
(cd "$REPO_PATH" && "$GITNEXUS_BIN" list >/tmp/gitnexus-smoke-list.log)

context_json="$(cd "$REPO_PATH" && "$GITNEXUS_BIN" context --repo "$REPO_NAME" "$SYMBOL_NAME" 2>&1)"
echo "$context_json" | jq -e '.status == "found"' >/dev/null

cypher_query="MATCH (n) WHERE n.name = '$SYMBOL_NAME' RETURN n.name, n.filePath LIMIT 1"
cypher_json="$(cd "$REPO_PATH" && "$GITNEXUS_BIN" cypher --repo "$REPO_NAME" "$cypher_query" 2>&1)"
echo "$cypher_json" | jq -e '.row_count >= 1' >/dev/null

impact_json="$(cd "$REPO_PATH" && "$SCRIPT_DIR/gitnexus-safe-impact.sh" "$REPO_NAME" "$SYMBOL_NAME")"
echo "$impact_json" | jq -e '.target.name == "'"$SYMBOL_NAME"'"' >/dev/null

echo "PASS: analyze/status/list/context/cypher/impact"
