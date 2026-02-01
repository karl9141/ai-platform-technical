-- 初始化数据库
-- 为 N8N 和 Dify 创建独立的数据库

-- N8N 数据库
CREATE DATABASE n8n;

-- Dify 数据库
CREATE DATABASE dify;

-- 授权（如果需要单独用户）
-- CREATE USER n8n_user WITH PASSWORD 'xxx';
-- GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n_user;
