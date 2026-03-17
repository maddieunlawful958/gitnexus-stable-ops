# Runbook

## Source Of Truth

- CLI: `~/.local/bin/gitnexus-stable`
- MCP launcher: `~/.local/bin/gitnexus-mcp-stable`
- Backend: LadybugDB
- Index path: `.gitnexus/lbug`

## 1. Diagnose One Repository

```bash
bin/gitnexus-doctor.sh /path/to/repo REPO_NAME SYMBOL_NAME
```

確認する点:

- stable wrapper が実行できる
- global `gitnexus` と version drift が分かる
- `.gitnexus/lbug` がある
- `status`, `list`, `context`, `safe-impact` が通る

## 2. Verify Before Large Changes

```bash
bin/gitnexus-smoke-test.sh /path/to/repo REPO_NAME SYMBOL_NAME
```

この script は次を確認します。

- `analyze`
- `status`
- `list`
- `context`
- `cypher`
- `impact` または safe fallback

## 3. Safe Impact

```bash
bin/gitnexus-safe-impact.sh REPO_NAME SYMBOL_NAME
```

`impact` が壊れても、`context` の incoming/outgoing refs を JSON で要約して返します。

## 4. Reindex One Repository

```bash
REPO_PATH=/path/to/repo bin/gitnexus-auto-reindex.sh
```

特徴:

- `meta.json.lastCommit` と `HEAD` を比較
- stale のときだけ再解析
- embeddings を自動保護

## 5. Reindex All Indexed Repositories

```bash
bin/gitnexus-reindex-all.sh
```

既定の挙動:

- registry に載っている repo だけ対象
- dirty worktree は skip
- embeddings がある repo は `--embeddings`

dirty repo も含める場合:

```bash
ALLOW_DIRTY_REINDEX=1 bin/gitnexus-reindex-all.sh
```

## 6. Reindex Recently Changed Repositories

```bash
REPOS_DIR=~/dev LOOKBACK_HOURS=24 bin/gitnexus-reindex.sh
```

用途:

- cron で毎日流す
- 直近更新のあった repo だけ再解析する

## 7. Graph Meta Generation

```bash
OUTPUT_DIR=./out bin/graph-meta-update.sh
```

出力:

- `graph-meta.jsonl`
- コミュニティ間の cross edge 集計

## Troubleshooting

### `impact` が落ちる

- `bin/gitnexus-safe-impact.sh` を使う
- 必要なら `gni cypher` で手動クエリへ切り替える

### `Index is stale`

- `~/.local/bin/gitnexus-stable analyze`
- embeddings ありなら `~/.local/bin/gitnexus-stable analyze --embeddings`

### CLI と MCP で結果が違う

- `gitnexus-doctor.sh` を実行
- global `gitnexus` と `gitnexus-stable` の version drift を確認

### dirty worktree で reindex したい

- 本当に必要なときだけ `ALLOW_DIRTY_REINDEX=1`
