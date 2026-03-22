# 🔧 gitnexus-stable-ops

[English](./README.md) | [中文](./README_zh.md) | [日本語](./README_ja.md)

![CI](https://github.com/ShunsukeHayashi/gitnexus-stable-ops/actions/workflows/ci.yml/badge.svg)
![Stars](https://img.shields.io/github/stars/ShunsukeHayashi/gitnexus-stable-ops?style=for-the-badge&color=yellow)
![License](https://img.shields.io/github/license/ShunsukeHayashi/gitnexus-stable-ops?style=for-the-badge)
![Last Commit](https://img.shields.io/github/last-commit/ShunsukeHayashi/gitnexus-stable-ops?style=for-the-badge)
[![Featured in GitNexus Community Integrations](https://img.shields.io/badge/GitNexus-Community%20Integration-blue?style=for-the-badge&logo=github)](https://github.com/abhigyanpatwari/GitNexus#community-integrations)

**Production-grade operational toolkit for running [GitNexus](https://github.com/abhigyanpatwari/GitNexus) at scale — safely, reliably, and autonomously.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub Stars](https://img.shields.io/github/stars/ShunsukeHayashi/gitnexus-stable-ops?style=social)](https://github.com/ShunsukeHayashi/gitnexus-stable-ops)
[![GitHub Issues](https://img.shields.io/github/issues/ShunsukeHayashi/gitnexus-stable-ops)](https://github.com/ShunsukeHayashi/gitnexus-stable-ops/issues)

Built by [合同会社みやび (LLC Miyabi)](https://miyabi-ai.jp) — Running 26 repositories indexed with GitNexus in production, daily.

> **⚠️ License Notice**: This repository is licensed under **MIT** and covers only the wrapper scripts, tooling, and documentation. **[GitNexus](https://github.com/abhigyanpatwari/GitNexus) itself is licensed under [PolyForm NonCommercial 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/).** This toolkit calls the GitNexus CLI but does not include or redistribute any GitNexus source code.

---

## Why This Exists

GitNexus is the most powerful open-source code intelligence engine available today (⭐18,700+). But running it in **production** — across dozens of repositories, with automated reindexing, inside AI agent workflows — exposes four critical operational problems:

| Problem | Impact | This toolkit's fix |
|---------|--------|-------------------|
| **Version drift** | CLI and MCP reference different GitNexus versions, causing data corruption | Pinned binary (`$GITNEXUS_BIN`) used by all scripts |
| **Embedding loss** | `analyze --force` without `--embeddings` silently deletes embeddings | Auto-detect existing embeddings, add flag automatically |
| **Dirty worktree** | Reindexing uncommitted work pollutes the code graph | Skip dirty repos by default (`ALLOW_DIRTY_REINDEX=0`) |
| **Impact instability** | `impact` command crashes on arm64 macOS with concurrent queries | Graceful fallback to context-based analysis |

**We discovered and solved these problems running GitNexus on 26 repos for 3+ months.**

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Your Repositories                         │
│   repo-1/  repo-2/  repo-3/  ...  repo-26/                     │
└─────────┬───────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────┐
│              gitnexus-stable-ops  (this toolkit)                 │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │  gni (CLI)   │  │   doctor.sh  │  │  auto-reindex.sh     │  │
│  │  Readable    │  │  Version     │  │  Stale detection     │  │
│  │  output +    │  │  drift +     │  │  Embedding protect   │  │
│  │  fallbacks   │  │  health      │  │  Dirty skip          │  │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘  │
│         │                 │                      │               │
│  ┌──────┴─────────────────┴──────────────────────┴───────────┐  │
│  │                  Pinned GitNexus Binary                    │  │
│  │              (~/.local/bin/gitnexus-stable)                │  │
│  └──────────────────────────┬────────────────────────────────┘  │
└─────────────────────────────┼───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ~/.gitnexus/                                   │
│   registry.json  ─  lbug/ databases  ─  meta.json per repo     │
│   43,000+ symbols  │  100,000+ edges  │  133 execution flows    │
└─────────────────────────────────────────────────────────────────┘
```

---

## Integration with AI Agent Systems

This toolkit was designed to work with **autonomous AI agent swarms** — systems where multiple agents collaborate on code changes across repositories.

### How agents use gitnexus-stable-ops

```
Agent receives task: "Fix auth bug in service-api"
    │
    ├─ 1. gni context AuthService     → Get callers, callees, dependencies
    ├─ 2. gni impact AuthService      → What breaks if we change it?
    ├─ 3. gni cypher "MATCH..."       → Custom graph queries
    ├─ 4. Agent writes code fix
    └─ 5. auto-reindex.sh             → Graph stays current (post-commit hook)
```

### OpenClaw Multi-Agent System example

We run gitnexus-stable-ops with [OpenClaw](https://github.com/openclaw/openclaw), where 38 agents coordinate across 26 repositories:

```yaml
# Agent workflow: "Fix Issue #123"
steps:
  - agent: dev-architect
    action: gni impact TargetClass --direction upstream
    purpose: Blast radius analysis before code change

  - agent: dev-coder
    action: gni context TargetClass
    purpose: Understand dependencies before writing fix

  - agent: guardian
    action: gitnexus-doctor.sh ~/dev/repo project TargetClass
    purpose: Post-change health verification

  - trigger: post-commit hook
    action: gitnexus-auto-reindex.sh
    purpose: Graph stays current for next agent
```

**Key insight**: When agents share a code knowledge graph, they make better decisions. `gni impact` prevents agents from breaking callers they don't know about.

---

## Production Deployment

### Docker (recommended for teams)

```dockerfile
FROM node:22-slim

# Install GitNexus
RUN npm install -g gitnexus@1.4.6

# Install stable-ops
RUN git clone https://github.com/ShunsukeHayashi/gitnexus-stable-ops.git /opt/stable-ops \
    && cd /opt/stable-ops && make install

# Pin the binary
RUN ln -sf $(which gitnexus) /usr/local/bin/gitnexus-stable

ENV GITNEXUS_BIN=/usr/local/bin/gitnexus-stable
ENV REPOS_DIR=/repos

# Daily reindex
COPY crontab /etc/cron.d/gitnexus
CMD ["cron", "-f"]
```

```bash
# docker-compose.yml
services:
  gitnexus:
    build: .
    volumes:
      - ./repos:/repos:ro
      - gitnexus-data:/root/.gitnexus
    restart: unless-stopped

volumes:
  gitnexus-data:
```

### Cron schedule (our production setup)

```cron
# Smart reindex: only repos changed in last 24h
0 3 * * *   cd /opt/stable-ops && REPOS_DIR=/repos bin/gitnexus-reindex.sh >> /var/log/gitnexus-reindex.log

# Weekly full reindex (Sunday 4 AM)
0 4 * * 0   cd /opt/stable-ops && bin/gitnexus-reindex-all.sh >> /var/log/gitnexus-full-reindex.log

# Health check (daily)
30 9 * * *  cd /opt/stable-ops && bin/gitnexus-doctor.sh /repos/main-app main-app >> /var/log/gitnexus-doctor.log
```

---

## Features

| Script | Purpose |
|--------|---------|
| `bin/gni` | Production CLI wrapper — readable output, cypher stderr capture, impact fallback |
| `bin/gitnexus-doctor.sh` | Diagnose version drift, index health, MCP config, embedding status |
| `bin/gitnexus-smoke-test.sh` | End-to-end health check (analyze → status → list → context → cypher → impact) |
| `bin/gitnexus-safe-impact.sh` | Impact analysis with automatic context-based fallback on failure |
| `bin/gitnexus-auto-reindex.sh` | Smart single-repo reindex (stale detection + embedding protection + dirty skip) |
| `bin/gitnexus-reindex.sh` | Batch reindex recently changed repos (cron-friendly) |
| `bin/gitnexus-reindex-all.sh` | Reindex all registered repos with safety defaults |
| `bin/graph-meta-update.sh` | Generate cross-community edge JSONL for graph visualization |
| `bin/gitnexus-install-hooks.sh` | Install git hooks for auto-reindex on commit/merge |

---

## Edge Cases & Lessons Learned

After 3 months of production use, here are the edge cases we've encountered and solved:

### 1. KuzuDB concurrent query segfault (arm64 macOS)

**Problem**: Running multiple `impact` queries simultaneously crashes the process with SIGSEGV.

**Root cause**: KuzuDB connections are not thread-safe. Node.js async event loop interleaves queries.

**Our fix**: `gitnexus-safe-impact.sh` catches the crash and returns context-based fallback JSON. Upstream PR [#425](https://github.com/abhigyanpatwari/GitNexus/pull/425) adds retry with exponential backoff.

### 2. Embedding silent deletion

**Problem**: `gitnexus analyze --force` rebuilds the index but drops embeddings if `--embeddings` is not explicitly passed.

**Our fix**: `gitnexus-auto-reindex.sh` checks `meta.json` for existing embedding data. If found, `--embeddings` is added automatically. **Zero embedding loss since deployment.**

### 3. Version drift between CLI and MCP

**Problem**: Global `npx gitnexus` might resolve to a different version than the MCP server's bundled CLI. KuzuDB → LadybugDB migration caused data format incompatibility.

**Our fix**: All scripts use `$GITNEXUS_BIN` which points to a pinned installation. `gitnexus-doctor.sh` detects version mismatches.

### 4. Dirty worktree graph pollution

**Problem**: Reindexing while you have uncommitted changes includes WIP code in the knowledge graph. Agents then see incomplete implementations.

**Our fix**: `gitnexus-auto-reindex.sh` skips dirty repos by default. Override with `ALLOW_DIRTY_REINDEX=1` when needed.

### 5. Large monorepo heap exhaustion

**Problem**: Repos with 100K+ files exhaust the default Node.js heap.

**Our fix**: Scripts inherit `NODE_OPTIONS="--max-old-space-size=8192"` when set. The auto-reindex detects failure and logs a clear error message.

---

## Quick Start

```bash
# Install
git clone https://github.com/ShunsukeHayashi/gitnexus-stable-ops.git
cd gitnexus-stable-ops
make install

# Run tests
make test

# Diagnose a repo
bin/gitnexus-doctor.sh ~/dev/my-repo my-repo MyClassName

# Smart reindex (skips if up-to-date)
REPO_PATH=~/dev/my-repo bin/gitnexus-auto-reindex.sh

# Batch reindex repos changed in last 24h
REPOS_DIR=~/dev bin/gitnexus-reindex.sh

# Install git hooks (auto-reindex on commit)
make install-hooks REPO=~/dev/my-repo
```

---

## Safety Defaults

| Feature | Default | Override |
|---------|---------|----------|
| Embedding protection | Auto-detect and preserve | Always on |
| Dirty worktree skip | Skip dirty repos | `ALLOW_DIRTY_REINDEX=1` |
| Impact fallback | Context-based JSON on failure | Always on |
| Version pinning | `$GITNEXUS_BIN` | Set env var |

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `GITNEXUS_BIN` | `~/.local/bin/gitnexus-stable` | Pinned GitNexus CLI path |
| `REGISTRY_PATH` | `~/.gitnexus/registry.json` | Indexed repo registry |
| `ALLOW_DIRTY_REINDEX` | `0` | Allow reindexing dirty worktrees |
| `REPOS_DIR` | `~/dev` | Root directory for batch reindex |
| `LOOKBACK_HOURS` | `24` | How far back to check for changes |

---

## Production Stats

Running in production at [合同会社みやび (LLC Miyabi)](https://miyabi-ai.jp):

| Metric | Value |
|--------|-------|
| Repositories indexed | **26** |
| Symbols in graph | **43,000+** |
| Relationships tracked | **100,000+** |
| Execution flows detected | **133** |
| Daily automated reindex | ✅ via cron |
| Embedding loss incidents | **0** (since deployment) |
| Uptime | **3+ months** |
| AI agents using the graph | **38** (via OpenClaw) |

---

## Compatibility

| Platform | Status |
|----------|--------|
| macOS (Apple Silicon) | ✅ Primary development platform |
| Linux (Ubuntu, Debian, Fedora) | ✅ Tested |
| Docker | ✅ See Docker section above |
| Windows | ⚠️ Use WSL or Git Bash |

Requires: Bash 4.0+ · Git 2.0+ · jq 1.6+ · Python 3.6+ · Node.js 20+

---

## Documentation

- [Runbook](docs/runbook.md) — Step-by-step operational procedures
- [Architecture](docs/architecture.md) — Design principles and data flow
- [MCP Integration](docs/mcp-integration.md) — MCP server configuration

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md).

All contributions must:
- Include tests for new functionality
- Follow [Conventional Commits](https://www.conventionalcommits.org/)
- Pass `make test`

---

## License

MIT — See [LICENSE](LICENSE).

**Note**: The MIT license applies only to this toolkit. [GitNexus](https://github.com/abhigyanpatwari/GitNexus) is licensed under [PolyForm NonCommercial 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/).

---

## Built by

**[合同会社みやび (LLC Miyabi)](https://miyabi-ai.jp)**

🐦 [@The_AGI_WAY](https://x.com/The_AGI_WAY) · 📧 shunsuke.hayashi@miyabi-ai.jp

<sub>Active contributor to [GitNexus](https://github.com/abhigyanpatwari/GitNexus) — 22 PRs submitted, 8 merged, 11 issues filed.</sub>
