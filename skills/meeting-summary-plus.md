---
name: meeting-summary-plus
description: 增强版会议纪要 — 在 CLI 内置会议纪要工作流基础上，用 MCP 生成格式化文档，创建待办任务，并发送通知到群聊。
metadata:
  bins:
    - lark-cli
    - mcporter
---

# 增强版会议纪要

在 CLI 内置的 `workflow-meeting-summary` 基础上增强：生成格式化的会议纪要文档，高亮关键决策，创建待办任务，并通知相关群组。

---

## When to Use This Skill

- User wants a formatted meeting summary document ("帮我整理会议纪要并生成文档")
- User wants action items from meetings converted to tasks ("把会议待办变成任务")
- User needs to send meeting summary to a group ("整理完会议纪要发到群里")
- User wants more than the basic CLI meeting summary — needs styling, tasks, and notifications
- User mentions "增强版会议纪要" or "会议纪要 plus"

---

## Prerequisites

1. Confirm CLI auth: `lark-cli auth status` — must show valid token.
2. Confirm MCP auth: `FEISHU_APP_ID` and `FEISHU_APP_SECRET` env vars set.
3. Required scopes: `vc:meeting:readonly`, `minutes:minute:readonly`, `docx:document`, `task:task`, `im:message`.
4. Determine the time range or specific meeting to summarize.

---

## Step-by-Step Workflow

### Step 1: Retrieve Meeting Data via CLI

**Tool**: CLI `lark-cli workflow meeting-summary` or `lark-cli minutes` + `lark-cli vc`

**Option A** — Use the built-in workflow (recommended for time-range summaries):

```bash
lark-cli workflow meeting-summary
```

This aggregates meetings within a time range and produces a structured summary including:
- Meeting list with titles, times, attendees
- AI-generated summaries per meeting
- Action items / todos
- Key discussion chapters

**Option B** — Manual approach for a single meeting:

First, find the meeting record:

```bash
lark-cli vc
```

Then get the detailed minutes:

```bash
lark-cli minutes
```

This returns: title, duration, AI summary, todos, chapters, and transcript.

**Error handling**:
- If "skill not found" → run `npx skills add larksuite/cli -y -g` and retry.
- If "no meetings found" → widen the time range or verify the date.
- If "permission denied" → ask user to add `vc:meeting:readonly` and `minutes:minute:readonly` scopes.

### Step 2: Create Formatted Summary Document

**Tool**: CLI `lark-cli doc +create` + MCP `batch_create_feishu_blocks`

First, create the document:

```bash
lark-cli doc +create
```

Provide a brief Markdown title like "会议纪要 — YYYY-MM-DD". Extract the document_id from the returned URL.

Then, add formatted content blocks via `batch_create_feishu_blocks`. Build the blocks array dynamically from Step 1's data using this structure:
- `heading1`: document title with date
- `heading2`: major sections (会议概览, AI 摘要, 关键决策, 待办事项, 讨论要点)
- `heading3`: individual topics/agenda items
- `text`: content paragraphs (meeting info, summaries, discussion details)
- `list`: decisions and action items

For multiple meetings, add a `heading2` section per meeting.

**Error handling**:
- If document creation fails → check auth with `lark-cli auth status`.
- If batch creation fails → split into smaller batches (max ~50 blocks per call).

### Step 3: Style Key Decisions and Action Items

**Tool**: MCP `update_feishu_block_text`

Get the block_ids from Step 2's response and apply styling with `update_feishu_block_text`:

- **blue** (`text_color: "blue"`): key decisions
- **red** (`text_color: "red"`): urgent or overdue action items
- **green** (`text_color: "green"`): completed items
- **purple** (`text_color: "purple"`): important notes or reminders

**Error handling**:
- If "block not found" → re-fetch blocks with `get_feishu_document_blocks` and find correct block_id.
- If styling fails → content is still readable. Log warning and continue.

### Step 4: Create Tasks from Action Items

**Tool**: CLI `lark-cli task +create`

For each action item extracted in Step 1, create a task:

```bash
lark-cli task +create
```

Provide for each task:
- **Title**: the action item description
- **Assignee**: the person mentioned (if identifiable)
- **Due date**: extracted from the meeting notes, or default based on urgency
- **Description**: include the meeting title and date for context

**Error handling**:
- If "permission denied" → ask user to add `task:task` scope.
- If assignee not found → create the task without assignee and note it in the output.
- If no action items found → skip this step and inform user.

### Step 5: Send Notification to Group

**Tool**: CLI `lark-cli im +send`

Send a notification via `lark-cli im +send`. Include: meeting title, date, document link, count of decisions and tasks created, and a 2-3 sentence summary.

**Error handling**:
- If user doesn't specify a chat → ask which group to notify, or skip this step.
- If "chat not found" → ask user for the correct chat ID or group name.
- If "permission denied" → ask user to add `im:message` scope.

---

## Output Format

Present the result to the user:

```
## 会议纪要整理完成

**文档**: [会议纪要 — YYYY-MM-DD](文档链接)
**会议数**: X 场
**关键决策**: X 条
**待办任务**: X 条（已创建）
**通知**: 已发送到 [群组名称]

### 关键决策
1. ...
2. ...

### 已创建的任务
1. [负责人] 任务描述 — 截止 YYYY-MM-DD
2. [负责人] 任务描述 — 截止 YYYY-MM-DD
```

---

## Example Prompts

- "帮我整理今天的会议纪要，生成文档并发到项目群"
- "把昨天的会议内容整理成文档，待办事项帮我建成任务"
- "整理本周所有会议纪要，生成一份格式化的汇总文档"
- "增强版会议纪要：上午的产品评审会"

---

## Partial Execution

- "只整理会议内容，不建任务" → Execute Steps 1-3, skip Steps 4-5.
- "整理完帮我发群里就行" → Execute Steps 1-2 and 5, skip Steps 3-4.
- "只看看有哪些会议和待办" → Execute Step 1 only, present raw data.
- "会议纪要已有文档了，帮我建任务和发通知" → Skip Steps 1-3, execute Steps 4-5 from provided doc.
