# Dify Docker 部署

## 快速启动

```bash
docker-compose up -d
```

## 访问

- Dify Web: http://localhost:3000
- Dify API: http://localhost:80/v1

## 默认配置

| 配置 | 值 |
|------|-----|
| Web 端口 | 3000 |
| API 端口 | 80 |
| 数据库 | PostgreSQL 15 |
| 向量数据库 | Weaviate |

## 首次使用

1. 访问 http://localhost:3000
2. 创建管理员账户
3. 配置 LLM 模型（OpenAI API Key）
4. 创建应用

## 配置 LLM

### OpenAI
1. 登录 Dify
2. 设置 → 模型供应商 → OpenAI
3. 输入 API Key

### Ollama (本地模型)
1. 安装 Ollama
2. 拉取模型: `ollama pull qwen2.5`
3. 在 Dify 中配置 Ollama 地址

## 数据持久化

| 卷 | 用途 |
|-----|------|
| dify_storage | 文件存储 |
| dify_postgres_data | 数据库 |
| dify_redis_data | 缓存 |
| dify_weaviate_data | 向量数据库 |

## 常用命令

```bash
# 启动
docker-compose up -d

# 停止
docker-compose down

# 查看日志
docker-compose logs -f api

# 重启
docker-compose restart api worker
```

## 环境变量

创建 `.env` 文件自定义配置：

```env
SECRET_KEY=your-secret-key
DB_PASSWORD=your-db-password
REDIS_PASSWORD=your-redis-password
```

## 常见问题

### 1. 内存不足

Dify 需要至少 4GB RAM。可以禁用 Weaviate 使用内置向量库：

```yaml
environment:
  VECTOR_STORE: chroma
```

### 2. 无法连接 OpenAI

检查网络配置，可考虑使用代理或切换到本地模型。
