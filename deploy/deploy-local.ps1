<#
.SYNOPSIS
    AI Platform - Local Deployment Script (Windows)

.DESCRIPTION
    Deploy all AI Platform services to local Docker environment

.EXAMPLE
    .\deploy-local.ps1
    .\deploy-local.ps1 -Clean
#>

param(
    [switch]$Clean,
    [switch]$Rebuild
)

$ErrorActionPreference = "Stop"

# Color output functions
function Write-Step { param($msg) Write-Host "[*] $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "[+] $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "[!] $msg" -ForegroundColor Yellow }
function Write-Err { param($msg) Write-Host "[-] $msg" -ForegroundColor Red }

# Header
Write-Host ""
Write-Host "============================================================" -ForegroundColor Blue
Write-Host "           AI Platform - Local Deployment v4.0              " -ForegroundColor Blue
Write-Host "============================================================" -ForegroundColor Blue
Write-Host ""

# Change to script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# Step 1: Check Docker
Write-Step "Checking Docker environment..."
try {
    docker info | Out-Null
    Write-Success "Docker is running"
}
catch {
    Write-Err "Docker is not running. Please start Docker Desktop first."
    exit 1
}

# Step 2: Check and create .env file
Write-Step "Checking environment configuration..."
if (-not (Test-Path ".env")) {
    if (Test-Path ".env.local") {
        Copy-Item ".env.local" ".env"
        Write-Success "Created .env from .env.local"
    }
    else {
        Write-Err "Missing .env.local configuration file"
        exit 1
    }
}
else {
    Write-Success ".env configuration exists"
}

# Step 3: Clean (if specified)
if ($Clean) {
    Write-Step "Cleaning existing containers and data..."
    docker compose down -v 2>$null
    Write-Success "Cleanup completed"
}

# Step 4: Pull images
Write-Step "Pulling Docker images (this may take a few minutes on first run)..."
docker compose pull
Write-Success "Image pull completed"

# Step 5: Start services
Write-Step "Starting all services..."
if ($Rebuild) {
    docker compose up -d --build --force-recreate
}
else {
    docker compose up -d
}

# Step 6: Wait for health checks
Write-Step "Waiting for services to start..."
$maxWait = 120
$waited = 0
while ($waited -lt $maxWait) {
    Start-Sleep -Seconds 5
    $waited += 5
    
    # Check critical services
    $pgHealth = docker inspect ai-platform-postgres --format='{{.State.Health.Status}}' 2>$null
    $redisHealth = docker inspect ai-platform-redis --format='{{.State.Health.Status}}' 2>$null
    $difyHealth = docker inspect ai-platform-dify-api --format='{{.State.Health.Status}}' 2>$null
    
    Write-Host "  PostgreSQL: $pgHealth | Redis: $redisHealth | Dify: $difyHealth" -ForegroundColor Gray
    
    if ($pgHealth -eq "healthy" -and $redisHealth -eq "healthy" -and $difyHealth -eq "healthy") {
        break
    }
}

# Step 7: Fix storage permissions (required for Dify)
Write-Step "Fixing Dify storage permissions..."
docker exec -u root ai-platform-dify-api chown -R dify:dify /app/api/storage 2>$null
Write-Success "Permission fix completed"

# Step 8: Show status
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "                  Deployment Complete!                      " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

Write-Host ""
Write-Host "Access URLs:" -ForegroundColor Cyan
Write-Host "  Dify:     http://localhost:3000" -ForegroundColor White
Write-Host "  N8N:      http://localhost:5678" -ForegroundColor White
Write-Host "  Weaviate: http://localhost:8080" -ForegroundColor White
Write-Host ""
Write-Host "Please complete Dify admin account setup on first use." -ForegroundColor Yellow
Write-Host ""
