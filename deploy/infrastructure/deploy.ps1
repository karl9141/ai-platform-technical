<#
.SYNOPSIS
    AI Platform 一键部署脚本 (Windows PowerShell)
.DESCRIPTION
    自动部署完整的 AI 辅助平台环境
.EXAMPLE
    .\deploy.ps1
    .\deploy.ps1 -Action start
    .\deploy.ps1 -Action stop
    .\deploy.ps1 -Action restart
    .\deploy.ps1 -Action status
    .\deploy.ps1 -Action logs
    .\deploy.ps1 -Action clean
#>

param(
    [ValidateSet("start", "stop", "restart", "status", "logs", "clean", "backup")]
    [string]$Action = "start"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 颜色输出函数
function Write-Title { Write-Host "`n$args" -ForegroundColor Cyan }
function Write-Success { Write-Host "✅ $args" -ForegroundColor Green }
function Write-Warning { Write-Host "⚠️  $args" -ForegroundColor Yellow }
function Write-Error { Write-Host "❌ $args" -ForegroundColor Red }
function Write-Info { Write-Host "ℹ️  $args" -ForegroundColor Blue }

# Banner
function Show-Banner {
    Write-Host @"

    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║     🤖 AI Platform - One-Click Deployment                ║
    ║                                                           ║
    ║     N8N + Dify + PostgreSQL + Redis + Weaviate          ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan
}

# 检查 Docker
function Test-Docker {
    Write-Title "检查 Docker 环境..."
    
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "Docker 未安装，请先安装 Docker Desktop"
        exit 1
    }
    
    try {
        docker info | Out-Null
        Write-Success "Docker 运行正常"
    }
    catch {
        Write-Error "Docker 未启动，请先启动 Docker Desktop"
        exit 1
    }
    
    if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
        if (-not (docker compose version 2>$null)) {
            Write-Error "Docker Compose 未安装"
            exit 1
        }
    }
    Write-Success "Docker Compose 可用"
}

# 初始化环境
function Initialize-Environment {
    Write-Title "初始化环境配置..."
    
    Set-Location $ScriptDir
    
    # 创建 .env 文件
    if (-not (Test-Path ".env")) {
        if (Test-Path ".env.example") {
            Copy-Item ".env.example" ".env"
            
            # 生成随机密钥
            $randomKey = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object { [char]$_ })
            $envContent = Get-Content ".env" -Raw
            $envContent = $envContent -replace "your-32-char-encryption-key-here", $randomKey
            $envContent = $envContent -replace "sk-your-dify-secret-key-at-least-32-chars", "sk-$randomKey"
            Set-Content ".env" $envContent
            
            Write-Success "已创建 .env 配置文件（密钥已自动生成）"
        }
        else {
            Write-Warning ".env.example 不存在，使用默认配置"
        }
    }
    else {
        Write-Info ".env 文件已存在，跳过初始化"
    }
    
    # 创建必要目录
    $dirs = @("backup", "n8n/workflows")
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    Write-Success "目录结构已就绪"
}

# 启动服务
function Start-Services {
    Write-Title "启动 AI Platform 服务..."
    
    Set-Location $ScriptDir
    
    # 拉取镜像
    Write-Info "拉取最新镜像..."
    docker-compose pull
    
    # 启动服务
    Write-Info "启动服务容器..."
    docker-compose up -d
    
    # 等待服务就绪
    Write-Info "等待服务启动..."
    $maxWait = 120
    $waited = 0
    
    while ($waited -lt $maxWait) {
        Start-Sleep -Seconds 5
        $waited += 5
        
        $healthy = docker-compose ps --format json 2>$null | ConvertFrom-Json | 
        Where-Object { $_.Health -eq "healthy" -or $_.State -eq "running" }
        
        if ($healthy.Count -ge 7) {
            break
        }
        
        Write-Host "." -NoNewline
    }
    Write-Host ""
    
    # 显示状态
    Show-Status
    
    Write-Host ""
    Write-Success "AI Platform 部署完成!"
    Write-Host ""
    Write-Host "  📊 访问地址:" -ForegroundColor Yellow
    Write-Host "     N8N:  http://localhost:5678" -ForegroundColor White
    Write-Host "     Dify: http://localhost:3000" -ForegroundColor White
    Write-Host ""
    Write-Host "  📝 首次使用:" -ForegroundColor Yellow
    Write-Host "     1. 访问 Dify 创建管理员账户" -ForegroundColor White
    Write-Host "     2. 配置 OpenAI API Key" -ForegroundColor White
    Write-Host "     3. 访问 N8N 创建工作流" -ForegroundColor White
    Write-Host ""
}

# 停止服务
function Stop-Services {
    Write-Title "停止 AI Platform 服务..."
    Set-Location $ScriptDir
    docker-compose stop
    Write-Success "服务已停止"
}

# 重启服务
function Restart-Services {
    Write-Title "重启 AI Platform 服务..."
    Set-Location $ScriptDir
    docker-compose restart
    Write-Success "服务已重启"
}

# 显示状态
function Show-Status {
    Write-Title "服务状态"
    Set-Location $ScriptDir
    docker-compose ps
}

# 查看日志
function Show-Logs {
    Write-Title "查看日志 (Ctrl+C 退出)"
    Set-Location $ScriptDir
    docker-compose logs -f --tail=100
}

# 清理环境
function Clear-Environment {
    Write-Title "清理 AI Platform 环境..."
    
    $confirm = Read-Host "确定要清理所有数据吗? (输入 'yes' 确认)"
    if ($confirm -ne "yes") {
        Write-Warning "操作已取消"
        return
    }
    
    Set-Location $ScriptDir
    docker-compose down -v --remove-orphans
    
    Write-Success "环境已清理"
}

# 备份数据
function Backup-Data {
    Write-Title "备份数据..."
    
    Set-Location $ScriptDir
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = "backup/$timestamp"
    
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    
    # 备份 PostgreSQL
    Write-Info "备份 PostgreSQL..."
    docker exec ai-platform-postgres pg_dumpall -U postgres > "$backupDir/postgres_dump.sql"
    
    Write-Success "备份完成: $backupDir"
}

# 主程序
Show-Banner

switch ($Action) {
    "start" {
        Test-Docker
        Initialize-Environment
        Start-Services
    }
    "stop" {
        Stop-Services
    }
    "restart" {
        Restart-Services
    }
    "status" {
        Show-Status
    }
    "logs" {
        Show-Logs
    }
    "clean" {
        Clear-Environment
    }
    "backup" {
        Backup-Data
    }
}
