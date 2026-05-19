<#
.SYNOPSIS
    SmartDiskThrottle v1.2 Auto-Installer
.DESCRIPTION
    Downloads, installs, and configures SmartDiskThrottle to run automatically at login.
    Requires Administrator privileges.
.LINK
    https://github.com/BibekG1/SmartDiskThrottle
#>

[CmdletBinding()]
param(
    [string]$RepoOwner = "BibekG1",
    [string]$RepoName  = "SmartDiskThrottle",
    [string]$Branch    = "main",
    [string]$InstallPath = "C:\Scripts"
)

# === 🔐 Run as Administrator Check ===
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ Please run as Administrator. Right-click PowerShell → 'Run as Administrator'" -ForegroundColor Red
    exit 1
}

# === 🌐 GitHub Raw URLs ===
$baseUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch/src"
$scriptUrl = "$baseUrl/SmartDiskThrottle.ps1"
$taskUrl   = "$baseUrl/SmartDiskThrottle_Task.xml"

# === 📥 Download Files ===
Write-Host "📥 Downloading SmartDiskThrottle v1.2..." -ForegroundColor Cyan

try {
    # Create install directory
    if (-not (Test-Path $InstallPath)) {
        New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null
    }

    # Download script
    $scriptPath = Join-Path $InstallPath "SmartDiskThrottle.ps1"
    Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptPath -UseBasicParsing -ErrorAction Stop
    Write-Host "✅ Script downloaded: $scriptPath" -ForegroundColor Green

    # Download task XML
    $taskPath = Join-Path $InstallPath "SmartDiskThrottle_Task.xml"
    Invoke-WebRequest -Uri $taskUrl -OutFile $taskPath -UseBasicParsing -ErrorAction Stop
    Write-Host "✅ Task config downloaded: $taskPath" -ForegroundColor Green

} catch {
    Write-Host "❌ Download failed: $_" -ForegroundColor Red
    Write-Host "💡 Check: 1) Internet connection 2) GitHub URL is public 3) Correct repo/branch" -ForegroundColor Yellow
    exit 1
}

# === ⚙️ Configure Execution Policy (if needed) ===
$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser -ErrorAction SilentlyContinue
if ($currentPolicy -eq 'Restricted' -or $currentPolicy -eq 'AllSigned') {
    Write-Host "🔓 Setting ExecutionPolicy to RemoteSigned (current user only)..." -ForegroundColor Yellow
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue
}

# === 🗓️ Import Task Scheduler Task ===
Write-Host "🗓️ Registering Task Scheduler task..." -ForegroundColor Cyan
try {
    # Unregister if exists (clean reinstall)
    Get-ScheduledTask -TaskName "SmartDiskThrottle" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false

    # Import new task
    Register-ScheduledTask -Xml (Get-Content $taskPath | Out-String) -TaskName "SmartDiskThrottle" -Force -ErrorAction Stop
    Write-Host "✅ Task 'SmartDiskThrottle' registered successfully" -ForegroundColor Green

    # Enable the task
    Enable-ScheduledTask -TaskName "SmartDiskThrottle" -ErrorAction SilentlyContinue

} catch {
    Write-Host "❌ Task registration failed: $_" -ForegroundColor Red
    exit 1
}

# === ✅ Final Verification ===
Write-Host "`n🔍 Verifying installation..." -ForegroundColor Cyan
$task = Get-ScheduledTask -TaskName "SmartDiskThrottle" -ErrorAction SilentlyContinue
if ($task -and $task.State -eq 'Ready') {
    Write-Host "✅ SmartDiskThrottle is installed and ready!" -ForegroundColor Green
    Write-Host "📝 Logs will appear at: %TEMP%\SmartDiskThrottle.log" -ForegroundColor Gray
    Write-Host "🔄 Task will start automatically at next login (with 1-min delay)" -ForegroundColor Gray
    Write-Host "`n🛠️ To manage: Open Task Scheduler → Library → SmartDiskThrottle" -ForegroundColor Gray
} else {
    Write-Host "⚠️ Task registered but not in 'Ready' state. Please check Task Scheduler manually." -ForegroundColor Yellow
}

# === 🎯 Quick Commands Reference ===
Write-Host "`n📋 Quick Reference:" -ForegroundColor Cyan
Write-Host "  • Pause throttling:    Disable task in Task Scheduler" -ForegroundColor Gray
Write-Host "  • View logs:           notepad `"$env:TEMP\SmartDiskThrottle.log`"" -ForegroundColor Gray
Write-Host "  • Uninstall:           Unregister-ScheduledTask -TaskName 'SmartDiskThrottle'; Remove-Item 'C:\Scripts\SmartDiskThrottle*' -Force" -ForegroundColor Gray
Write-Host "  • Update:              Re-run this installer" -ForegroundColor Gray

Write-Host "`n🎉 Installation complete! Reboot to activate." -ForegroundColor Green
