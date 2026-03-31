# Feishu-MCP v2 — 飞书全能集成套件

## What This Project Is

**feishu-mcp 是飞书全能集成套件（Meta-Skill Package）**— 让飞书 CLI 和社区 MCP 作为一个统一系统工作的集成层。

它不是 MCP 服务器，不是 CLI 替代品，不是运行时组件。它是：
1. **一条命令安装脚本** — 安装 + 配置 CLI + 社区 MCP + OpenClaw 检测
2. **决策矩阵 Skill** (`SKILL.md`) — 告诉 AI agent 每个任务该用哪个工具
3. **Agent 文档** — 让 AI 助手自助完成安装、诊断、错误恢复
4. **用户引导文档** — 零技术背景用户的中文指南
5. **平台配置模板** — OpenClaw / Claude Code / Cursor 预配置
6. **工作流 Skill** — 展示 CLI + MCP 协同能力 + 中文友好化包装

## Harness Methodology

This project uses a **Planner → Builder → QA** harness for ALL development (full process).

### Agent Roles
- **@planner**: Expands goals into specs with acceptance criteria. Writes WHAT, never HOW.
- **@builder**: Implements features according to specs. Follows existing patterns.
- **@qa**: Independently verifies output. Scores 5 dimensions, any < 6 = FAIL.
- **@coordinator**: Routes requests to the right agent based on change size.

### Communication
Agents communicate through files in `.harness/`:
- `spec.md` — Overall transformation plan (ground truth)
- `contracts/{unit}.md` — Per-unit specs (Planner output)
- `reports/build_{unit}_r{N}.md` — Builder reports
- `reports/qa_{unit}_r{N}.md` — QA reports
- `progress.tsv` — Iteration history
- `experience/` — Accumulated patterns and lessons

### Workflow
```
Plan → Build → QA ─── PASS → git commit → next unit
                    └─ FAIL → same failure?
                               ├─ NO → fix → re-verify
                               └─ YES → replan
```

## Architecture: Two-Layer (CLI + Community MCP)

```
User <-> OpenClaw/Claude Code/Cursor <-> feishu-mcp 集成层
                                              |
                                    +---------+---------+
                                    |                   |
                              Feishu CLI          Community MCP
                              (@larksuite/cli)    (feishu-mcp)
                              200+ commands       15 doc editing tools
                              19 AI skills        Block-level precision
                              11 business domains
```

**Key Principle: CLI for breadth, Community MCP for depth.**

### Why Two Layers (Not Three)

CLI 已覆盖官方 MCP 的大部分能力。官方 MCP（Beta）作为高级可选项，不在默认安装中。

### CLI vs Community MCP: Complementary Capabilities

| Capability | Feishu CLI | Community MCP | Who Wins |
|-----------|-----------|---------------|----------|
| Batch block creation | ⚠️ Partial (Markdown) | ✅ `batch_create` | **MCP unique advantage** |
| Text formatting (color/align) | ✅ (Markdown syntax) | ✅ (8-color, alignment) | **MCP more precise** |
| Mermaid diagrams | ✅ (whiteboard skill) | ❌ (planned) | **CLI unique advantage** |
| Advanced charts/DSL | ✅ (DSL path) | ❌ (planned) | **CLI unique advantage** |
| Whiteboard editing | ✅ (create+edit) | ⚠️ (read-only) | **CLI unique advantage** |
| Image upload | ✅ | ✅ | CLI more robust |
| Block editing | ✅ (selection) | ✅ (direct API) | MCP more granular |
| Block deletion | ✅ | ✅ | Equal |
| Messaging/Calendar/Mail/Tasks/Contacts/Meetings/Wiki/Sheets/Base | ✅ | ❌ | **CLI only** |

### Decision Matrix: CLI vs MCP

| Task | Use | Reason |
|------|-----|--------|
| Send message | CLI (`lark-cli im +send`) | Full control, attachments |
| Calendar ops | CLI (`lark-cli calendar +agenda`) | Complete API coverage |
| Create document | CLI (`lark-cli doc +create`) | Markdown input, simpler |
| Edit doc blocks precisely | Community MCP (`update_feishu_block_text`) | Granular block control |
| Batch create blocks | Community MCP (`batch_create_feishu_blocks`) | Atomic batch operation |
| Text color/alignment | Community MCP (style properties) | 8-color palette, explicit align |
| Insert Mermaid diagram | CLI (`lark-cli whiteboard`) | Community MCP doesn't support yet |
| Insert charts | CLI (whiteboard DSL) | Community MCP doesn't support yet |
| Whiteboard create/edit | CLI (`lark-cli docs +whiteboard-update`) | MCP is read-only |
| Upload image to doc | CLI (`lark-cli docs +media-insert`) or MCP | Both work, CLI more robust |
| Query bitable | CLI (`lark-cli base +query`) | CLI simpler |
| Search docs | CLI (`lark-cli doc +search`) | Official, more reliable |
| Send mail | CLI (`lark-cli mail +compose`) | Only option |
| Manage tasks | CLI (`lark-cli task +list`) | Only option |
| Wiki operations | CLI (`lark-cli wiki`) | Only option |
| Contacts | CLI (`lark-cli contact`) | Only option |
| Meetings/Minutes | CLI (`lark-cli vc`, `lark-cli minutes`) | Only option |

## Conventions

### Languages
- **User-facing content**: Chinese (primary), English section headers
- **Agent-facing docs**: English (primary), Chinese examples where helpful
- **Code comments**: English
- **Commit messages**: English

### File Structure
```
feishu-mcp/
  setup.sh              ← Legacy setup (v1, kept for compatibility)
  setup-v2.sh           ← New smart setup script
  README.md             ← User-facing intro + quick start
  GUIDE.md              ← Step-by-step visual guide for non-technical users
  SKILL.md              ← Decision matrix (CLI + MCP routing)
  AGENTS.md             ← Master reference for AI agents
  QUICKSTART-AGENT.md   ← Agent setup automation guide
  TROUBLESHOOT-AGENT.md ← Agent error recovery guide
  CLAUDE.md             ← This file (project context + harness rules)
  configs/
    openclaw.json       ← OpenClaw config template
    claude-code.json    ← Claude Code config template
    cursor.json         ← Cursor config template
  skills/
    feishu-overview.md  ← Overview: Chinese index of all 19 CLI skills + MCP tools
    doc-review.md       ← Workflow: read blocks (MCP) → create tasks (CLI) → send summary (CLI)
    data-to-doc.md      ← Workflow: query bitable (CLI) → generate formatted doc (MCP)
    knowledge-sync.md   ← Workflow: read Wiki (CLI) → update doc content (MCP)
    meeting-summary-plus.md ← Enhanced: CLI built-in + MCP formatted doc output
  .claude/
    agents/
      planner.md
      builder.md
      qa.md
      coordinator.md
    settings.json
  .harness/
    spec.md
    progress.tsv
    contracts/
    reports/
    experience/
```

### Naming
- Shell scripts: `kebab-case.sh`
- Top-level docs: `UPPER-CASE.md`
- Subdirectory docs: `kebab-case.md`
- Config files: `{tool-name}.json`

### Shell Script Standards
- Shebang: `#!/usr/bin/env bash`
- `set -euo pipefail` at top
- All user prompts in Chinese
- Error messages suggest fix action
- No `sudo` required
- No hardcoded paths (use `$HOME`, `$XDG_CONFIG_HOME`)
- Idempotent (safe to re-run)

### Documentation Standards
- Agent docs: imperative voice ("Do X", "Check Y", "If Z then W")
- User docs: conversational, zero jargon, step-by-step
- Every doc has a clear audience header
- No placeholder values in published docs — use descriptive comments

## Quality Dimensions

QA scores 5 dimensions (1-10 each). Any < 6 = FAIL:
1. **User Experience** (30%) — minimal steps, no config editing, clear errors
2. **Agent Operability** (25%) — unambiguous tool selection, automated recovery
3. **Completeness** (20%) — all Feishu capabilities accessible
4. **Error Handling** (15%) — common errors have recovery paths
5. **Documentation Clarity** (10%) — non-technical user can follow

## Key Dependencies

### Required (default install)
- Node.js >= 16
- npm
- `@larksuite/cli` >= 1.0.0 (official Feishu CLI)
- `feishu-mcp` (community MCP for document editing)
- `mcporter` (MCP port multiplexer)
- Feishu Open Platform app (user creates at open.feishu.cn)

### Optional
- `@larksuiteoapi/lark-mcp` (official MCP, advanced users only)
- `@larksuiteoapi/feishu-openclaw-plugin` (OpenClaw channel plugin)

## Auth Flow Summary

1. User creates app at open.feishu.cn → gets App ID + App Secret
2. Setup script configures redirect URL (http://localhost:3000/callback for CLI, http://localhost:3333/callback for community MCP)
3. `lark-cli auth login --recommend` opens browser for OAuth
4. User approves permissions → token stored in OS keychain (CLI) and env vars (MCP)
5. Token refresh: CLI handles automatically, community MCP may need manual refresh
