---
name: feishu-tools
description: 飞书工具能力 - 让 AI 读写云文档、多维表格、知识库。基于官方 lark-openapi-mcp。
metadata: {"clawdbot":{"emoji":"📘","requires":{"bins":["mcporter"]}}}
---

# 飞书工具 (Feishu Tools)

通过 MCP 让 Clawdbot 操作飞书资源。

## 前置

1. 飞书应用的 App ID + App Secret
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

用户授权（访问个人文档需要）:
```bash
npx -y @larksuiteoapi/lark-mcp login -a "AppID" -s "AppSecret"
```

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

- `feishu` — 应用身份，操作应用创建的资源
- `feishu-user` — 用户身份，访问用户个人文档/知识库

详见 README.md
