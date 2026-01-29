#!/bin/bash
# feishu-mcp 一键配置脚本
# 整合社区版 feishu-mcp + 官方 lark-mcp

set -e

echo "🚀 飞书 MCP 全能配置向导"
echo "   整合文档编辑 + 多维表格 + 搜索能力"
echo ""

# 检查 node
if ! command -v node &> /dev/null; then
    echo "❌ 需要先安装 Node.js: https://nodejs.org"
    exit 1
fi

# 检查/安装 mcporter
if ! command -v mcporter &> /dev/null; then
    echo "📦 安装 mcporter..."
    npm install -g mcporter
fi

# 获取凭证
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "请输入飞书应用凭证（在 open.feishu.cn 获取）："
    echo ""
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
if [ -d "./config" ]; then
    CONFIG_PATH="./config/mcporter.json"
elif [ -d "$HOME/.config/mcporter" ]; then
    CONFIG_PATH="$HOME/.config/mcporter/config.json"
else
    mkdir -p ./config
    CONFIG_PATH="./config/mcporter.json"
fi

# 初始化配置文件
if [ ! -f "$CONFIG_PATH" ]; then
    echo '{"mcpServers":{}}' > "$CONFIG_PATH"
fi

echo ""
echo "📝 配置文件: $CONFIG_PATH"

# 写入配置
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

// 社区版 feishu-mcp - 文档创建/编辑能力
config.mcpServers.feishu = {
    command: 'npx',
    args: ['-y', 'feishu-mcp@latest', '--stdio'],
    env: {
        FEISHU_APP_ID: appId,
        FEISHU_APP_SECRET: appSecret,
        FEISHU_AUTH_TYPE: 'user'
    }
};

// 官方 lark-mcp - 多维表格/搜索（应用身份）
config.mcpServers.lark = {
    command: 'npx',
    args: ['-y', '@larksuiteoapi/lark-mcp', 'mcp', '-a', appId, '-s', appSecret]
};

// 官方 lark-mcp - 搜索/知识库（用户身份）
config.mcpServers['lark-user'] = {
    command: 'npx',
    args: ['-y', '@larksuiteoapi/lark-mcp', 'mcp', '-a', appId, '-s', appSecret, '--oauth', '--token-mode', 'user_access_token']
};

fs.writeFileSync(path, JSON.stringify(config, null, 2));
console.log('✅ MCP 配置已写入');
console.log('');
console.log('已配置的服务：');
console.log('  • feishu     - 文档创建/编辑/图表（社区版）');
console.log('  • lark       - 多维表格/消息（官方-应用身份）');
console.log('  • lark-user  - 搜索/知识库（官方-用户身份）');
"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 接下来进行用户授权"
echo ""
echo "⚠️  请先确保已在飞书开放平台配置："
echo "   https://open.feishu.cn/app/${APP_ID}/safe"
echo ""
echo "   添加重定向 URL:"
echo "   • http://localhost:3000/callback  (官方 MCP)"
echo "   • http://localhost:3333/callback  (社区 MCP)"
echo ""
read -p "已配置好？按 Enter 继续..."

echo ""
echo "🔑 [1/2] 官方 lark-mcp 授权..."
npx -y @larksuiteoapi/lark-mcp login -a "$APP_ID" -s "$APP_SECRET" || echo "⚠️ 官方授权跳过（可稍后手动完成）"

echo ""
echo "🔑 [2/2] 社区 feishu-mcp 授权..."
echo "   社区版会在首次使用时自动引导授权"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 配置完成！"
echo ""
echo "测试命令："
echo ""
echo "  # 搜索文档"
echo "  mcporter call lark-user.docx_builtin_search --args '{\"data\":{\"search_key\":\"会议\",\"count\":3}}'"
echo ""
echo "  # 创建文档（社区版）"
echo "  mcporter call feishu.create_feishu_document --args '{\"title\":\"测试文档\",\"folderToken\":\"根目录token\"}'"
echo ""
echo "  # 创建多维表格"
echo "  mcporter call lark.bitable_v1_app_create --args '{\"data\":{\"name\":\"测试表格\"}}'"
echo ""
echo "📚 完整文档: https://github.com/AlexAnys/feishu-mcp"
echo ""
