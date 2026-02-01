# AI Platform - 一键部署方案

## 📋 概述

本方案提供完整的一键部署能力，同时确保每个服务都是**生产级标准**、**可独立运维**的。

---

## 🏗️ 架构组件

| 服务 | 端口 | 用途 | 独立运维 |
|------|------|------|----------|
| **PostgreSQL** | 5432 | 共享数据库 | ✅ |
| **Redis** | 6379 | 缓存/队列 | ✅ |
| **Weaviate** | 8080 | 向量数据库 | ✅ |
| **N8N** | 5678 | 工作流引擎 | ✅ |
| **Dify API** | 5001 | AI 应用后端 | ✅ |
| **Dify Worker** | - | 后台任务 | ✅ |
| **Dify Web** | 3000 | 前端界面 | ✅ |
| **Nginx** | 80/3000 | 反向代理 | ✅ |

---

## 🚀 一键部署

### Windows

```powershell
cd deploy\infrastructure
.\deploy.ps1
```

### Linux/macOS

```bash
cd deploy/infrastructure
chmod +x deploy.sh
./deploy.sh
```

---

## 📁 目录结构

```
deploy/infrastructure/
├── docker-compose.yml      # 主配置文件
├── .env.example            # 环境变量模板
├── .env                    # 环境变量（自动生成）
├── deploy.ps1              # Windows 部署脚本
├── deploy.sh               # Linux/macOS 部署脚本
├── init-scripts/           # 数据库初始化
│   └── 01-init-db.sql
├── nginx/                  # Nginx 配置
│   ├── nginx.conf
│   └── conf.d/
│       └── default.conf
├── n8n/                    # N8N 配置
│   └── workflows/          # 工作流备份
└── backup/                 # 备份目录
```

---

## ⚙️ 配置说明

### 环境变量 (`.env`)

```bash
# 数据库
POSTGRES_USER=postgres
POSTGRES_PASSWORD=你的安全密码

# Redis
REDIS_PASSWORD=你的安全密码

# N8N
N8N_ENCRYPTION_KEY=32位加密密钥
WEBHOOK_URL=http://你的域名:5678/

# Dify
DIFY_SECRET_KEY=sk-32位密钥

# 时区
TIMEZONE=Asia/Tokyo
```

---

## 🔧 运维命令

### 服务管理

| 操作 | Windows | Linux/macOS |
|------|---------|-------------|
| 启动 | `.\deploy.ps1 -Action start` | `./deploy.sh start` |
| 停止 | `.\deploy.ps1 -Action stop` | `./deploy.sh stop` |
| 重启 | `.\deploy.ps1 -Action restart` | `./deploy.sh restart` |
| 状态 | `.\deploy.ps1 -Action status` | `./deploy.sh status` |
| 日志 | `.\deploy.ps1 -Action logs` | `./deploy.sh logs` |
| 备份 | `.\deploy.ps1 -Action backup` | `./deploy.sh backup` |
| 清理 | `.\deploy.ps1 -Action clean` | `./deploy.sh clean` |

### 单服务操作

```bash
# 查看单个服务日志
docker logs -f ai-platform-n8n

# 重启单个服务
docker restart ai-platform-dify-api

# 进入容器
docker exec -it ai-platform-postgres psql -U postgres
```

---

## ✅ 生产级特性

### 1. 健康检查

每个服务都配置了健康检查：

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:5001/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 60s
```

### 2. 资源限制

```yaml
deploy:
  resources:
    limits:
      memory: 2G
    reservations:
      memory: 1G
```

### 3. 日志管理

```yaml
logging:
  driver: "json-file"
  options:
    max-size: "50m"
    max-file: "5"
```

### 4. 自动重启

```yaml
restart: unless-stopped
```

### 5. 依赖管理

```yaml
depends_on:
  postgres:
    condition: service_healthy
```

### 6. 数据持久化

```yaml
volumes:
  postgres_data:
    name: ai-platform-postgres-data
```

---

## 📊 资源需求

| 配置 | 最低 | 推荐 |
|------|------|------|
| **CPU** | 4 核 | 8 核 |
| **内存** | 8 GB | 16 GB |
| **磁盘** | 20 GB | 50 GB |

### 服务内存分配

| 服务 | 限制 | 预留 |
|------|------|------|
| PostgreSQL | 512 MB | 256 MB |
| Redis | 256 MB | 128 MB |
| Weaviate | 1 GB | 512 MB |
| N8N | 1 GB | 512 MB |
| Dify API | 2 GB | 1 GB |
| Dify Worker | 1 GB | 512 MB |
| Dify Web | 512 MB | 256 MB |
| Nginx | 128 MB | 64 MB |
| **总计** | **~6.5 GB** | **~3.2 GB** |

---

## 🔐 安全配置

### 1. 密码强度

- 所有密码使用随机生成的 32 位字符串
- 部署脚本自动生成安全密钥

### 2. 网络隔离

```yaml
networks:
  ai-platform-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.28.0.0/16
```

### 3. 生产环境建议

1. **修改默认密码**: 编辑 `.env` 文件
2. **启用 HTTPS**: 配置 SSL 证书
3. **限制端口**: 仅暴露必要端口
4. **定期备份**: 使用 `backup` 命令

---

## 💾 备份恢复

### 备份

```bash
# 自动备份
./deploy.sh backup

# 手动备份 PostgreSQL
docker exec ai-platform-postgres pg_dumpall -U postgres > backup/pg_dump.sql
```

### 恢复

```bash
# 恢复数据库
cat backup/pg_dump.sql | docker exec -i ai-platform-postgres psql -U postgres
```

---

## 🔍 故障排查

### 常见问题

| 问题 | 解决方案 |
|------|----------|
| 端口占用 | 修改 `.env` 中的端口配置 |
| 内存不足 | 增加 Docker Desktop 内存限制 |
| 启动失败 | 查看日志: `docker logs ai-platform-xxx` |
| 网络问题 | 重建网络: `docker network prune` |

### 日志位置

| 服务 | 日志命令 |
|------|----------|
| 全部 | `docker-compose logs -f` |
| N8N | `docker logs -f ai-platform-n8n` |
| Dify | `docker logs -f ai-platform-dify-api` |
| PostgreSQL | `docker logs -f ai-platform-postgres` |

---

## 🔄 升级流程

```bash
# 1. 备份数据
./deploy.sh backup

# 2. 拉取新镜像
docker-compose pull

# 3. 重新部署
docker-compose up -d

# 4. 验证服务
./deploy.sh status
```

---

## 📞 访问地址

部署完成后：

| 服务 | URL | 说明 |
|------|-----|------|
| **N8N** | http://localhost:5678 | 工作流管理 |
| **Dify** | http://localhost:3000 | AI 应用平台 |
| **PostgreSQL** | localhost:5432 | 数据库 |
| **Redis** | localhost:6379 | 缓存 |
| **Weaviate** | http://localhost:8080 | 向量数据库 |
