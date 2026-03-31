---
name: knowledge-sync
description: 知识同步工作流 — Wiki 与文档之间的双向同步：从 Wiki 读取内容更新到文档(CLI→MCP)，或从文档内容创建/更新 Wiki 节点(MCP→CLI)。
metadata:
  bins:
    - lark-cli
    - mcporter
---

# 知识同步工作流

组合 CLI 和 MCP，在飞书 Wiki 知识库和云文档之间实现双向内容同步。

---

## When to Use This Skill

- User wants to sync Wiki content to a document ("把知识库里的内容同步到文档")
- User wants to update Wiki from document content ("把文档内容更新到知识库")
- User needs to consolidate information from Wiki into a summary doc ("把几篇 Wiki 整理成一份文档")
- User needs to keep Wiki and standalone documents in sync

---

## Prerequisites

1. Confirm CLI auth: `lark-cli auth status` — must show valid token.
2. Confirm MCP auth: `FEISHU_APP_ID` and `FEISHU_APP_SECRET` env vars set.
3. Required scopes: `wiki:wiki`, `docx:document`. Verify at `https://open.feishu.cn/app/{APP_ID}/security`.
4. Determine sync direction:
   - **Direction A**: Wiki → Document (read Wiki, write to doc)
   - **Direction B**: Document → Wiki (read doc, write to Wiki)

---

## Direction A: Wiki to Document

Use this when: extracting Wiki content and writing it into a standalone document or consolidating multiple Wiki pages into one document.

### Step A1: Read Wiki Content

**Tool**: CLI `lark-cli wiki`

First, list available knowledge spaces to find the target:

```bash
lark-cli wiki +list
```

Browse the Wiki structure to locate the target node(s). Note the wiki_token(s) for the pages to sync.

To get detailed metadata about a specific node:

```
MCP tool: get_feishu_wiki_node_info
Parameters: { "token": "<wiki_token>" }
```

This returns the node's title, type, parent, and the associated document_id (obj_token).

**Error handling**:
- If "space not found" → ask user for the correct knowledge space name or ID.
- If "permission denied" → ask user to add `wiki:wiki` or `wiki:wiki:readonly` scope.

### Step A2: Extract Key Information

**Tool**: MCP `get_feishu_document_text` + `get_feishu_document_blocks`

Wiki nodes are backed by documents. Use the obj_token (document_id) from Step A1 to read content:

```
MCP tool: get_feishu_document_text
Parameters: { "document_id": "<obj_token>" }
```

For structured extraction (headings, lists, code blocks):

```
MCP tool: get_feishu_document_blocks
Parameters: { "document_id": "<obj_token>" }
```

Process the content:
1. Extract key sections by heading structure.
2. Identify content that has changed since last sync (compare with target doc if it exists).
3. Organize extracted content into a coherent structure for the target document.

If syncing multiple Wiki pages, repeat for each page and merge content logically.

**Error handling**:
- If "document not found" → the wiki node may not have an associated document. Ask user to verify the Wiki page exists and has content.

### Step A3: Update Target Document

**Tool**: CLI `lark-cli doc +create` (if new) + MCP `batch_create_feishu_blocks` + `update_feishu_block_text`

If the target document does not exist, create it first with `lark-cli doc +create`.

Then add extracted content as formatted blocks via `batch_create_feishu_blocks`:
- Use `heading2` for source page titles, `heading3` for sections, `text` for content.
- Include a "同步时间: YYYY-MM-DD HH:MM" block at the top.

To update existing blocks (rather than append), use `update_feishu_block_text` with the target block_id. To remove outdated blocks, use `delete_feishu_document_blocks`.

**Error handling**:
- If "block not found" → re-fetch block list with `get_feishu_document_blocks`.
- If batch creation fails → split into smaller batches and retry.

---

## Direction B: Document to Wiki

Use this when: publishing document content into a Wiki knowledge base for team access, or keeping a Wiki page updated from a source document.

### Step B1: Read Document Content

**Tool**: MCP `get_feishu_document_text` + `get_feishu_document_blocks`

Read the source document with `get_feishu_document_text` for plain text and `get_feishu_document_blocks` for structure.

**Error handling**:
- If "document not found" → verify document_id with user.
- If "permission denied" → check `docx:document:readonly` scope.

### Step B2: Extract and Transform Content

**Tool**: AI analysis (no external tool needed)

Process the document content:
1. Identify the main sections and their hierarchy.
2. Extract key content to sync to Wiki.
3. If the target Wiki node already exists, determine what has changed.
4. Format the content appropriately for the Wiki target.

### Step B3: Create or Update Wiki Node

**Tool**: CLI `lark-cli wiki +create` (new node) or MCP `batch_create_feishu_blocks` + `update_feishu_block_text` (existing node)

For new Wiki nodes, use `lark-cli wiki +create`. The CLI prompts for target knowledge space, parent node, title, and content (Markdown).

For existing Wiki nodes, use the node's associated document_id (from `get_feishu_wiki_node_info`) and update via MCP: `batch_create_feishu_blocks` to add blocks, `update_feishu_block_text` to modify existing blocks.

**Error handling**:
- If "space not found" → ask user which knowledge space to use.
- If "permission denied" → ask user to add `wiki:wiki` scope (write, not readonly).
- If "parent node not found" → list nodes with `lark-cli wiki +list` and let user choose parent.

---

## Output Format

Report sync results to the user:

```
## 知识同步完成

**方向**: Wiki → 文档 / 文档 → Wiki
**来源**: [来源标题](来源链接)
**目标**: [目标标题](目标链接)
**同步时间**: YYYY-MM-DD HH:MM

### 同步内容
- 新增: X 个内容块
- 更新: X 个内容块
- 删除: X 个内容块

### 注意事项
- （如有冲突或需手动检查的内容列出）
```

---

## Example Prompts

- "把技术文档知识库里的 API 指南同步到这个文档"
- "把这篇文档发布到产品知识库里"
- "把三篇 Wiki 整理成一份汇总文档"
- "更新知识库里的部署文档，用这个文档的最新内容"

---

## Partial Execution

- "只读取 Wiki 内容" → Execute Step A1-A2 only.
- "只把文档内容推到 Wiki" → Execute Direction B.
- "看看两边有什么不同" → Execute A1-A2 and B1-B2, compare and report differences.
