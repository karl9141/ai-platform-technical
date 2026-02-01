#!/bin/bash
#===============================================================================
# N8N 一键部署到 AWS EKS
# 
# 使用方法:
#   1. 修改 values.yaml 中的配置
#   2. 运行: ./deploy.sh
#===============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VALUES_FILE="$SCRIPT_DIR/values.yaml"
NAMESPACE="n8n"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║     N8N Deployment to AWS EKS             ║"
echo "╚═══════════════════════════════════════════╝"
echo ""

#-------------------------------------------------------------------------------
# 1. 读取配置
#-------------------------------------------------------------------------------
echo "[1/4] 读取配置..."

# 解析 YAML 配置
parse_yaml() {
    grep "^$1:" "$VALUES_FILE" | sed "s/$1: *\"\{0,1\}\([^\"]*\)\"\{0,1\}/\1/" | tr -d '\r'
}

DB_HOST=$(parse_yaml "DB_HOST")
DB_PORT=$(parse_yaml "DB_PORT")
DB_NAME=$(parse_yaml "DB_NAME")
DB_USER=$(parse_yaml "DB_USER")
DB_PASSWORD=$(parse_yaml "DB_PASSWORD")
N8N_DOMAIN=$(parse_yaml "N8N_DOMAIN")
N8N_ENCRYPTION_KEY=$(parse_yaml "N8N_ENCRYPTION_KEY")
ACM_CERTIFICATE_ARN=$(parse_yaml "ACM_CERTIFICATE_ARN")
TIMEZONE=$(parse_yaml "TIMEZONE")
STORAGE_SIZE=$(parse_yaml "STORAGE_SIZE")
STORAGE_CLASS=$(parse_yaml "STORAGE_CLASS")

# 设置默认值
TIMEZONE=${TIMEZONE:-"Asia/Tokyo"}
STORAGE_SIZE=${STORAGE_SIZE:-"10Gi"}
STORAGE_CLASS=${STORAGE_CLASS:-"gp3"}

# 生成加密密钥（如果未提供）
if [ -z "$N8N_ENCRYPTION_KEY" ]; then
    N8N_ENCRYPTION_KEY=$(openssl rand -hex 16 2>/dev/null || cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 32 | head -n 1)
    echo -e "${GREEN}✓ 已自动生成加密密钥${NC}"
fi

# 验证必填项
if [ -z "$DB_HOST" ] || [ "$DB_HOST" = "your-rds-endpoint.ap-northeast-1.rds.amazonaws.com" ]; then
    echo -e "${RED}✗ 请在 values.yaml 中配置 DB_HOST${NC}"
    exit 1
fi
if [ -z "$N8N_DOMAIN" ] || [ "$N8N_DOMAIN" = "n8n.your-domain.com" ]; then
    echo -e "${RED}✗ 请在 values.yaml 中配置 N8N_DOMAIN${NC}"
    exit 1
fi
if [ -z "$ACM_CERTIFICATE_ARN" ] || [[ "$ACM_CERTIFICATE_ARN" == *"YOUR_"* ]]; then
    echo -e "${RED}✗ 请在 values.yaml 中配置 ACM_CERTIFICATE_ARN${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 配置验证通过${NC}"
echo "  域名: $N8N_DOMAIN"
echo "  数据库: $DB_HOST"

#-------------------------------------------------------------------------------
# 2. 生成 Kubernetes 清单
#-------------------------------------------------------------------------------
echo ""
echo "[2/4] 生成 Kubernetes 清单..."

cat > "$SCRIPT_DIR/.generated.yaml" << EOF
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
EOF

echo -e "${GREEN}✓ 清单已生成${NC}"

#-------------------------------------------------------------------------------
# 3. 部署到集群
#-------------------------------------------------------------------------------
echo ""
echo "[3/4] 部署到 Kubernetes..."

kubectl apply -f "$SCRIPT_DIR/.generated.yaml"

echo ""
echo "[4/4] 等待 Pod 就绪..."
kubectl wait --for=condition=ready pod -l app=n8n -n $NAMESPACE --timeout=180s 2>/dev/null || true

#-------------------------------------------------------------------------------
# 完成
#-------------------------------------------------------------------------------
echo ""
echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ 部署完成!${NC}"
echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo ""
echo "  访问地址: https://$N8N_DOMAIN"
echo ""
echo "  下一步:"
echo "  1. 获取 ALB 地址: kubectl get ingress -n $NAMESPACE"
echo "  2. 配置 DNS: 将 $N8N_DOMAIN 指向 ALB"
echo "  3. 访问 N8N 创建管理员账户"
echo ""
echo "  常用命令:"
echo "  kubectl get pods -n $NAMESPACE"
echo "  kubectl logs -f deployment/n8n -n $NAMESPACE"
echo ""
