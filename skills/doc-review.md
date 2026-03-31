---
name: doc-review
description: 文档审阅工作流 — 读取文档内容(MCP)，分析质量和结构，创建待办任务(CLI)，发送审阅总结到群聊(CLI)。
metadata:
  bins:
    - lark-cli
    - mcporter
---

# 文档审阅工作流

组合 CLI 和 MCP 完成文档审阅闭环：读取文档 → 分析内容 → 创建任务 → 发送总结。

---

## When to Use This Skill

- User asks to review a Feishu document ("帮我审阅这个文档", "看看这篇文档写得怎么样")
- User wants to check document quality, structure, or completeness
- User needs to create action items from a document review
- User wants to send review feedback to a group chat

---

## Prerequisites

1. Confirm CLI auth: `lark-cli auth status` — must show valid token.
2. Confirm MCP auth: `FEISHU_APP_ID` and `FEISHU_APP_SECRET` env vars set.
3. Obtain the document_id from the user. If user provides a URL like `https://xxx.feishu.cn/docx/doxcnXXX`, extract `doxcnXXX` as the document_id.

---

## Step-by-Step Workflow

### Step 1: Read Document Content

**Tool**: MCP `get_feishu_document_blocks` + `get_feishu_document_text`

First, get the block structure to understand the document layout:

```
MCP tool: get_feishu_document_blocks
Parameters: { "document_id": "<document_id>" }
```

Then, get the plain text for content analysis:

```
MCP tool: get_feishu_document_text
Parameters: { "document_id": "<document_id>" }
```

**Error handling**:
- If "document not found" → verify the document_id with the user.
- If "permission denied" → ask user to add `docx:document:readonly` scope at `https://open.feishu.cn/app/{APP_ID}/security`.
- If "unauthorized" → run `lark-cli auth login --recommend` to refresh token.

### Step 2: Analyze Content Quality

**Tool**: AI analysis (no external tool needed)

Analyze the document on these dimensions:

1. **Structure** — Does the document have clear headings, sections, and logical flow? Count heading blocks from Step 1's block structure.
2. **Completeness** — Are there TODO markers, empty sections, placeholder text, or missing content?
3. **Clarity** — Is the language clear? Are key terms defined? Are there ambiguous statements?
4. **Formatting** — Are lists, tables, and code blocks used appropriately? Is formatting consistent?
5. **Action items** — Identify any items that require follow-up (TODOs, decisions needed, open questions).

Produce a structured review summary with:
- Overall quality score (1-10)
- Strengths (bullet list)
- Issues found (bullet list with severity: high/medium/low)
- Action items (numbered list)

### Step 3: Create Tasks for Action Items

**Tool**: CLI `lark-cli task +create`

For each action item identified in Step 2, create a task:

```bash
lark-cli task +create
```

The CLI will prompt for task details interactively. Provide:
- Task title: the action item description
- Due date: based on urgency (high = 3 days, medium = 7 days, low = 14 days)
- Assignee: if mentioned in the document or specified by user

**Error handling**:
- If "skill not found" → run `npx skills add larksuite/cli -y -g` and retry.
- If "permission denied" → ask user to add `task:task` scope.

### Step 4: Send Review Summary to Group Chat

**Tool**: CLI `lark-cli im +send`

Send the review summary to the specified group chat:

```bash
lark-cli im +send
```

The message should include:
- Document title and link
- Overall quality score
- Key issues found (top 3)
- Number of tasks created
- Brief recommendation (approve / needs revision / major rework)

**Error handling**:
- If "chat not found" → ask user for the correct chat ID or group name.
- If "permission denied" → ask user to add `im:message` scope.
- If user doesn't specify a chat → ask which group to send to, or skip this step.

---

## Output Format

Present the review to the user in this structure:

```
## 文档审阅报告

**文档**: [标题](链接)
**审阅时间**: YYYY-MM-DD
**综合评分**: X/10

### 优点
- ...

### 问题
- [高] ...
- [中] ...
- [低] ...

### 待办任务（已创建）
1. ...（截止日期: YYYY-MM-DD）
2. ...

### 建议
通过 / 需修改 / 需重写
```

---

## Example Prompts

- "帮我审阅一下这个文档 https://xxx.feishu.cn/docx/doxcnXXX"
- "检查这篇文档的质量，找出需要改进的地方"
- "审阅文档并把问题发到项目群里"
- "看看这个文档有没有遗漏的内容，创建待办任务跟进"

---

## Partial Execution

If the user only needs part of the workflow:
- "只看看文档内容" → Execute Steps 1-2 only.
- "审阅完帮我建任务" → Execute Steps 1-3, skip Step 4.
- "审阅完发到群里就行" → Execute Steps 1-2 and 4, skip Step 3.

Adapt to the user's request. Do not force all steps if not needed.
