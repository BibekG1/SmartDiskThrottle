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
    Read-Host -Prompt "Press Enter to exit"
    exit 1
}

# === 🌐 GitHub Raw URLs ===
$baseUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch/src"
$scriptUrl = "$baseUrl/SmartDiskThrottle.ps1"
$taskUrl   = "$baseUrl/SmartDiskThrottle_Task.xml"

# === 📥 Download Files ===
Write-Host "📥 Downloading SmartDiskThrottle v1.2..." -ForegroundColor Cyan

try {
    if (-not (Test-Path $InstallPath)) {
        New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null
    }

    $scriptPath = Join-Path $InstallPath "SmartDiskThrottle.ps1"
    Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptPath -UseBasicParsing -ErrorAction Stop
    Write-Host "✅ Script downloaded: $scriptPath" -ForegroundColor Green

    $taskPath = Join-Path $InstallPath "SmartDiskThrottle_Task.xml"
    Invoke-WebRequest -Uri $taskUrl -OutFile $taskPath -UseBasicParsing -ErrorAction Stop
    Write-Host "✅ Task config downloaded: $taskPath" -ForegroundColor Green

} catch {
    Write-Host "❌ Download failed: $_" -ForegroundColor Red
    Write-Host "💡 Check: 1) Internet 2) GitHub URL is public 3) Correct repo/branch" -ForegroundColor Yellow
    Read-Host -Prompt "Press Enter to exit"
    exit 1
}

# === ⚙️ Configure Execution Policy ===
$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser -ErrorAction SilentlyContinue
if ($currentPolicy -eq 'Restricted' -or $currentPolicy -eq 'AllSigned') {
    Write-Host "🔓 Setting ExecutionPolicy to RemoteSigned (current user only)..." -ForegroundColor Yellow
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue
}

# === 🗓️ Register Task Scheduler Task (Robust Method) ===
Write-Host "🗓️ Registering Task Scheduler task..." -ForegroundColor Cyan
try {
    # Clean up existing task first
    Get-ScheduledTask -TaskName "SmartDiskThrottle" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false

    # Read XML with correct encoding (UTF-16 as declared in file)
    $xmlContent = Get-Content -Path $taskPath -Raw -Encoding UTF8

    # Register the task
    Register-ScheduledTask -Xml $xmlContent -TaskName "SmartDiskThrottle" -Force -ErrorAction Stop

    # Enable and verify
    Enable-ScheduledTask -TaskName "SmartDiskThrottle" -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    $task = Get-ScheduledTask -TaskName "SmartDiskThrottle" -ErrorAction Stop

    if ($task.State -eq 'Ready') {
        Write-Host "✅ Task 'SmartDiskThrottle' registered and ready" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Task registered but state is: $($task.State)" -ForegroundColor Yellow
    }

} catch {
    Write-Host "❌ Task registration failed: $_" -ForegroundColor Red
    Write-Host "`n🔧 Try manual import:" -ForegroundColor Yellow
    Write-Host "1. Open Task Scheduler as Admin" -ForegroundColor Gray
    Write-Host "2. Right-click 'Task Scheduler Library' → 'Import Task...'" -ForegroundColor Gray
    Write-Host "3. Select: $taskPath" -ForegroundColor Gray
    Write-Host "4. Click OK and confirm" -ForegroundColor Gray
    Read-Host -Prompt "Press Enter to exit"
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
    Write-Host "⚠️ Task not in 'Ready' state. Please check Task Scheduler manually." -ForegroundColor Yellow
}

# === 🎯 Quick Reference ===
Write-Host "`n📋 Quick Reference:" -ForegroundColor Cyan
Write-Host "  • Pause throttling:    Disable task in Task Scheduler" -ForegroundColor Gray
Write-Host "  • View logs:           notepad `"$env:TEMP\SmartDiskThrottle.log`"" -ForegroundColor Gray
Write-Host "  • Uninstall:           Unregister-ScheduledTask -TaskName 'SmartDiskThrottle'; Remove-Item 'C:\Scripts\SmartDiskThrottle*' -Force" -ForegroundColor Gray
Write-Host "  • Update:              Re-run this installer" -ForegroundColor Gray

Write-Host "`n🎉 Installation complete! Reboot to activate." -ForegroundColor Green
Read-Host -Prompt "Press Enter to exit"
