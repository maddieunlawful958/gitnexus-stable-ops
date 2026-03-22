# Architecture

## Goal

Ensure all GitNexus operations (CLI, MCP, cron, agent workflows) share the same stable binary, safety defaults, and data assumptions.

## Design Principles

1. **Pinned binary** — All scripts use `$GITNEXUS_BIN`, never `npx gitnexus`
2. **Fail fast** — Shell scripts exit on first error (`set -euo pipefail`)
3. **Embedding preservation** — Never run `--force` without checking for existing embeddings
4. **Dirty worktree safety** — Never index uncommitted changes by default
5. **Graceful degradation** — When `impact` crashes, return fallback JSON instead of failing

## Data Flow

```
Repository (git repo)
    │
    ▼  gitnexus analyze
┌──────────────────────────┐
│    ~/.gitnexus/lbug/     │  LadybugDB knowledge graph
│    ├─ nodes (symbols)    │  43,000+ symbols across 26 repos
│    ├─ edges (relations)  │  100,000+ CALLS/IMPORTS/EXTENDS edges
│    ├─ processes          │  133 execution flows
│    └─ embeddings (opt)   │  Semantic vectors for BM25+vector search
└──────────┬───────────────┘
           │
    ┌──────┴──────────────────────────┐
    │                                  │
    ▼                                  ▼
┌──────────────┐              ┌──────────────────┐
│  gni (CLI)   │              │  MCP Server       │
│  Human-      │              │  Agent-facing      │
│  readable    │              │  JSON-RPC          │
│  output      │              │  over stdio/HTTP   │
└──────────────┘              └──────────────────┘
```

## Component Responsibilities

### `bin/gni` — CLI Wrapper
- Captures cypher stderr JSON (GitNexus sends results to stderr)
- Provides readable formatted output for human consumption
- Falls back to context when impact fails

### `bin/gitnexus-doctor.sh` — Health Diagnosis
- Compares pinned binary version vs global installation
- Checks `.gitnexus/lbug/` database integrity
- Validates MCP config points to correct binary
- Reports embedding status per repository

### `bin/gitnexus-auto-reindex.sh` — Smart Reindex
- Reads `meta.json` last-indexed commit hash
- Compares with current `git rev-parse HEAD`
- Skips if index is current (idempotent)
- Auto-adds `--embeddings` when existing embeddings detected
- Skips dirty worktrees (configurable)

### `bin/gitnexus-reindex.sh` — Batch Reindex
- Scans `$REPOS_DIR` for repos modified in last `$LOOKBACK_HOURS`
- Calls `gitnexus-auto-reindex.sh` for each eligible repo
- Designed for cron: low noise, clear logging

### `bin/gitnexus-safe-impact.sh` — Resilient Impact Analysis
- Runs `gitnexus impact` with timeout
- On SIGSEGV/timeout: queries `gitnexus context` as fallback
- Returns structured JSON regardless of outcome
- Critical for AI agent workflows that cannot tolerate failures

### `bin/graph-meta-update.sh` — Cross-Community Edges
- Queries each repo for community structure
- Generates JSONL of cross-community relationships
- Input for graph visualization tools

## Safety Mechanisms

| Mechanism | Protected Against | Implementation |
|-----------|-------------------|----------------|
| Version pinning | Data format incompatibility | `$GITNEXUS_BIN` env var |
| Embedding detection | Silent embedding loss | `meta.json` check in auto-reindex |
| Dirty skip | Graph pollution | `git status --porcelain` check |
| Impact fallback | arm64 SIGSEGV crash | Try/catch with context fallback |
| Stale detection | Unnecessary reindex cycles | HEAD hash comparison |

## Integration Points

### With CI/CD
```bash
# In GitHub Actions
- run: bin/gitnexus-doctor.sh . my-repo ClassName
```

### With AI Agents (OpenClaw)
```bash
# Agent queries the graph
gni impact AuthService --direction upstream
gni context AuthService
gni cypher "MATCH (n)-[r:CALLS]->(m) WHERE n.name = 'AuthService' RETURN m"
```

### With Cron
```cron
0 3 * * *  REPOS_DIR=~/dev bin/gitnexus-reindex.sh
```

## Non-Goals

- Modifying GitNexus core parser or ingestion pipeline
- Implementing an MCP server (GitNexus provides this)
- Building a GUI
- Replacing GitNexus CLI — this toolkit wraps it
