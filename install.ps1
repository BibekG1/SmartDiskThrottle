<#
.SYNOPSIS
    SmartDiskThrottle v1.2 Auto-Installer
.DESCRIPTION
    Downloads and configures SmartDiskThrottle to run automatically at login.
    Uses native PowerShell Scheduled Task cmdlets (no XML import).
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

# === 🔐 Admin Check ===
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ Please run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# === 🌐 GitHub URL ===
$scriptUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch/src/SmartDiskThrottle.ps1"
$scriptPath = Join-Path $InstallPath "SmartDiskThrottle.ps1"

# === 📥 Download Core Script ===
Write-Host "📥 Downloading SmartDiskThrottle v1.2..." -ForegroundColor Cyan
try {
    if (-not (Test-Path $InstallPath)) { New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null }
    Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptPath -UseBasicParsing -ErrorAction Stop
    Write-Host "✅ Script downloaded: $scriptPath" -ForegroundColor Green
} catch {
    Write-Host "❌ Download failed: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# === ⚙️ Execution Policy ===
$policy = Get-ExecutionPolicy -Scope CurrentUser -ErrorAction SilentlyContinue
if ($policy -match 'Restricted|AllSigned') {
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue
}

# === 🗓️ Create Task via Native PowerShell (No XML) ===
Write-Host "🗓️ Creating Task Scheduler task..." -ForegroundColor Cyan
try {
    # Clean up existing
    Get-ScheduledTask -TaskName "SmartDiskThrottle" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false

    # Action
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -NoProfile -File `"$scriptPath`""

    # Trigger (At logon + 1 min delay)
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $trigger.Delay = "PT1M"

    # Principal (Run as Admin group, highest privileges)
    $principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest

    # Settings (Allow on battery, don't stop on battery, hidden, infinite runtime, restart on failure)
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -Hidden `
        -ExecutionTimeLimit (New-TimeSpan -Minutes 0) `
        -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 5)

    # Register Task
    Register-ScheduledTask -TaskName "SmartDiskThrottle" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force -ErrorAction Stop

    # Verify
    Start-Sleep 2
    $task = Get-ScheduledTask -TaskName "SmartDiskThrottle"
    if ($task.State -eq 'Ready') {
        Write-Host "✅ Task registered and ready!" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Task state: $($task.State)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Task creation failed: $_" -ForegroundColor Red
    Write-Host "`n💡 Tip: Run PowerShell via 'Start-Process powershell -Verb RunAs' if token elevation fails." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# === ✅ Success ===
Write-Host "`n✅ Installation complete!" -ForegroundColor Green
Write-Host "📝 Logs: %TEMP%\SmartDiskThrottle.log" -ForegroundColor Gray
Write-Host "🔄 Starts automatically at next login." -ForegroundColor Gray
Read-Host "Press Enter to exit"
