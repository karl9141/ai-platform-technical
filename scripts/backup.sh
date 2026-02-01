#!/bin/bash
# =============================================================================
# AI 平台数据备份脚本
# =============================================================================

set -e

BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "╔═══════════════════════════════════════════╗"
echo "║     AI Platform Backup Script             ║"
echo "╚═══════════════════════════════════════════╝"
echo "备份目录: $BACKUP_DIR"

# 备份 PostgreSQL
echo "[1/3] 备份 PostgreSQL..."
docker exec ai-platform-postgres pg_dumpall -U postgres > "$BACKUP_DIR/postgres_dump.sql"
echo "✅ PostgreSQL 备份完成"

# 备份 N8N 数据
echo "[2/3] 备份 N8N 数据..."
docker run --rm \
    -v ai_platform_n8n:/data \
    -v "$(pwd)/$BACKUP_DIR":/backup \
    alpine tar czf /backup/n8n_data.tar.gz /data
echo "✅ N8N 数据备份完成"

# 备份 Dify 存储
echo "[3/3] 备份 Dify 存储..."
docker run --rm \
    -v ai_platform_dify_storage:/data \
    -v "$(pwd)/$BACKUP_DIR":/backup \
    alpine tar czf /backup/dify_storage.tar.gz /data
echo "✅ Dify 存储备份完成"

echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║     ✅ 备份完成!                          ║"
echo "╚═══════════════════════════════════════════╝"
echo "备份文件:"
ls -la "$BACKUP_DIR"
