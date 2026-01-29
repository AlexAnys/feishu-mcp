# feishu-mcp

飞书 MCP 配置指南 — 让 AI 助手读写你的飞书文档、多维表格、知识库。

专为 **Moltbot**（原 Clawdbot）优化，也适用于其他支持 MCP 的 AI 工具（Cursor、Claude Desktop 等）。

## 能做什么？

| 功能 | 示例 |
|------|------|
| 🔍 搜索文档 | "帮我找一下上周的会议记录" |
| 📄 读取内容 | "总结一下这篇文档的要点" |
| 📊 操作多维表格 | "把这些信息写入项目跟踪表" |
| 📚 查询知识库 | "在 Wiki 里搜一下入职流程" |
| 💬 管理群聊 | "发个消息到项目群" |

## 快速开始

### 1. 准备飞书应用

去 [飞书开放平台](https://open.feishu.cn/app) 创建自建应用，拿到：
- **App ID**（cli_xxx）
- **App Secret**

> 💡 如果已有飞书机器人（如 [moltbot-feishu](https://github.com/AlexAnys/moltbot-feishu)），可复用同一个应用。

### 2. 配置回调地址（仅一次）

飞书开放平台 → 应用 → **安全设置** → 重定向 URL，添加：
```
http://localhost:3000/callback
```

### 3. 一键配置

```bash
# 下载并运行配置脚本
curl -fsSL https://raw.githubusercontent.com/AlexAnys/feishu-mcp/main/setup.sh | bash
```

或手动运行：
```bash
git clone https://github.com/AlexAnys/feishu-mcp.git
cd feishu-mcp
./setup.sh
```

脚本会自动：
- ✅ 安装 mcporter（如果没有）
- ✅ 写入 MCP 配置
- ✅ 引导完成用户授权

### 4. 验证

```bash
mcporter call feishu-user.docx_builtin_search --args '{"data":{"search_key":"测试","count":3}}'
```

---

## 手动配置（可选）

如果你想手动配置，或用于 Cursor / Claude Desktop：

<details>
<summary>展开手动配置步骤</summary>

### 安装 mcporter

```bash
npm install -g mcporter
```

### 编辑配置文件

Moltbot 用户编辑 `config/mcporter.json`，Cursor/Claude 用户编辑各自的 MCP 配置文件：

```json
{
  "mcpServers": {
    "feishu": {
      "command": "npx",
      "args": ["-y", "@larksuiteoapi/lark-mcp", "mcp", "-a", "cli_你的AppID", "-s", "你的AppSecret"]
    },
    "feishu-user": {
      "command": "npx",
      "args": ["-y", "@larksuiteoapi/lark-mcp", "mcp", "-a", "cli_你的AppID", "-s", "你的AppSecret", "--oauth", "--token-mode", "user_access_token"]
    }
  }
}
```

### 用户授权

```bash
npx -y @larksuiteoapi/lark-mcp login -a "cli_你的AppID" -s "你的AppSecret"
```

浏览器打开飞书授权页，点同意即可。

</details>

---

**两种身份说明**：
- `feishu` — 应用身份：创建表格、发消息
- `feishu-user` — 用户身份：搜索/读取个人文档

## 开通权限

首次调用 API 可能提示权限不足，按提示链接开通。常用：

| 权限 | 用途 |
|------|------|
| `docx:document:readonly` | 读取文档 |
| `wiki:wiki:readonly` | 搜索知识库 |
| `bitable:app` | 操作多维表格 |
| `search:docs:read` | 搜索文档 |
| `im:message` | 发送消息 |

## 使用示例

```bash
# 搜索文档
mcporter call feishu-user.docx_builtin_search \
  --args '{"data":{"search_key":"会议记录","count":5}}'

# 读取文档内容
mcporter call feishu-user.docx_v1_document_rawContent \
  --args '{"path":{"document_id":"文档token"}}'

# 创建多维表格
mcporter call feishu.bitable_v1_app_create \
  --args '{"data":{"name":"项目跟踪表"}}'

# 写入记录
mcporter call feishu.bitable_v1_appTableRecord_create \
  --args '{"path":{"app_token":"xxx","table_id":"xxx"},"data":{"fields":{"标题":"新任务"}}}'

# 搜索知识库
mcporter call feishu-user.wiki_v1_node_search \
  --args '{"data":{"query":"入职"}}'
```

## 配合 Moltbot 使用

配置好后，在 Moltbot 对话中可以直接：

> "帮我搜一下上周的会议记录，整理出待办事项"
> 
> "把我们讨论的内容写入项目知识库"
>
> "创建一个多维表格来跟踪这个项目"

### 完整飞书方案

| 组件 | 作用 | 安装 |
|------|------|------|
| [moltbot-feishu](https://github.com/AlexAnys/moltbot-feishu) | 消息通道（在飞书里对话） | `clawdbot plugins install moltbot-feishu` |
| **feishu-mcp**（本项目） | 工具能力（操作文档/表格） | 按上面配置 |

两者组合 = 完整的飞书 AI 助手 🎉

## 限制

官方 MCP 目前不支持：
- ❌ 文件上传/下载
- ❌ 直接编辑文档内容（只能读取或导入 Markdown）

## 相关链接

- [官方 lark-openapi-mcp](https://github.com/larksuite/lark-openapi-mcp) — 飞书官方 MCP
- [飞书开放平台](https://open.feishu.cn)
- [Moltbot](https://github.com/moltbot/moltbot)（原 Clawdbot）
- [moltbot-feishu](https://github.com/AlexAnys/moltbot-feishu) — 飞书消息插件

## License

MIT
