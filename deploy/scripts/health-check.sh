#!/bin/bash
# =============================================================================
# 健康检查脚本
# =============================================================================

echo "AI Platform 健康状态"
echo "===================="
echo ""

services=("postgres" "redis" "weaviate" "dify-api" "dify-web" "n8n" "nginx")

for svc in "${services[@]}"; do
    status=$(docker inspect "ai-platform-$svc" --format='{{.State.Health.Status}}' 2>/dev/null || echo "not running")
    if [ "$status" = "healthy" ]; then
        echo "✓ $svc: $status"
    else
        echo "✗ $svc: $status"
    fi
done

echo ""
echo "详细状态:"
docker compose ps
