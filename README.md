# 🔧 gitnexus-stable-ops

[English](./README.md) | [中文](./README_zh.md) | [日本語](./README_ja.md)

[![CI](https://github.com/ShunsukeHayashi/gitnexus-stable-ops/actions/workflows/ci.yml/badge.svg)](https://github.com/ShunsukeHayashi/gitnexus-stable-ops/actions)
[![Stars](https://img.shields.io/github/stars/ShunsukeHayashi/gitnexus-stable-ops?style=for-the-badge&color=yellow)](https://github.com/ShunsukeHayashi/gitnexus-stable-ops/stargazers)
[![License](https://img.shields.io/github/license/ShunsukeHayashi/gitnexus-stable-ops?style=for-the-badge)](LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/ShunsukeHayashi/gitnexus-stable-ops?style=for-the-badge)](https://github.com/ShunsukeHayashi/gitnexus-stable-ops/commits/main)
[![Featured in GitNexus Community Integrations](https://img.shields.io/badge/GitNexus-Community%20Integration-blue?style=for-the-badge&logo=github)](https://github.com/abhigyanpatwari/GitNexus)

**Production-grade operational toolkit for running [GitNexus](https://github.com/abhigyanpatwari/GitNexus) at scale — purpose-built for autonomous AI agent swarms.**

> *"designed for autonomous agent swarms"* — [@d3thshot7777](https://github.com/abhigyanpatwari/GitNexus), GitNexus maintainer

Built by [Miyabi G.K. (合同会社みやび)](https://miyabi-ai.jp) — powering a 40-agent autonomous development system across 25+ repositories in production.

---

## 🏭 Production at Scale

| Metric | Value |
|--------|-------|
| **Repositories indexed** | 25+ |
| **Symbols in knowledge graph** | 32,000+ |
| **Edges (relationships)** | 73,000+ |
| **AI agents using this toolkit** | 40 (OpenClaw MAS) |
| **Uptime** | Daily automated reindex, zero embedding loss |
| **CI integration** | Git hooks + cron on every commit/merge |

---

## 🤖 Built for Autonomous Agent Swarms

Modern AI development pipelines rely on **fleets of agents** that must understand codebases, trace dependencies, and safely refactor code — autonomously, at scale.

This toolkit turns [GitNexus](https://github.com/abhigyanpatwari/GitNexus) into a **reliable, always-on code intelligence backend** for those agents.

```
┌──────────────────────────────────────────────────────────────┐
│              Autonomous Agent Layer (OpenClaw MAS)           │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐   │
│  │ dev-arch │ │dev-coder │ │dev-review│ │ sns-strategist│   │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └──────┬───────┘   │
│       └────────────┴────────────┴───────────────┘            │
│                            │                                  │
│                     MCP Protocol                              │
│                            │                                  │
├────────────────────────────▼─────────────────────────────────┤
│              gitnexus-stable-ops (This Toolkit)              │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  Safe Reindex │ Impact Analysis │ Doctor │ Smoke Test │    │
│  │  Git Hooks    │ Batch Cron      │ gni CLI│ Graph Meta │    │
│  └──────────────────────────────────────────────────────┘    │
├────────────────────────────┬─────────────────────────────────┤
│         GitNexus Core      │  KuzuDB Knowledge Graph         │
│   (code intelligence)      │  32K+ symbols · 73K+ edges      │
└────────────────────────────┴─────────────────────────────────┘
```

---

## 💡 Why This Exists

GitNexus is powerful, but running it in production across many repos creates critical operational challenges:

| Problem | Impact | This Toolkit |
|---------|--------|-------------|
| **Version drift** | CLI ↔ MCP use different GitNexus versions → KuzuDB corruption | Pinned `$GITNEXUS_BIN` across all scripts |
| **Silent embedding loss** | `analyze --force` without `--embeddings` deletes existing vectors | Auto-detects existing embeddings, adds flag automatically |
| **Dirty worktree corruption** | Reindexing uncommitted work pollutes the code graph | Stale detection + dirty skip (override: `ALLOW_DIRTY_REINDEX=1`) |
| **Impact analysis instability** | `impact` fails intermittently, blocking agent workflows | Context-based fallback in `gitnexus-safe-impact.sh` |
| **No batch management** | Managing 25+ repos manually is unsustainable | Registry-based batch reindex with cron support |

---

## 🛠 Feature Overview

| Script | Purpose |
|--------|---------|
| `bin/gni` | Enhanced CLI wrapper — readable output, impact fallback, MCP-ready |
| `bin/gitnexus-doctor.sh` | Diagnose version drift, index health, MCP config |
| `bin/gitnexus-smoke-test.sh` | End-to-end health check (analyze/status/list/context/cypher/impact) |
| `bin/gitnexus-safe-impact.sh` | Impact analysis with automatic context-based fallback |
| `bin/gitnexus-auto-reindex.sh` | Smart single-repo reindex (stale detection, embedding protection) |
| `bin/gitnexus-reindex.sh` | Batch reindex recently changed repos (cron-friendly) |
| `bin/gitnexus-reindex-all.sh` | Reindex all registered repos with safety defaults |
| `bin/graph-meta-update.sh` | Generate cross-community edge JSONL for graph visualization |
| `bin/gitnexus-install-hooks.sh` | Install git hooks for auto-reindex on commit/merge |

---

## 🏢 Enterprise Use Cases

### 1. Autonomous Code Review Pipeline
Agents use `gitnexus-safe-impact.sh` to assess blast radius before every PR — without manual intervention.
```bash
# Agent runs before approving PR
impact=$(bin/gitnexus-safe-impact.sh ~/repos/my-service my-service validateUser upstream)
# Returns JSON: { "risk": "LOW", "direct_callers": 3, "affected_processes": 1 }
```

### 2. CI/CD Safety Gate
Git hooks auto-reindex on every commit. Agents query the updated graph before deploying.
```bash
make install-hooks REPO=~/repos/my-service
# Now every `git commit` triggers background reindex — no workflow delay
```

### 3. Multi-Agent Code Intelligence (MCP)
Any MCP-compatible agent (Claude Code, Cursor, Codex) connects via GitNexus MCP server, powered by a stable, always-fresh index.
```json
{
  "mcpServers": {
    "gitnexus": {
      "command": "gitnexus",
      "args": ["serve", "--port", "4747"]
    }
  }
}
```

### 4. Large-Scale Repository Fleet Management
Manage 10–100+ repos with a single registry and daily cron.
```bash
# Daily reindex at 3 AM — all repos, embedding-safe
0 3 * * * cd /path/to/gitnexus-stable-ops && bin/gitnexus-reindex-all.sh
```

---

## 🔌 MCP / Claude Code Integration

This toolkit is designed as the **stable backend** for MCP-connected AI agents.

```bash
# Start MCP server backed by this toolkit
gitnexus serve --port 4747

# Claude Code, Cursor, or any MCP client connects automatically
# using .mcp.json or claude_desktop_config.json
```

Compatible with:
- ✅ Claude Code (Anthropic)
- ✅ Cursor
- ✅ OpenCode
- ✅ OpenClaw MAS (autonomous agent orchestration)
- ✅ Any MCP-compatible client

---


### 🪟 Windows Setup

**Option 1: WSL2 (Recommended)**
```powershell
# Install WSL2 (PowerShell as Administrator)
wsl --install

# Then in WSL terminal:
git clone https://github.com/ShunsukeHayashi/gitnexus-stable-ops.git
cd gitnexus-stable-ops && make install
```

**Option 2: Git Bash**
```bash
# Git Bash already includes bash, git, python3
# Install jq for Windows: https://jqlang.github.io/jq/download/
# Then:
git clone https://github.com/ShunsukeHayashi/gitnexus-stable-ops.git
cd gitnexus-stable-ops && make install
```

> **Note**: Native CMD/PowerShell are not supported. WSL2 provides the best experience and is recommended for production use.

## 🚀 Quick Start

### One-liner install
```bash
git clone https://github.com/ShunsukeHayashi/gitnexus-stable-ops.git
cd gitnexus-stable-ops && make install
```

### Basic usage
```bash
# Diagnose a repo
bin/gitnexus-doctor.sh ~/dev/my-repo my-repo

# Smart reindex (skips if index is current, protects embeddings)
REPO_PATH=~/dev/my-repo bin/gitnexus-auto-reindex.sh

# Batch reindex repos changed in last 24h
REPOS_DIR=~/dev bin/gitnexus-reindex.sh

# Run full health check
bin/gitnexus-smoke-test.sh ~/dev/my-repo my-repo
```

### Install CI git hooks
```bash
make install-hooks REPO=~/dev/my-repo
# Hooks run in background on every commit/merge — zero delay
```

---

## ⚙️ Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `GITNEXUS_BIN` | `~/.local/bin/gitnexus-stable` | Pinned CLI path |
| `REGISTRY_PATH` | `~/.gitnexus/registry.json` | Indexed repo registry |
| `ALLOW_DIRTY_REINDEX` | `0` | Allow reindexing dirty worktrees |
| `FORCE_REINDEX` | `1` | Force reindex in smoke tests |
| `REPOS_DIR` | `~/dev` | Root directory for batch reindex |
| `LOOKBACK_HOURS` | `24` | How far back to check for changes |
| `GITNEXUS_AUTO_REINDEX` | `1` | Set `0` to disable git hook auto-reindex |

---

## 📋 Requirements

- `bash` 4.0+, `git` 2.0+, `jq` 1.6+, `python3` 3.6+
- `gitnexus` CLI ([install guide](https://github.com/abhigyanpatwari/GitNexus))

## 🖥 Compatibility

| Platform | Status |
|----------|--------|
| macOS (Apple Silicon / x86) | ✅ Primary development platform |
| Linux (Ubuntu, Debian, Fedora) | ✅ Tested and supported |
| Windows 10/11 (WSL2) | ✅ Recommended — full feature support |
| Windows 10/11 (Git Bash) | ✅ Supported — all scripts work |
| Windows 10/11 (Native CMD/PowerShell) | ❌ Not supported |

---

## 📚 Documentation

- [Runbook](docs/runbook.md) — Step-by-step operational procedures
- [Architecture](docs/architecture.md) — Design principles and data flow

---

## 🤝 Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md).

All contributions must:
- Include tests (`make test`)
- Follow [Conventional Commits](https://www.conventionalcommits.org/)
- Pass CI

---

## ⚖️ License

MIT — See [LICENSE](LICENSE).

> **Note**: MIT applies only to wrapper scripts and tooling in this repo. [GitNexus](https://github.com/abhigyanpatwari/GitNexus) is licensed under [PolyForm NonCommercial 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/). No GitNexus source code is included here.

---

## 🏢 Built by

**[Miyabi G.K. (合同会社みやび)](https://miyabi-ai.jp)**
Running a 40-agent autonomous AI development system in production.

- 🐦 X: [@The_AGI_WAY](https://x.com/The_AGI_WAY)
- 📧 shunsuke.hayashi@miyabi-ai.jp
- 🐙 GitHub: [@ShunsukeHayashi](https://github.com/ShunsukeHayashi)

