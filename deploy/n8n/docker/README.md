# N8N Docker 部署

## 快速启动

```bash
docker-compose up -d
```

## 访问

- URL: http://localhost:5678

## 默认配置

| 配置 | 值 |
|------|-----|
| 端口 | 5678 |
| 数据库 | PostgreSQL |
| 时区 | Asia/Tokyo |

## 数据持久化

- N8N 数据: `n8n_data` 卷
- PostgreSQL 数据: `n8n_postgres_data` 卷

## 常用命令

```bash
# 启动
docker-compose up -d

# 停止
docker-compose down

# 查看日志
docker-compose logs -f n8n

# 重启
docker-compose restart n8n
```

## 生产环境建议

1. 修改 `POSTGRES_PASSWORD`
2. 配置 `N8N_ENCRYPTION_KEY`
3. 使用反向代理配置 HTTPS
