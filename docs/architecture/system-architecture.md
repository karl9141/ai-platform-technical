# 系统架构设计

**文档版本**: v2.0  
**更新日期**: 2026-02-01  
**状态**: 已评审  

---

## 1. 执行摘要

本平台是一套**轻量级、可扩展的 AI 辅助决策系统**，采用事件驱动架构，实现运维任务智能化处理。

| 核心价值 | 说明 |
|----------|------|
| 🎯 **提升效率** | 自动分析任务/告警，减少人工判断时间 |
| 🧠 **知识沉淀** | RAG 知识库持续积累，降低人员依赖 |
| ✅ **质量保障** | AI 辅助 + 人工确认，确保决策准确性 |

---

## 2. 系统全景架构

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#1e88e5', 'primaryTextColor': '#fff', 'primaryBorderColor': '#1565c0', 'lineColor': '#90a4ae', 'secondaryColor': '#f5f5f5', 'tertiaryColor': '#fff'}}}%%
flowchart TB
    subgraph Users["👥 用户层"]
        direction LR
        Dev["👨‍💻 运维人员"]
        Leader["👔 运维 Leader"]
        PM["📊 项目经理"]
    end

    subgraph Channels["🌐 接入渠道层"]
        direction LR
        LarkBot["💬 Lark Bot<br/>━━━━━━━━━<br/>消息接收<br/>交互卡片<br/>通知推送"]
        EmailGateway["📧 邮件网关<br/>━━━━━━━━━<br/>IMAP 接收<br/>告警解析<br/>回复发送"]
        JiraAPI["📋 Jira API<br/>━━━━━━━━━<br/>工单创建<br/>状态同步<br/>Webhook"]
    end

    subgraph Core["🏢 AI 辅助平台核心"]
        direction TB
        
        subgraph Orchestration["⚙️ 工作流编排层 - N8N"]
            direction LR
            WF1["🔄 任务收集<br/>工作流"]
            WF2["🚨 告警处理<br/>工作流"]
            WF3["📈 健康评估<br/>工作流"]
            Router["🔀 事件路由器"]
        end

        subgraph AILayer["🤖 AI 能力层 - Dify"]
            direction LR
            TaskAgent["📝 任务分析器<br/>━━━━━━━━━<br/>意图识别<br/>信息提取<br/>分配建议"]
            AlertAgent["🔔 告警分析器<br/>━━━━━━━━━<br/>类型分类<br/>优先级评估<br/>方案生成"]
            KnowledgeBase["📚 知识库<br/>━━━━━━━━━<br/>RAG 检索<br/>案例匹配<br/>持续学习"]
        end

        subgraph LLMLayer["🧠 大语言模型层"]
            direction LR
            OpenAI["✅ OpenAI<br/>GPT-4o-mini<br/>━━━━━━━━━<br/>推荐首选<br/>日本直连<br/>$0.15/1M"]
            Gemini["☑️ Gemini Pro<br/>━━━━━━━━━<br/>备选方案<br/>东京机房"]
        end
    end

    subgraph Infrastructure["🗄️ 基础设施层"]
        direction LR
        PostgreSQL["🐘 PostgreSQL 16<br/>━━━━━━━━━<br/>业务数据<br/>审计日志<br/>工作流状态"]
        Redis["⚡ Redis 7<br/>━━━━━━━━━<br/>会话缓存<br/>限流控制"]
        VectorDB["🔍 向量数据库<br/>━━━━━━━━━<br/>知识嵌入<br/>相似检索"]
    end

    %% 连接关系
    Dev --> LarkBot
    Leader --> LarkBot
    PM --> JiraAPI
    
    LarkBot --> Router
    EmailGateway --> Router
    JiraAPI <--> Router
    
    Router --> WF1
    Router --> WF2
    Router --> WF3
    
    WF1 <--> TaskAgent
    WF2 <--> AlertAgent
    WF3 <--> KnowledgeBase
    
    TaskAgent --> OpenAI
    AlertAgent --> OpenAI
    TaskAgent -.-> Gemini
    AlertAgent -.-> Gemini
    AlertAgent <--> KnowledgeBase
    
    KnowledgeBase --> VectorDB
    Orchestration --> PostgreSQL
    AILayer --> PostgreSQL
    AILayer --> Redis

    %% 样式
    style Core fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    style OpenAI fill:#10a37f,color:#fff,stroke:#0d8c6d
    style Gemini fill:#4285f4,color:#fff,stroke:#3367d6
    style LarkBot fill:#00d4aa,color:#fff
    style PostgreSQL fill:#336791,color:#fff
    style Redis fill:#dc382d,color:#fff
```

---

## 3. 分层架构详解

### 3.1 接入渠道层

负责接收外部事件，提供用户交互入口。

```mermaid
%%{init: {'theme': 'base'}}%%
flowchart LR
    subgraph Lark["💬 Lark 集成"]
        L1["Webhook 接收"] --> L2["消息解析"]
        L2 --> L3["卡片交互"]
        L3 --> L4["回调处理"]
    end
    
    subgraph Email["📧 邮件集成"]
        E1["IMAP 轮询"] --> E2["告警识别"]
        E2 --> E3["内容提取"]
        E3 --> E4["模板回复"]
    end
    
    subgraph Jira["📋 Jira 集成"]
        J1["REST API"] --> J2["Issue 创建"]
        J2 --> J3["状态更新"]
        J3 --> J4["Webhook 监听"]
    end
```

| 渠道 | 协议 | 功能 | SLA |
|------|------|------|-----|
| **Lark** | HTTPS Webhook | 消息接收、卡片交互、通知推送 | < 3s |
| **Email** | IMAP/SMTP | 告警接收、内容解析、回复发送 | < 30s |
| **Jira** | REST API | 工单 CRUD、状态同步 | < 5s |

### 3.2 工作流编排层 (N8N)

可视化工作流引擎，负责流程编排和系统集成。

```mermaid
%%{init: {'theme': 'base'}}%%
flowchart TB
    subgraph N8N["⚙️ N8N 工作流引擎"]
        direction TB
        
        subgraph Triggers["触发器"]
            T1["� Webhook"]
            T2["📧 IMAP"]
            T3["⏰ Cron"]
        end
        
        subgraph Logic["逻辑处理"]
            L1["🔀 条件分支"]
            L2["🔄 循环"]
            L3["⚡ 并行"]
        end
        
        subgraph Actions["动作执行"]
            A1["🌐 HTTP 请求"]
            A2["📤 消息发送"]
            A3["📝 数据写入"]
        end
        
        Triggers --> Logic --> Actions
    end
```

| 工作流 | 触发方式 | 处理步骤 | 输出 |
|--------|----------|----------|------|
| **任务收集** | Lark @触发 | 消息解析 → AI分析 → 确认卡片 → Jira创建 | Jira Issue |
| **告警处理** | 邮件接收 | 告警解析 → AI分类 → 知识匹配 → 多渠道通知 | 通知 + 工单 |
| **健康评估** | 定时触发 | 数据采集 → 指标计算 → AI评估 → 报告生成 | 健康报告 |

### 3.3 AI 能力层 (Dify)

AI 应用开发平台，提供 LLM 调用、RAG 检索、Prompt 管理。

```mermaid
%%{init: {'theme': 'base'}}%%
flowchart TB
    subgraph Dify["🤖 Dify AI 平台"]
        direction TB
        
        subgraph Apps["AI 应用"]
            App1["📝 任务分析器"]
            App2["🔔 告警分析器"]
            App3["📧 邮件生成器"]
        end
        
        subgraph Core["核心能力"]
            C1["💬 对话管理"]
            C2["📚 RAG 检索"]
            C3["🔧 工具调用"]
        end
        
        subgraph Models["模型管理"]
            M1["OpenAI"]
            M2["Gemini"]
            M3["本地模型"]
        end
        
        Apps --> Core --> Models
    end
```

| 应用 | 输入 | 输出 | 模型 |
|------|------|------|------|
| **任务分析器** | Lark 消息文本 | 任务 JSON（系统/目的/紧急度） | GPT-4o-mini |
| **告警分析器** | 告警邮件内容 | 分类 + 建议 + 历史案例 | GPT-4o-mini + RAG |
| **邮件生成器** | 告警摘要 | 客户回复模板 | GPT-4o-mini |

### 3.4 基础设施层

数据存储和计算资源。

| 组件 | 版本 | 用途 | 部署方式 |
|------|------|------|----------|
| **PostgreSQL** | 16 | 业务数据、审计日志、工作流状态 | Docker / RDS |
| **Redis** | 7 | 会话缓存、限流、队列 | Docker / ElastiCache |
| **向量数据库** | Weaviate | 知识嵌入、相似检索 | Dify 内置 |

---

## 4. LLM 选型决策

### 4.1 推荐方案（日本地区）

```mermaid
%%{init: {'theme': 'base'}}%%
flowchart LR
    subgraph Recommended["✅ 推荐"]
        OpenAI["🟢 OpenAI GPT-4o-mini<br/>━━━━━━━━━━<br/>• 日本直连稳定<br/>• 响应 100-300ms<br/>• $0.15/1M tokens<br/>• 效果优秀"]
    end
    
    subgraph Alternative["☑️ 备选"]
        Gemini["🔵 Google Gemini Pro<br/>━━━━━━━━━━<br/>• 东京数据中心<br/>• 低延迟<br/>• $0.125/1M tokens"]
    end
    
    subgraph NotRecommended["⚠️ 不推荐"]
        CN["🔴 国内模型<br/>━━━━━━━━━━<br/>• 通义千问<br/>• 文心一言<br/>• 需大陆身份验证"]
    end

    style OpenAI fill:#10a37f,color:#fff
    style Gemini fill:#4285f4,color:#fff
    style CN fill:#ffcdd2
```

### 4.2 选型对比

| 维度 | OpenAI GPT-4o-mini | Gemini Pro | 国内模型 |
|------|-------------------|------------|----------|
| **网络** | ✅ 日本直连 | ✅ 东京机房 | ❌ 需验证 |
| **延迟** | 100-300ms | 80-200ms | 不适用 |
| **价格** | $0.15/1M | $0.125/1M | - |
| **效果** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | - |
| **推荐度** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐ |

---

## 5. 业务流程设计

### 5.1 运维任务收集流程

```mermaid
%%{init: {'theme': 'base'}}%%
sequenceDiagram
    autonumber
    participant U as 👤 用户
    participant L as 💬 Lark
    participant N as ⚙️ N8N
    participant D as 🤖 Dify
    participant O as 🧠 OpenAI
    participant LD as 👔 Leader
    participant J as 📋 Jira

    rect rgb(230, 245, 255)
        Note over U,L: 1️⃣ 任务提交
        U->>L: @运维 请重启 prod-api-01
        L->>N: Webhook 推送消息
    end

    rect rgb(255, 243, 224)
        Note over N,O: 2️⃣ AI 分析
        N->>D: 调用任务分析 API
        D->>O: Prompt + 消息内容
        O-->>D: 分析结果 JSON
        D-->>N: 返回结构化数据
    end

    rect rgb(232, 245, 233)
        Note over N,LD: 3️⃣ 人工确认
        N->>L: 发送确认卡片
        L->>LD: 展示任务详情
        LD->>L: 点击「确认创建」
        L->>N: 回调确认动作
    end

    rect rgb(243, 229, 245)
        Note over N,J: 4️⃣ 工单创建
        N->>J: 创建 Jira Issue
        J-->>N: 返回 Issue Key
        N->>L: 通知创建成功
        L->>U: 显示结果
    end
```

### 5.2 告警处理流程

```mermaid
%%{init: {'theme': 'base'}}%%
sequenceDiagram
    autonumber
    participant M as 🖥️ 监控系统
    participant E as 📧 邮件服务器
    participant N as ⚙️ N8N
    participant D as 🤖 Dify
    participant K as 📚 知识库
    participant L as 💬 Lark
    participant J as 📋 Jira

    rect rgb(255, 235, 238)
        Note over M,E: 1️⃣ 告警触发
        M->>E: 发送告警邮件
        E->>N: IMAP 接收
    end

    rect rgb(255, 243, 224)
        Note over N,K: 2️⃣ 智能分析
        N->>D: 调用告警分析 API
        D->>K: RAG 检索相似案例
        K-->>D: 返回历史方案
        D->>D: AI 分析 + 生成建议
        D-->>N: 返回完整分析
    end

    rect rgb(232, 245, 233)
        Note over N,J: 3️⃣ 多渠道分发
        N->>L: 推送告警卡片
        N->>J: 创建告警工单
        Note over L: 包含：摘要、建议、历史案例
    end
```

---

## 6. 部署架构

### 6.1 开发环境 (Docker Compose)

```mermaid
%%{init: {'theme': 'base'}}%%
flowchart TB
    subgraph Local["�️ 开发环境 - Docker Compose"]
        direction TB
        
        subgraph Services["服务容器"]
            N8N["⚙️ N8N<br/>:5678"]
            Dify["🤖 Dify<br/>:3000"]
            DifyWorker["🔧 Dify Worker"]
        end
        
        subgraph Data["数据容器"]
            PG["🐘 PostgreSQL<br/>:5432"]
            Redis["⚡ Redis<br/>:6379"]
            Weaviate["🔍 Weaviate<br/>:8080"]
        end
        
        N8N --> PG
        Dify --> PG
        Dify --> Redis
        Dify --> Weaviate
        DifyWorker --> PG
        DifyWorker --> Redis
    end
    
    User["👤 开发者"] --> N8N
    User --> Dify

    style N8N fill:#ff6d5a,color:#fff
    style Dify fill:#1e88e5,color:#fff
```

### 6.2 生产环境 (AWS EKS)

```mermaid
%%{init: {'theme': 'base'}}%%
flowchart TB
    subgraph AWS["☁️ AWS Tokyo Region"]
        subgraph VPC["VPC"]
            ALB["🔀 Application Load Balancer<br/>HTTPS 终止"]
            
            subgraph EKS["EKS Cluster"]
                subgraph NodeGroup["Node Group"]
                    N8NPod["⚙️ N8N Pod<br/>t3.medium"]
                    DifyPod["🤖 Dify Pod<br/>t3.large"]
                end
            end
            
            subgraph Managed["托管服务"]
                RDS["🐘 RDS PostgreSQL<br/>db.t3.small"]
                ElastiCache["⚡ ElastiCache Redis<br/>cache.t3.micro"]
            end
        end
        
        S3["📦 S3<br/>文件存储"]
    end
    
    Internet["🌐 Internet"] --> ALB
    ALB --> N8NPod
    ALB --> DifyPod
    N8NPod --> RDS
    DifyPod --> RDS
    DifyPod --> ElastiCache
    DifyPod --> S3

    style ALB fill:#ff9900,color:#fff
    style RDS fill:#3b48cc,color:#fff
    style ElastiCache fill:#c7131f,color:#fff
    style S3 fill:#569a31,color:#fff
```

---

## 7. 安全架构

```mermaid
%%{init: {'theme': 'base'}}%%
flowchart TB
    subgraph Security["🔐 安全架构"]
        direction TB
        
        subgraph Transport["传输安全"]
            T1["🔒 HTTPS/TLS 1.3"]
            T2["🔑 API Key 认证"]
        end
        
        subgraph Data["数据安全"]
            D1["🙈 敏感信息脱敏"]
            D2["📝 审计日志"]
            D3["🔐 加密存储"]
        end
        
        subgraph Access["访问控制"]
            A1["🛡️ VPC 隔离"]
            A2["👤 RBAC 权限"]
            A3["🚫 IP 白名单"]
        end
    end
```

| 安全层 | 措施 | 说明 |
|--------|------|------|
| **传输** | TLS 1.3 | 所有 API 通信加密 |
| **认证** | API Key + OAuth | Dify/N8N 访问控制 |
| **数据** | 脱敏处理 | LLM 调用前移除敏感信息 |
| **审计** | 完整日志 | 所有 AI 决策可追溯 |
| **网络** | VPC + SG | 内网隔离，最小权限 |

---

## 8. 扩展路线图

```mermaid
%%{init: {'theme': 'base'}}%%
gantt
    title 📅 功能扩展路线图
    dateFormat YYYY-MM-DD
    
    section Phase 0 - 基础
    环境搭建           :done, p0, 2026-02-01, 1w
    
    section Phase 1 - MVP
    任务收集流程       :active, p1, after p0, 2w
    Lark 集成         :p1a, after p0, 1w
    AI 分析开发       :p1b, after p1a, 1w
    
    section Phase 2 - 告警
    告警分析流程       :p2, after p1, 2w
    邮件集成          :p2a, after p1, 1w
    分类模型调优      :p2b, after p2a, 1w
    
    section Phase 3 - 知识库
    RAG 知识库        :p3, after p2, 2w
    
    section Future
    健康度评估        :p4, after p3, 4w
    本地模型迁移      :milestone, p5, after p4, 0d
```

---

## 附录

### A. 技术栈版本

| 组件 | 版本 | 许可证 |
|------|------|--------|
| N8N | latest | Fair-code |
| Dify | latest | Apache 2.0 |
| PostgreSQL | 16 | PostgreSQL |
| Redis | 7 | BSD |
| Docker | 24+ | Apache 2.0 |

### B. 相关文档

- [任务收集模块设计](../design/module-a-task-collection.md)
- [告警分析模块设计](../design/module-b-alert-analysis.md)
- [实施计划](../implementation/implementation-plan.md)
- [成本估算](../implementation/cost-estimation.md)
