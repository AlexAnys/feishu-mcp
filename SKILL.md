---
name: feishu-mcp
description: 飞书 MCP 配置指南 - 让 AI 读写云文档、多维表格、知识库。适配 Moltbot/Clawdbot、Cursor、Claude Desktop。
metadata: {"clawdbot":{"emoji":"📘","requires":{"bins":["mcporter"]}}}
---

# 飞书 MCP (Feishu MCP)

通过 MCP 让 AI 操作飞书资源：文档、多维表格、知识库、消息。

## 前置

1. 飞书应用 App ID + App Secret（[开放平台](https://open.feishu.cn/app) 创建）
2. mcporter: `npm i -g mcporter`

## 配置

编辑 `config/mcporter.json`:

```json
{
  "mcpServers": {
    "feishu": {
      "command": "npx",
      "args": ["-y", "@larksuiteoapi/lark-mcp", "mcp", "-a", "AppID", "-s", "AppSecret"]
    },
    "feishu-user": {
      "command": "npx", 
      "args": ["-y", "@larksuiteoapi/lark-mcp", "mcp", "-a", "AppID", "-s", "AppSecret", "--oauth", "--token-mode", "user_access_token"]
    }
  }
}
```

## 用户授权

访问个人文档需要先授权：

1. 飞书开放平台 → 应用 → 安全设置 → 添加重定向 URL：`http://localhost:3000/callback`
2. 运行：`npx -y @larksuiteoapi/lark-mcp login -a "AppID" -s "AppSecret"`

## 常用命令

```bash
# 搜索文档
mcporter call feishu-user.docx_builtin_search --args '{"data":{"search_key":"关键词","count":5}}'

# 读取文档
mcporter call feishu-user.docx_v1_document_rawContent --args '{"path":{"document_id":"文档ID"}}'

# 创建多维表格
mcporter call feishu.bitable_v1_app_create --args '{"data":{"name":"表格名"}}'

# 写入记录
mcporter call feishu.bitable_v1_appTableRecord_create --args '{"path":{"app_token":"xxx","table_id":"xxx"},"data":{"fields":{"字段":"值"}}}'

# 搜索知识库
mcporter call feishu-user.wiki_v1_node_search --args '{"data":{"query":"关键词"}}'
```

## 两种身份

| 服务 | 身份 | 用途 |
|------|------|------|
| `feishu` | 应用 | 创建表格、发消息 |
| `feishu-user` | 用户 | 读取个人文档/知识库 |

详见 [README.md](https://github.com/AlexAnys/feishu-mcp)
