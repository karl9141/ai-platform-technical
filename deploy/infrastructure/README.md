# AI 平台一键部署

一键部署完整的 AI 辅助平台环境。

## 包含组件

| 组件 | 端口 | 说明 |
|------|------|------|
| N8N | 5678 | 工作流引擎 |
| Dify | 3000 | AI 应用平台 |
| PostgreSQL | 5432 | 数据库 |
| Redis | 6379 | 缓存 |
| Weaviate | 8080 | 向量数据库 |
| Nginx | 80 | 反向代理 |

## 系统要求

- Docker & Docker Compose
- 8GB+ RAM (推荐)
- 20GB+ 磁盘空间

## 快速启动

```bash
# 启动所有服务
docker-compose up -d

# 查看状态
docker-compose ps
```

## 访问地址

| 服务 | URL |
|------|-----|
| N8N | http://localhost:5678 |
| Dify | http://localhost:3000 |

## 配置

### 使用 .env 文件

创建 `.env` 文件自定义配置：

```env
# 数据库
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your-secure-password

# Redis
REDIS_PASSWORD=your-secure-password

# Dify
DIFY_SECRET_KEY=your-secret-key

# N8N
N8N_HOST=your-domain.com
N8N_WEBHOOK_URL=https://your-domain.com/

# 时区
TIMEZONE=Asia/Tokyo
```

## 初次设置

### 1. N8N 设置

1. 访问 http://localhost:5678
2. 创建管理员账户
3. 配置凭据（Lark、Jira 等）

### 2. Dify 设置

1. 访问 http://localhost:3000
2. 创建管理员账户
3. 设置 → 模型供应商 → 添加 OpenAI API Key
4. 创建 AI 应用

### 3. 集成 N8N + Dify

1. 在 Dify 中创建应用，获取 API Key
2. 在 N8N 中创建 HTTP Request 节点
3. 配置调用 Dify API

## 常用命令

```bash
# 启动
docker-compose up -d

# 停止
docker-compose down

# 重启
docker-compose restart

# 查看日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f n8n
docker-compose logs -f dify-api
```

## 数据备份

```bash
# 备份数据库
docker exec ai-platform-postgres pg_dumpall -U postgres > backup.sql

# 备份卷
docker run --rm -v ai_platform_postgres:/data -v $(pwd):/backup alpine tar czf /backup/postgres.tar.gz /data
```

## 故障排除

### 1. 内存不足

减少组件或增加服务器内存。

### 2. 端口冲突

修改 docker-compose.yml 中的端口映射。

### 3. 服务启动失败

```bash
# 查看日志
docker-compose logs [service-name]

# 重建服务
docker-compose up -d --force-recreate [service-name]
```

## 升级

```bash
# 拉取最新镜像
docker-compose pull

# 重启服务
docker-compose up -d
```
