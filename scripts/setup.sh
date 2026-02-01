#!/bin/bash
# =============================================================================
# AI 平台环境初始化脚本
# =============================================================================

set -e

echo "╔═══════════════════════════════════════════╗"
echo "║     AI Platform Setup Script              ║"
echo "╚═══════════════════════════════════════════╝"

# 检查 Docker
echo "[1/4] 检查 Docker..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker"
    exit 1
fi
echo "✅ Docker 已安装: $(docker --version)"

# 检查 Docker Compose
echo "[2/4] 检查 Docker Compose..."
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose 未安装"
    exit 1
fi
echo "✅ Docker Compose 已安装"

# 创建 .env 文件
echo "[3/4] 创建配置文件..."
if [ ! -f "deploy/infrastructure/.env" ]; then
    cat > deploy/infrastructure/.env << 'EOF'
# AI Platform Configuration
POSTGRES_USER=postgres
POSTGRES_PASSWORD=ai_platform_2026
REDIS_PASSWORD=ai_platform_2026
DIFY_SECRET_KEY=sk-$(openssl rand -hex 16)
N8N_HOST=localhost
N8N_WEBHOOK_URL=http://localhost:5678/
TIMEZONE=Asia/Tokyo
EOF
    echo "✅ 已创建 .env 配置文件"
else
    echo "⚠️  .env 文件已存在，跳过"
fi

# 启动服务
echo "[4/4] 启动服务..."
cd deploy/infrastructure
docker-compose up -d

echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║     ✅ 部署完成!                          ║"
echo "╚═══════════════════════════════════════════╝"
echo ""
echo "访问地址:"
echo "  N8N:  http://localhost:5678"
echo "  Dify: http://localhost:3000"
echo ""
