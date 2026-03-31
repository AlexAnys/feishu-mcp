---
name: data-to-doc
description: 数据报告生成工作流 — 从多维表格查询数据(CLI)，处理汇总后创建格式化文档(CLI+MCP)，支持样式化关键指标。
metadata:
  bins:
    - lark-cli
    - mcporter
---

# 数据报告生成工作流

组合 CLI 和 MCP，从多维表格查询数据，自动生成带格式的飞书文档报告。

---

## When to Use This Skill

- User asks to generate a report from bitable/multidimensional table data ("用多维表格数据生成报告")
- User wants to create a formatted document from structured data ("把数据整理成文档")
- User needs a periodic data summary document ("帮我出一份数据周报")
- User wants to visualize key metrics in a Feishu document

---

## Prerequisites

1. Confirm CLI auth: `lark-cli auth status` — must show valid token.
2. Confirm MCP auth: `FEISHU_APP_ID` and `FEISHU_APP_SECRET` env vars set.
3. Obtain bitable identifiers from the user:
   - `app_token`: the bitable app token (from URL `https://xxx.feishu.cn/base/<app_token>`)
   - `table_id`: the specific table within the bitable (ask user if multiple tables exist)
4. Determine report scope: date range, filters, grouping criteria.

---

## Step-by-Step Workflow

### Step 1: Query Data from Multidimensional Table

**Tool**: CLI `lark-cli base +query`

```bash
lark-cli base +query
```

The CLI will prompt for:
- app_token and table_id
- Filter conditions (e.g., date range, status)
- Sort order
- Fields to return

**Error handling**:
- If "skill not found" → run `npx skills add larksuite/cli -y -g` and retry.
- If "permission denied" → ask user to add `bitable:app` scope at `https://open.feishu.cn/app/{APP_ID}/security`.
- If "app_token invalid" → verify the bitable URL with the user.
- If no records returned → inform user the query returned empty results. Adjust filters and retry.

### Step 2: Process and Summarize Data

**Tool**: AI analysis (no external tool needed)

Process the raw records from Step 1:

1. **Aggregate**: Calculate totals, averages, counts, percentages as appropriate.
2. **Group**: Organize data by categories (e.g., by status, by person, by date).
3. **Highlight**: Identify key metrics — highest/lowest values, trends, anomalies.
4. **Structure**: Plan the document layout:
   - Title with date range
   - Executive summary (2-3 sentences)
   - Key metrics section (highlighted numbers)
   - Detailed data breakdown (grouped tables or lists)
   - Conclusion / next steps

### Step 3: Create a New Document

**Tool**: CLI `lark-cli doc +create`

```bash
lark-cli doc +create
```

Provide a Markdown template with the report title and basic structure. The CLI will create the document and return a document URL and document_id.

Extract the document_id from the returned URL for subsequent MCP operations.

**Error handling**:
- If "permission denied" → ask user to add `docx:document` scope.
- If creation fails → retry once. If still failing, check `lark-cli auth status`.

### Step 4: Add Formatted Blocks with Data

**Tool**: MCP `batch_create_feishu_blocks`

Use `batch_create_feishu_blocks` to add structured content. Build the blocks array dynamically from Step 2's processed data. Recommended document structure:
- `heading2` "数据概览" with report period
- `heading3` "关键指标" with aggregated metrics
- `heading3` "分类明细" with per-category breakdowns
- `heading2` "总结与下一步" with conclusions

Use appropriate block types:
- `heading2` for major sections
- `heading3` for subsections
- `text` for paragraphs and data
- `list` for bullet points (ordered or unordered)
- `code` for raw data or formulas

**Error handling**:
- If "document not found" → verify document_id from Step 3.
- If batch creation partially fails → retry failed blocks individually.
- If block limit exceeded → split into multiple batch calls (max ~50 blocks per call).

### Step 5: Apply Styling to Key Metrics

**Tool**: MCP `update_feishu_block_text`

After creating blocks, apply visual emphasis to key metrics. First, identify the block_ids of key metric blocks from Step 4's response.

For each key metric block, apply styling:

```
MCP tool: update_feishu_block_text
Parameters: {
  "document_id": "<document_id>",
  "block_id": "<block_id>",
  "content": "完成率: 95%",
  "text_color": "green",
  "align": "center"
}
```

Color guidelines:
- **green**: positive metrics (targets met, growth)
- **red**: negative metrics (decline, missed targets)
- **blue**: neutral highlights (totals, key numbers)
- **orange**: warnings (approaching threshold)

Available colors: `red`, `orange`, `yellow`, `green`, `blue`, `purple`, `grey`, `default`.

**Error handling**:
- If "block not found" → re-fetch block list with `get_feishu_document_blocks` and find correct block_id.
- If styling fails → the content is still readable without styling. Log warning and continue.

---

## Output Format

The generated document will have this structure:

```
# [报告标题] — YYYY-MM-DD

## 数据概览
报告期间: ... 至 ...

## 关键指标
总计: XXX     完成率: XX%     增长: XX%
(green)       (green/red)      (green/red)

## 分类明细
### 类别 A
- 记录数: XX (XX%)
- 关键数据: ...

### 类别 B
- 记录数: XX (XX%)
- 关键数据: ...

## 总结与下一步
- 总结要点 1
- 总结要点 2
- 下一步行动
```

Return the document URL to the user upon completion.

---

## Example Prompts

- "用项目跟踪表的数据生成一份周报"
- "从 Bug 多维表格生成本月 Bug 统计报告"
- "把销售数据表整理成一份格式化的文档报告"
- "用这个多维表格 https://xxx.feishu.cn/base/appXXX 生成数据报告"

---

## Partial Execution

- "只查数据不生成文档" → Execute Step 1-2 only, present summary to user.
- "文档已经有了，帮我填入数据" → Skip Step 3, execute Steps 1-2 and 4-5 on existing document.
- "不需要样式，纯文本就行" → Execute Steps 1-4, skip Step 5.
