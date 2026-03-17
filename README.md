# gitnexus-stable-ops

GitNexus を `gitnexus-stable` で固定運用するための Bash ベースの運用ツール集。

この project は次の問題を避けるために作られています。

- CLI と MCP が別バージョンの GitNexus を参照して壊れる
- `analyze` 実行時に embeddings を誤って消す
- dirty worktree に対して無差別に reindex してローカル差分を汚す
- `impact` が不安定なときに調査フローが止まる

## Features

- `bin/gni`: GitNexus CLI wrapper
- `bin/gitnexus-safe-impact.sh`: `impact` 失敗時の `context` フォールバック
- `bin/gitnexus-doctor.sh`: stable wrapper / MCP / index backend の診断
- `bin/gitnexus-smoke-test.sh`: `analyze/status/list/context/cypher/impact` の疎通確認
- `bin/gitnexus-reindex-all.sh`: registry 配下の全 repo を安全に再解析
- `bin/gitnexus-auto-reindex.sh`: 単一 repo の stale 判定付き再解析
- `bin/gitnexus-reindex.sh`: 最近更新された複数 repo の再解析
- `bin/graph-meta-update.sh`: コミュニティ間エッジの集計 JSONL 生成

## Requirements

- `bash`
- `git`
- `jq`
- `python3`
- `gitnexus-stable` が存在すること

デフォルトの CLI は `~/.local/bin/gitnexus-stable` を参照します。

## Quick Start

```bash
git clone git@github.com:ShunsukeHayashi/gitnexus-stable-ops.git
cd gitnexus-stable-ops

bin/gitnexus-doctor.sh /path/to/repo REPO_NAME SYMBOL_NAME
bin/gitnexus-smoke-test.sh /path/to/repo REPO_NAME SYMBOL_NAME
```

## Core Commands

```bash
# 1 repo の診断
bin/gitnexus-doctor.sh ~/dev/my-repo my-repo targetSymbol

# impact が落ちても止めない
bin/gitnexus-safe-impact.sh my-repo targetSymbol

# stale repo を自動判定して再解析
REPO_PATH=~/dev/my-repo bin/gitnexus-auto-reindex.sh

# registry 上の全 repo を再解析
bin/gitnexus-reindex-all.sh

# 最近 24h で更新のあった repo だけ再解析
REPOS_DIR=~/dev bin/gitnexus-reindex.sh
```

## Environment Variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `GITNEXUS_BIN` | `~/.local/bin/gitnexus-stable` | Canonical GitNexus CLI |
| `REGISTRY_PATH` | `~/.gitnexus/registry.json` | Indexed repo registry |
| `ALLOW_DIRTY_REINDEX` | `0` | dirty worktree を再解析するか |
| `FORCE_REINDEX` | `1` | smoke test で `analyze --force` するか |
| `REPO_PATH` | `$PWD` | 単一 repo reindex 対象 |
| `REPOS_DIR` | `~/dev` | バッチ reindex の探索ルート |
| `OUTPUT_DIR` | `./out` | graph meta 出力先 |

## Safety Defaults

- embeddings が既にある repo は `--embeddings` を自動付与
- dirty worktree は既定で skip
- `impact` 失敗時は `context` から direct dependency を要約
- `graph-meta-update.sh` は stable wrapper が無ければ fail fast

## Documentation

- [Runbook](docs/runbook.md)
- [Architecture](docs/architecture.md)

## License

MIT
