# Dify AI 平台

Dify 1.12.0 - AI 应用开发平台

## 组件

| 组件 | 镜像 | 功能 |
|------|------|------|
| dify-api | langgenius/dify-api:1.12.0 | API 后端 |
| dify-worker | langgenius/dify-api:1.12.0 | 后台任务处理 |
| dify-worker-beat | langgenius/dify-api:1.12.0 | 定时任务调度 |
| dify-web | langgenius/dify-web:1.12.0 | 前端界面 |
| plugin_daemon | langgenius/dify-plugin-daemon:0.5.3-local | 插件服务 |
| sandbox | langgenius/dify-sandbox:0.2.12 | 代码沙箱 |
| ssrf_proxy | ubuntu/squid:latest | SSRF 防护代理 |

## 访问地址

- Web 界面: http://localhost:3000

## 依赖

- PostgreSQL (dify, dify_plugin 数据库)
- Redis
- Weaviate (向量存储)

## 配置

主要配置在 `config.env`:

```env
SECRET_KEY=<your-secret-key>
PLUGIN_DAEMON_KEY=<plugin-key>
SANDBOX_API_KEY=<sandbox-key>
```

## 单独部署

```bash
# 部署 Dify
./deploy-local.sh
```
