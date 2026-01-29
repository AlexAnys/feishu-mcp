# feishu-tools

让 AI 助手读写你的飞书文档、多维表格、知识库。

## 能做什么？

| 功能 | 说明 |
|------|------|
| 🔍 搜索文档 | "帮我找一下上周的会议记录" |
| 📄 读取内容 | "总结一下这篇文档的要点" |
| 📊 操作多维表格 | "把这些信息写入项目跟踪表" |
| 📚 查询知识库 | "在 Wiki 里搜一下入职流程" |
| 💬 管理群聊 | "列出我所在的群" |

## 快速开始

### 1. 准备飞书应用

如果你已经有飞书机器人（比如用了 [moltbot-feishu](https://github.com/AlexAnys/moltbot-feishu)），可以复用同一个应用。

没有的话，去 [飞书开放平台](https://open.feishu.cn/app) 创建一个自建应用，拿到 **App ID** 和 **App Secret**。

### 2. 安装 mcporter

```bash
npm install -g mcporter
```

### 3. 配置飞书 MCP

编辑 `~/.config/mcporter/config.json`（或项目目录下的 `config/mcporter.json`）：

```json
{
  "mcpServers": {
    "feishu": {
      "command": "npx",
      "args": ["-y", "@larksuiteoapi/lark-mcp", "mcp", "-a", "你的AppID", "-s", "你的AppSecret"]
    }
  }
}
```

### 4. 验证

```bash
mcporter list feishu
```

看到工具列表就说明配置成功。

## 访问个人文档

默认用的是「应用身份」，只能操作应用自己创建的资源。

要访问你的个人文档，需要「用户授权」：

### 1. 配置回调地址

飞书开放平台 → 你的应用 → 安全设置 → 重定向 URL，添加：
```
http://localhost:3000/callback
```

### 2. 登录授权

```bash
npx -y @larksuiteoapi/lark-mcp login -a "你的AppID" -s "你的AppSecret"
```

浏览器会打开飞书授权页面，点击同意。

### 3. 添加用户身份配置

```json
{
  "mcpServers": {
    "feishu": {
      "command": "npx",
      "args": ["-y", "@larksuiteoapi/lark-mcp", "mcp", "-a", "你的AppID", "-s", "你的AppSecret"]
    },
    "feishu-user": {
      "command": "npx",
      "args": ["-y", "@larksuiteoapi/lark-mcp", "mcp", "-a", "你的AppID", "-s", "你的AppSecret", "--oauth", "--token-mode", "user_access_token"]
    }
  }
}
```

- `feishu` — 应用身份，创建表格、发消息
- `feishu-user` — 用户身份，搜索/读取个人文档

## 开通权限

首次调用某个 API 可能提示权限不足，按提示链接开通即可。常用权限：

| 权限 | 用途 |
|------|------|
| `docx:document:readonly` | 读取文档内容 |
| `wiki:wiki:readonly` | 搜索知识库 |
| `bitable:app` | 操作多维表格 |
| `im:message` | 发送消息 |
| `search:docs:read` | 搜索文档 |

## 使用示例

```bash
# 搜索文档
mcporter call feishu-user.docx_builtin_search --args '{"data":{"search_key":"会议记录","count":5}}'

# 读取文档内容
mcporter call feishu-user.docx_v1_document_rawContent --args '{"path":{"document_id":"文档ID"}}'

# 创建多维表格
mcporter call feishu.bitable_v1_app_create --args '{"data":{"name":"新表格"}}'

# 写入记录
mcporter call feishu.bitable_v1_appTableRecord_create --args '{"path":{"app_token":"表格token","table_id":"表ID"},"data":{"fields":{"标题":"测试"}}}'
```

## 与 Clawdbot 配合

配置好后，在 Clawdbot 对话中可以直接让 AI 操作飞书：

> "帮我搜一下上周的会议记录，整理成待办事项"
> 
> "把我们刚才讨论的内容写入项目知识库"

## 限制

官方 MCP 目前不支持：
- 文件上传/下载
- 直接编辑文档（只能读取或导入）

## 相关链接

- [官方 MCP 仓库](https://github.com/larksuite/lark-openapi-mcp)
- [飞书开放平台](https://open.feishu.cn)
- [moltbot-feishu 插件](https://github.com/AlexAnys/moltbot-feishu) — 飞书消息通道

## 协议

MIT
