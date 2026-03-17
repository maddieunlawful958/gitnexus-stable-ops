#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
GITNEXUS_BIN="${GITNEXUS_BIN:-$HOME/.local/bin/gitnexus-stable}"
OUTPUT_DIR="${OUTPUT_DIR:-$PWD/out}"
OUTPUT_FILE="${OUTPUT_FILE:-$OUTPUT_DIR/graph-meta.jsonl}"
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LOG="${LOG:-/tmp/graph-meta-update.log}"

echo "=== Graph Meta Update $TS ===" > "$LOG"

if [[ ! -x "$GITNEXUS_BIN" ]]; then
  echo "ERROR: gitnexus binary not found: $GITNEXUS_BIN" >> "$LOG"
  cat "$LOG"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

REPOS=$("$GITNEXUS_BIN" list 2>/dev/null | grep -E '^  [A-Za-z]' | sed 's/^  //' | grep -v '^Indexed' || true)
if [[ -z "$REPOS" ]]; then
  echo "No indexed repos found" >> "$LOG"
  cat "$LOG"
  exit 0
fi

QUERY="MATCH (a)-[r:CodeRelation]->(b), (c1:Community)-[:CodeRelation]->(a), (c2:Community)-[:CodeRelation]->(b) WHERE c1 <> c2 RETURN c1.label AS from_cluster, c1.symbolCount AS from_size, c2.label AS to_cluster, c2.symbolCount AS to_size, count(r) AS cross_edges ORDER BY cross_edges DESC LIMIT 50"
TMP=$(mktemp)
PYSCRIPT=$(mktemp /tmp/parse_graph_XXXX.py)

cat > "$PYSCRIPT" <<'PYEOF'
import sys, json
repo = sys.argv[1]
ts = sys.argv[2]
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if "error" in data or "markdown" not in data:
    sys.exit(0)
lines = data["markdown"].strip().split("\n")
for line in lines[2:]:
    cols = [c.strip() for c in line.split("|") if c.strip()]
    if len(cols) < 5:
        continue
    try:
        edges = int(cols[4])
    except ValueError:
        continue
    if edges >= 10:
        weight = 0.95
    elif edges >= 5:
        weight = round(0.7 + (edges - 5) * 0.04, 2)
    elif edges >= 2:
        weight = round(0.4 + (edges - 2) * 0.1, 2)
    else:
        weight = 0.2
    print(json.dumps({
        "repo": repo,
        "fromCluster": cols[0],
        "fromLabel": cols[1],
        "toCluster": cols[2],
        "toLabel": cols[3],
        "crossEdges": edges,
        "weight": weight,
        "ts": ts
    }))
PYEOF

while IFS= read -r repo; do
  [[ -z "$repo" ]] && continue
  RESULT=$("$GITNEXUS_BIN" cypher --repo "$repo" "$QUERY" 2>&1) || true
  if [[ -z "$RESULT" ]]; then
    continue
  fi
  echo "$RESULT" | python3 "$PYSCRIPT" "$repo" "$TS" >> "$TMP" 2>/dev/null || true
done <<< "$REPOS"

rm -f "$PYSCRIPT"

if [[ -s "$TMP" ]]; then
  mv "$TMP" "$OUTPUT_FILE"
  echo "Updated $OUTPUT_FILE" >> "$LOG"
else
  rm -f "$TMP"
  echo "No data generated" >> "$LOG"
fi

cat "$LOG"
