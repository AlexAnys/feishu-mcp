# TROUBLESHOOT-AGENT.md — Feishu Integration Error Recovery Guide

**Audience**: AI agents diagnosing and recovering from Feishu integration errors.
**Purpose**: Structured error patterns, diagnostic commands, and automated recovery steps.

When an error occurs, find the matching error pattern below and execute the recovery steps in order. If no pattern matches, run Quick Diagnostics first.

---

## Quick Diagnostics

Run these commands first to assess system health. Execute all 6 in sequence.

### Diagnostic 1: CLI installation status

```bash
which lark-cli && lark-cli --version
```
- **Healthy**: Returns a path and version number.
- **Unhealthy**: "command not found" → CLI not installed. See E-001.

### Diagnostic 2: CLI auth status

```bash
lark-cli auth status
```
- **Healthy**: Shows App ID, user identity, valid token with future expiry.
- **Unhealthy**: "Not logged in" → See E-002. "Token expired" → See E-001.

### Diagnostic 3: CLI skills loaded

```bash
lark-cli skills list 2>/dev/null | head -20
```
- **Healthy**: Lists installed skills (e.g., lark-calendar, lark-im, lark-doc).
- **Unhealthy**: Empty list or error → See E-011.

### Diagnostic 4: MCP environment variables

```bash
echo "APP_ID: ${FEISHU_APP_ID:-NOT SET}" && echo "SECRET: $([ -n "$FEISHU_APP_SECRET" ] && echo SET || echo NOT SET)"
```
- **Healthy**: APP_ID shows `cli_xxx`, SECRET shows `SET`.
- **Unhealthy**: Either shows `NOT SET` → See E-010.

### Diagnostic 5: mcporter configuration

```bash
which mcporter && mcporter list 2>/dev/null
```
- **Healthy**: Returns mcporter path and lists configured MCP servers.
- **Unhealthy**: "command not found" → See E-012. No servers listed → See E-010.

### Diagnostic 6: Network connectivity to Feishu API

```bash
curl -s -o /dev/null -w "%{http_code}" https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal 2>/dev/null || echo "NETWORK_ERROR"
```
- **Healthy**: Returns HTTP status code (e.g., `400` for missing body is normal — means API is reachable).
- **Unhealthy**: Returns `NETWORK_ERROR` or no output → See E-006.

---

## Auth Errors

### E-001: Token expired

**Pattern**: `token expired` | `token_expired` | `access token is expired`
**Layer**: CLI
**Cause**: OAuth access token has expired (typically after ~2 hours).
**Diagnosis**:
```bash
lark-cli auth status
```
Confirm output mentions "expired" or shows a past expiry time.
**Recovery**:
1. Run `lark-cli auth login --recommend`.
2. Wait for user to complete OAuth in browser.
3. Run `lark-cli auth status` to verify new token.
**If recovery fails**: Ask the user: "飞书授权页面是否正常打开？请确认浏览器中完成了授权操作。如果页面无法加载，请检查端口 3000 是否被占用（运行 `lsof -i :3000`）。"

---

### E-002: Token missing / not logged in

**Pattern**: `not logged in` | `no token` | `please login first` | `unauthorized`
**Layer**: CLI
**Cause**: User has never authenticated or auth state was cleared.
**Diagnosis**:
```bash
lark-cli auth status
```
Confirm output shows "Not logged in" or similar.
**Recovery**:
1. Run `lark-cli config init --new` if no app configuration exists.
2. Run `lark-cli auth login --recommend`.
3. Wait for user to complete OAuth.
4. Run `lark-cli auth status` to confirm.
**If recovery fails**: Ask the user: "请确认你的飞书应用 App ID 和 App Secret 是否正确。可以在 https://open.feishu.cn/app 查看。"

---

### E-003: Invalid App ID or App Secret

**Pattern**: `invalid app_id` | `invalid app_secret` | `app not found` | `10003`
**Layer**: Both
**Cause**: The App ID or App Secret provided does not match any Feishu application.
**Diagnosis**:
```bash
echo "Current APP_ID: $FEISHU_APP_ID"
lark-cli auth status
```
Check if APP_ID starts with `cli_` and has the correct format.
**Recovery**:
1. Ask the user to verify their App ID at https://open.feishu.cn/app.
2. If incorrect, re-run `lark-cli config init --new` with the correct credentials.
3. Re-set `FEISHU_APP_ID` and `FEISHU_APP_SECRET` env vars.
4. Re-authenticate: `lark-cli auth login --recommend`.
**If recovery fails**: Ask the user: "请确认应用已发布（不是草稿状态），并且 App ID 以 cli_ 开头。"

---

### E-004: Insufficient permissions (scope missing)

**Pattern**: `permission denied` | `scope.*not.*authorized` | `insufficient.*scope` | `10012` | `99991672`
**Layer**: Both
**Cause**: The Feishu application lacks the required permission scope for the requested operation.
**Diagnosis**:
1. Identify the missing scope from the error message. The error usually contains the required scope name.
2. Cross-reference with the permissions table in SKILL.md.
**Recovery**:
1. Identify the required scope from the error message or from this mapping:
   - Documents → `docx:document`
   - Cloud Storage → `drive:drive`
   - Wiki → `wiki:wiki`
   - Bitable → `bitable:app`
   - Messaging → `im:message`
   - Search → `search:docs:read`
   - Calendar → `calendar:calendar`
   - Email → `mail:message`
   - Contacts → `contact:user.base:readonly`
   - Meetings → `vc:meeting:readonly`
   - Minutes → `minutes:minute:readonly`
   - Tasks → `task:task`
2. Direct the user to add the scope: `https://open.feishu.cn/app/{APP_ID}/security`.
3. After adding the scope, the user must re-publish the app version.
4. Re-authenticate: `lark-cli auth login --recommend`.
5. Retry the original command.
**If recovery fails**: Ask the user: "权限已添加但仍报错？请检查是否已重新发布应用版本。在开放平台点击「创建版本」→「发布」。"

---

## Network Errors

### E-005: Connection refused / timeout

**Pattern**: `ECONNREFUSED` | `ETIMEDOUT` | `connect ECONNREFUSED` | `request timeout`
**Layer**: Both
**Cause**: Cannot reach Feishu API servers. Network issue, firewall, or proxy.
**Diagnosis**:
```bash
curl -s -o /dev/null -w "%{http_code}" https://open.feishu.cn 2>/dev/null || echo "UNREACHABLE"
```
If output is "UNREACHABLE", the network cannot reach Feishu.
**Recovery**:
1. Check internet connectivity: `ping -c 3 open.feishu.cn`.
2. If behind a proxy, set HTTP_PROXY and HTTPS_PROXY env vars.
3. If DNS fails, try `curl -s https://223.5.5.5` to test basic connectivity.
4. Retry the original command after network is restored.
**If recovery fails**: Ask the user: "你的网络能否访问 https://open.feishu.cn ？如果在公司网络，可能需要配置代理。"

---

### E-006: Proxy configuration needed

**Pattern**: `ENOTFOUND` | `getaddrinfo ENOTFOUND` | `proxy.*error`
**Layer**: Both
**Cause**: DNS resolution fails, typically in corporate networks requiring proxy.
**Diagnosis**:
```bash
echo "HTTP_PROXY: ${HTTP_PROXY:-NOT SET}" && echo "HTTPS_PROXY: ${HTTPS_PROXY:-NOT SET}"
curl -s -o /dev/null -w "%{http_code}" https://open.feishu.cn 2>/dev/null || echo "DNS_FAIL"
```
**Recovery**:
1. If proxy vars are not set and user is on corporate network, ask for proxy URL.
2. Set proxy: `export HTTPS_PROXY="http://proxy.company.com:8080"`.
3. Retry the original command.
4. For npm operations, also set: `npm config set proxy $HTTP_PROXY`.
**If recovery fails**: Ask the user: "请提供公司网络的代理服务器地址（如 http://proxy.company.com:8080）。"

---

## Tool-Specific Errors

### E-007: Document not found (invalid document_id)

**Pattern**: `document not found` | `invalid document_id` | `doc.*not.*exist` | `10001`
**Layer**: Both
**Cause**: The document_id does not exist or the user has no access to it.
**Diagnosis**:
1. Verify the document_id format. Feishu document IDs typically start with `doxcn`.
2. If user provided a URL, extract the ID using the pattern: `/docx/([A-Za-z0-9]+)`.
**Recovery**:
1. Confirm the document_id with the user.
2. If a URL was provided, extract the correct token: `https://*.feishu.cn/docx/{document_id}`.
3. Check if the user has access to the document (shared with them or in their drive).
4. Retry with the correct document_id.
**If recovery fails**: Ask the user: "请确认这个文档链接是否正确，以及你是否有权限访问该文档。"

---

### E-008: Block not found (invalid block_id)

**Pattern**: `block not found` | `invalid block_id` | `block.*not.*exist`
**Layer**: MCP
**Cause**: The block_id does not exist in the specified document, or the document structure changed.
**Diagnosis**:
```bash
mcporter call feishu.get_feishu_document_blocks --args '{"document_id":"THE_DOC_ID"}'
```
List all blocks and verify the target block_id exists.
**Recovery**:
1. Fetch the current block structure: `get_feishu_document_blocks`.
2. Find the correct block_id from the returned structure.
3. Retry the operation with the correct block_id.
**If recovery fails**: Retry after 5 seconds — the document may have been concurrently edited and block IDs may have changed.

---

### E-009: Folder access denied

**Pattern**: `folder.*denied` | `no permission.*folder` | `folder.*forbidden`
**Layer**: Both
**Cause**: The user does not have permission to access the specified folder.
**Diagnosis**:
1. Check if `drive:drive` scope is authorized.
2. Check if the folder is shared with the user.
**Recovery**:
1. Verify `drive:drive` scope is enabled at `https://open.feishu.cn/app/{APP_ID}/security`.
2. Ask the user to check if the folder is shared with their account.
3. If using tenant auth, the app may not have folder access — switch to user auth.
4. Retry the operation.
**If recovery fails**: Ask the user: "请确认你是否有权限访问此文件夹。可以在飞书云空间中查看文件夹的共享设置。"

---

### E-010: Rate limiting / throttle

**Pattern**: `rate limit` | `too many requests` | `429` | `frequency limit`
**Layer**: Both
**Cause**: Too many API calls in a short time. Feishu enforces per-app rate limits.
**Diagnosis**: Check if the error includes a retry-after header or time.
**Recovery**:
1. Wait 60 seconds.
2. Retry the original command.
3. If rate-limited again, wait 5 minutes and retry.
4. If still failing, reduce request frequency. Batch operations where possible (use `batch_create_feishu_blocks` instead of individual block calls).
**If recovery fails**: Wait 15 minutes and retry. Rate limits typically reset within this window.

---

## Setup Errors

### E-011: CLI not installed

**Pattern**: `command not found: lark-cli` | `lark-cli.*not found`
**Layer**: CLI
**Cause**: The Feishu CLI package is not installed globally.
**Diagnosis**:
```bash
which lark-cli || echo "NOT INSTALLED"
npm list -g @larksuite/cli 2>/dev/null || echo "NOT IN NPM"
```
**Recovery**:
1. Run `npm install -g @larksuite/cli`.
2. Run `npx skills add larksuite/cli -y -g`.
3. Verify: `lark-cli --version`.
**If recovery fails**: Check npm global directory permissions. Run `npm config get prefix` to find the global dir. If permissions are wrong, fix with `sudo chown -R $(whoami) $(npm config get prefix)/{lib/node_modules,bin,share}`.

---

### E-012: MCP not configured (mcporter config missing)

**Pattern**: `mcporter.*not found` | `no.*mcp.*configured` | `ENOENT.*mcporter`
**Layer**: MCP
**Cause**: mcporter is not installed or MCP server configuration is missing.
**Diagnosis**:
```bash
which mcporter || echo "NOT INSTALLED"
mcporter list 2>/dev/null || echo "NO CONFIG"
```
**Recovery**:
1. Install mcporter: `npm install -g mcporter`.
2. Check if `FEISHU_APP_ID` and `FEISHU_APP_SECRET` are set.
3. If not set, ask the user for their App ID and App Secret.
4. Configure mcporter with the community MCP server.
5. Verify: `mcporter list`.
**If recovery fails**: Fall back to direct npx invocation: `npx -y feishu-mcp@latest --stdio`.

---

### E-013: Skills not loaded

**Pattern**: `skill not found` | `unknown skill` | `no such command`
**Layer**: CLI
**Cause**: CLI skills have not been installed or loaded.
**Diagnosis**:
```bash
lark-cli skills list 2>/dev/null | head -10
```
If output is empty or missing expected skills.
**Recovery**:
1. Run `npx skills add larksuite/cli -y -g`.
2. Wait for installation to complete.
3. Verify: `lark-cli skills list`.
4. Retry the original command.
**If recovery fails**: Retry once more. If still failing, ask the user: "CLI 技能安装失败。请检查网络连接后手动运行：`npx skills add larksuite/cli -y -g`。"

---

### E-014: Port already in use (OAuth)

**Pattern**: `EADDRINUSE` | `port.*in use` | `address already in use`
**Layer**: Both
**Cause**: Port 3000 (CLI OAuth) or 3333 (MCP OAuth) is occupied by another process.
**Diagnosis**:
```bash
lsof -i :3000 2>/dev/null | head -5
lsof -i :3333 2>/dev/null | head -5
```
**Recovery**:
1. Identify the process using the port from the `lsof` output.
2. If the process is not critical, kill it: `kill -9 {PID}`.
3. Retry the auth command.
**If recovery fails**: Ask the user: "端口 3000 或 3333 被其他程序占用。请关闭占用端口的程序后重试。"

---

## Data Errors

### E-015: Invalid JSON in request

**Pattern**: `invalid json` | `JSON.*parse.*error` | `unexpected token` | `SyntaxError.*JSON`
**Layer**: MCP
**Cause**: The request body contains malformed JSON.
**Diagnosis**: Review the JSON string passed to the MCP tool call. Check for unescaped quotes, missing commas, or trailing commas.
**Recovery**:
1. Validate the JSON with `echo '...' | python3 -m json.tool` or `echo '...' | node -e "JSON.parse(require('fs').readFileSync(0))"`.
2. Fix the JSON syntax error.
3. Retry with corrected JSON.
**If recovery fails**: Simplify the request to minimal parameters and add fields incrementally.

---

### E-016: Required parameter missing

**Pattern**: `required.*parameter` | `missing.*field` | `field.*required` | `parameter.*missing`
**Layer**: MCP
**Cause**: A required parameter was not provided in the tool call.
**Diagnosis**: Read the error message to identify which parameter is missing. Cross-reference with the tool parameter list in AGENTS.md.
**Recovery**:
1. Identify the missing parameter from the error message.
2. Check AGENTS.md for the tool's required parameters.
3. Add the missing parameter to the request.
4. Retry.
**If recovery fails**: Consult AGENTS.md tool inventory for the complete parameter list of the tool.

---

### E-017: Document ID format error

**Pattern**: `invalid.*token` | `malformed.*id` | `document_id.*format`
**Layer**: Both
**Cause**: The document/folder/wiki token does not match the expected format.
**Diagnosis**: Feishu tokens have specific prefixes:
- Document: typically `doxcn...`
- Spreadsheet: typically contains alphanumeric chars
- Wiki: typically `wikcn...`
- Folder: typically `fldcn...`
**Recovery**:
1. If the user provided a full URL, extract the token using patterns from AGENTS.md "Extracting IDs from Feishu URLs" section.
2. Verify the extracted token format.
3. Retry with the correct token.
**If recovery fails**: Ask the user: "请提供完整的飞书文档链接，我来提取正确的 token。"

---

## Permission Error Handling — Scope Reference

When a permission error occurs, use this section to identify and resolve the missing scope.

### Identifying the missing scope

1. Read the error message. Feishu permission errors typically include the required scope name or an error code.
2. Common error codes for permission issues: `10012`, `99991672`, `99991663`.
3. Map the operation domain to the required scope:

| Domain | Required Scope | Error Hint |
|---|---|---|
| Documents | `docx:document` | "docx" in error |
| Cloud Storage | `drive:drive` | "drive" in error |
| Wiki | `wiki:wiki` | "wiki" in error |
| Bitable | `bitable:app` | "bitable" in error |
| Messaging | `im:message` | "im" or "message" in error |
| Search | `search:docs:read` | "search" in error |
| Calendar | `calendar:calendar` | "calendar" in error |
| Email | `mail:message` | "mail" in error |
| Contacts | `contact:user.base:readonly` | "contact" in error |
| Meetings | `vc:meeting:readonly` | "vc" or "meeting" in error |
| Minutes | `minutes:minute:readonly` | "minutes" in error |
| Tasks | `task:task` | "task" in error |

### Resolution procedure

1. Identify the missing scope from the table above.
2. Direct the user to the permissions page: `https://open.feishu.cn/app/{APP_ID}/security`.
3. Instruct the user to search for and enable the required scope.
4. After adding the scope, the user must create a new app version and publish it.
5. Re-authenticate: `lark-cli auth login --recommend`.
6. Retry the original operation.

### Scope activation check

Some scopes require admin approval. If the user adds a scope but still gets permission errors:

1. Check if the scope status is "已开通" (activated) vs "审核中" (pending approval).
2. If pending, the user must wait for admin approval or ask their Feishu workspace admin to approve.
3. Direct the user to contact their admin with the specific scope name.

---

## Escalation Summary

| Error | Can Auto-Recover? | Human Action Required |
|---|---|---|
| E-001 Token expired | Yes (re-login) | User approves OAuth in browser |
| E-002 Not logged in | Yes (login) | User approves OAuth in browser |
| E-003 Invalid credentials | No | User verifies App ID/Secret |
| E-004 Missing scope | No | User adds scope in Feishu console |
| E-005 Network timeout | Yes (retry) | None if network recovers |
| E-006 Proxy needed | No | User provides proxy URL |
| E-007 Doc not found | Partial (URL extraction) | User confirms doc access |
| E-008 Block not found | Yes (re-fetch blocks) | None |
| E-009 Folder denied | No | User checks folder sharing |
| E-010 Rate limited | Yes (wait + retry) | None |
| E-011 CLI not installed | Yes (npm install) | None |
| E-012 MCP not configured | Yes (install + configure) | User provides credentials if missing |
| E-013 Skills not loaded | Yes (npx skills add) | None |
| E-014 Port in use | Partial (kill process) | User closes conflicting app |
| E-015 Invalid JSON | Yes (fix JSON) | None |
| E-016 Missing parameter | Yes (add parameter) | None |
| E-017 ID format error | Yes (extract from URL) | User provides URL if ID unknown |
