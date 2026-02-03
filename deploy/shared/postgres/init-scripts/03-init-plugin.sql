-- =============================================================================
-- PostgreSQL 初始化脚本 - Dify Plugin 数据库
-- =============================================================================

CREATE DATABASE dify_plugin
    WITH OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TEMPLATE = template0;

GRANT ALL PRIVILEGES ON DATABASE dify_plugin TO postgres;

COMMENT ON DATABASE dify_plugin IS 'Dify Plugin Daemon - Database';
