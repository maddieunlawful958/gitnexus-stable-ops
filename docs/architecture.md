# Architecture

## Goal

GitNexus の運用を「CLI / MCP / cron / docs」で同じ前提に揃えること。

## Design Principles

- pinned binary を使う
- shell script は fail fast
- embeddings を壊さない
- dirty worktree を勝手に触らない
- `impact` 障害時も診断フローを止めない

## Components

### `bin/gni`

- 読みやすい CLI wrapper
- `cypher` の stderr JSON を整形
- `impact` の代替ビューを提供

### `bin/gitnexus-safe-impact.sh`

- `impact` が正常ならその JSON を返す
- 失敗時は `context` ベースの fallback JSON を返す

### `bin/gitnexus-doctor.sh`

- stable wrapper と global binary の差分確認
- `.gitnexus/lbug` の存在確認
- MCP config の参照先確認

### `bin/gitnexus-smoke-test.sh`

- CI 的な最小健全性チェック
- 1 repo に対する end-to-end 疎通確認

### `bin/gitnexus-auto-reindex.sh`

- 単一 repo の stale 判定付き reindex
- `meta.json` と `HEAD` の差分で判断

### `bin/gitnexus-reindex-all.sh`

- registry ベースの全 repo 再解析
- dirty skip と embeddings 保護が既定

### `bin/gitnexus-reindex.sh`

- `REPOS_DIR` 配下から最近更新 repo を探索
- cron 向け

### `bin/graph-meta-update.sh`

- cross-community edge を JSONL に集計
- graph master 系の可視化入力を作る

## Data Flow

1. `gitnexus-stable` が repo を index
2. scripts が `.gitnexus/meta.json` を見て embeddings の有無を判断
3. diagnostics は `status/context/impact/cypher` を呼ぶ
4. graph meta は `list` と `cypher` の結果を JSONL に変換する

## Non Goals

- GitNexus 本体の parser 修正
- MCP server 自体の実装
- GUI の提供
