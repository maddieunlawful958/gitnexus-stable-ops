# 🔧 gitnexus-stable-ops

**Operational toolkit for running [GitNexus](https://github.com/nicholasgasior/gitnexus) with a pinned, stable CLI/MCP workflow.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Built by [合同会社みやび (LLC Miyabi)](https://miyabi-ai.jp) — Managing 25+ repositories indexed with GitNexus in production.

---

## Problem

GitNexus is powerful, but running it in production across many repos creates operational challenges:

- 🔴 **Version drift** — CLI and MCP reference different GitNexus versions (KuzuDB vs LadybugDB), causing data corruption
- 🔴 **Embedding loss** — `analyze --force` without `--embeddings` silently deletes existing embeddings
- 🔴 **Dirty worktree corruption** — Reindexing uncommitted work pollutes the code graph
- 🔴 **Impact instability** — `impact` command fails intermittently, blocking analysis workflows

This toolkit solves all four.

## Features

| Script | Purpose |
|--------|---------|
| `bin/gni` | Improved CLI wrapper with readable output and impact fallback views |
| `bin/gitnexus-doctor.sh` | Diagnose version drift, index health, and MCP config |
| `bin/gitnexus-smoke-test.sh` | End-to-end health check (analyze/status/list/context/cypher/impact) |
| `bin/gitnexus-safe-impact.sh` | Impact analysis with automatic context-based fallback |
| `bin/gitnexus-auto-reindex.sh` | Smart single-repo reindex (stale detection, embedding protection) |
| `bin/gitnexus-reindex.sh` | Batch reindex recently changed repos (cron-friendly) |
| `bin/gitnexus-reindex-all.sh` | Reindex all registered repos with safety defaults |
| `bin/graph-meta-update.sh` | Generate cross-community edge JSONL for graph visualization |

## Requirements

- `bash`, `git`, `jq`, `python3`
- `gitnexus` CLI installed (default: `~/.local/bin/gitnexus-stable`)

## Quick Start

```bash
git clone https://github.com/ShunsukeHayashi/gitnexus-stable-ops.git
cd gitnexus-stable-ops

# Diagnose a repo
bin/gitnexus-doctor.sh ~/dev/my-repo my-repo MyClassName

# Run smoke test
bin/gitnexus-smoke-test.sh ~/dev/my-repo my-repo MyClassName

# Smart reindex (skips if index is current)
REPO_PATH=~/dev/my-repo bin/gitnexus-auto-reindex.sh

# Batch reindex repos changed in last 24h
REPOS_DIR=~/dev bin/gitnexus-reindex.sh
```

## Safety Defaults

- **Embedding protection** — Repos with existing embeddings automatically get `--embeddings` flag
- **Dirty worktree skip** — Uncommitted changes → skip reindex (override: `ALLOW_DIRTY_REINDEX=1`)
- **Impact fallback** — When `impact` fails, `gitnexus-safe-impact.sh` returns context-based JSON
- **Version pinning** — All scripts use `$GITNEXUS_BIN` (default: `~/.local/bin/gitnexus-stable`)

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `GITNEXUS_BIN` | `~/.local/bin/gitnexus-stable` | Pinned GitNexus CLI path |
| `REGISTRY_PATH` | `~/.gitnexus/registry.json` | Indexed repo registry |
| `ALLOW_DIRTY_REINDEX` | `0` | Allow reindexing dirty worktrees |
| `FORCE_REINDEX` | `1` | Force reindex in smoke tests |
| `REPOS_DIR` | `~/dev` | Root directory for batch reindex |
| `LOOKBACK_HOURS` | `24` | How far back to check for changes |
| `OUTPUT_DIR` | `./out` | Graph meta output directory |

## Use with Cron

```bash
# Daily reindex at 3 AM
0 3 * * * cd /path/to/gitnexus-stable-ops && REPOS_DIR=~/dev bin/gitnexus-reindex.sh

# Weekly full reindex
0 4 * * 1 cd /path/to/gitnexus-stable-ops && bin/gitnexus-reindex-all.sh
```

## Documentation

- [Runbook](docs/runbook.md) — Step-by-step operational procedures
- [Architecture](docs/architecture.md) — Design principles and data flow

## Production Stats

Running in production at 合同会社みやび:
- **25 repositories** indexed and monitored
- **32,000+ symbols** / **73,000+ edges** in the knowledge graph
- **Daily automated reindex** via cron
- **Zero embedding loss** since deploying this toolkit

## License

MIT — See [LICENSE](LICENSE).

## Built by

**[合同会社みやび (LLC Miyabi)](https://miyabi-ai.jp)**

- 🐦 [@The_AGI_WAY](https://x.com/The_AGI_WAY)
- 📧 shunsuke.hayashi@miyabi-ai.jp
