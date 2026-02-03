# AI Platform 部署指南

完整的 AI 应用平台，包含 Dify、N8N、PostgreSQL、Redis、Weaviate 和 Nginx。

## 🚀 快速开始

### 本地部署 (Windows)

```powershell
# 1. 复制环境配置
Copy-Item .env.local .env

# 2. 一键部署
.\deploy-local.ps1

# 3. 访问服务
# Dify:  http://localhost:3000
# N8N:   http://localhost:5678
```

### 本地部署 (Linux/Mac)

```bash
# 1. 复制环境配置
cp .env.local .env

# 2. 一键部署
./deploy-local.sh

# 3. 访问服务
```

---

## 📁 目录结构

```
deploy/
├── .env.example          # 环境变量模板
├── .env.local            # 本地环境配置
├── .env.staging          # AWS Staging 配置
├── docker-compose.yml    # 全量服务部署
├── deploy-local.ps1/sh   # 本地一键部署
├── deploy-staging.sh     # AWS 部署
├── shared/               # 共享基础设施
│   ├── postgres/         # 数据库
│   ├── redis/            # 缓存
│   └── nginx/            # 反向代理
├── dify/                 # Dify AI 平台
├── n8n/                  # N8N 工作流
├── weaviate/             # 向量数据库
└── scripts/              # 工具脚本
```

---

## 🔧 服务说明

| 服务 | 端口 | 描述 |
|------|------|------|
| **Dify** | 3000 | AI 应用开发平台 |
| **N8N** | 5678 | 工作流自动化引擎 |
| **PostgreSQL** | 5432 | 主数据库 |
| **Redis** | 6379 | 缓存服务 |
| **Weaviate** | 8080 | 向量数据库 |

---

## 📋 部署检查清单

### 前置条件
- [ ] Docker Desktop 已安装并运行
- [ ] Docker Compose v2+ 已安装
- [ ] 端口 5678, 3000, 5432, 6379, 8080 未被占用

### 部署步骤
- [ ] 复制 `.env.local` 为 `.env`
- [ ] 运行 `deploy-local.ps1` 或 `deploy-local.sh`
- [ ] 等待所有容器启动 (约 2-3 分钟)
- [ ] 访问 http://localhost:3000 完成 Dify 初始设置

### 验证
- [ ] `docker compose ps` 显示所有服务 healthy
- [ ] http://localhost:3000 可访问 Dify
- [ ] http://localhost:5678 可访问 N8N

---

## 🔐 安全注意事项

> [!CAUTION]
> `.env.local` 中的密钥仅用于本地开发，**生产环境必须生成新密钥**！
> 
> 生成强密钥: `openssl rand -base64 42`

---

## 📚 单服务部署

每个服务可独立部署：

```bash
# 仅部署 Dify
cd dify && docker compose up -d

# 仅部署 N8N
cd n8n && docker compose up -d
```

---

## 🛠️ 常用命令

```bash
# 查看状态
docker compose ps

# 查看日志
docker compose logs -f [service_name]

# 重启服务
docker compose restart [service_name]

# 停止所有
docker compose down

# 完全清理 (包括数据)
docker compose down -v
```
