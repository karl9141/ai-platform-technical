#!/bin/bash
# =============================================================================
# AI Platform - Local Deployment Script (Linux/Mac)
# =============================================================================

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Output functions
step() { echo -e "${CYAN}[*] $1${NC}"; }
success() { echo -e "${GREEN}[+] $1${NC}"; }
warn() { echo -e "${YELLOW}[!] $1${NC}"; }
error() { echo -e "${RED}[-] $1${NC}"; exit 1; }

# Header
echo ""
echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}           AI Platform - Local Deployment v4.0              ${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

# Change to script directory
cd "$(dirname "$0")"

# Step 1: Check Docker
step "Checking Docker environment..."
if ! docker info > /dev/null 2>&1; then
    error "Docker is not running. Please start Docker first."
fi
success "Docker is running"

# Step 2: Check .env file
step "Checking environment configuration..."
if [ ! -f ".env" ]; then
    if [ -f ".env.local" ]; then
        cp .env.local .env
        success "Created .env from .env.local"
    else
        error "Missing .env.local configuration file"
    fi
else
    success ".env configuration exists"
fi

# Step 3: Clean (if specified --clean)
if [ "$1" = "--clean" ]; then
    step "Cleaning existing containers and data..."
    docker compose down -v 2>/dev/null || true
    success "Cleanup completed"
fi

# Step 4: Pull images
step "Pulling Docker images..."
docker compose pull
success "Image pull completed"

# Step 5: Start services
step "Starting all services..."
docker compose up -d

# Step 6: Wait for health checks
step "Waiting for services to start..."
max_wait=120
waited=0
while [ $waited -lt $max_wait ]; do
    sleep 5
    waited=$((waited + 5))
    
    pg_health=$(docker inspect ai-platform-postgres --format='{{.State.Health.Status}}' 2>/dev/null || echo "starting")
    redis_health=$(docker inspect ai-platform-redis --format='{{.State.Health.Status}}' 2>/dev/null || echo "starting")
    dify_health=$(docker inspect ai-platform-dify-api --format='{{.State.Health.Status}}' 2>/dev/null || echo "starting")
    
    echo "  PostgreSQL: $pg_health | Redis: $redis_health | Dify: $dify_health"
    
    if [ "$pg_health" = "healthy" ] && [ "$redis_health" = "healthy" ] && [ "$dify_health" = "healthy" ]; then
        break
    fi
done

# Step 7: Fix storage permissions
step "Fixing Dify storage permissions..."
docker exec -u root ai-platform-dify-api chown -R dify:dify /app/api/storage 2>/dev/null || true
success "Permission fix completed"

# Step 8: Show status
echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}                  Deployment Complete!                      ${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""

docker compose ps

echo ""
echo -e "${CYAN}Access URLs:${NC}"
echo "  Dify:     http://localhost:3000"
echo "  N8N:      http://localhost:5678"
echo "  Weaviate: http://localhost:8080"
echo ""
echo -e "${YELLOW}Please complete N8N and Dify admin account setup on first use.${NC}"
echo ""
