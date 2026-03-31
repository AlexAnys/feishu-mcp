---
name: feishu-overview
description: 飞书全能集成套件总览 — 所有 CLI 技能和 MCP 工具的中文索引，快速路由指南，当用户笼统提及"飞书"时加载此技能。
metadata:
  bins:
    - lark-cli
    - mcporter
---

# 飞书能力总览

当用户笼统提及"飞书"、"帮我用飞书"、"飞书能做什么"时，加载此技能作为入口。根据用户意图路由到具体技能或工具。

---

## When to Use This Skill

- User mentions "飞书" without specifying a domain
- User asks "飞书能做什么" or "有哪些飞书功能"
- User needs help choosing the right tool for a Feishu task
- First interaction involving Feishu — orient the user before diving in

---

## CLI 技能一览（19 个技能，11 业务域）

| 技能 | 中文名称 | 一句话说明 |
|---|---|---|
| `lark-shared` | 认证与配置 | 应用初始化、OAuth 登录、身份切换、权限管理 |
| `lark-calendar` | 日历管理 | 查看日程、创建会议、查询忙闲、推荐空闲时段 |
| `lark-im` | 即时通讯 | 发送/回复消息、搜索聊天记录、管理群聊 |
| `lark-doc` | 云文档 | 从 Markdown 创建文档、搜索文档、更新内容、插入图片 |
| `lark-drive` | 云空间 | 上传/下载文件、管理文件夹、管理权限和评论 |
| `lark-sheets` | 电子表格 | 创建表格、读写单元格、追加行、导出文件 |
| `lark-base` | 多维表格 | 建表、字段管理、记录查询、视图配置、仪表盘 |
| `lark-task` | 任务管理 | 创建待办、查看任务列表、子任务拆分、分配成员 |
| `lark-mail` | 邮件 | 起草/发送/回复/转发/搜索邮件 |
| `lark-contact` | 通讯录 | 搜索员工、查看组织架构、查询部门结构 |
| `lark-wiki` | 知识库 | 管理知识空间、创建文档节点、组织层级结构 |
| `lark-vc` | 视频会议 | 查询已结束的会议记录、获取会议纪要 |
| `lark-minutes` | 妙记 | 获取妙记基础信息、AI 总结、待办、章节 |
| `lark-whiteboard` | 画板 | 创建画板、Mermaid 图表、流程图、思维导图 |
| `lark-event` | 事件订阅 | WebSocket 实时监听飞书事件，输出 NDJSON |
| `lark-openapi-explorer` | API 探索 | 从官方文档库挖掘未封装的 OpenAPI 接口 |
| `lark-skill-maker` | 技能创建 | 创建自定义 lark-cli Skill |
| `lark-workflow-meeting-summary` | 会议纪要工作流 | 汇总会议纪要并生成结构化报告 |
| `lark-workflow-standup-report` | 站会报告工作流 | 生成日程 + 未完成任务摘要 |

---

## 社区 MCP 工具一览（17 个工具）

| 工具名称 | 中文名称 | 一句话说明 |
|---|---|---|
| `create_feishu_document` | 创建文档 | 在指定文件夹创建新文档 |
| `get_feishu_document_info` | 获取文档信息 | 返回标题、修改时间等元数据 |
| `get_feishu_document_blocks` | 获取 Block 结构 | 返回文档完整 Block 树 |
| `get_feishu_document_text` | 提取纯文本 | 提取文档的纯文本内容 |
| `batch_create_feishu_blocks` | 批量创建 Block | 原子操作，支持 text/code/heading/list |
| `update_feishu_block_text` | 更新 Block 样式 | 修改文本内容、8 色彩、对齐方式 |
| `delete_feishu_document_blocks` | 删除 Block | 按 block_id 精确删除 |
| `upload_and_bind_image_to_block` | 上传图片 | 上传图片并绑定到 Block 一步完成 |
| `create_feishu_table` | 创建表格 | 在文档中创建指定行列数的表格 |
| `create_feishu_folder` | 创建文件夹 | 在云空间创建文件夹 |
| `list_feishu_folder_contents` | 列出文件夹内容 | 浏览文件夹中的文件和子文件夹 |
| `get_feishu_folder_files` | 获取文件列表 | 获取文件夹内的文件清单 |
| `search_feishu_documents` | 搜索文档 | 按关键词搜索文档 |
| `get_feishu_wiki_node_info` | Wiki 节点信息 | 获取知识库节点元数据 |
| `get_feishu_whiteboard_content` | 读取画板 | 读取画板内容（只读） |

---

## 快速路由指南

**想要做 X？用 Y：**

| 想要做什么 | 用什么 | 具体命令/工具 |
|---|---|---|
| 想看今天有什么会 | CLI | `lark-cli calendar +agenda` |
| 想约个会议 | CLI | `lark-cli calendar +create` |
| 想发条消息给同事 | CLI | `lark-cli im +send` |
| 想搜聊天记录 | CLI | `lark-cli im +search` |
| 想写个新文档 | CLI | `lark-cli doc +create` |
| 想给文档加格式化内容 | MCP | `batch_create_feishu_blocks` |
| 想改文字颜色/对齐 | MCP | `update_feishu_block_text` |
| 想查多维表格数据 | CLI | `lark-cli base +query` |
| 想创建待办任务 | CLI | `lark-cli task +create` |
| 想发邮件 | CLI | `lark-cli mail +compose` |
| 想找个人的联系方式 | CLI | `lark-cli contact +search` |
| 想查知识库 | CLI | `lark-cli wiki +list` |
| 想看会议纪要 | CLI | `lark-cli minutes` |
| 想画流程图 | CLI | `lark-cli docs +whiteboard-update` |
| 想读文档全文 | MCP | `get_feishu_document_text` |
| 想分析文档结构 | MCP | `get_feishu_document_blocks` |
| 想上传文件 | CLI | `lark-cli drive upload` |
| 想生成格式化报告 | CLI+MCP | 先查数据(CLI)，再写格式化文档(MCP) |

---

## 组合工作流技能

以下技能组合 CLI 和 MCP，完成多步操作：

| 工作流 | 说明 | 技能文件 |
|---|---|---|
| 文档审阅 | 读取文档 → 分析内容 → 创建任务 → 发送总结 | `skills/doc-review.md` |
| 数据报告生成 | 查询数据 → 生成格式化文档 | `skills/data-to-doc.md` |
| 知识同步 | Wiki 与文档之间双向同步 | `skills/knowledge-sync.md` |
| 增强版会议纪要 | 会议纪要 + 格式化文档 + 任务创建 | `skills/meeting-summary-plus.md` |

---

## 操作前检查

执行任何飞书操作前，按顺序验证：

1. CLI 已安装：`which lark-cli`
2. CLI 已认证：`lark-cli auth status`
3. CLI 技能已加载：`lark-cli skills list`
4. MCP 环境变量已设置：`FEISHU_APP_ID` 和 `FEISHU_APP_SECRET` 非空
5. mcporter 已安装：`which mcporter`

如果任何检查失败，参考 `TROUBLESHOOT-AGENT.md` 进行修复。

---

## 决策原则（简版）

1. 非文档域一律用 CLI（消息、日历、邮件、任务等）
2. 精确 Block 编辑用 MCP（颜色、对齐、批量格式化）
3. CLI 和 MCP 都能做时优先 CLI
4. 图表和画板编辑用 CLI
5. 多步工作流可组合两层

完整决策矩阵参见 `SKILL.md`。
