#!/usr/bin/env bash
# setup-v2.sh — Feishu MCP v2 smart setup script
# Installs and configures Feishu CLI + community MCP + optional official MCP.
# Detects AI platforms (OpenClaw, Claude Code, Cursor) and generates configs.
# All user-facing output is in Chinese. Code comments in English.

set -euo pipefail

# ============================================================
# Constants
# ============================================================

SETUP_VERSION="2.0.0"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MIN_NODE_VERSION=16

# Flags (defaults)
FLAG_FORCE=false
FLAG_MCP_ONLY=false
FLAG_NO_INTERACTIVE=false
FLAG_HELP=false
FLAG_VERSION=false
FLAG_PLATFORM=""

# State tracking
CLI_INSTALLED=false
CLI_VERSION=""
MCPORTER_CONFIGURED=false
OFFICIAL_MCP_CONFIGURED=false
DETECTED_PLATFORMS=""

# Credentials (will be set during execution)
APP_ID=""
APP_SECRET=""

# ============================================================
# Trap: friendly error handler on unexpected failures
# ============================================================

cleanup_on_error() {
    local exit_code=$?
    # Exit code 130 = Ctrl+C — trap_ctrlc already printed a message
    if [ "$exit_code" -ne 0 ] && [ "$exit_code" -ne 130 ]; then
        echo ""
        echo "❌ 脚本遇到意外错误 (退出码: $exit_code)"
        echo "   请检查上方的错误信息，或重新运行脚本"
        echo "   如需帮助: ./setup-v2.sh --help"
    fi
}
trap cleanup_on_error EXIT

# Trap Ctrl+C during auth to give a helpful message
trap_ctrlc() {
    echo ""
    echo "⚠️  操作已中断"
    echo "   可稍后手动完成认证："
    echo "   lark-cli auth login --recommend"
    exit 130
}

# ============================================================
# Helper functions
# ============================================================

# Print usage/help in Chinese
print_help() {
    cat <<'HELPEOF'
飞书 MCP v2 安装脚本

用法:
  ./setup-v2.sh [App_ID] [App_Secret] [选项]

参数:
  App_ID          飞书应用 App ID (可选，不提供则交互式输入)
  App_Secret      飞书应用 App Secret (可选，不提供则交互式输入)

选项:
  -h, --help           显示此帮助信息
  -v, --version        显示脚本版本
  --force              强制重新执行所有步骤（忽略已有配置）
  --mcp-only           仅安装社区 MCP，跳过 CLI 安装
  --no-interactive     非交互模式（需通过参数提供凭证，CI/自动化使用）
  --platform <name>    手动指定目标平台 (openclaw / claude-code / cursor)

示例:
  # 交互式安装（推荐）
  ./setup-v2.sh

  # 非交互式安装
  ./setup-v2.sh cli_abcd1234 your_secret_here

  # 仅安装社区 MCP（不安装 CLI）
  ./setup-v2.sh --mcp-only

  # 强制重新配置
  ./setup-v2.sh --force

获取凭证: https://open.feishu.cn
项目文档: https://github.com/AlexAnys/feishu-mcp
HELPEOF
}

# Trim leading/trailing whitespace (Bash 3.2 compatible)
trim() {
    local var="$1"
    # Remove leading whitespace
    var="${var#"${var%%[![:space:]]*}"}"
    # Remove trailing whitespace
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

# Get mcporter config path following XDG convention
get_mcporter_config_path() {
    if [ -n "${XDG_CONFIG_HOME:-}" ]; then
        echo "${XDG_CONFIG_HOME}/mcporter/config.json"
    else
        echo "${HOME}/.config/mcporter/config.json"
    fi
}

# Check if a previous successful setup exists (for idempotency)
has_existing_config() {
    local config_path
    config_path="$(get_mcporter_config_path)"
    if [ -f "$config_path" ]; then
        # Check if the file contains a feishu entry with non-empty credentials
        FEISHU_CONFIG_PATH="$config_path" node -e "
            var fs = require('fs');
            try {
                var c = JSON.parse(fs.readFileSync(process.env.FEISHU_CONFIG_PATH, 'utf8'));
                if (c.mcpServers && c.mcpServers.feishu &&
                    c.mcpServers.feishu.env &&
                    c.mcpServers.feishu.env.FEISHU_APP_ID &&
                    c.mcpServers.feishu.env.FEISHU_APP_ID !== '') {
                    process.exit(0);
                }
            } catch(e) {}
            process.exit(1);
        " 2>/dev/null
        return $?
    fi
    return 1
}

# Read existing credentials from mcporter config
read_existing_credentials() {
    local config_path
    config_path="$(get_mcporter_config_path)"
    if [ -f "$config_path" ]; then
        FEISHU_CONFIG_PATH="$config_path" node -e "
            var fs = require('fs');
            try {
                var c = JSON.parse(fs.readFileSync(process.env.FEISHU_CONFIG_PATH, 'utf8'));
                if (c.mcpServers && c.mcpServers.feishu && c.mcpServers.feishu.env) {
                    console.log(c.mcpServers.feishu.env.FEISHU_APP_ID || '');
                    console.log(c.mcpServers.feishu.env.FEISHU_APP_SECRET || '');
                } else {
                    console.log('');
                    console.log('');
                }
            } catch(e) {
                console.log('');
                console.log('');
            }
        " 2>/dev/null
    fi
}

# ============================================================
# Parse command-line arguments (Bash 3.2 compatible)
# ============================================================

POSITIONAL_ARGS=""
POSITIONAL_COUNT=0

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            FLAG_HELP=true
            shift
            ;;
        -v|--version)
            FLAG_VERSION=true
            shift
            ;;
        --force)
            FLAG_FORCE=true
            shift
            ;;
        --mcp-only)
            FLAG_MCP_ONLY=true
            shift
            ;;
        --no-interactive)
            FLAG_NO_INTERACTIVE=true
            shift
            ;;
        --platform)
            if [ -n "${2:-}" ]; then
                FLAG_PLATFORM="$2"
                shift 2
            else
                echo "❌ --platform 需要指定平台名称 (openclaw / claude-code / cursor)"
                exit 1
            fi
            ;;
        -*)
            echo "❌ 未知选项: $1"
            echo "   使用 --help 查看所有选项"
            exit 1
            ;;
        *)
            # Positional argument
            POSITIONAL_COUNT=$((POSITIONAL_COUNT + 1))
            if [ "$POSITIONAL_COUNT" -eq 1 ]; then
                APP_ID="$1"
            elif [ "$POSITIONAL_COUNT" -eq 2 ]; then
                APP_SECRET="$1"
            fi
            shift
            ;;
    esac
done

# Handle --help and --version early exits
if [ "$FLAG_HELP" = true ]; then
    print_help
    exit 0
fi

if [ "$FLAG_VERSION" = true ]; then
    echo "feishu-mcp setup v${SETUP_VERSION}"
    exit 0
fi

# ============================================================
# Banner
# ============================================================

echo ""
echo "🚀 飞书 MCP v2 智能配置向导 (v${SETUP_VERSION})"
echo "   CLI 全能管理 + 社区 MCP 精细文档编辑"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================================
# Step 1: Prerequisites check (AC-1.1.1, E-5)
# ============================================================

echo "📋 [1/7] 检查环境..."
echo ""

# Detect OS and architecture
DETECTED_OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
DETECTED_ARCH="$(uname -m)"

case "$DETECTED_OS" in
    darwin)
        OS_DISPLAY="macOS"
        ;;
    linux)
        OS_DISPLAY="Linux"
        ;;
    mingw*|msys*|cygwin*)
        echo "❌ 不支持 Windows 原生环境"
        echo "   请使用 WSL (Windows Subsystem for Linux) 运行此脚本"
        echo "   安装 WSL: https://learn.microsoft.com/zh-cn/windows/wsl/install"
        exit 1
        ;;
    *)
        echo "❌ 不支持的操作系统: ${DETECTED_OS}"
        echo "   此脚本支持 macOS 和 Linux"
        exit 1
        ;;
esac

case "$DETECTED_ARCH" in
    x86_64|amd64)
        ARCH_DISPLAY="x64"
        ;;
    arm64|aarch64)
        ARCH_DISPLAY="arm64"
        ;;
    *)
        ARCH_DISPLAY="$DETECTED_ARCH"
        ;;
esac

echo "   系统: ${OS_DISPLAY} (${ARCH_DISPLAY})"

# Check Node.js
if ! command -v node >/dev/null 2>&1; then
    echo ""
    echo "❌ 未检测到 Node.js"
    echo "   请先安装 Node.js (>= ${MIN_NODE_VERSION})："
    echo "   下载地址: https://nodejs.org"
    echo ""
    echo "   macOS 推荐: brew install node"
    echo "   Linux 推荐: https://github.com/nodesource/distributions"
    exit 1
fi

NODE_VERSION_FULL="$(node --version 2>/dev/null)"
# Extract major version number (strip 'v' prefix, get first segment)
NODE_MAJOR="$(echo "$NODE_VERSION_FULL" | sed 's/^v//' | cut -d. -f1)"

if [ "$NODE_MAJOR" -lt "$MIN_NODE_VERSION" ] 2>/dev/null; then
    echo ""
    echo "❌ Node.js 版本过低: ${NODE_VERSION_FULL}"
    echo "   最低要求: v${MIN_NODE_VERSION}.0.0"
    echo "   请升级 Node.js: https://nodejs.org"
    echo ""
    echo "   macOS: brew upgrade node"
    echo "   nvm 用户: nvm install --lts"
    exit 1
fi

echo "   Node.js: ${NODE_VERSION_FULL}"

# Check npm
if ! command -v npm >/dev/null 2>&1; then
    echo ""
    echo "❌ 未检测到 npm"
    echo "   Node.js 已安装但缺少 npm，请重新安装 Node.js："
    echo "   https://nodejs.org"
    exit 1
fi

NPM_VERSION="$(npm --version 2>/dev/null)"
echo "   npm: v${NPM_VERSION}"
echo ""

# ============================================================
# Step 2: Credentials (AC-1.1.2, E-6)
# ============================================================

echo "📋 [2/7] 获取应用凭证..."
echo ""

# Idempotency: if config exists and not --force, reuse credentials
if [ "$FLAG_FORCE" = false ] && has_existing_config 2>/dev/null; then
    echo "   ✅ 检测到已有配置，使用现有凭证"
    EXISTING_CREDS="$(read_existing_credentials)"
    EXISTING_ID="$(echo "$EXISTING_CREDS" | head -1)"
    EXISTING_SECRET="$(echo "$EXISTING_CREDS" | tail -1)"

    # If positional args provided, use them instead
    if [ -n "$APP_ID" ] && [ -n "$APP_SECRET" ]; then
        echo "   📝 使用命令行提供的新凭证"
    elif [ -n "$EXISTING_ID" ] && [ -n "$EXISTING_SECRET" ]; then
        APP_ID="$EXISTING_ID"
        APP_SECRET="$EXISTING_SECRET"
        echo "   App ID: ${APP_ID}"
        echo ""
    fi
else
    # Need credentials
    if [ -z "$APP_ID" ] || [ -z "$APP_SECRET" ]; then
        if [ "$FLAG_NO_INTERACTIVE" = true ]; then
            echo "❌ 非交互模式下必须提供 App ID 和 App Secret"
            echo "   用法: ./setup-v2.sh <App_ID> <App_Secret> --no-interactive"
            exit 1
        fi

        echo "   请输入飞书应用凭证（在 open.feishu.cn 创建应用后获取）"
        echo ""

        if [ -z "$APP_ID" ]; then
            printf "   App ID (cli_xxx): "
            read -r APP_ID
        fi
        if [ -z "$APP_SECRET" ]; then
            printf "   App Secret (输入不显示): "
            # Suppress echo for secret input; handle terminals that don't support -s
            if stty -echo 2>/dev/null; then
                read -r APP_SECRET
                stty echo
                echo ""
            else
                read -r APP_SECRET
            fi
        fi
    fi
fi

# Trim whitespace from credentials
APP_ID="$(trim "$APP_ID")"
APP_SECRET="$(trim "$APP_SECRET")"

# Validate credentials are non-empty
if [ -z "$APP_ID" ] || [ -z "$APP_SECRET" ]; then
    echo ""
    echo "❌ App ID 或 App Secret 不能为空"
    echo "   请在飞书开放平台获取: https://open.feishu.cn"
    exit 1
fi

# Warn if App ID doesn't start with cli_ (don't block -- format may change)
case "$APP_ID" in
    cli_*)
        ;;
    *)
        echo "   ⚠️  App ID 通常以 'cli_' 开头，当前值: ${APP_ID}"
        echo "      如果确认无误请继续，否则请检查"
        echo ""
        ;;
esac

# ============================================================
# Step 3: Feishu CLI installation (AC-1.1.3, E-3)
# ============================================================

echo "📋 [3/7] 安装飞书 CLI..."
echo ""

if [ "$FLAG_MCP_ONLY" = true ]; then
    echo "   ⏭️  已跳过 CLI 安装 (--mcp-only 模式)"
    echo ""
    CLI_INSTALLED=false
else
    # Check if CLI is already installed
    if command -v lark-cli >/dev/null 2>&1; then
        CLI_VERSION="$(lark-cli --version 2>/dev/null || echo "unknown")"
        echo "   ✅ 飞书 CLI 已安装: ${CLI_VERSION}"
        CLI_INSTALLED=true
        if [ "$FLAG_FORCE" = false ]; then
            echo "   ⏭️  跳过重新安装（使用 --force 强制重新安装）"
        else
            echo "   🔄 强制重新安装..."
            if npm install -g @larksuite/cli 2>/tmp/feishu-cli-install-err.log; then
                CLI_VERSION="$(lark-cli --version 2>/dev/null || echo "unknown")"
                echo "   ✅ 飞书 CLI 已更新: ${CLI_VERSION}"
            else
                echo "   ⚠️  CLI 更新失败，继续使用现有版本"
            fi
        fi
    else
        echo "   📦 正在安装 @larksuite/cli..."
        if npm install -g @larksuite/cli 2>/tmp/feishu-cli-install-err.log; then
            CLI_VERSION="$(lark-cli --version 2>/dev/null || echo "unknown")"
            echo "   ✅ 飞书 CLI 安装成功: ${CLI_VERSION}"
            CLI_INSTALLED=true
        else
            # Graceful degradation: CLI install failed, continue with MCP-only
            CLI_INSTALLED=false
            INSTALL_ERR="$(cat /tmp/feishu-cli-install-err.log 2>/dev/null || echo "")"

            echo "   ⚠️  飞书 CLI 安装失败，将以 MCP-only 模式继续"
            echo ""

            # Detect specific error types and provide targeted advice
            case "$INSTALL_ERR" in
                *EACCES*|*permission*)
                    echo "   💡 权限不足。请运行以下命令修复 npm 全局安装路径："
                    echo "      npm config set prefix '~/.npm-global'"
                    echo "      export PATH=~/.npm-global/bin:\$PATH"
                    echo "      # 添加到 ~/.bashrc 或 ~/.zshrc 以永久生效"
                    ;;
                *ENOTFOUND*|*EAI_AGAIN*|*network*|*ETIMEDOUT*)
                    echo "   💡 网络连接失败。请检查："
                    echo "      - 网络连接是否正常"
                    echo "      - 是否需要配置代理: npm config set proxy <url>"
                    if [ -z "${HTTP_PROXY:-}${HTTPS_PROXY:-}${http_proxy:-}${https_proxy:-}" ]; then
                        echo "      - 未检测到代理环境变量，如需代理请设置 HTTPS_PROXY"
                    fi
                    ;;
                *404*|*E404*)
                    echo "   💡 npm 包可能尚未发布或名称已变更"
                    echo "      飞书 CLI 是新发布的工具，如遇此问题请稍后重试"
                    ;;
                *)
                    echo "   💡 安装失败原因:"
                    echo "      $(echo "$INSTALL_ERR" | head -3)"
                    ;;
            esac
            echo ""
            echo "   📝 MCP-only 模式仍可使用文档编辑等核心功能"
            echo ""
        fi
    fi

    # Install CLI skills (only if CLI was successfully installed)
    if [ "$CLI_INSTALLED" = true ]; then
        echo "   📦 安装 CLI 技能包..."
        if npx skills add larksuite/cli -y -g 2>/dev/null; then
            echo "   ✅ CLI 技能包安装成功"
        else
            echo "   ⚠️  CLI 技能包安装失败（非关键，可稍后手动安装）"
            echo "      手动安装: npx skills add larksuite/cli -y -g"
        fi
    fi
    echo ""
fi

# ============================================================
# Step 4: Community MCP via mcporter (AC-1.1.4, E-7)
# ============================================================

echo "📋 [4/7] 配置社区 MCP (feishu-mcp)..."
echo ""

# Install mcporter if not present
if ! command -v mcporter >/dev/null 2>&1; then
    echo "   📦 安装 mcporter..."
    if npm install -g mcporter 2>/tmp/feishu-mcporter-err.log; then
        echo "   ✅ mcporter 安装成功"
    else
        MCPORTER_ERR="$(cat /tmp/feishu-mcporter-err.log 2>/dev/null || echo "")"
        case "$MCPORTER_ERR" in
            *EACCES*|*permission*)
                echo "   ❌ mcporter 安装失败 — 权限不足"
                echo "      请运行: npm config set prefix '~/.npm-global'"
                echo "      然后重新运行此脚本"
                ;;
            *ENOTFOUND*|*EAI_AGAIN*|*ETIMEDOUT*)
                echo "   ❌ mcporter 安装失败 — 网络错误"
                echo "      请检查网络连接后重试"
                if [ -z "${HTTP_PROXY:-}${HTTPS_PROXY:-}${http_proxy:-}${https_proxy:-}" ]; then
                    echo "      如需代理请设置: export HTTPS_PROXY=<url>"
                fi
                ;;
            *)
                echo "   ❌ mcporter 安装失败"
                echo "      $(echo "$MCPORTER_ERR" | head -3)"
                ;;
        esac
        echo ""
        echo "   手动安装: npm install -g mcporter"
        exit 1
    fi
else
    echo "   ✅ mcporter 已安装"
fi

# Generate/merge mcporter config
MCPORTER_CONFIG="$(get_mcporter_config_path)"
MCPORTER_CONFIG_DIR="$(dirname "$MCPORTER_CONFIG")"

# Ensure config directory exists
mkdir -p "$MCPORTER_CONFIG_DIR"

# Use inline Node.js to safely read/merge/write JSON config (v1 pattern)
# Credentials passed via environment variables to avoid injection (HIGH-1)
NODE_ERR_FILE="$(mktemp /tmp/feishu-node-err.XXXXXX)"
if FEISHU_APP_ID="$APP_ID" FEISHU_APP_SECRET="$APP_SECRET" \
   FEISHU_CONFIG_PATH="$MCPORTER_CONFIG" node -e "
var fs = require('fs');
var configPath = process.env.FEISHU_CONFIG_PATH;
var appId = process.env.FEISHU_APP_ID;
var appSecret = process.env.FEISHU_APP_SECRET;

var config = {};

// Read existing config if present
if (fs.existsSync(configPath)) {
    try {
        config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    } catch(e) {
        // E-7: Malformed JSON — back up and start fresh
        var timestamp = Date.now();
        var backupPath = configPath + '.bak.' + timestamp;
        fs.renameSync(configPath, backupPath);
        console.log('   ⚠️  现有配置文件格式错误，已备份到: ' + backupPath);
        config = {};
    }
}

if (!config.mcpServers) config.mcpServers = {};

// Add/update community MCP entry (preserves other entries)
config.mcpServers.feishu = {
    command: 'npx',
    args: ['-y', 'feishu-mcp@latest', '--stdio'],
    env: {
        FEISHU_APP_ID: appId,
        FEISHU_APP_SECRET: appSecret,
        FEISHU_AUTH_TYPE: 'user'
    }
};

fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
console.log('   ✅ 社区 MCP 配置已写入: ' + configPath);
" 2>"$NODE_ERR_FILE"; then
    :
else
    echo "   ❌ 社区 MCP 配置写入失败"
    if [ -s "$NODE_ERR_FILE" ]; then
        echo "      错误详情: $(head -3 "$NODE_ERR_FILE")"
    fi
    echo "      请检查文件权限后重试: ${MCPORTER_CONFIG}"
    rm -f "$NODE_ERR_FILE"
    exit 1
fi
rm -f "$NODE_ERR_FILE"

MCPORTER_CONFIGURED=true
echo ""

# ============================================================
# Step 5: Official MCP (optional) (AC-1.1.5)
# ============================================================

echo "📋 [5/7] 官方 MCP (可选)..."
echo ""

INSTALL_OFFICIAL=false

if [ "$FLAG_NO_INTERACTIVE" = true ]; then
    echo "   ⏭️  非交互模式，跳过官方 MCP"
    echo "   稍后安装: npx -y @larksuiteoapi/lark-mcp login -a <APP_ID> -s <APP_SECRET>"
else
    printf "   是否安装官方 lark-mcp？(多维表格/搜索/知识库能力) [y/N]: "
    read -r OFFICIAL_ANSWER || true
    OFFICIAL_ANSWER="$(trim "${OFFICIAL_ANSWER:-N}")"

    case "$OFFICIAL_ANSWER" in
        y|Y|yes|YES|是)
            INSTALL_OFFICIAL=true
            ;;
        *)
            INSTALL_OFFICIAL=false
            ;;
    esac
fi

if [ "$INSTALL_OFFICIAL" = true ]; then
    echo ""
    echo "   📦 添加官方 MCP 配置..."

    # Add official MCP entries to mcporter config
    # Credentials passed via environment variables to avoid injection (HIGH-1)
    NODE_ERR_FILE="$(mktemp /tmp/feishu-node-err.XXXXXX)"
    if FEISHU_APP_ID="$APP_ID" FEISHU_APP_SECRET="$APP_SECRET" \
       FEISHU_CONFIG_PATH="$MCPORTER_CONFIG" node -e "
    var fs = require('fs');
    var configPath = process.env.FEISHU_CONFIG_PATH;
    var appId = process.env.FEISHU_APP_ID;
    var appSecret = process.env.FEISHU_APP_SECRET;

    var config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    if (!config.mcpServers) config.mcpServers = {};

    // Official lark-mcp — app identity (bitable, messaging)
    config.mcpServers.lark = {
        command: 'npx',
        args: ['-y', '@larksuiteoapi/lark-mcp', 'mcp', '-a', appId, '-s', appSecret]
    };

    // Official lark-mcp — user identity (search, wiki)
    config.mcpServers['lark-user'] = {
        command: 'npx',
        args: ['-y', '@larksuiteoapi/lark-mcp', 'mcp', '-a', appId, '-s', appSecret,
               '--oauth', '--token-mode', 'user_access_token']
    };

    fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
    console.log('   ✅ 官方 MCP 配置已添加');
    " 2>"$NODE_ERR_FILE"; then
        :
    else
        echo "   ❌ 官方 MCP 配置写入失败"
        if [ -s "$NODE_ERR_FILE" ]; then
            echo "      错误详情: $(head -3 "$NODE_ERR_FILE")"
        fi
        echo "      请手动添加: npx -y @larksuiteoapi/lark-mcp login -a <APP_ID> -s <APP_SECRET>"
    fi
    rm -f "$NODE_ERR_FILE"

    echo "   🔑 正在进行官方 MCP 授权..."
    npx -y @larksuiteoapi/lark-mcp login -a "$APP_ID" -s "$APP_SECRET" || echo "   ⚠️  官方 MCP 授权跳过（可稍后手动完成: npx -y @larksuiteoapi/lark-mcp login）"

    OFFICIAL_MCP_CONFIGURED=true
else
    echo "   ⏭️  跳过官方 MCP"
    echo "   稍后安装: 重新运行此脚本，或手动添加到 mcporter 配置"
fi

echo ""

# ============================================================
# Step 6: Auth configuration (AC-1.1.6, E-10)
# ============================================================

echo "📋 [6/7] 认证配置..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 请在飞书开放平台配置重定向 URL"
echo ""
echo "   打开: https://open.feishu.cn/app/${APP_ID}/safe"
echo ""
echo "   添加以下重定向 URL："

if [ "$CLI_INSTALLED" = true ]; then
    echo "   • http://localhost:3000/callback  (飞书 CLI)"
fi
echo "   • http://localhost:3333/callback  (社区 MCP)"

if [ "$OFFICIAL_MCP_CONFIGURED" = true ]; then
    echo "   • http://localhost:3000/callback  (官方 MCP)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$FLAG_NO_INTERACTIVE" = false ]; then
    printf "   配置完成后按 Enter 继续..."
    read -r _PAUSE || true
fi

echo ""

# CLI auth (only if CLI was installed)
if [ "$CLI_INSTALLED" = true ]; then
    if [ "$FLAG_NO_INTERACTIVE" = false ]; then
        echo "   🔑 初始化 CLI 配置..."
        if lark-cli config init --new 2>/dev/null; then
            echo "   ✅ CLI 配置初始化成功"
        else
            echo "   ⚠️  CLI 配置初始化失败"
            echo "      手动执行: lark-cli config init --new"
        fi

        echo ""
        echo "   🔑 CLI OAuth 登录（浏览器将自动打开）..."
        echo "   如果 10 秒内浏览器未打开，请手动访问终端中显示的 URL"
        echo ""

        # Trap Ctrl+C to provide friendly skip message
        trap trap_ctrlc INT
        if lark-cli auth login --recommend 2>/dev/null; then
            echo "   ✅ CLI 认证成功"
        else
            echo "   ⚠️  CLI 认证未完成"
            echo "      手动执行: lark-cli auth login --recommend"
        fi
        # Restore default trap
        trap cleanup_on_error EXIT
        trap - INT
    else
        echo "   ⏭️  非交互模式，跳过 CLI 认证"
        echo "      请稍后手动执行认证:"
        echo "      lark-cli config init --new"
        echo "      lark-cli auth login --recommend"
    fi
fi

echo ""
echo "   📝 社区 MCP 会在首次使用时自动引导 OAuth 授权"
echo ""

# ============================================================
# Step 7: Platform detection and config generation (AC-1.1.7, E-9)
# ============================================================

echo "📋 [7/7] 检测 AI 平台并生成配置..."
echo ""

# Ensure configs/ directory in project exists for portable templates
mkdir -p "${SCRIPT_DIR}/configs"

# Platform detection functions
detect_openclaw() {
    if command -v openclaw >/dev/null 2>&1; then
        return 0
    fi
    if [ -d "${HOME}/.openclaw" ] || [ -d "${HOME}/.config/openclaw" ]; then
        return 0
    fi
    return 1
}

detect_claude_code() {
    if command -v claude >/dev/null 2>&1; then
        return 0
    fi
    if [ -d "${HOME}/.claude" ]; then
        return 0
    fi
    return 1
}

detect_cursor() {
    if [ -d "${HOME}/.cursor" ]; then
        return 0
    fi
    # macOS app check
    if [ "$DETECTED_OS" = "darwin" ] && [ -d "/Applications/Cursor.app" ]; then
        return 0
    fi
    # Linux common locations
    if [ "$DETECTED_OS" = "linux" ]; then
        if command -v cursor >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# Generate personalized config for a platform using Node.js
# Args: $1=platform_name, $2=output_path, $3=template_path
generate_platform_config() {
    local platform="$1"
    local output_path="$2"
    local template_path="$3"

    # Check if output already exists (and not --force)
    if [ -f "$output_path" ] && [ "$FLAG_FORCE" = false ]; then
        if [ "$FLAG_NO_INTERACTIVE" = true ]; then
            echo "   ⏭️  ${platform} 配置已存在，跳过: ${output_path}"
            return 0
        fi
        printf "   ${platform} 配置已存在，是否覆盖？ [y/N]: "
        read -r OVERWRITE_ANSWER || true
        OVERWRITE_ANSWER="$(trim "${OVERWRITE_ANSWER:-N}")"
        case "$OVERWRITE_ANSWER" in
            y|Y|yes|YES|是) ;;
            *)
                echo "   ⏭️  跳过 ${platform} 配置"
                return 0
                ;;
        esac
    fi

    # Ensure output directory exists
    mkdir -p "$(dirname "$output_path")"

    # Generate config by MERGING feishu entry into existing file (BLOCKER-1 fix)
    # Credentials passed via environment variables to avoid injection (HIGH-1)
    NODE_ERR_FILE="$(mktemp /tmp/feishu-node-err.XXXXXX)"
    if FEISHU_APP_ID="$APP_ID" FEISHU_APP_SECRET="$APP_SECRET" \
       FEISHU_TEMPLATE_PATH="$template_path" FEISHU_OUTPUT_PATH="$output_path" node -e "
    var fs = require('fs');
    var templatePath = process.env.FEISHU_TEMPLATE_PATH;
    var outputPath = process.env.FEISHU_OUTPUT_PATH;
    var appId = process.env.FEISHU_APP_ID;
    var appSecret = process.env.FEISHU_APP_SECRET;

    // Read template to get the feishu entry structure
    var template = JSON.parse(fs.readFileSync(templatePath, 'utf8'));

    // Read existing output file if present — preserve other entries
    var config = {};
    if (fs.existsSync(outputPath)) {
        try {
            config = JSON.parse(fs.readFileSync(outputPath, 'utf8'));
        } catch(e) {
            // Malformed JSON — back up and start fresh
            var timestamp = Date.now();
            var backupPath = outputPath + '.bak.' + timestamp;
            fs.renameSync(outputPath, backupPath);
            console.log('   ⚠️  现有配置文件格式错误，已备份到: ' + backupPath);
            config = {};
        }
    }

    if (!config.mcpServers) config.mcpServers = {};

    // Merge feishu entry from template (with credentials filled in)
    if (template.mcpServers && template.mcpServers.feishu) {
        var feishuEntry = JSON.parse(JSON.stringify(template.mcpServers.feishu));
        if (feishuEntry.env) {
            feishuEntry.env.FEISHU_APP_ID = appId;
            feishuEntry.env.FEISHU_APP_SECRET = appSecret;
        }
        config.mcpServers.feishu = feishuEntry;
    }

    fs.writeFileSync(outputPath, JSON.stringify(config, null, 2));
    " 2>"$NODE_ERR_FILE"; then
        echo "   ✅ ${platform} 配置已生成: ${output_path}"
    else
        echo "   ❌ ${platform} 配置生成失败"
        if [ -s "$NODE_ERR_FILE" ]; then
            echo "      错误详情: $(head -3 "$NODE_ERR_FILE")"
        fi
        echo "      请检查文件权限后重试: ${output_path}"
    fi
    rm -f "$NODE_ERR_FILE"
}

# Determine which platforms to configure
PLATFORM_LIST=""

if [ -n "$FLAG_PLATFORM" ]; then
    # Manual platform specification
    PLATFORM_LIST="$FLAG_PLATFORM"
    echo "   📋 手动指定平台: ${FLAG_PLATFORM}"
else
    # Auto-detect platforms
    if detect_openclaw; then
        PLATFORM_LIST="${PLATFORM_LIST} openclaw"
        DETECTED_PLATFORMS="${DETECTED_PLATFORMS}OpenClaw "
        echo "   🔍 检测到 OpenClaw"
    fi
    if detect_claude_code; then
        PLATFORM_LIST="${PLATFORM_LIST} claude-code"
        DETECTED_PLATFORMS="${DETECTED_PLATFORMS}Claude-Code "
        echo "   🔍 检测到 Claude Code"
    fi
    if detect_cursor; then
        PLATFORM_LIST="${PLATFORM_LIST} cursor"
        DETECTED_PLATFORMS="${DETECTED_PLATFORMS}Cursor "
        echo "   🔍 检测到 Cursor"
    fi

    if [ -z "$PLATFORM_LIST" ]; then
        echo "   📋 未检测到已安装的 AI 平台"
    fi
fi

echo ""

# Generate configs for detected/specified platforms
for platform in $PLATFORM_LIST; do
    case "$platform" in
        openclaw)
            # OpenClaw: generate in project configs/ and inform user
            generate_platform_config "OpenClaw" \
                "${SCRIPT_DIR}/configs/openclaw-configured.json" \
                "${SCRIPT_DIR}/configs/openclaw.json"
            echo "      💡 请将配置导入 OpenClaw 或复制到 OpenClaw 配置目录"
            ;;
        claude-code)
            # Claude Code: generate to ~/.claude/
            CLAUDE_MCP_DIR="${HOME}/.claude"
            mkdir -p "$CLAUDE_MCP_DIR"
            generate_platform_config "Claude Code" \
                "${CLAUDE_MCP_DIR}/mcp.json" \
                "${SCRIPT_DIR}/configs/claude-code.json"
            ;;
        cursor)
            # Cursor: generate to ~/.cursor/mcp.json
            CURSOR_DIR="${HOME}/.cursor"
            mkdir -p "$CURSOR_DIR"
            generate_platform_config "Cursor" \
                "${CURSOR_DIR}/mcp.json" \
                "${SCRIPT_DIR}/configs/cursor.json"
            ;;
        *)
            echo "   ⚠️  未知平台: ${platform}"
            echo "      支持的平台: openclaw, claude-code, cursor"
            ;;
    esac
done

# Always generate portable templates in project configs/ directory
echo ""
echo "   📁 便携配置模板已保存在: ${SCRIPT_DIR}/configs/"
echo "      openclaw.json, claude-code.json, cursor.json"
echo ""

# ============================================================
# Validation and summary (AC-1.1.9)
# ============================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 安装摘要"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# CLI auth status check
if [ "$CLI_INSTALLED" = true ]; then
    AUTH_STATUS="$(lark-cli auth status 2>/dev/null || echo "未认证")"
    echo "   飞书 CLI:    ✅ 已安装 (${CLI_VERSION})"
    echo "   CLI 认证:    ${AUTH_STATUS}"
else
    echo "   飞书 CLI:    ❌ 未安装"
    if [ "$FLAG_MCP_ONLY" = true ]; then
        echo "                (--mcp-only 模式，已跳过)"
    else
        echo "                安装方法: npm install -g @larksuite/cli"
    fi
fi

if [ "$MCPORTER_CONFIGURED" = true ]; then
    echo "   社区 MCP:    ✅ 已配置"
else
    echo "   社区 MCP:    ❌ 未配置"
fi

if [ "$INSTALL_OFFICIAL" = true ] && [ "$OFFICIAL_MCP_CONFIGURED" = true ]; then
    echo "   官方 MCP:    ✅ 已配置"
elif [ "$INSTALL_OFFICIAL" = true ]; then
    echo "   官方 MCP:    ⚠️  配置不完整"
else
    echo "   官方 MCP:    ⏭️  已跳过"
fi

echo "   配置文件:    ${MCPORTER_CONFIG}"

if [ -n "$DETECTED_PLATFORMS" ]; then
    echo "   平台配置:    ${DETECTED_PLATFORMS}"
else
    echo "   平台配置:    便携模板 (${SCRIPT_DIR}/configs/)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 配置完成！"
echo ""
echo "试试以下命令："
echo ""

if [ "$CLI_INSTALLED" = true ]; then
    echo "  # 搜索文档"
    echo "  lark-cli doc +search --keyword '会议纪要'"
    echo ""
fi

echo "  # 创建文档（社区 MCP）"
echo "  mcporter call feishu.create_feishu_document --args '{\"title\":\"测试文档\"}'"
echo ""

if [ "$CLI_INSTALLED" = true ]; then
    echo "  # 查看日历"
    echo "  lark-cli calendar +agenda"
    echo ""
fi

echo "📚 完整文档: https://github.com/AlexAnys/feishu-mcp"
echo ""
