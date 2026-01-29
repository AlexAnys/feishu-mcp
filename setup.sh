#!/bin/bash
# feishu-mcp 一键配置脚本

set -e

echo "🚀 飞书 MCP 配置向导"
echo ""

# 检查 mcporter
if ! command -v mcporter &> /dev/null; then
    echo "📦 安装 mcporter..."
    npm install -g mcporter
fi

# 获取凭证
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "请输入飞书应用凭证："
    read -p "App ID (cli_xxx): " APP_ID
    read -p "App Secret: " APP_SECRET
else
    APP_ID=$1
    APP_SECRET=$2
fi

if [ -z "$APP_ID" ] || [ -z "$APP_SECRET" ]; then
    echo "❌ 缺少 App ID 或 App Secret"
    exit 1
fi

# 确定配置文件路径
if [ -f "./config/mcporter.json" ]; then
    CONFIG_PATH="./config/mcporter.json"
elif [ -f "$HOME/.config/mcporter/config.json" ]; then
    CONFIG_PATH="$HOME/.config/mcporter/config.json"
else
    mkdir -p ./config
    CONFIG_PATH="./config/mcporter.json"
    echo '{"mcpServers":{}}' > "$CONFIG_PATH"
fi

echo ""
echo "📝 配置文件: $CONFIG_PATH"

# 使用 node 更新 JSON（避免 jq 依赖）
node -e "
const fs = require('fs');
const path = '$CONFIG_PATH';
const appId = '$APP_ID';
const appSecret = '$APP_SECRET';

let config = {};
try {
    config = JSON.parse(fs.readFileSync(path, 'utf8'));
} catch(e) {
    config = { mcpServers: {} };
}

if (!config.mcpServers) config.mcpServers = {};

config.mcpServers.feishu = {
    command: 'npx',
    args: ['-y', '@larksuiteoapi/lark-mcp', 'mcp', '-a', appId, '-s', appSecret]
};

config.mcpServers['feishu-user'] = {
    command: 'npx',
    args: ['-y', '@larksuiteoapi/lark-mcp', 'mcp', '-a', appId, '-s', appSecret, '--oauth', '--token-mode', 'user_access_token']
};

fs.writeFileSync(path, JSON.stringify(config, null, 2));
console.log('✅ MCP 配置已写入');
"

echo ""
echo "📋 当前配置的 MCP 服务："
mcporter config list 2>/dev/null | grep -E "^(feishu|  )" || echo "  feishu, feishu-user"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 接下来进行用户授权（访问个人文档需要）"
echo ""
echo "⚠️  请先确保已在飞书开放平台配置回调地址："
echo "   https://open.feishu.cn/app/${APP_ID}/safe"
echo "   添加: http://localhost:3000/callback"
echo ""
read -p "已配置好回调地址？按 Enter 继续授权..."

echo ""
echo "🌐 正在打开授权页面..."
npx -y @larksuiteoapi/lark-mcp login -a "$APP_ID" -s "$APP_SECRET"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 配置完成！"
echo ""
echo "测试命令："
echo "  mcporter call feishu-user.docx_builtin_search --args '{\"data\":{\"search_key\":\"测试\",\"count\":3}}'"
echo ""
