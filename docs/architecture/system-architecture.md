# 系统架构设计

## 1. 架构概述

本平台采用分层架构设计，实现事件驱动的 AI 辅助决策系统。

- **设计理念**：AI 辅助决策，人工最终确认
- **核心价值**：提升运维效率，沉淀知识资产
- **技术路线**：开源优先，云端 API + 自托管

---

## 2. 系统架构图

```mermaid
flowchart TB
    subgraph External["🌐 外部系统"]
        Lark["💬 Lark<br/>企业协作"]
        Email["📧 Email<br/>告警邮件"]
        Jira["📋 Jira<br/>任务管理"]
    end

    subgraph Platform["🏢 AI 辅助平台"]
        subgraph Orchestration["⚙️ 工作流编排层"]
            N8N["N8N<br/>可视化工作流引擎"]
        end

        subgraph AI["🤖 AI 能力层"]
            Dify["Dify<br/>AI 应用平台"]
            TaskAnalyzer["任务分析器"]
            AlertAnalyzer["告警分析器"]
            KB["知识库<br/>RAG"]
        end

        subgraph LLM["🧠 大语言模型"]
            OpenAI["OpenAI<br/>GPT-4o-mini<br/>✅ 推荐"]
            Gemini["Google Gemini<br/>备选"]
        end

        subgraph Infra["🗄️ 基础设施"]
            PostgreSQL["PostgreSQL<br/>数据存储"]
            Redis["Redis<br/>缓存"]
            Vector["向量数据库<br/>知识检索"]
        end
    end

    Lark --> N8N
    Email --> N8N
    Jira <--> N8N
    
    N8N <--> Dify
    Dify --> TaskAnalyzer
    Dify --> AlertAnalyzer
    Dify --> KB
    
    TaskAnalyzer --> OpenAI
    AlertAnalyzer --> OpenAI
    TaskAnalyzer -.-> Gemini
    AlertAnalyzer -.-> Gemini
    
    KB --> Vector
    N8N --> PostgreSQL
    Dify --> PostgreSQL
    Dify --> Redis

    style OpenAI fill:#10a37f,color:#fff
    style Dify fill:#1e88e5,color:#fff
    style N8N fill:#ff6d5a,color:#fff
    style Platform fill:#f5f5f5
```

---

## 3. 业务流程图

### 3.1 运维任务收集流程

```mermaid
sequenceDiagram
    participant User as 👤 用户
    participant Lark as 💬 Lark
    participant N8N as ⚙️ N8N
    participant Dify as 🤖 Dify
    participant Leader as 👔 Leader
    participant Jira as 📋 Jira

    User->>Lark: @运维 请重启 prod-api-01
    Lark->>N8N: Webhook 消息
    N8N->>Dify: 调用任务分析 API
    Dify->>Dify: AI 分析任务内容
    Dify-->>N8N: 返回分析结果
    N8N->>Lark: 发送确认卡片
    Lark->>Leader: 展示任务确认卡片
    Leader->>Lark: 点击「确认创建」
    Lark->>N8N: 回调确认动作
    N8N->>Jira: 创建 Issue
    Jira-->>N8N: 返回 Issue Key
    N8N->>Lark: 通知创建成功
```

### 3.2 告警邮件分析流程

```mermaid
sequenceDiagram
    participant Monitor as 🖥️ 监控系统
    participant Email as 📧 邮件服务器
    participant N8N as ⚙️ N8N
    participant Dify as 🤖 Dify
    participant KB as 📚 知识库
    participant Lark as 💬 Lark

    Monitor->>Email: 发送告警邮件
    Email->>N8N: IMAP 接收
    N8N->>Dify: 调用告警分析 API
    Dify->>KB: RAG 检索相似案例
    KB-->>Dify: 返回历史方案
    Dify->>Dify: AI 分析 + 生成建议
    Dify-->>N8N: 返回分析结果
    N8N->>Lark: 推送告警通知卡片
    Note over Lark: 包含告警摘要、建议操作、历史案例
```

---

## 4. 分层架构说明

### 4.1 事件入口层

| 组件 | 协议 | 职责 | 状态 |
|------|------|------|------|
| Lark Webhook | HTTPS | 接收群消息、交互卡片回调 | ✅ 已集成 |
| Email IMAP | IMAP/SMTP | 接收告警邮件、发送回复 | ✅ 已集成 |
| Jira Webhook | HTTPS | 状态变更通知 | ✅ 已集成 |

### 4.2 工作流编排层 (N8N)

| 工作流 | 触发方式 | 功能 |
|--------|----------|------|
| 任务收集 | Lark Webhook | Lark 消息 → AI 分析 → 确认 → Jira |
| 告警处理 | Email IMAP | 告警邮件 → AI 分析 → 多渠道分发 |
| 健康度评估 | 定时触发 | 数据采集 → 评估 → 报告生成 |

### 4.3 AI 能力层 (Dify)

| 应用 | 功能 | 模型 |
|------|------|------|
| 任务分析器 | 识别任务、提取信息、生成建议 | GPT-4o-mini |
| 告警分析器 | 告警分类、知识库匹配、建议生成 | GPT-4o-mini |
| 知识库 | RAG 检索历史案例 | 向量数据库 |

### 4.4 基础设施层

| 组件 | 用途 | 部署方式 |
|------|------|----------|
| PostgreSQL 16 | 共享数据库（N8N、Dify） | Docker / RDS |
| Redis 7 | 会话缓存、限流 | Docker / ElastiCache |
| 向量数据库 | 知识库存储 | Dify 内置 |

---

## 5. 技术选型

### 5.1 核心组件

| 类别 | 选型 | 版本 | 选型理由 |
|------|------|------|----------|
| 工作流引擎 | **N8N** | latest | 开源、可视化、400+ 集成 |
| AI 应用平台 | **Dify** | latest | 开源、RAG 内置、多模型支持 |
| 数据库 | **PostgreSQL** | 16 | 稳定、与组件兼容性好 |

### 5.2 LLM 选型（日本地区）

| 模型 | 推荐度 | 价格 | 说明 |
|------|--------|------|------|
| ✅ **OpenAI GPT-4o-mini** | ⭐⭐⭐⭐⭐ | $0.15/1M | **首选**，日本直连稳定 |
| ✅ Google Gemini Pro | ⭐⭐⭐⭐ | $0.125/1M | 备选，东京数据中心 |
| ⚠️ 通义千问/文心一言 | ⭐ | - | 不推荐，需大陆身份验证 |

> **注意**：当前方案使用云端 API（OpenAI GPT-4o-mini），后期可根据需要切换至本地模型。

---

## 6. 部署架构

### 6.1 开发环境

```mermaid
flowchart LR
    subgraph Docker["🐳 Docker Compose"]
        N8N["N8N<br/>:5678"]
        Dify["Dify<br/>:3000"]
        PG["PostgreSQL<br/>:5432"]
        Redis["Redis<br/>:6379"]
    end
    
    User["👤 开发者"] --> N8N
    User --> Dify
```

### 6.2 生产环境 (AWS)

```mermaid
flowchart TB
    subgraph AWS["☁️ AWS Cloud"]
        subgraph VPC["VPC"]
            ALB["Application<br/>Load Balancer"]
            
            subgraph EKS["EKS Cluster"]
                N8N["N8N Pod"]
                Dify["Dify Pod"]
            end
            
            subgraph RDS["RDS"]
                PostgreSQL["PostgreSQL"]
            end
            
            subgraph ElastiCache["ElastiCache"]
                Redis["Redis"]
            end
        end
    end
    
    Internet["🌐 Internet"] --> ALB
    ALB --> N8N
    ALB --> Dify
    N8N --> PostgreSQL
    Dify --> PostgreSQL
    Dify --> Redis
```

---

## 7. 安全设计

| 安全措施 | 说明 |
|----------|------|
| 🔐 传输加密 | 所有 API 通信使用 HTTPS |
| 🔒 敏感信息脱敏 | 发送给 LLM 前脱敏客户信息 |
| 📝 审计日志 | 所有 AI 决策过程可追溯 |
| 🛡️ 访问控制 | N8N/Dify 仅内网访问 + 认证 |

---

## 8. 扩展路线图

```mermaid
gantt
    title 功能扩展路线图
    dateFormat  YYYY-MM
    section Phase 1
    环境搭建           :done, p0, 2026-02, 1w
    section Phase 2
    任务收集 MVP       :active, p1, after p0, 2w
    section Phase 3
    告警分析 MVP       :p2, after p1, 2w
    section Phase 4
    知识库沉淀         :p3, after p2, 2w
    section Future
    健康度评估         :p4, after p3, 4w
    本地模型切换       :p5, after p4, 2w
```
