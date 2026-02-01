# N8N 部署到 AWS EKS

使用 AWS RDS MySQL 作为数据库后端，一键部署 N8N 到 Kubernetes 集群。

## 📁 文件说明

```
k8s/
├── values.yaml      # 配置文件（只需修改这个）
├── deploy.sh        # Linux/macOS 部署脚本
├── deploy.ps1       # Windows 部署脚本
└── README.md        # 本文档
```

---

## � 部署步骤

### Step 1: 配置 RDS MySQL 数据库

在 AWS RDS MySQL 中执行以下 SQL：

```sql
CREATE DATABASE n8n CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'n8n_user'@'%' IDENTIFIED BY 'your-password';
GRANT ALL PRIVILEGES ON n8n.* TO 'n8n_user'@'%';
FLUSH PRIVILEGES;
```

### Step 2: 修改配置文件

编辑 `values.yaml`，填入你的实际配置：

```yaml
# ===== AWS RDS MySQL 配置 (必填) =====
DB_HOST: "your-rds-endpoint.ap-northeast-1.rds.amazonaws.com"
DB_PORT: "3306"
DB_NAME: "n8n"
DB_USER: "n8n_user"
DB_PASSWORD: "your-rds-password"

# ===== N8N 配置 (必填) =====
N8N_DOMAIN: "n8n.your-domain.com"

# ===== AWS ALB 配置 (必填) =====
ACM_CERTIFICATE_ARN: "arn:aws:acm:ap-northeast-1:123456789:certificate/xxx"

# ===== 可选配置 =====
TIMEZONE: "Asia/Tokyo"
STORAGE_SIZE: "10Gi"
STORAGE_CLASS: "gp3"
```

### Step 3: 运行部署脚本

**Linux / macOS / Git Bash:**

```bash
chmod +x deploy.sh
./deploy.sh
```

**Windows PowerShell:**

```powershell
.\deploy.ps1
```

### Step 4: 配置 DNS

1. 获取 ALB 地址：

```bash
kubectl get ingress -n n8n
```

2. 在 Route 53 或你的 DNS 服务商中，将域名解析到 ALB 地址

### Step 5: 访问 N8N

打开 `https://your-domain.com`，创建管理员账户。

---

## � 常用命令

```bash
# 查看 Pod 状态
kubectl get pods -n n8n

# 查看日志
kubectl logs -f deployment/n8n -n n8n

# 本地端口转发测试
kubectl port-forward svc/n8n-service 5678:80 -n n8n

# 获取 ALB 地址
kubectl get ingress -n n8n -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'

# 重启 N8N
kubectl rollout restart deployment/n8n -n n8n

# 删除部署
kubectl delete namespace n8n
```

---

## 🔧 故障排除

### Pod 无法启动 (CrashLoopBackOff)

1. 检查日志：
```bash
kubectl logs deployment/n8n -n n8n
```

2. 常见原因：
   - RDS 连接信息错误
   - RDS 安全组未允许 EKS 节点访问
   - 数据库用户权限不足

### 无法连接 RDS

1. 确认 RDS 安全组入站规则包含 EKS 节点的 CIDR
2. 确认 RDS 和 EKS 在同一 VPC 或有正确的 VPC Peering

### Ingress 没有 ALB 地址

1. 确认已安装 AWS Load Balancer Controller：
```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
```

2. 检查 Ingress 事件：
```bash
kubectl describe ingress n8n-ingress -n n8n
```

---

## � 安全建议

1. **加密密钥备份**: 部署后获取自动生成的加密密钥并妥善保管
   ```bash
   kubectl get secret n8n-secrets -n n8n -o jsonpath='{.data.N8N_ENCRYPTION_KEY}' | base64 -d
   ```

2. **使用 AWS Secrets Manager**: 生产环境建议使用 External Secrets Operator

3. **定期备份 RDS**: 配置 AWS Backup 自动备份策略

---

## 📚 参考链接

- [N8N 官方文档](https://docs.n8n.io/)
- [N8N 环境变量](https://docs.n8n.io/hosting/configuration/environment-variables/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
