#!/bin/bash
# =============================================================================
# AI Platform 一键部署脚本 (Linux/macOS)
# =============================================================================
#
# 使用方法:
#   ./deploy.sh [start|stop|restart|status|logs|clean|backup]
#
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 输出函数
title() { echo -e "\n${CYAN}$1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║     🤖 AI Platform - One-Click Deployment                ║"
    echo "║                                                           ║"
    echo "║     N8N + Dify + PostgreSQL + Redis + Weaviate          ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 检查 Docker
check_docker() {
    title "检查 Docker 环境..."
    
    if ! command -v docker &> /dev/null; then
        error "Docker 未安装，请先安装 Docker"
    fi
    
    if ! docker info &> /dev/null; then
        error "Docker 未启动，请先启动 Docker"
    fi
    success "Docker 运行正常"
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        error "Docker Compose 未安装"
    fi
    success "Docker Compose 可用"
}

# 初始化环境
init_environment() {
    title "初始化环境配置..."
    
    # 创建 .env 文件
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            cp .env.example .env
            
            # 生成随机密钥
            RANDOM_KEY=$(openssl rand -hex 16)
            sed -i.bak "s/your-32-char-encryption-key-here/$RANDOM_KEY/g" .env
            sed -i.bak "s/sk-your-dify-secret-key-at-least-32-chars/sk-$RANDOM_KEY/g" .env
            rm -f .env.bak
            
            success "已创建 .env 配置文件（密钥已自动生成）"
        else
            warning ".env.example 不存在，使用默认配置"
        fi
    else
        info ".env 文件已存在，跳过初始化"
    fi
    
    # 创建必要目录
    mkdir -p backup n8n/workflows
    success "目录结构已就绪"
}

# 启动服务
start_services() {
    title "启动 AI Platform 服务..."
    
    info "拉取最新镜像..."
    docker-compose pull
    
    info "启动服务容器..."
    docker-compose up -d
    
    info "等待服务启动..."
    sleep 30
    
    show_status
    
    echo ""
    success "AI Platform 部署完成!"
    echo ""
    echo -e "${YELLOW}  📊 访问地址:${NC}"
    echo "     N8N:  http://localhost:5678"
    echo "     Dify: http://localhost:3000"
    echo ""
    echo -e "${YELLOW}  📝 首次使用:${NC}"
    echo "     1. 访问 Dify 创建管理员账户"
    echo "     2. 配置 OpenAI API Key"
    echo "     3. 访问 N8N 创建工作流"
    echo ""
}

# 停止服务
stop_services() {
    title "停止 AI Platform 服务..."
    docker-compose stop
    success "服务已停止"
}

# 重启服务
restart_services() {
    title "重启 AI Platform 服务..."
    docker-compose restart
    success "服务已重启"
}

# 显示状态
show_status() {
    title "服务状态"
    docker-compose ps
}

# 查看日志
show_logs() {
    title "查看日志 (Ctrl+C 退出)"
    docker-compose logs -f --tail=100
}

# 清理环境
clean_environment() {
    title "清理 AI Platform 环境..."
    
    read -p "确定要清理所有数据吗? (输入 'yes' 确认): " confirm
    if [ "$confirm" != "yes" ]; then
        warning "操作已取消"
        exit 0
    fi
    
    docker-compose down -v --remove-orphans
    success "环境已清理"
}

# 备份数据
backup_data() {
    title "备份数据..."
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_DIR="backup/$TIMESTAMP"
    mkdir -p "$BACKUP_DIR"
    
    info "备份 PostgreSQL..."
    docker exec ai-platform-postgres pg_dumpall -U postgres > "$BACKUP_DIR/postgres_dump.sql"
    
    success "备份完成: $BACKUP_DIR"
}

# 主程序
show_banner

ACTION=${1:-start}

case "$ACTION" in
    start)
        check_docker
        init_environment
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    clean)
        clean_environment
        ;;
    backup)
        backup_data
        ;;
    *)
        echo "使用方法: $0 [start|stop|restart|status|logs|clean|backup]"
        exit 1
        ;;
esac
