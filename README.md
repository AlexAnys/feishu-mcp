# feishu-mcp

飞书全能 MCP — 让 AI 助手完整操作你的飞书：创建文档、编辑内容、插入图表、管理表格。

专为 **Moltbot/Clawdbot** 用户设计，也适用于 Cursor、Claude Desktop、Windsurf 等 AI 工具。

## 🆕 新选择：Lark CLI（2026.3.28）

飞书官方开源了 [Lark CLI](https://github.com/larksuite/cli)（MIT），**一行命令调飞书 2500+ API**，内置 19 个 AI Agent Skills。相比 MCP 方案，Lark CLI 安装更简单、覆盖更广：

| | MCP 方案（本项目） | Lark CLI |
|---|---|---|
| **安装** | 需配置 mcporter + MCP servers | `npm install -g @larksuite/cli` |
| **覆盖** | 文档/表格/搜索/日历 | 11 个领域 200+ 命令 |
| **调用方式** | 通过 MCP 协议 | 直接 CLI 命令 |
| **Agent 适配** | 需要 MCP 支持 | 任何能执行命令的 Agent |

**建议**：
- 需要**文档深度编辑**（块级操作、Mermaid 图表插入）→ 继续用本项目的 MCP 方案
- 需要**广覆盖的飞书操作**（搜文档、读妙记、查日历、发消息等）→ 用 Lark CLI 更简单

两者可以共存。安装 Lark CLI 只需告诉你的 Agent 一句话：

```text
帮我安装飞书 Lark CLI。
参考这个指南：https://github.com/AlexAnys/openclaw-feishu/blob/main/docs/lark-cli-guide.md
```

👉 详见 [Lark CLI 上手指南](https://github.com/AlexAnys/openclaw-feishu/blob/main/docs/lark-cli-guide.md)

---

## ✨ 能做什么？

### 📄 文档操作
- **创建文档** — "帮我新建一个项目周报文档"
- **编辑内容** — "在文档开头加一段摘要"
- **读取内容** — "总结一下这篇文档的要点"
- **批量更新** — "把所有标题改成粗体"

### 📊 表格与图表
- **创建表格** — "插入一个三列的对比表"
- **Mermaid 图表** — "画一个用户注册流程图"
- **思维导图** — "把这些要点整理成思维导图"

### 🖼️ 多媒体
- **插入图片** — "把这张截图加到文档里"
- **画板内容** — "获取画板里的流程图"

### 📚 知识管理
- **搜索文档** — "找一下上周的会议记录"
- **浏览文件夹** — "列出项目文档文件夹的内容"
- **知识库** — "在 Wiki 里创建一个新页面"

### 📋 多维表格
- **创建表格** — "新建一个项目跟踪表"
- **写入数据** — "把这些任务添加到表里"
- **查询记录** — "查一下本周的待办事项"

## 🚀 快速开始

### 1. 准备飞书应用

去 [飞书开放平台](https://open.feishu.cn/app) 创建自建应用：

1. 创建应用，拿到 **App ID** 和 **App Secret**
2. 开通权限（见下方权限列表）
3. 安全设置 → 重定向 URL 添加：`http://localhost:3333/callback`
4. 发布应用

### 2. 一键配置

```bash
curl -fsSL https://raw.githubusercontent.com/AlexAnys/feishu-mcp/main/setup.sh | bash
```

按提示输入 App ID 和 App Secret，脚本会自动完成所有配置。

### 3. 开始使用

在 Moltbot 对话中直接说：
> "帮我在飞书创建一个新文档，标题是《项目周报》"

---

## 📦 包含的 MCP 服务

本 Skill 整合了两个 MCP，发挥各自优势：

| MCP | 用途 | 服务名 |
|-----|------|--------|
| [feishu-mcp](https://github.com/cso1z/Feishu-MCP) (社区版) | 文档创建/编辑、图表、图片 | `feishu` |
| [lark-openapi-mcp](https://github.com/larksuite/lark-openapi-mcp) (官方) | 多维表格、日历、消息、搜索 | `lark` / `lark-user` |

## 🔑 需要的权限

在飞书开放平台开通以下权限：

### 基础权限（必需）
| 权限 | 说明 |
|------|------|
| `docx:document` | 读写文档 |
| `drive:drive` | 访问云空间 |
| `wiki:wiki` | 访问知识库 |

### 推荐权限
| 权限 | 说明 |
|------|------|
| `bitable:app` | 多维表格 |
| `im:message` | 发送消息 |
| `search:docs:read` | 搜索文档 |
| `calendar:calendar` | 日历管理 |

> 💡 首次调用某功能时如果提示权限不足，按提示链接开通即可。

## 🛠️ 可用工具一览

### 文档管理（feishu-mcp）

| 工具 | 功能 |
|------|------|
| `create_feishu_document` | 创建新文档 |
| `get_feishu_document_info` | 获取文档信息 |
| `get_feishu_document_blocks` | 获取文档结构 |
| `batch_create_feishu_blocks` | 批量创建内容块 |
| `update_feishu_block_text` | 更新文本内容 |
| `delete_feishu_document_blocks` | 删除内容块 |
| `create_feishu_table` | 创建表格 |
| `upload_and_bind_image_to_block` | 上传图片 |
| `get_feishu_folder_files` | 获取文件夹内容 |
| `create_feishu_folder` | 创建文件夹 |
| `search_feishu_documents` | 搜索文档 |
| `get_feishu_whiteboard_content` | 获取画板内容 |

### 多维表格（lark-mcp）

| 工具 | 功能 |
|------|------|
| `bitable_v1_app_create` | 创建多维表格 |
| `bitable_v1_appTable_list` | 列出数据表 |
| `bitable_v1_appTableRecord_create` | 创建记录 |
| `bitable_v1_appTableRecord_search` | 搜索记录 |
| `bitable_v1_appTableRecord_update` | 更新记录 |

### 搜索与知识库（lark-mcp）

| 工具 | 功能 |
|------|------|
| `docx_builtin_search` | 搜索云文档 |
| `docx_v1_document_rawContent` | 获取文档纯文本 |
| `wiki_v1_node_search` | 搜索知识库 |
| `wiki_v2_space_getNode` | 获取 Wiki 节点 |

## 📝 使用示例

### 创建并编辑文档

```
用户：帮我创建一个文档，标题是"Q1 工作总结"

AI：我来创建文档...
    [调用 create_feishu_document]
    文档已创建：https://xxx.feishu.cn/docx/xxx
    
用户：在里面加上三个章节：目标回顾、主要成果、下季度计划

AI：正在添加章节...
    [调用 batch_create_feishu_blocks]
    已添加三个章节标题，请查看文档。
```

### 插入流程图

```
用户：在文档里画一个用户注册流程图

AI：我来创建 Mermaid 流程图...
    [调用 batch_create_feishu_blocks with mermaid]
    
    已插入流程图：
    用户访问 → 填写信息 → 验证手机 → 注册成功
```

### 搜索并总结

```
用户：找一下上周的产品会议记录，总结出行动项

AI：搜索中...
    [调用 docx_builtin_search]
    找到 3 篇相关文档，正在读取...
    [调用 docx_v1_document_rawContent]
    
    行动项汇总：
    1. @张三 完成原型设计 - 本周五
    2. @李四 准备用户访谈 - 下周一
    ...
```

### 写入多维表格

```
用户：把这些任务添加到项目跟踪表

AI：正在写入...
    [调用 bitable_v1_appTableRecord_create]
    已添加 5 条记录到多维表格。
```

## 🔧 手动配置（可选）

<details>
<summary>点击展开手动配置步骤</summary>

### 安装依赖

```bash
npm install -g mcporter
```

### 配置文件

编辑 `config/mcporter.json`：

```json
{
  "mcpServers": {
    "feishu": {
      "command": "npx",
      "args": ["-y", "feishu-mcp@latest", "--stdio"],
      "env": {
        "FEISHU_APP_ID": "cli_你的AppID",
        "FEISHU_APP_SECRET": "你的AppSecret",
        "FEISHU_AUTH_TYPE": "user"
      }
    },
    "lark": {
      "command": "npx",
      "args": ["-y", "@larksuiteoapi/lark-mcp", "mcp", "-a", "cli_你的AppID", "-s", "你的AppSecret"]
    },
    "lark-user": {
      "command": "npx",
      "args": ["-y", "@larksuiteoapi/lark-mcp", "mcp", "-a", "cli_你的AppID", "-s", "你的AppSecret", "--oauth", "--token-mode", "user_access_token"]
    }
  }
}
```

### 用户授权

```bash
# 社区版授权
npx feishu-mcp@latest --feishu-app-id="cli_xxx" --feishu-app-secret="secret" --feishu-auth-type="user"

# 官方版授权
npx -y @larksuiteoapi/lark-mcp login -a "cli_xxx" -s "secret"
```

</details>

## ❓ 常见问题

### Q: tenant 和 user 认证有什么区别？

| 认证类型 | 身份 | 适用场景 |
|----------|------|----------|
| `tenant` | 应用 | 操作应用创建的资源 |
| `user` | 用户本人 | 访问个人文档（推荐）|

**强烈建议使用 user 认证**，功能更完整。

### Q: 权限不足怎么办？

按错误提示的链接开通权限，或在开放平台手动添加。

### Q: 文档链接怎么获取 token？

飞书文档链接格式：`https://xxx.feishu.cn/docx/AbCdEfGhIjKl`  
最后一段 `AbCdEfGhIjKl` 就是 document_token。

## 🔗 相关资源

- [Lark CLI](https://github.com/larksuite/cli) — 飞书官方 CLI，覆盖 2500+ API（推荐搭配使用）
- [feishu-mcp (社区版)](https://github.com/cso1z/Feishu-MCP) — 文档编辑能力
- [lark-openapi-mcp (官方)](https://github.com/larksuite/lark-openapi-mcp) — 官方 API
- [openclaw-feishu](https://github.com/AlexAnys/openclaw-feishu) — 飞书 × OpenClaw 配置指南
- [飞书开放平台](https://open.feishu.cn)

## 📜 License

MIT
