#!/bin/bash
# =============================================================================
# 数据库备份脚本
# =============================================================================

set -e

BACKUP_DIR="${BACKUP_DIR:-./backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "➜ 开始备份..."

# PostgreSQL 备份
echo "  备份 PostgreSQL..."
docker exec ai-platform-postgres pg_dumpall -U postgres > "$BACKUP_DIR/postgres_$TIMESTAMP.sql"

echo "✓ 备份完成: $BACKUP_DIR/postgres_$TIMESTAMP.sql"
