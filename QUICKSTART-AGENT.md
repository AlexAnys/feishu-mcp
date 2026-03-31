# QUICKSTART-AGENT.md — Feishu Integration Setup Automation

**Audience**: AI agents automating Feishu setup for a new user.
**Purpose**: Step-by-step procedure to install and configure CLI + Community MCP from scratch.
**Prerequisites**: Node.js >= 16, npm, internet access.

All instructions are imperative. Execute steps in order. Prompt the user only when prefixed with `[ASK USER]` or `[USER ACTION]`.

---

## Pre-Setup Checks

Run these checks before starting. If any fails, resolve before proceeding.

### Check 1: Node.js version

```bash
node --version
```
- **Expected**: `v16.x.x` or higher (e.g., `v18.17.0`, `v20.11.0`).
- **If fails**: Output "Node.js 未安装或版本过低。请安装 Node.js 16 或更高版本：https://nodejs.org/". Stop.

### Check 2: npm presence

```bash
npm --version
```
- **Expected**: Any version number (e.g., `9.8.1`).
- **If fails**: Output "npm 未找到。Node.js 安装通常自带 npm。请重新安装 Node.js：https://nodejs.org/". Stop.

### Check 3: CLI already installed

```bash
which lark-cli
```
- **Expected**: A path (e.g., `/usr/local/bin/lark-cli`).
- **If not found**: CLI not installed. Continue to setup — installation will happen in the procedure.

### Check 4: MCP already configured

```bash
echo $FEISHU_APP_ID
```
- **Expected**: A string starting with `cli_` (e.g., `cli_a1234567890`).
- **If empty**: MCP not configured. Continue to setup.
- **If set**: MCP may already be configured. Verify with a test call in the smoke test section.

### Check 5: mcporter presence

```bash
which mcporter
```
- **Expected**: A path (e.g., `/usr/local/bin/mcporter`).
- **If not found**: mcporter not installed. Will be installed during setup.

---

## Setup Procedure

### Step 1: Run setup script

**[EXECUTE]** Run the setup script:

```bash
bash setup-v2.sh
```

If `setup-v2.sh` does not exist in the current directory, download it:

```bash
curl -fsSL https://raw.githubusercontent.com/AlexAnys/feishu-mcp/main/setup-v2.sh -o setup-v2.sh && bash setup-v2.sh
```

**If fails**: Check error output. Common issues:
- "npm: command not found" → Node.js/npm not installed. Go back to Pre-Setup Checks.
- Network error → Check internet connectivity. Retry after network is restored.
- Permission error → Do not use `sudo`. Check npm global directory permissions.

If the setup script is not available, proceed with manual steps (Steps 2-6 below). If the script ran successfully, skip to Step 7.

---

### Step 2: Install Feishu CLI

**[EXECUTE]** Install the CLI globally:

```bash
npm install -g @larksuite/cli
```

**If fails**: Try with explicit registry:
```bash
npm install -g @larksuite/cli --registry https://registry.npmjs.org
```
If still fails, check npm permissions. Output the error to the user.

---

### Step 3: Install CLI skills

**[EXECUTE]** Load all 19 AI skills:

```bash
npx skills add larksuite/cli -y -g
```

**If fails**: Retry once. If still fails, output "CLI 技能安装失败。请检查网络连接后重试。" and continue — skills can be installed later.

---

### Step 4: Guide user through Feishu app creation

**[ASK USER]** Display:

> 需要创建一个飞书自建应用来获取 API 凭证。
>
> 请打开飞书开放平台：https://open.feishu.cn/app
>
> 1. 点击「创建企业自建应用」
> 2. 输入应用名称（如：我的 AI 助手）
> 3. 创建完成后，在「凭证与基础信息」页面找到 **App ID** 和 **App Secret**
>
> 请提供你的 App ID（以 cli_ 开头）：

Wait for user to provide the App ID. Store as `APP_ID`.

**[ASK USER]** Display:

> 请提供 App Secret：

Wait for user to provide the App Secret. Store as `APP_SECRET`.

**If user cannot create the app**: Direct them to https://open.feishu.cn/app with step-by-step guidance. They must be a Feishu admin or have app creation permissions.

---

### Step 5: Configure redirect URLs

**[USER ACTION]** Display:

> 在飞书开放平台的应用设置中，请添加以下重定向 URL：
>
> 安全设置 → 重定向 URL → 添加：
> - `http://localhost:3000/callback`（CLI 认证用）
> - `http://localhost:3333/callback`（MCP 认证用）
>
> 添加完成后请确认。

Wait for user confirmation.

**If user cannot find the setting**: Direct them to: `https://open.feishu.cn/app/{APP_ID}/security` → "重定向 URL" section.

---

### Step 6: Configure and authenticate

**[EXECUTE]** Initialize CLI configuration:

```bash
lark-cli config init --new
```

When prompted, enter the App ID and App Secret provided by the user.

**[EXECUTE]** Start OAuth login:

```bash
lark-cli auth login --recommend
```

**[USER ACTION]** Display:

> 浏览器将打开飞书授权页面。请在浏览器中：
> 1. 使用飞书账号登录
> 2. 点击「授权」按钮
> 3. 看到「授权成功」后回到这里

Wait for OAuth to complete.

**If fails**: Check that port 3000 is not in use (`lsof -i :3000`). If occupied, kill the process and retry.

---

### Step 7: Configure community MCP

**[EXECUTE]** Install mcporter if not present:

```bash
npm install -g mcporter
```

**[EXECUTE]** Set MCP environment variables (use the App ID and App Secret from Step 4):

```bash
export FEISHU_APP_ID="$APP_ID"
export FEISHU_APP_SECRET="$APP_SECRET"
```

**If setup-v2.sh was used**: These should already be configured. Verify with `echo $FEISHU_APP_ID`.

---

### Step 8: Verify auth status

**[EXECUTE]** Check CLI auth:

```bash
lark-cli auth status
```

- **Expected**: Shows App ID, user identity, valid token.
- **If "Not logged in"**: Re-run `lark-cli auth login --recommend`.
- **If "Token expired"**: Re-run `lark-cli auth login --recommend`.

**[EXECUTE]** Check MCP env vars:

```bash
echo "APP_ID: $FEISHU_APP_ID"
echo "SECRET set: $([ -n "$FEISHU_APP_SECRET" ] && echo yes || echo no)"
```

- **Expected**: APP_ID shows `cli_xxx`, SECRET shows `yes`.
- **If empty**: Re-set the environment variables from Step 7.

---

### Step 9: Enable Feishu permissions

**[USER ACTION]** Display:

> 请在飞书开放平台开通以下权限：
>
> 打开：https://open.feishu.cn/app/{APP_ID}/security
>
> 基础权限（必需）：
> - `docx:document` — 读写文档
> - `drive:drive` — 云空间
> - `wiki:wiki` — 知识库
>
> 推荐权限：
> - `bitable:app` — 多维表格
> - `im:message` — 消息
> - `search:docs:read` — 搜索
> - `calendar:calendar` — 日历
> - `mail:message` — 邮件
> - `contact:user.base:readonly` — 通讯录
> - `task:task` — 任务
>
> 开通后请确认。

Wait for user confirmation.

---

## Smoke Tests

After setup completes, run these tests to verify the integration works end-to-end.

### Smoke Test 1: CLI Layer

```bash
lark-cli auth status
```

- **Success**: Output shows valid App ID and user identity with unexpired token.
- **Failure**: Output shows "Not logged in" or error.
- **Recovery**: Run `lark-cli auth login --recommend` and repeat.

### Smoke Test 2: CLI Command

```bash
lark-cli calendar +agenda
```

- **Success**: Output shows today's calendar events (or empty list if no events).
- **Failure — "skill not found"**: Run `npx skills add larksuite/cli -y -g` then retry.
- **Failure — "permission denied"**: Add `calendar:calendar` scope at `https://open.feishu.cn/app/{APP_ID}/security`.
- **Failure — auth error**: Run `lark-cli auth login --recommend` then retry.

### Smoke Test 3: MCP Layer

```bash
mcporter call feishu.create_feishu_document --args '{"title":"测试文档"}'
```

- **Success**: Output returns a document_id and URL. Delete the test document afterwards.
- **Failure — "unauthorized"**: Check `FEISHU_APP_ID` and `FEISHU_APP_SECRET` env vars. Re-set and restart mcporter.
- **Failure — "permission denied"**: Add `docx:document` scope at `https://open.feishu.cn/app/{APP_ID}/security`.
- **Failure — "mcporter: command not found"**: Run `npm install -g mcporter` and retry.

---

## Post-Setup Summary

After all smoke tests pass, output:

> 飞书集成配置完成！
>
> - CLI 认证：已通过 ✓
> - MCP 连接：已通过 ✓
> - 权限配置：已完成 ✓
>
> 现在可以使用以下功能：
> - 发消息、管理日历、查看任务（CLI）
> - 创建/编辑文档、精确 Block 操作（MCP）
> - 搜索文档、管理知识库、上传文件
>
> 详细用法参考 SKILL.md（路由决策）或 AGENTS.md（完整工具手册）。
