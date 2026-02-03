# Weaviate 向量数据库

Weaviate 1.19.0 - 开源向量数据库

## 访问地址

- API: http://localhost:8080

## 用途

- Dify 知识库向量存储
- 语义搜索
- AI 应用向量化

## 配置

```env
AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED=true
DEFAULT_VECTORIZER_MODULE=none
```

## 单独部署

```bash
cd weaviate
docker compose up -d
```
