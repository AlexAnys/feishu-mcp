---
name: feishu-mcp
description: 飞书全能集成套件 — CLI（19 技能、11 业务域、200+ 命令）+ 社区 MCP（15 文档编辑工具、Block 级精度）统一路由决策矩阵，让 AI Agent 精准选择每个飞书操作的最佳工具。
metadata:
  clawdbot:
    emoji: "📘"
    requires:
      bins:
        - mcporter
---

# 飞书全能集成套件 — 决策矩阵

整合飞书 CLI（`@larksuite/cli`，19 AI 技能，200+ 命令，覆盖 11 业务域）和社区 MCP（`feishu-mcp`，15 文档编辑工具，Block 级精度），为 AI Agent 提供统一路由决策。

---

## Decision Principles — 决策原则

按顺序应用以下规则，选择第一条匹配的规则：

1. **非文档域一律用 CLI** — 如果任务涉及消息、日历、邮件、任务、通讯录、会议、妙记、电子表格、多维表格、Wiki 管理 或 事件订阅，使用 CLI。
2. **精确 Block 编辑用 MCP** — 如果任务需要精确的 Block 级文档编辑（指定颜色、对齐方式、批量创建格式化 Block、更新特定 Block 的样式），使用社区 MCP。
3. **CLI 和 MCP 都能做时优先 CLI** — 如果两层都能完成任务，优先使用 CLI，除非 MCP 在精度上有明确优势。
4. **图表和画板编辑用 CLI** — Mermaid 图表、高级图表 DSL、画板创建/编辑仅 CLI 支持（MCP 仅能读取画板内容）。
5. **多步工作流可组合两层** — 如果任务需要先查询数据（CLI）再生成格式化文档（MCP），按步骤组合使用。

---

## Quick Decision Table — 快速决策表

| User Intent (用户意图) | Tool Layer | Specific Tool/Command | Notes |
|---|---|---|---|
| 查看今天的日程 | CLI | `lark-cli calendar +agenda` | 快速概览今日行程 |
| 创建日程/会议 | CLI | `lark-cli calendar +create` | 支持邀请参会人 |
| 查询某人忙闲状态 | CLI | `lark-cli calendar +freebusy` | 查询主日历忙闲 |
| 推荐空闲会议时段 | CLI | `lark-cli calendar +suggestion` | 多方案推荐 |
| 发送飞书消息 | CLI | `lark-cli im +send` | 支持文本/富文本/附件 |
| 搜索聊天记录 | CLI | `lark-cli im +search` | 按关键词搜索 |
| 从 Markdown 创建文档 | CLI | `lark-cli doc +create` | Markdown 输入最简单 |
| 搜索云空间文档 | CLI | `lark-cli doc +search` | 官方接口更可靠 |
| 更新文档内容（追加/覆盖） | CLI | `lark-cli docs +update` | 支持 append/overwrite/replace/insert/delete 模式 |
| 在文档中插入图片 | CLI | `lark-cli docs +media-insert` | CLI 更健壮 |
| 创建文档（指定文件夹） | MCP | `create_feishu_document` | 可指定 folderToken |
| 获取文档元信息 | MCP | `get_feishu_document_info` | 返回标题、修改时间等 |
| 获取文档 Block 结构 | MCP | `get_feishu_document_blocks` | 返回完整 Block 树 |
| 提取文档纯文本 | MCP | `get_feishu_document_text` | 纯文本提取 |
| 批量创建格式化 Block | MCP | `batch_create_feishu_blocks` | 原子操作，支持 text/code/heading/list |
| 更新 Block 文本及样式 | MCP | `update_feishu_block_text` | 8 色彩、对齐方式 |
| 删除文档中的 Block | MCP | `delete_feishu_document_blocks` | 按 block_id 删除 |
| 上传图片并绑定到 Block | MCP | `upload_and_bind_image_to_block` | 图片上传 + 绑定一步完成 |
| 在文档中创建表格 | MCP | `create_feishu_table` | 指定行列数 |
| 创建文件夹 | MCP | `create_feishu_folder` | 云空间文件夹 |
| 列出文件夹内容 | MCP | `list_feishu_folder_contents` | 浏览文件夹结构 |
| 获取文件夹文件列表 | MCP | `get_feishu_folder_files` | 文件夹内文件清单 |
| 搜索文档（MCP 层） | MCP | `search_feishu_documents` | 社区 MCP 搜索 |
| 获取 Wiki 节点信息 | MCP | `get_feishu_wiki_node_info` | Wiki 元数据 |
| 获取画板内容 | MCP | `get_feishu_whiteboard_content` | 仅读取，不可编辑 |
| 上传文件到云空间 | CLI | `lark-cli drive upload` | 支持多种文件类型 |
| 下载云空间文件 | CLI | `lark-cli drive download` | 下载到本地 |
| 创建电子表格 | CLI | `lark-cli sheets +create` | 创建并写入表头 |
| 读取电子表格数据 | CLI | `lark-cli sheets +read` | 读取单元格范围 |
| 写入电子表格数据 | CLI | `lark-cli sheets +write` | 批量写入单元格 |
| 查询多维表格记录 | CLI | `lark-cli base +query` | 支持筛选/排序 |
| 创建多维表格 | CLI | `lark-cli base +create` | 创建表 + 字段 |
| 创建待办任务 | CLI | `lark-cli task +create` | 支持分配/截止日期 |
| 查看我的任务列表 | CLI | `lark-cli task +get-my-tasks` | 个人待办 |
| 写邮件并发送 | CLI | `lark-cli mail +compose` | 支持抄送/附件 |
| 查看收件箱 | CLI | `lark-cli mail +inbox` | 最近邮件列表 |
| 搜索邮件 | CLI | `lark-cli mail +search` | 按关键词搜索 |
| 搜索员工/联系人 | CLI | `lark-cli contact +search` | 姓名/邮箱/手机号 |
| 列出 Wiki 知识空间 | CLI | `lark-cli wiki +list` | 浏览知识空间 |
| 在 Wiki 中创建文档 | CLI | `lark-cli wiki +create` | 知识库节点创建 |
| 创建画板 | CLI | `lark-cli whiteboard +create` | 新建飞书画板 |
| 编辑画板内容 | CLI | `lark-cli docs +whiteboard-update` | Mermaid/图表/视觉编辑 |
| 查看认证状态 | CLI | `lark-cli auth status` | 检查 token 是否有效 |
| 登录认证 | CLI | `lark-cli auth login` | OAuth 浏览器认证 |
| Check my schedule for tomorrow | CLI | `lark-cli calendar +agenda` | English: same command |
| Create a document from notes | CLI | `lark-cli doc +create` | English: Markdown input |
| Search for meeting minutes | CLI | `lark-cli doc +search` | English: keyword search |
| 生成格式化报告（查询 + 文档） | CLI+MCP | `lark-cli base +query` → `batch_create_feishu_blocks` | 多步：先查数据再写文档 |
| 整理会议纪要到文档 | CLI+MCP | `lark-cli vc` → `batch_create_feishu_blocks` | 多步：获取纪要再格式化 |

---

## Domain Sections — 业务域详解

### Auth/Identity — 认证与身份

**Skill**: `lark-shared` — 应用配置初始化、认证登录、身份切换、权限管理。

| 命令/工具 | 描述 |
|---|---|
| `lark-cli config init --new` | 初始化应用配置 |
| `lark-cli auth login --recommend` | OAuth 浏览器登录 |
| `lark-cli auth status` | 查看当前认证状态 |
| `lark-cli auth check` | 检查 token 有效性 |

**示例 Prompt：**
- "检查一下飞书认证状态" → `lark-cli auth status`
- "重新登录飞书" → `lark-cli auth login --recommend`

**路由说明：** CLI only。社区 MCP 认证通过环境变量，不提供交互式认证命令。如果此技能不可用，检查：`lark-cli skills list`。

---

### Calendar — 日历

**Skill**: `lark-calendar` — 提供日历与日程的全面管理：查看/搜索日程、创建/更新日程、管理参会人、查询忙闲状态及推荐空闲时段。

| 命令/工具 | 描述 |
|---|---|
| `lark-cli calendar +agenda` | 快速概览今日/近期行程 |
| `lark-cli calendar +create` | 创建日程并邀请参会人 |
| `lark-cli calendar +freebusy` | 查询用户主日历忙闲信息 |
| `lark-cli calendar +suggestion` | 提供多个时间推荐方案 |

**示例 Prompt：**
- "看一下今天有什么会议" → `lark-cli calendar +agenda`
- "帮我约一个明天下午的会议" → `lark-cli calendar +create`
- "查一下张三这周的忙闲状态" → `lark-cli calendar +freebusy`

**路由说明：** CLI only。社区 MCP 不支持日历操作。如果此技能不可用，检查：`lark-cli skills list`。

---

### Messaging — 即时通讯

**Skill**: `lark-im` — 收发消息和管理群聊：发送/回复消息、搜索聊天记录、管理群聊成员、上传下载文件/图片、管理表情回复。

| 命令/工具 | 描述 |
|---|---|
| `lark-cli im +send` | 发送消息（文本/富文本/附件） |
| `lark-cli im +search` | 搜索聊天记录 |

**示例 Prompt：**
- "给张三发条消息说明天开会" → `lark-cli im +send`
- "搜索最近关于项目上线的聊天记录" → `lark-cli im +search`

**路由说明：** CLI only。社区 MCP 不支持消息操作。如果此技能不可用，检查：`lark-cli skills list`。

---

### Documents — 文档操作

**Skill**: `lark-doc` — 创建和编辑飞书文档：从 Markdown 创建、获取内容、更新（追加/覆盖/替换/插入/删除）、上传图片和文件、搜索文档。此域 CLI 和 MCP 重叠最多，需仔细路由。

**CLI 命令：**

| 命令 | 描述 |
|---|---|
| `lark-cli doc +create` | 从 Markdown 创建文档 |
| `lark-cli doc +search` | 搜索云空间文档 |
| `lark-cli docs +update` | 更新文档（append/overwrite/replace/insert/delete） |
| `lark-cli docs +media-insert` | 在文档中插入图片/文件 |

**MCP 工具：**

| 工具 | 描述 |
|---|---|
| `create_feishu_document` | 创建文档（可指定文件夹） |
| `get_feishu_document_info` | 获取文档元信息 |
| `get_feishu_document_blocks` | 获取文档 Block 结构树 |
| `get_feishu_document_text` | 提取文档纯文本 |
| `batch_create_feishu_blocks` | 批量创建 Block（text/code/heading/list），原子操作 |
| `update_feishu_block_text` | 更新 Block 文本及样式（8 色彩、对齐方式） |
| `delete_feishu_document_blocks` | 按 block_id 删除 Block |
| `upload_and_bind_image_to_block` | 上传图片并绑定到 Block |
| `create_feishu_table` | 在文档中创建表格 |

**示例 Prompt：**
- "帮我新建一个项目周报文档" → `lark-cli doc +create`
- "搜索一下上周的会议纪要" → `lark-cli doc +search`
- "在文档末尾追加一段总结" → `lark-cli docs +update` (append 模式)
- "在文档里插入截图" → `lark-cli docs +media-insert`
- "获取这篇文档的所有 Block 结构" → `get_feishu_document_blocks`
- "给文档的第二个标题改成红色" → `update_feishu_block_text`
- "一次性添加 5 个格式化段落" → `batch_create_feishu_blocks`
- "删除文档中指定的 Block" → `delete_feishu_document_blocks`
- "Create a new doc titled Q1 Summary" → `lark-cli doc +create`

**路由说明：**
- 简单创建/搜索/追加/覆盖 → 用 CLI（更简洁）
- 需要精确 Block 操作（指定颜色、对齐、批量格式化 Block）→ 用 MCP
- 需要读取 Block 结构树 → 用 MCP（`get_feishu_document_blocks`）
- 需要提取纯文本 → 用 MCP（`get_feishu_document_text`）
- 如果此技能不可用，检查：`lark-cli skills list`

---

### Cloud Storage — 云空间

**Skill**: `lark-drive` — 管理云空间中的文件和文件夹：上传/下载文件、创建文件夹、复制/移动/删除文件、管理文档评论和权限。

**CLI 命令：**

| 命令 | 描述 |
|---|---|
| `lark-cli drive upload` | 上传文件到云空间 |
| `lark-cli drive download` | 下载文件到本地 |

**MCP 工具：**

| 工具 | 描述 |
|---|---|
| `create_feishu_folder` | 创建文件夹 |
| `list_feishu_folder_contents` | 列出文件夹内容 |
| `get_feishu_folder_files` | 获取文件夹文件列表 |

**示例 Prompt：**
- "上传这个 PDF 到飞书云空间" → `lark-cli drive upload`
- "下载这个文件" → `lark-cli drive download`
- "创建一个新文件夹叫项目资料" → `create_feishu_folder`
- "列出项目文档文件夹的内容" → `list_feishu_folder_contents`

**路由说明：** 上传/下载用 CLI；文件夹管理 CLI 和 MCP 都可用，CLI 更完整。如果此技能不可用，检查：`lark-cli skills list`。

---

### Spreadsheets — 电子表格

**Skill**: `lark-sheets` — 创建和操作电子表格：创建表格并写入数据、读取和写入单元格、追加行、查找内容、导出文件。

| 命令/工具 | 描述 |
|---|---|
| `lark-cli sheets +create` | 创建电子表格并写入表头 |
| `lark-cli sheets +write` | 批量写入单元格 |
| `lark-cli sheets +read` | 读取单元格范围 |

**示例 Prompt：**
- "创建一个销售数据表" → `lark-cli sheets +create`
- "把这些数据写入表格" → `lark-cli sheets +write`
- "读取 A1:D10 的数据" → `lark-cli sheets +read`

**路由说明：** CLI only。社区 MCP 不支持电子表格操作。如果此技能不可用，检查：`lark-cli skills list`。

---

### Bitable — 多维表格

**Skill**: `lark-base` — 管理多维表格：创建表/字段/记录、查询数据、配置视图、管理仪表盘。

| 命令/工具 | 描述 |
|---|---|
| `lark-cli base +query` | 查询多维表格记录（支持筛选/排序） |
| `lark-cli base +create` | 创建多维表格 |

**示例 Prompt：**
- "查询项目表中本周的记录" → `lark-cli base +query`
- "新建一个 Bug 追踪多维表格" → `lark-cli base +create`

**路由说明：** CLI only。社区 MCP 不支持多维表格。如果此技能不可用，检查：`lark-cli skills list`。

---

### Tasks — 任务

**Skill**: `lark-task` — 管理任务和清单：创建待办、查看/更新状态、子任务拆分、分配协作成员。

| 命令/工具 | 描述 |
|---|---|
| `lark-cli task +create` | 创建待办任务 |
| `lark-cli task +get-my-tasks` | 查看个人任务列表 |

**示例 Prompt：**
- "创建一个任务：下周五前完成设计评审" → `lark-cli task +create`
- "看看我还有哪些未完成的任务" → `lark-cli task +get-my-tasks`

**路由说明：** CLI only。社区 MCP 不支持任务操作。如果此技能不可用，检查：`lark-cli skills list`。

---

### Email — 邮件

**Skill**: `lark-mail` — 飞书邮箱管理：起草/发送/回复/转发/搜索邮件，管理草稿和通讯录。

| 命令/工具 | 描述 |
|---|---|
| `lark-cli mail +compose` | 写邮件并发送 |
| `lark-cli mail +inbox` | 查看收件箱 |
| `lark-cli mail +search` | 搜索邮件 |

**示例 Prompt：**
- "给团队发一封项目进度邮件" → `lark-cli mail +compose`
- "查看最近的收件箱" → `lark-cli mail +inbox`
- "搜索关于合同的邮件" → `lark-cli mail +search`

**路由说明：** CLI only。社区 MCP 不支持邮件操作。如果此技能不可用，检查：`lark-cli skills list`。

---

### Contacts — 通讯录

**Skill**: `lark-contact` — 查询组织架构和人员信息：搜索员工、查看个人信息、查询部门结构。

| 命令/工具 | 描述 |
|---|---|
| `lark-cli contact +search` | 搜索员工（姓名/邮箱/手机号） |

**示例 Prompt：**
- "搜索张三的联系方式" → `lark-cli contact +search`
- "查一下产品部有哪些人" → `lark-cli contact +search`

**路由说明：** CLI only。社区 MCP 不支持通讯录操作。如果此技能不可用，检查：`lark-cli skills list`。

---

### Wiki — 知识库

**Skill**: `lark-wiki` — 管理知识空间和文档节点：创建/查询知识空间、管理节点层级、组织文档。

**CLI 命令：**

| 命令 | 描述 |
|---|---|
| `lark-cli wiki +list` | 列出知识空间 |
| `lark-cli wiki +create` | 在知识库中创建文档 |

**MCP 工具：**

| 工具 | 描述 |
|---|---|
| `get_feishu_wiki_node_info` | 获取 Wiki 节点元数据 |

**示例 Prompt：**
- "列出所有知识空间" → `lark-cli wiki +list`
- "在技术文档知识库里创建一个新页面" → `lark-cli wiki +create`
- "获取这个 Wiki 节点的元信息" → `get_feishu_wiki_node_info`

**路由说明：** 管理操作（创建、列表、导航）用 CLI；仅查询节点元数据可用 MCP。如果此技能不可用，检查：`lark-cli skills list`。

---

### Meetings/Minutes — 会议与妙记

**Skills**: `lark-vc` + `lark-minutes` — 查询会议记录、获取会议纪要产物（总结、待办、章节、逐字稿）。

| 命令/工具 | 描述 |
|---|---|
| `lark-cli vc` | 查询视频会议记录（结束的会议） |
| `lark-cli minutes` | 获取妙记信息（标题、时长、AI 总结） |

**示例 Prompt：**
- "看看昨天有哪些会议记录" → `lark-cli vc`
- "获取这个妙记的 AI 总结" → `lark-cli minutes`

**路由说明：** CLI only。社区 MCP 不支持会议操作。查未来日程用 `lark-cli calendar +agenda`，查已结束会议用 `lark-cli vc`。如果此技能不可用，检查：`lark-cli skills list`。

---

### Whiteboard — 画板

**Skill**: `lark-whiteboard` — 创建和编辑飞书画板：Mermaid 图表、流程图、架构图、思维导图。

**CLI 命令：**

| 命令 | 描述 |
|---|---|
| `lark-cli whiteboard +create` | 创建新画板 |
| `lark-cli docs +whiteboard-update` | 编辑画板（Mermaid/图表/视觉内容） |

**MCP 工具：**

| 工具 | 描述 |
|---|---|
| `get_feishu_whiteboard_content` | 读取画板内容（只读） |

**示例 Prompt：**
- "创建一个新画板" → `lark-cli whiteboard +create`
- "在画板上画一个流程图" → `lark-cli docs +whiteboard-update`
- "获取这个画板的内容" → `get_feishu_whiteboard_content`

**路由说明：** 创建和编辑用 CLI（MCP 不支持写入）；读取画板内容 CLI 和 MCP 均可，MCP 返回结构化数据。如果此技能不可用，检查：`lark-cli skills list`。

---

### Events — 事件订阅

**Skill**: `lark-event` — 通过 WebSocket 实时监听飞书事件（消息变更、通讯录变更、日历变更等）。

| 命令/工具 | 描述 |
|---|---|
| `lark-cli event` | WebSocket 事件订阅，输出 NDJSON |

**示例 Prompt：**
- "监听飞书的新消息事件" → `lark-cli event`
- "订阅日历变更事件" → `lark-cli event`

**路由说明：** CLI only。社区 MCP 不支持事件订阅。如果此技能不可用，检查：`lark-cli skills list`。

---

### Search — 文档搜索

跨域搜索飞书文档和知识库内容。

**CLI 命令：**

| 命令 | 描述 |
|---|---|
| `lark-cli doc +search` | 搜索云空间文档（官方接口） |

**MCP 工具：**

| 工具 | 描述 |
|---|---|
| `search_feishu_documents` | 搜索文档（社区 MCP） |

**示例 Prompt：**
- "搜索关于 Q1 的文档" → `lark-cli doc +search`
- "Find documents about onboarding" → `lark-cli doc +search`

**路由说明：** 优先使用 CLI（`doc +search`），官方接口更可靠。如果 CLI 不可用，使用 MCP（`search_feishu_documents`）。如果此技能不可用，检查：`lark-cli skills list`。

---

## Additional CLI Skills — 扩展技能

以下技能提供高级工作流和 API 探索能力：

| 技能 | 描述 |
|---|---|
| `lark-openapi-explorer` | 从官方文档库中挖掘未封装的原生 OpenAPI 接口 |
| `lark-skill-maker` | 创建自定义 lark-cli Skill |
| `lark-workflow-meeting-summary` | 汇总会议纪要并生成结构化报告 |
| `lark-workflow-standup-report` | 生成日程 + 未完成任务摘要 |

---

## Overlap Resolution — 重叠能力路由

当 CLI 和 MCP 都能完成某个操作时，参考此表选择：

| Capability | CLI Tool | MCP Tool | Recommended | Reason |
|---|---|---|---|---|
| 文档创建 | `lark-cli doc +create` | `create_feishu_document` | CLI | Markdown 输入更简洁，无需指定 folderToken |
| 文档文本读取 | `lark-cli docs +update` (read) | `get_feishu_document_text` | Depends | 需要纯文本提取用 MCP；需要 Markdown 格式用 CLI |
| Block 编辑/更新 | `lark-cli docs +update` | `update_feishu_block_text` | Depends | 需要指定颜色或对齐方式用 MCP；简单文本替换用 CLI |
| Block 删除 | `lark-cli docs +update` (delete) | `delete_feishu_document_blocks` | Depends | 需要按 block_id 精确删除用 MCP；按位置删除用 CLI |
| 图片上传到文档 | `lark-cli docs +media-insert` | `upload_and_bind_image_to_block` | CLI | CLI 更健壮，错误处理更完善 |
| 文档搜索 | `lark-cli doc +search` | `search_feishu_documents` | CLI | 官方接口，更可靠 |
| Wiki 节点读取 | `lark-cli wiki +list` | `get_feishu_wiki_node_info` | Depends | 需要节点元数据详情用 MCP；浏览知识空间结构用 CLI |
| 画板内容读取 | `lark-cli whiteboard` | `get_feishu_whiteboard_content` | Depends | 需要结构化 JSON 数据用 MCP；需要视觉编辑用 CLI |
| 批量创建 Block | `lark-cli docs +update` (append) | `batch_create_feishu_blocks` | MCP | 原子操作，支持精确格式化（颜色、对齐、类型） |
| 文件夹创建 | `lark-cli drive` | `create_feishu_folder` | CLI | CLI 支持更多文件夹操作 |

---

## Auth Prerequisites — 认证前置条件

### CLI 层认证

```bash
# 检查认证状态
lark-cli auth status
# 成功输出：显示当前 App ID、用户身份、token 有效期
# 失败输出：Not logged in 或 Token expired
```

如果未认证：
```bash
lark-cli config init --new   # 初始化应用配置
lark-cli auth login --recommend  # OAuth 浏览器登录（端口 3000）
```

### 社区 MCP 层认证

检查环境变量是否设置：
```bash
echo $FEISHU_APP_ID     # 应输出 cli_xxxxxxxx
echo $FEISHU_APP_SECRET  # 应输出非空字符串
```

社区 MCP OAuth 使用端口 3333（重定向 URL: `http://localhost:3333/callback`）。

### 官方 MCP 层认证（可选）

```bash
npx -y @larksuiteoapi/lark-mcp login -a "$APP_ID" -s "$APP_SECRET"
```

### Pre-flight Checklist — 操作前检查清单

执行任何飞书操作前，按顺序检查：

1. CLI 已安装：`which lark-cli` 应返回路径
2. CLI 已认证：`lark-cli auth status` 应显示有效 token
3. CLI 技能已加载：`lark-cli skills list` 应列出所需技能
4. MCP 环境变量已设置：`FEISHU_APP_ID` 和 `FEISHU_APP_SECRET` 非空
5. mcporter 已安装：`which mcporter` 应返回路径

---

## Permissions Reference — 权限参考

| Domain | Required Scopes | Optional Scopes |
|---|---|---|
| Documents | `docx:document` | `docx:document:readonly` |
| Cloud Storage | `drive:drive` | `drive:drive:readonly` |
| Wiki | `wiki:wiki` | `wiki:wiki:readonly` |
| Bitable | `bitable:app` | `bitable:app:readonly` |
| Messaging | `im:message` | `im:message:readonly`, `im:chat:readonly` |
| Search | `search:docs:read` | — |
| Calendar | `calendar:calendar` | `calendar:calendar:readonly` |
| Email | `mail:message` | `mail:message:readonly` |
| Contacts | `contact:user.base:readonly` | `contact:department:readonly` |
| Meetings | `vc:meeting:readonly` | — |
| Minutes | `minutes:minute:readonly` | — |
| Tasks | `task:task` | `task:task:readonly` |
| Events | 按需订阅事件类型 | — |

飞书权限配置地址：`https://open.feishu.cn/app/{APP_ID}/security`

重定向 URL 配置：
- CLI: `http://localhost:3000/callback`
- 社区 MCP: `http://localhost:3333/callback`

---

## Official MCP (Optional) — 官方 MCP（可选）

官方 MCP（`@larksuiteoapi/lark-mcp`，Beta）作为高级可选项。默认安装不包含。

如果安装了官方 MCP，以下路由可能变化：

| Capability | Default (CLI) | With Official MCP |
|---|---|---|
| 多维表格操作 | `lark-cli base` | 可用 `bitable_v1_*` 工具 |
| 文档搜索 | `lark-cli doc +search` | 可用 `docx_builtin_search` |
| Wiki 搜索 | `lark-cli wiki +list` | 可用 `wiki_v1_node_search` |

官方 MCP 提供的主要工具：`bitable_v1_app_create`、`bitable_v1_appTableRecord_create`、`bitable_v1_appTableRecord_search`、`docx_builtin_search`、`docx_v1_document_rawContent`、`wiki_v1_node_search`、`wiki_v2_space_getNode`。

如果未安装官方 MCP，决策矩阵正常工作，所有功能通过 CLI + 社区 MCP 覆盖。

---

## MCP-Only Mode — 仅 MCP 模式

如果 CLI 未安装（`setup-v2.sh --mcp-only`），以下能力可用：

**可用（MCP）：** 文档创建/编辑/读取、Block 操作、文件夹管理、文档搜索、Wiki 节点查询、画板内容读取。

**不可用（CLI only）：** 消息、日历、邮件、任务、通讯录、会议、妙记、电子表格、多维表格、事件订阅、画板编辑、Mermaid 图表。
