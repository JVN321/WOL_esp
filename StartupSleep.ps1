# Load environment variables from .env file
$envFile = Join-Path $PSScriptRoot ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Variable -Name $name -Value $value -Scope Script
        }
    }
} else {
    Write-Error "Environment file not found: $envFile"
    exit 1
}

# Set your bot token and chat ID from environment variables
$botToken = $BOT_TOKEN
$chatId = $CHAT_ID
$message = "🔥PC turned on"

# Telegram API URL
$uri = "https://api.telegram.org/bot$botToken/sendMessage"

# Prepare message body
$body = @{
    chat_id = $chatId
    text    = $message
}

# Send the message
Invoke-RestMethod -Uri $uri -Method Post -Body $body

# Wait for 5 minutes (300 seconds)
Start-Sleep -Seconds 30

# Check if any user is logged in (not on lock screen)
$activeSession = quser 2>$null | Where-Object { $_ -match "Active" -and $_ -notmatch "Disc" }

if (-not $activeSession) {
    # No active user session, send sleep message
    $sleepMessage = "😴 PC going to sleep"
    $sleepBody = @{
        chat_id = $chatId
        text    = $sleepMessage
    }
    
    # Send sleep notification
    Invoke-RestMethod -Uri $uri -Method Post -Body $sleepBody
    
    # Put PC to sleep
    Start-Sleep -Seconds 5  # Brief delay to ensure message is sent
    rundll32.exe powrprof.dll,SetSuspendState 0,1,0
} else {
    # Active user session found, send debug message
    $debugMessage = "👤 Active user session detected"
    $debugBody = @{
        chat_id = $chatId
        text    = $debugMessage
    }
    
    # Send debug notification
    Invoke-RestMethod -Uri $uri -Method Post -Body $debugBody
}

# Check if desktop is locked or user is not actively using the system
Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    public class User32 {
        [DllImport("user32.dll")]
        public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);
        
        [DllImport("user32.dll")]
        public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, ref bool pvParam, uint fWinIni);
        
        public struct LASTINPUTINFO {
            public uint cbSize;
            public uint dwTime;
        }
    }
"@

# Check if screen is locked
$SPI_GETSCREENSAVERRUNNING = 0x0072
$isScreenSaverRunning = $false
[User32]::SystemParametersInfo($SPI_GETSCREENSAVERRUNNING, 0, [ref]$isScreenSaverRunning, 0)

# Check if workstation is locked
$isLocked = $false
try {
    $lockInfo = Get-Process -Name "LogonUI" -ErrorAction SilentlyContinue
    if ($lockInfo) { $isLocked = $true }
} catch {}

if ($isLocked -or $isScreenSaverRunning) {
    # Desktop is locked or screensaver running, send sleep message
    $sleepMessage = "😴 PC going to sleep"
    $sleepBody = @{
        chat_id = $chatId
        text    = $sleepMessage
    }
    
    # Send sleep notification
    Invoke-RestMethod -Uri $uri -Method Post -Body $sleepBody
    
    # Put PC to sleep
    Start-Sleep -Seconds 5  # Brief delay to ensure message is sent
    rundll32.exe powrprof.dll,SetSuspendState 0,1,0
} else {
    # Desktop is unlocked and active, send debug message
    $debugMessage = "👤 Desktop is unlocked and active"
    $debugBody = @{
        chat_id = $chatId
        text    = $debugMessage
    }
    
    # Send debug notification
    Invoke-RestMethod -Uri $uri -Method Post -Body $debugBody
}
