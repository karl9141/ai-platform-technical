# N8N 工作流引擎

N8N 2.7.1 - 开源工作流自动化平台

## 访问地址

- Web 界面: http://localhost (端口 80)

## 依赖

- PostgreSQL (n8n 数据库)

## 配置

主要配置在 `config.env`:

```env
N8N_HOST=localhost
N8N_PORT=5678
N8N_ENCRYPTION_KEY=<your-32-char-key>
WEBHOOK_URL=http://localhost:5678/
```

## 功能

- 工作流自动化
- Webhook 触发器
- 200+ 集成节点
- 定时任务

## 单独部署

```bash
cd n8n
docker compose up -d
```
