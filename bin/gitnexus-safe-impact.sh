#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <repo_name> <symbol_name> [direction]" >&2
  exit 1
fi

REPO_NAME="$1"
SYMBOL_NAME="$2"
DIRECTION="${3:-upstream}"
GITNEXUS_BIN="${GITNEXUS_BIN:-$HOME/.local/bin/gitnexus-stable}"

if [[ ! -x "$GITNEXUS_BIN" ]]; then
  echo "ERROR: gitnexus stable wrapper not found: $GITNEXUS_BIN" >&2
  exit 1
fi

impact_output=""
impact_status=0

set +e
impact_output="$("$GITNEXUS_BIN" impact --repo "$REPO_NAME" "$SYMBOL_NAME" 2>&1)"
impact_status=$?
set -e

if [[ $impact_status -eq 0 ]] && echo "$impact_output" | jq -e 'type == "object" and (.error? == null)' >/dev/null 2>&1; then
  echo "$impact_output"
  exit 0
fi

echo "WARN: impact failed, falling back to context-based summary" >&2
echo "$impact_output" >&2

context_output="$("$GITNEXUS_BIN" context --repo "$REPO_NAME" "$SYMBOL_NAME" 2>&1)" || {
  echo "ERROR: context fallback failed" >&2
  exit 2
}

echo "$context_output" | jq --arg direction "$DIRECTION" '
  def direct_refs:
    if $direction == "upstream"
    then ((.incoming.calls // []) + (.incoming.imports // []) + (.incoming.extends // []) + (.incoming.implements // []))
    else ((.outgoing.calls // []) + (.outgoing.imports // []) + (.outgoing.extends // []) + (.outgoing.implements // []))
    end;
  def risk_for($count):
    if $count >= 15 then "HIGH"
    elif $count >= 5 then "MEDIUM"
    else "LOW"
    end;
  . as $ctx
  | (direct_refs) as $refs
  | {
      target: {
        id: $ctx.symbol.uid,
        name: $ctx.symbol.name,
        type: $ctx.symbol.kind,
        filePath: $ctx.symbol.filePath
      },
      direction: $direction,
      impactedCount: ($refs | length),
      risk: risk_for($refs | length),
      summary: {
        direct: ($refs | length),
        processes_affected: (($ctx.processes // []) | length),
        modules_affected: 0
      },
      affected_processes: ($ctx.processes // []),
      affected_modules: [],
      byDepth: {
        "1": ($refs | map({
          depth: 1,
          id: .uid,
          name: .name,
          type: .kind,
          filePath: .filePath,
          relationType: "CALLS/IMPORTS",
          confidence: 0.5
        }))
      },
      fallbackUsed: true,
      fallbackSource: "context"
    }
'
