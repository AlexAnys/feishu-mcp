# AGENTS.md — Feishu Integration Master Agent Reference

**Audience**: AI agents (Claude Code, OpenClaw, Cursor, etc.)
**Purpose**: Complete reference for all Feishu operations — tool inventory, decision tree, auth verification, command examples.
**Quick reference**: Consult SKILL.md for routing decisions. This file is the full manual.

All instructions in this file are imperative. Execute them literally.

---

## Architecture Overview

The Feishu integration uses a two-layer architecture:

```
User <-> AI Agent <-> feishu-mcp Integration Layer
                              |
                    +---------+---------+
                    |                   |
              Feishu CLI          Community MCP
              (@larksuite/cli)    (feishu-mcp)
              200+ commands       15 doc editing tools
              19 AI skills        Block-level precision
              11 business domains
              OAuth port: 3000    OAuth port: 3333
```

- **Feishu CLI** (`@larksuite/cli`): Breadth layer. 19 AI skills covering 11 business domains with 200+ commands. Auth stored in OS keychain. OAuth callback on port 3000. Shortcut syntax uses `+` prefix (e.g., `+agenda`, `+send`, `+create`).
- **Community MCP** (`feishu-mcp`): Depth layer. 15 document editing tools with block-level precision, batch operations, and formatting control (8-color palette, alignment). Auth via env vars (`FEISHU_APP_ID`, `FEISHU_APP_SECRET`). OAuth callback on port 3333.
- **Official MCP** (`@larksuiteoapi/lark-mcp`): Optional. Advanced bitable, doc search, and wiki tools. Not installed by default.

Key principle: Use CLI for breadth (anything beyond documents). Use MCP for depth (precise block manipulation, formatting, batch operations).

---

## Complete Tool Inventory

### CLI Skills (19 total, 11 business domains)

#### lark-shared — 认证与身份
应用配置初始化、认证登录、身份切换、权限管理。
```bash
lark-cli auth status          # Check current auth state
lark-cli auth login --recommend  # OAuth browser login
lark-cli config init --new    # Initialize app configuration
```

#### lark-calendar — 日历
日历与日程管理：查看/搜索日程、创建/更新日程、管理参会人、查询忙闲状态。
```bash
lark-cli calendar +agenda     # View today's schedule
lark-cli calendar +create     # Create calendar event
lark-cli calendar +freebusy   # Check free/busy status
lark-cli calendar +suggestion # Get meeting time suggestions
```

#### lark-im — 即时通讯
收发消息、搜索聊天记录、管理群聊。
```bash
lark-cli im +send            # Send message
lark-cli im +search          # Search chat history
```

#### lark-doc — 文档
从 Markdown 创建文档、获取内容、更新、搜索。
```bash
lark-cli doc +create          # Create document from Markdown
lark-cli doc +search          # Search documents in cloud space
lark-cli docs +update         # Update document (append/overwrite/replace/insert/delete)
lark-cli docs +media-insert   # Insert image/file into document
```

#### lark-drive — 云空间
上传/下载文件、管理文件夹、管理权限和评论。
```bash
lark-cli drive upload         # Upload file to cloud space
lark-cli drive download       # Download file from cloud space
```

#### lark-sheets — 电子表格
创建、读写、搜索、导出电子表格。
```bash
lark-cli sheets +create       # Create spreadsheet with headers
lark-cli sheets +write        # Write cell data
lark-cli sheets +read         # Read cell range
```

#### lark-base — 多维表格
表、字段、记录、视图、仪表盘管理。
```bash
lark-cli base +query          # Query records (filter/sort)
lark-cli base +create         # Create bitable
```

#### lark-task — 任务
创建/更新任务、子任务、清单、分配成员。
```bash
lark-cli task +create         # Create task
lark-cli task +get-my-tasks   # Get my task list
```

#### lark-mail — 邮件
起草、发送、回复、转发、搜索邮件。
```bash
lark-cli mail +compose        # Compose and send email
lark-cli mail +inbox          # View inbox
lark-cli mail +search         # Search emails
```

#### lark-contact — 通讯录
查询组织架构、搜索员工信息。
```bash
lark-cli contact +search      # Search contacts (name/email/phone)
```

#### lark-wiki — 知识库
管理知识空间、文档节点、层级结构。
```bash
lark-cli wiki +list           # List knowledge spaces
lark-cli wiki +create         # Create wiki document
```

#### lark-event — 事件订阅
WebSocket 实时监听飞书事件。
```bash
lark-cli event                # Subscribe to events (NDJSON output)
```

#### lark-vc — 视频会议
查询会议记录、获取会议纪要。
```bash
lark-cli vc                   # Query meeting records
```

#### lark-minutes — 妙记
获取妙记基础信息和 AI 产物。
```bash
lark-cli minutes              # Get minutes info (summary, todos, chapters)
```

#### lark-whiteboard — 画板
Mermaid 图表、流程图、架构图、思维导图。
```bash
lark-cli whiteboard +create           # Create new whiteboard
lark-cli docs +whiteboard-update      # Edit whiteboard content
```

#### lark-openapi-explorer — API 探索
从官方文档库挖掘未封装的原生 OpenAPI 接口。
```bash
lark-cli openapi-explorer     # Explore unwrapped OpenAPI endpoints
```

#### lark-skill-maker — 技能创建
创建自定义 lark-cli Skill。
```bash
lark-cli skill-maker          # Create custom CLI skill
```

#### lark-workflow-meeting-summary — 会议纪要工作流
汇总会议纪要并生成结构化报告。
```bash
lark-cli workflow-meeting-summary  # Aggregate meeting minutes into report
```

#### lark-workflow-standup-report — 站会报告工作流
生成日程 + 未完成任务摘要。
```bash
lark-cli workflow-standup-report   # Generate schedule + task summary
```

---

### Community MCP Tools (17 total)

Each tool is invoked via direct tool call or mcporter:

#### create_feishu_document
Create a document in a folder.
- Parameters: `title` (string, required), `folderToken` (string, optional)
```bash
mcporter call feishu.create_feishu_document --args '{"title":"新文档"}'
```

#### get_feishu_document_info
Get document metadata (title, revision, create/update time).
- Parameters: `document_id` (string, required)
```bash
mcporter call feishu.get_feishu_document_info --args '{"document_id":"doxcnXXX"}'
```

#### get_feishu_document_blocks
Get the block structure tree of a document.
- Parameters: `document_id` (string, required)
```bash
mcporter call feishu.get_feishu_document_blocks --args '{"document_id":"doxcnXXX"}'
```

#### get_feishu_document_text
Extract plain text from a document.
- Parameters: `document_id` (string, required)
```bash
mcporter call feishu.get_feishu_document_text --args '{"document_id":"doxcnXXX"}'
```

#### batch_create_feishu_blocks
Batch create blocks (text, code, heading, list) atomically.
- Parameters: `document_id` (string, required), `blocks` (array, required)
```bash
mcporter call feishu.batch_create_feishu_blocks --args '{"document_id":"doxcnXXX","blocks":[{"type":"heading2","content":"标题"},{"type":"text","content":"正文"}]}'
```

#### update_feishu_block_text
Update text/code/heading block with formatting (8 colors, alignment).
- Parameters: `document_id` (string, required), `block_id` (string, required), `content` (string, required), `text_color` (string, optional), `align` (string, optional)
```bash
mcporter call feishu.update_feishu_block_text --args '{"document_id":"doxcnXXX","block_id":"blkXXX","content":"更新内容","text_color":"red"}'
```

#### delete_feishu_document_blocks
Delete blocks by block_id.
- Parameters: `document_id` (string, required), `block_ids` (array, required)
```bash
mcporter call feishu.delete_feishu_document_blocks --args '{"document_id":"doxcnXXX","block_ids":["blkXXX"]}'
```

#### upload_and_bind_image_to_block
Upload an image and bind it to a block in one step.
- Parameters: `document_id` (string, required), `image_path` or `image_url` (string, required)
```bash
mcporter call feishu.upload_and_bind_image_to_block --args '{"document_id":"doxcnXXX","image_url":"https://example.com/img.png"}'
```

#### create_feishu_table
Create a table in a document.
- Parameters: `document_id` (string, required), `rows` (number, required), `cols` (number, required)
```bash
mcporter call feishu.create_feishu_table --args '{"document_id":"doxcnXXX","rows":3,"cols":3}'
```

#### create_feishu_folder
Create a folder in cloud space.
- Parameters: `name` (string, required), `folderToken` (string, optional)
```bash
mcporter call feishu.create_feishu_folder --args '{"name":"项目文档"}'
```

#### list_feishu_folder_contents
List contents of a folder.
- Parameters: `folderToken` (string, required)
```bash
mcporter call feishu.list_feishu_folder_contents --args '{"folderToken":"fldcnXXX"}'
```

#### get_feishu_folder_files
Get file listing from a folder.
- Parameters: `folderToken` (string, required)
```bash
mcporter call feishu.get_feishu_folder_files --args '{"folderToken":"fldcnXXX"}'
```

#### search_feishu_documents
Search documents by keyword.
- Parameters: `query` (string, required), `count` (number, optional)
```bash
mcporter call feishu.search_feishu_documents --args '{"query":"会议记录","count":10}'
```

#### get_feishu_wiki_node_info
Get wiki node metadata.
- Parameters: `token` (string, required)
```bash
mcporter call feishu.get_feishu_wiki_node_info --args '{"token":"wikcnXXX"}'
```

#### get_feishu_whiteboard_content
Read whiteboard content (read-only).
- Parameters: `whiteboard_id` (string, required)
```bash
mcporter call feishu.get_feishu_whiteboard_content --args '{"whiteboard_id":"wbXXX"}'
```

---

### Official MCP Tools (Optional)

If `@larksuiteoapi/lark-mcp` is installed, these additional tools become available. This layer is optional and not part of the default installation.

| Tool | Description | Example |
|---|---|---|
| `bitable_v1_app_create` | Create bitable app | `mcporter call lark.bitable_v1_app_create --args '{"data":{"name":"表"}}'` |
| `bitable_v1_appTableRecord_create` | Create bitable record | `mcporter call lark.bitable_v1_appTableRecord_create --args '...'` |
| `bitable_v1_appTableRecord_search` | Search bitable records | `mcporter call lark.bitable_v1_appTableRecord_search --args '...'` |
| `docx_builtin_search` | Search cloud documents | `mcporter call lark-user.docx_builtin_search --args '{"data":{"search_key":"..."}}'` |
| `docx_v1_document_rawContent` | Get document raw text | `mcporter call lark-user.docx_v1_document_rawContent --args '...'` |
| `wiki_v1_node_search` | Search wiki nodes | `mcporter call lark-user.wiki_v1_node_search --args '...'` |
| `wiki_v2_space_getNode` | Get wiki space node | `mcporter call lark-user.wiki_v2_space_getNode --args '...'` |

---

## Decision Tree

Follow this tree step-by-step. At each numbered item, evaluate the condition and follow the matching branch. Every path ends at a specific tool/command.

1. **User wants to send or read messages**
   1. Send message → `lark-cli im +send`
   2. Search chat history → `lark-cli im +search`

2. **User wants to create a document**
   1. Has Markdown content or simple creation → `lark-cli doc +create`
   2. Needs to specify target folder by token → `create_feishu_document`
   3. Needs batch formatted blocks immediately after creation → `lark-cli doc +create` then `batch_create_feishu_blocks`

3. **User wants to edit an existing document**
   1. Simple append/overwrite/replace → `lark-cli docs +update`
   2. Needs specific block color or alignment → `update_feishu_block_text`
   3. Needs batch creation of multiple formatted blocks → `batch_create_feishu_blocks`
   4. Needs to delete specific blocks by ID → `delete_feishu_document_blocks`
   5. Needs to insert image → `lark-cli docs +media-insert`
   6. Needs to insert table → `create_feishu_table`

4. **User wants to search for something**
   1. Search cloud documents → `lark-cli doc +search`
   2. Search chat messages → `lark-cli im +search`
   3. Search emails → `lark-cli mail +search`
   4. Search contacts → `lark-cli contact +search`

5. **User wants calendar/scheduling operations**
   1. View schedule → `lark-cli calendar +agenda`
   2. Create event → `lark-cli calendar +create`
   3. Check free/busy → `lark-cli calendar +freebusy`
   4. Get time suggestions → `lark-cli calendar +suggestion`

6. **User wants to manage tasks**
   1. Create task → `lark-cli task +create`
   2. View my tasks → `lark-cli task +get-my-tasks`

7. **User wants to send email**
   1. Compose/send → `lark-cli mail +compose`
   2. View inbox → `lark-cli mail +inbox`
   3. Search → `lark-cli mail +search`

8. **User wants to work with spreadsheets**
   1. Create spreadsheet → `lark-cli sheets +create`
   2. Write data → `lark-cli sheets +write`
   3. Read data → `lark-cli sheets +read`

9. **User wants to work with bitable (multi-dimensional tables)**
   1. Query records → `lark-cli base +query`
   2. Create bitable → `lark-cli base +create`

10. **User wants meeting/minutes information**
    1. Query past meeting records → `lark-cli vc`
    2. Get meeting minutes/AI summary → `lark-cli minutes`
    3. Query future meetings (schedule) → `lark-cli calendar +agenda`
    4. Generate meeting summary report → `lark-cli workflow-meeting-summary`

11. **User wants to manage wiki/knowledge base**
    1. List knowledge spaces → `lark-cli wiki +list`
    2. Create wiki document → `lark-cli wiki +create`
    3. Get wiki node metadata → `get_feishu_wiki_node_info`

12. **User wants to create diagrams/charts**
    1. Mermaid flowchart/sequence/mindmap → `lark-cli docs +whiteboard-update`
    2. Create new whiteboard → `lark-cli whiteboard +create`
    3. Read whiteboard content → `get_feishu_whiteboard_content`

13. **User wants file/folder operations**
    1. Upload file → `lark-cli drive upload`
    2. Download file → `lark-cli drive download`
    3. Create folder → `create_feishu_folder`
    4. List folder contents → `list_feishu_folder_contents`

14. **User wants contact/people information**
    1. Search by name/email/phone → `lark-cli contact +search`

15. **User wants to subscribe to events**
    1. Real-time event monitoring → `lark-cli event`

**Fallback**: If CLI returns "skill not found", run `npx skills add larksuite/cli -y -g` and retry the command.

---

## Auth Verification Procedures

### Procedure 1: CLI Auth Check

1. Run `lark-cli auth status`.
2. If output shows a valid App ID, user identity, and unexpired token → auth is valid. Proceed.
3. If output shows "Not logged in" or "Token expired" → run `lark-cli auth login --recommend`.
4. If `lark-cli` is not found → run `npm install -g @larksuite/cli` then `npx skills add larksuite/cli -y -g`.

### Procedure 2: MCP Auth Check

1. Check that `FEISHU_APP_ID` env var is set and starts with `cli_`.
2. Check that `FEISHU_APP_SECRET` env var is set and is non-empty.
3. If either is missing → ask the user for their Feishu App ID and App Secret.
4. Test with a minimal MCP call: `mcporter call feishu.get_feishu_document_info --args '{"document_id":"test"}'`. If the error is about document_id (not auth), auth is working.
5. If the error mentions "unauthorized" or "invalid token" → verify env vars and restart mcporter.

### Procedure 3: Token Refresh

1. **CLI token refresh**: Run `lark-cli auth login --recommend`. The browser opens for OAuth. Wait for user to approve.
2. **MCP token refresh**: If using user auth mode, the user must re-authorize. Run the community MCP startup command to trigger OAuth on port 3333. If using tenant mode, tokens are auto-refreshed via App ID + App Secret.
3. **Verify after refresh**: Run `lark-cli auth status` for CLI. Run a test MCP call for MCP.

---

## Extracting IDs from Feishu URLs

When a user provides a Feishu URL instead of a token/ID, extract the ID using these patterns:

| URL Format | ID Type | Regex |
|---|---|---|
| `https://*.feishu.cn/docx/{id}` | document_id | `/docx/([A-Za-z0-9]+)` |
| `https://*.feishu.cn/wiki/{token}` | wiki_token | `/wiki/([A-Za-z0-9]+)` |
| `https://*.feishu.cn/sheets/{token}` | spreadsheet_token | `/sheets/([A-Za-z0-9]+)` |
| `https://*.feishu.cn/base/{token}` | bitable app_token | `/base/([A-Za-z0-9]+)` |
| `https://*.feishu.cn/drive/folder/{token}` | folder_token | `/folder/([A-Za-z0-9]+)` |
| `https://*.feishu.cn/minutes/{token}` | minute_token | `/minutes/([A-Za-z0-9]+)` |

Example: From `https://abc.feishu.cn/docx/doxcn1234567890`, extract `doxcn1234567890` as the document_id.

---

## Command Examples (30+)

### Calendar Domain

**1.** "查看今天的日程" (View today's schedule)
```bash
lark-cli calendar +agenda
```
Expected output: List of today's events with time, title, and attendees.

**2.** "帮我创建一个明天下午 2 点的会议" (Create a meeting tomorrow at 2 PM)
```bash
lark-cli calendar +create
```
Expected output: Event created confirmation with event link.

**3.** "查一下张三这周的忙闲" (Check Zhang San's availability this week)
```bash
lark-cli calendar +freebusy
```
Expected output: Free/busy time blocks for the specified user.

**4.** "推荐一个三人都有空的时间" (Suggest a time when all three are free)
```bash
lark-cli calendar +suggestion
```
Expected output: Multiple time slot suggestions with availability info.

### Messaging Domain

**5.** "给张三发消息说明天开会" (Send Zhang San a message about tomorrow's meeting)
```bash
lark-cli im +send
```
Expected output: Message sent confirmation with message_id.

**6.** "搜索关于项目上线的聊天记录" (Search chat history about project launch)
```bash
lark-cli im +search
```
Expected output: List of matching messages with sender, time, and content preview.

### Documents Domain

**7.** "创建一个项目周报文档" (Create a weekly report document)
```bash
lark-cli doc +create
```
Expected output: Document created with URL.

**8.** "搜索上周的会议纪要" (Search for last week's meeting notes)
```bash
lark-cli doc +search
```
Expected output: List of matching documents with titles and URLs.

**9.** "在文档末尾追加一段总结" (Append a summary to the document)
```bash
lark-cli docs +update
```
Expected output: Document updated confirmation.

**10.** "在文档里插入一张截图" (Insert a screenshot into the document)
```bash
lark-cli docs +media-insert
```
Expected output: Image inserted confirmation with image key.

**11.** "获取文档的 Block 结构" (Get block structure of a document)
```bash
mcporter call feishu.get_feishu_document_blocks --args '{"document_id":"doxcnXXX"}'
```
Expected output: JSON array of blocks with type, content, and block_id.

**12.** "提取文档的纯文本" (Extract plain text from a document)
```bash
mcporter call feishu.get_feishu_document_text --args '{"document_id":"doxcnXXX"}'
```
Expected output: Plain text string of the document content.

**13.** "一次性添加三个标题段落" (Batch add three heading paragraphs)
```bash
mcporter call feishu.batch_create_feishu_blocks --args '{"document_id":"doxcnXXX","blocks":[{"type":"heading2","content":"第一章"},{"type":"heading2","content":"第二章"},{"type":"heading2","content":"第三章"}]}'
```
Expected output: Array of created block_ids.

**14.** "把标题改成红色" (Change heading color to red)
```bash
mcporter call feishu.update_feishu_block_text --args '{"document_id":"doxcnXXX","block_id":"blkXXX","content":"标题","text_color":"red"}'
```
Expected output: Block updated confirmation.

**15.** "删除文档中的第三个 Block" (Delete the third block)
```bash
mcporter call feishu.delete_feishu_document_blocks --args '{"document_id":"doxcnXXX","block_ids":["blk3XXX"]}'
```
Expected output: Deletion confirmation.

**16.** "上传图片到文档" (Upload image to document)
```bash
mcporter call feishu.upload_and_bind_image_to_block --args '{"document_id":"doxcnXXX","image_url":"https://example.com/img.png"}'
```
Expected output: Image uploaded and bound, returns block_id.

**17.** "在文档中创建一个 3x4 表格" (Create a 3x4 table in the document)
```bash
mcporter call feishu.create_feishu_table --args '{"document_id":"doxcnXXX","rows":3,"cols":4}'
```
Expected output: Table created, returns table block_id.

### Cloud Storage Domain

**18.** "上传这个 PDF" (Upload this PDF)
```bash
lark-cli drive upload
```
Expected output: Upload confirmation with file token.

**19.** "下载这个文件" (Download this file)
```bash
lark-cli drive download
```
Expected output: File downloaded to local path.

**20.** "创建一个叫项目资料的文件夹" (Create a folder called Project Materials)
```bash
mcporter call feishu.create_feishu_folder --args '{"name":"项目资料"}'
```
Expected output: Folder created with folder_token.

**21.** "列出项目文档文件夹的内容" (List contents of the project documents folder)
```bash
mcporter call feishu.list_feishu_folder_contents --args '{"folderToken":"fldcnXXX"}'
```
Expected output: Array of files/folders with names, types, and tokens.

### Spreadsheets Domain

**22.** "创建一个销售数据表" (Create a sales data spreadsheet)
```bash
lark-cli sheets +create
```
Expected output: Spreadsheet created with URL and token.

**23.** "把数据写入 A1:C5" (Write data to A1:C5)
```bash
lark-cli sheets +write
```
Expected output: Cells updated confirmation.

**24.** "读取 A1:D10 的数据" (Read data from A1:D10)
```bash
lark-cli sheets +read
```
Expected output: Cell values in tabular format.

### Bitable Domain

**25.** "查询项目表中本周的记录" (Query this week's records from the project table)
```bash
lark-cli base +query
```
Expected output: Records matching the filter with field values.

**26.** "新建一个 Bug 跟踪表" (Create a new bug tracking table)
```bash
lark-cli base +create
```
Expected output: Bitable created with app_token and URL.

### Tasks Domain

**27.** "创建一个任务：下周五前完成设计评审" (Create a task: complete design review by next Friday)
```bash
lark-cli task +create
```
Expected output: Task created with task_id and link.

**28.** "看看我的待办任务" (View my pending tasks)
```bash
lark-cli task +get-my-tasks
```
Expected output: List of tasks with status, due date, and assignee.

### Email Domain

**29.** "给团队发一封项目进度邮件" (Send a project progress email to the team)
```bash
lark-cli mail +compose
```
Expected output: Email sent confirmation with message_id.

**30.** "搜索关于合同的邮件" (Search for emails about contracts)
```bash
lark-cli mail +search
```
Expected output: List of matching emails with subject, sender, and date.

### Wiki Domain

**31.** "列出所有知识空间" (List all knowledge spaces)
```bash
lark-cli wiki +list
```
Expected output: List of wiki spaces with names and tokens.

**32.** "获取这个 Wiki 节点的信息" (Get wiki node information)
```bash
mcporter call feishu.get_feishu_wiki_node_info --args '{"token":"wikcnXXX"}'
```
Expected output: Node metadata including title, type, parent.

### Whiteboard Domain

**33.** "创建一个新画板" (Create a new whiteboard)
```bash
lark-cli whiteboard +create
```
Expected output: Whiteboard created with URL.

**34.** "在画板上画一个流程图" (Draw a flowchart on the whiteboard)
```bash
lark-cli docs +whiteboard-update
```
Expected output: Whiteboard updated with Mermaid diagram.

**35.** "获取画板内容" (Get whiteboard content)
```bash
mcporter call feishu.get_feishu_whiteboard_content --args '{"whiteboard_id":"wbXXX"}'
```
Expected output: JSON structure of whiteboard elements.

### Contacts Domain

**36.** "搜索张三的联系方式" (Search for Zhang San's contact info)
```bash
lark-cli contact +search
```
Expected output: User profile with name, email, phone, department.

### Meetings Domain

**37.** "看看昨天有哪些会议记录" (View yesterday's meeting records)
```bash
lark-cli vc
```
Expected output: List of meeting records with title, time, organizer.

### Search Domain (cross-domain)

**38.** "搜索关于 Q1 的文档" (Search for documents about Q1)
```bash
lark-cli doc +search
```
Expected output: List of documents matching the query.

**39.** "搜索文档（通过 MCP）" (Search documents via MCP)
```bash
mcporter call feishu.search_feishu_documents --args '{"query":"Q1","count":10}'
```
Expected output: Array of matching documents with title and token.

---

## Operating in MCP-Only Mode

If CLI is not installed (setup ran with `--mcp-only`), only the following capabilities are available:

**Available (via Community MCP):**
- Document creation, editing, reading, and block manipulation
- Folder creation and listing
- Document search
- Wiki node metadata queries
- Whiteboard content reading (read-only)

**Not available (CLI required):**
- Messaging (im)
- Calendar
- Email
- Tasks
- Contacts
- Meetings / Minutes
- Spreadsheets
- Bitable
- Event subscriptions
- Whiteboard creation and editing
- Mermaid diagrams / advanced charts
- File upload / download

If a user requests an unavailable capability in MCP-only mode, inform them: "此功能需要飞书 CLI。运行 `npm install -g @larksuite/cli && npx skills add larksuite/cli -y -g` 安装 CLI。"

---

## Permissions Quick Reference

| Domain | Required Scope |
|---|---|
| Documents | `docx:document` |
| Cloud Storage | `drive:drive` |
| Wiki | `wiki:wiki` |
| Bitable | `bitable:app` |
| Messaging | `im:message` |
| Search | `search:docs:read` |
| Calendar | `calendar:calendar` |
| Email | `mail:message` |
| Contacts | `contact:user.base:readonly` |
| Meetings | `vc:meeting:readonly` |
| Minutes | `minutes:minute:readonly` |
| Tasks | `task:task` |

Manage permissions at: `https://open.feishu.cn/app/{APP_ID}/security`

---

## Error Handling Quick Reference

If any command fails, consult TROUBLESHOOT-AGENT.md for diagnosis and recovery steps.

Common quick fixes:
- "command not found: lark-cli" → `npm install -g @larksuite/cli`
- "skill not found" → `npx skills add larksuite/cli -y -g`
- "Token expired" → `lark-cli auth login --recommend`
- "Permission denied" → Add missing scope at `https://open.feishu.cn/app/{APP_ID}/security`
- "FEISHU_APP_ID not set" → Set env vars and restart mcporter
