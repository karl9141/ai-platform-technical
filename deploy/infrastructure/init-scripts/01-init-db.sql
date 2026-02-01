-- =============================================================================
-- AI Platform - 数据库初始化脚本
-- =============================================================================
-- 
-- 此脚本在 PostgreSQL 首次启动时自动执行
-- 创建各服务所需的数据库和用户
--
-- =============================================================================

-- 创建 N8N 数据库
CREATE DATABASE n8n
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TEMPLATE = template0;

COMMENT ON DATABASE n8n IS 'N8N Workflow Engine Database';

-- 创建 Dify 数据库
CREATE DATABASE dify
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TEMPLATE = template0;

COMMENT ON DATABASE dify IS 'Dify AI Platform Database';

-- 创建扩展（在 dify 数据库中）
\c dify
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- 输出完成信息
\echo '======================================'
\echo 'Database initialization completed!'
\echo 'Created databases: n8n, dify'
\echo '======================================'
