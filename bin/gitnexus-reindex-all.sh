#!/usr/bin/env bash
set -euo pipefail

GITNEXUS_BIN="${GITNEXUS_BIN:-$HOME/.local/bin/gitnexus-stable}"
REGISTRY_PATH="${REGISTRY_PATH:-$HOME/.gitnexus/registry.json}"
ALLOW_DIRTY_REINDEX="${ALLOW_DIRTY_REINDEX:-0}"

if [[ ! -x "$GITNEXUS_BIN" ]]; then
  echo "ERROR: gitnexus stable wrapper not found: $GITNEXUS_BIN" >&2
  exit 1
fi

if [[ ! -f "$REGISTRY_PATH" ]]; then
  echo "ERROR: registry not found: $REGISTRY_PATH" >&2
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

jq -r '.[].path' "$REGISTRY_PATH" | while IFS= read -r repo_path; do
  [[ -z "$repo_path" ]] && continue
  if [[ ! -d "$repo_path" ]]; then
    echo "SKIP: missing repo path $repo_path" >&2
    continue
  fi

  if [[ "$ALLOW_DIRTY_REINDEX" != "1" ]] && is_dirty_repo "$repo_path"; then
    echo "SKIP: dirty worktree $repo_path (set ALLOW_DIRTY_REINDEX=1 to override)" >&2
    continue
  fi

  analyze_args=(analyze --force)
  embedding_flag="$(embedding_flag_for_repo "$repo_path")"
  if [[ -n "$embedding_flag" ]]; then
    analyze_args+=("$embedding_flag")
  fi

  echo "== Reindex: $repo_path =="
  (
    cd "$repo_path"
    "$GITNEXUS_BIN" "${analyze_args[@]}"
  )
done
