<#
.SYNOPSIS
    N8N 一键部署到 AWS EKS
.DESCRIPTION
    使用方法:
      1. 修改 values.yaml 中的配置
      2. 运行: .\deploy.ps1
#>

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ValuesFile = Join-Path $ScriptDir "values.yaml"
$NAMESPACE = "n8n"

Write-Host ""
Write-Host "╔═══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     N8N Deployment to AWS EKS             ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

#-------------------------------------------------------------------------------
# 1. 读取配置
#-------------------------------------------------------------------------------
Write-Host "[1/4] 读取配置..." -ForegroundColor Yellow

function Get-YamlValue {
    param([string]$Key)
    $content = Get-Content $ValuesFile -Raw
    if ($content -match "(?m)^${Key}:\s*`"?([^`"\r\n]+)`"?") {
        return $Matches[1].Trim()
    }
    return ""
}

$DB_HOST = Get-YamlValue "DB_HOST"
$DB_PORT = Get-YamlValue "DB_PORT"
$DB_NAME = Get-YamlValue "DB_NAME"
$DB_USER = Get-YamlValue "DB_USER"
$DB_PASSWORD = Get-YamlValue "DB_PASSWORD"
$N8N_DOMAIN = Get-YamlValue "N8N_DOMAIN"
$N8N_ENCRYPTION_KEY = Get-YamlValue "N8N_ENCRYPTION_KEY"
$ACM_CERTIFICATE_ARN = Get-YamlValue "ACM_CERTIFICATE_ARN"
$TIMEZONE = Get-YamlValue "TIMEZONE"
$STORAGE_SIZE = Get-YamlValue "STORAGE_SIZE"
$STORAGE_CLASS = Get-YamlValue "STORAGE_CLASS"

# 默认值
if (-not $TIMEZONE) { $TIMEZONE = "Asia/Tokyo" }
if (-not $STORAGE_SIZE) { $STORAGE_SIZE = "10Gi" }
if (-not $STORAGE_CLASS) { $STORAGE_CLASS = "gp3" }

# 生成加密密钥
if (-not $N8N_ENCRYPTION_KEY) {
    $N8N_ENCRYPTION_KEY = -join ((48..57) + (97..102) | Get-Random -Count 32 | ForEach-Object { [char]$_ })
    Write-Host "✓ 已自动生成加密密钥" -ForegroundColor Green
}

# 验证必填项
if (-not $DB_HOST -or $DB_HOST -eq "your-rds-endpoint.ap-northeast-1.rds.amazonaws.com") {
    Write-Host "✗ 请在 values.yaml 中配置 DB_HOST" -ForegroundColor Red
    exit 1
}
if (-not $N8N_DOMAIN -or $N8N_DOMAIN -eq "n8n.your-domain.com") {
    Write-Host "✗ 请在 values.yaml 中配置 N8N_DOMAIN" -ForegroundColor Red
    exit 1
}
if (-not $ACM_CERTIFICATE_ARN -or $ACM_CERTIFICATE_ARN -like "*YOUR_*") {
    Write-Host "✗ 请在 values.yaml 中配置 ACM_CERTIFICATE_ARN" -ForegroundColor Red
    exit 1
}

Write-Host "✓ 配置验证通过" -ForegroundColor Green
Write-Host "  域名: $N8N_DOMAIN"
Write-Host "  数据库: $DB_HOST"

#-------------------------------------------------------------------------------
# 2. 生成 Kubernetes 清单
#-------------------------------------------------------------------------------
Write-Host ""
Write-Host "[2/4] 生成 Kubernetes 清单..." -ForegroundColor Yellow

$GeneratedFile = Join-Path $ScriptDir ".generated.yaml"

@"
---
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE
---
apiVersion: v1
kind: Secret
metadata:
  name: n8n-secrets
  namespace: $NAMESPACE
type: Opaque
stringData:
  DB_MYSQLDB_HOST: "$DB_HOST"
  DB_MYSQLDB_PORT: "$DB_PORT"
  DB_MYSQLDB_DATABASE: "$DB_NAME"
  DB_MYSQLDB_USER: "$DB_USER"
  DB_MYSQLDB_PASSWORD: "$DB_PASSWORD"
  N8N_ENCRYPTION_KEY: "$N8N_ENCRYPTION_KEY"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: n8n-config
  namespace: $NAMESPACE
data:
  DB_TYPE: "mysqldb"
  N8N_HOST: "0.0.0.0"
  N8N_PORT: "5678"
  N8N_PROTOCOL: "https"
  WEBHOOK_URL: "https://$N8N_DOMAIN/"
  GENERIC_TIMEZONE: "$TIMEZONE"
  TZ: "$TIMEZONE"
  EXECUTIONS_MODE: "regular"
  N8N_LOG_LEVEL: "info"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: n8n-pvc
  namespace: $NAMESPACE
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: $STORAGE_CLASS
  resources:
    requests:
      storage: $STORAGE_SIZE
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: n8n
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: n8n
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: n8n
    spec:
      containers:
        - name: n8n
          image: docker.n8n.io/n8nio/n8n:latest
          ports:
            - containerPort: 5678
          envFrom:
            - configMapRef:
                name: n8n-config
          env:
            - name: DB_MYSQLDB_HOST
              valueFrom: {secretKeyRef: {name: n8n-secrets, key: DB_MYSQLDB_HOST}}
            - name: DB_MYSQLDB_PORT
              valueFrom: {secretKeyRef: {name: n8n-secrets, key: DB_MYSQLDB_PORT}}
            - name: DB_MYSQLDB_DATABASE
              valueFrom: {secretKeyRef: {name: n8n-secrets, key: DB_MYSQLDB_DATABASE}}
            - name: DB_MYSQLDB_USER
              valueFrom: {secretKeyRef: {name: n8n-secrets, key: DB_MYSQLDB_USER}}
            - name: DB_MYSQLDB_PASSWORD
              valueFrom: {secretKeyRef: {name: n8n-secrets, key: DB_MYSQLDB_PASSWORD}}
            - name: N8N_ENCRYPTION_KEY
              valueFrom: {secretKeyRef: {name: n8n-secrets, key: N8N_ENCRYPTION_KEY}}
          volumeMounts:
            - name: data
              mountPath: /home/node/.n8n
          resources:
            requests: {memory: "512Mi", cpu: "250m"}
            limits: {memory: "2Gi", cpu: "1000m"}
          livenessProbe:
            httpGet: {path: /healthz, port: 5678}
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet: {path: /healthz, port: 5678}
            initialDelaySeconds: 10
            periodSeconds: 5
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: n8n-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: n8n-service
  namespace: $NAMESPACE
spec:
  selector:
    app: n8n
  ports:
    - port: 80
      targetPort: 5678
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: n8n-ingress
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    alb.ingress.kubernetes.io/certificate-arn: $ACM_CERTIFICATE_ARN
    alb.ingress.kubernetes.io/healthcheck-path: /healthz
spec:
  ingressClassName: alb
  rules:
    - host: $N8N_DOMAIN
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: n8n-service
                port:
                  number: 80
"@ | Out-File -FilePath $GeneratedFile -Encoding UTF8

Write-Host "✓ 清单已生成" -ForegroundColor Green

#-------------------------------------------------------------------------------
# 3. 部署到集群
#-------------------------------------------------------------------------------
Write-Host ""
Write-Host "[3/4] 部署到 Kubernetes..." -ForegroundColor Yellow

kubectl apply -f $GeneratedFile

Write-Host ""
Write-Host "[4/4] 等待 Pod 就绪..." -ForegroundColor Yellow
try {
    kubectl wait --for=condition=ready pod -l app=n8n -n $NAMESPACE --timeout=180s
}
catch {}

#-------------------------------------------------------------------------------
# 完成
#-------------------------------------------------------------------------------
Write-Host ""
Write-Host "════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✓ 部署完成!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "  访问地址: https://$N8N_DOMAIN"
Write-Host ""
Write-Host "  下一步:"
Write-Host "  1. 获取 ALB 地址: kubectl get ingress -n $NAMESPACE"
Write-Host "  2. 配置 DNS: 将 $N8N_DOMAIN 指向 ALB"
Write-Host "  3. 访问 N8N 创建管理员账户"
Write-Host ""
Write-Host "  常用命令:"
Write-Host "  kubectl get pods -n $NAMESPACE"
Write-Host "  kubectl logs -f deployment/n8n -n $NAMESPACE"
Write-Host ""
