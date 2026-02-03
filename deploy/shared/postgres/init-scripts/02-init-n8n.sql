-- =============================================================================
-- PostgreSQL 初始化脚本 - N8N 数据库
-- =============================================================================

CREATE DATABASE n8n
    WITH OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TEMPLATE = template0;

GRANT ALL PRIVILEGES ON DATABASE n8n TO postgres;

COMMENT ON DATABASE n8n IS 'N8N Workflow Automation - Database';
