-- =============================================================================
-- PostgreSQL 初始化脚本 - Dify 数据库
-- =============================================================================

-- 创建 Dify 主数据库
CREATE DATABASE dify
    WITH OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TEMPLATE = template0;

-- 授权
GRANT ALL PRIVILEGES ON DATABASE dify TO postgres;

-- 添加注释
COMMENT ON DATABASE dify IS 'Dify AI Platform - Main Database';
