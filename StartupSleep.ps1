# Load environment variables from .env file
$envFile = Join-Path $PSScriptRoot ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            
            # Remove inline comments (everything after #)
            if ($value -match '^([^#]*)#.*$') {
                $value = $matches[1].Trim()
            }
            
            Set-Variable -Name $name -Value $value -Scope Script
        }
    }
} else {
    Write-Error "Environment file not found: $envFile"
    exit 1
}

# Function to send Telegram message
function Send-TelegramMessage {
    param(
        [string]$Message,
        [string]$BotToken,
        [string]$ChatId
    )
    
    $uri = "https://api.telegram.org/bot$BotToken/sendMessage"
    $body = @{
        chat_id = $ChatId
        text = $Message
        parse_mode = "Markdown"
    }
    
    try {
        Invoke-RestMethod -Uri $uri -Method Post -Body $body -ErrorAction Stop
    }
    catch {
        Write-Host "Failed to send Telegram message: $_"
    }
}

# Function to execute command and return output
function Execute-Command {
    param(
        [string]$Command
    )
    
    try {
        # Execute the command and capture output
        $output = Invoke-Expression $Command 2>&1 | Out-String
        
        # Limit output to 4000 characters (Telegram message limit is 4096)
        if ($output.Length -gt 4000) {
            $output = $output.Substring(0, 4000) + "`n... (output truncated)"
        }
        
        return "✅ Command executed successfully:`n``````n$output`n``````"
    }
    catch {
        return "❌ Command failed:`n``````n$($_.Exception.Message)`n``````"
    }
}

# Function to get Telegram updates
function Get-TelegramUpdates {
    param(
        [string]$BotToken,
        [int]$Offset = 0
    )
    
    $uri = "https://api.telegram.org/bot$BotToken/getUpdates"
    $body = @{
        offset = $Offset
        timeout = 10
    }
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ErrorAction Stop
        return $response.result
    }
    catch {
        Write-Host "Failed to get Telegram updates: $_"
        return @()
    }
}

# Function to process Telegram messages
function Process-TelegramMessages {
    param(
        [string]$BotToken,
        [string]$ChatId
    )
    
    $lastUpdateId = 0
    $updateFile = Join-Path $PSScriptRoot "last_update.txt"
    
    # Load last update ID if exists
    if (Test-Path $updateFile) {
        $lastUpdateId = [int](Get-Content $updateFile -ErrorAction SilentlyContinue)
    }
    
    while ($true) {
        $updates = Get-TelegramUpdates -BotToken $BotToken -Offset ($lastUpdateId + 1)
        
        foreach ($update in $updates) {
            $lastUpdateId = $update.update_id
            
            # Only process messages from the authorized chat
            if ($update.message.chat.id -eq $ChatId) {
                $messageText = $update.message.text
                
                # Check if message starts with /cmd
                if ($messageText -match '^/cmd\s+(.+)$') {
                    $command = $matches[1]
                    Send-TelegramMessage -Message "🔄 Executing command: ``$command``" -BotToken $BotToken -ChatId $ChatId
                    
                    $result = Execute-Command -Command $command
                    Send-TelegramMessage -Message $result -BotToken $BotToken -ChatId $ChatId
                }
                # Check for help command
                elseif ($messageText -eq "/help") {
                    $helpMessage = @"
🤖 **PC Remote Control Commands**

**/cmd [command]** - Execute command line command
Example: ``/cmd dir C:\``
Example: ``/cmd Get-Process | Select-Object -First 5``

**/help** - Show this help message

⚠️ **Security Note**: Only use trusted commands. Avoid commands that might hang or require user input.
"@
                    Send-TelegramMessage -Message $helpMessage -BotToken $BotToken -ChatId $ChatId
                }
            }
        }
        
        # Save last update ID
        $lastUpdateId | Out-File -FilePath $updateFile -Encoding utf8
        
        # Short delay to prevent excessive API calls
        Start-Sleep -Seconds 5
    }
}

# Set your bot token and chat ID from environment variables
$botToken = $BOT_TOKEN
$chatId = $CHAT_ID
$sleepTime = if ($SLEEP_TIME) { [int]$SLEEP_TIME } else { 30 }  # Default to 30 seconds if not specified
$enableCommandListener = if ($ENABLE_COMMAND_LISTENER) { $ENABLE_COMMAND_LISTENER -eq "true" } else { $false }
$message = "🔥PC turned on"

# Send startup notification
Send-TelegramMessage -Message $message -BotToken $botToken -ChatId $chatId

# Start command listener in background job if enabled
$commandListenerJob = $null
if ($enableCommandListener) {
    Send-TelegramMessage -Message "🎯 Command listener enabled. Send /help for available commands." -BotToken $botToken -ChatId $chatId
    
    $commandListenerJob = Start-Job -ScriptBlock {
        param($BotToken, $ChatId, $ScriptRoot)
        
        # Re-define functions in the job context
        function Send-TelegramMessage {
            param([string]$Message, [string]$BotToken, [string]$ChatId)
            $uri = "https://api.telegram.org/bot$BotToken/sendMessage"
            $body = @{ chat_id = $ChatId; text = $Message; parse_mode = "Markdown" }
            try { Invoke-RestMethod -Uri $uri -Method Post -Body $body -ErrorAction Stop }
            catch { Write-Host "Failed to send Telegram message: $_" }
        }
        
        function Execute-Command {
            param([string]$Command)
            try {
                $output = Invoke-Expression $Command 2>&1 | Out-String
                if ($output.Length -gt 4000) {
                    $output = $output.Substring(0, 4000) + "`n... (output truncated)"
                }
                return "✅ Command executed successfully:`n``````n$output`n``````"
            }
            catch { return "❌ Command failed:`n``````n$($_.Exception.Message)`n``````" }
        }
        
        function Get-TelegramUpdates {
            param([string]$BotToken, [int]$Offset = 0)
            $uri = "https://api.telegram.org/bot$BotToken/getUpdates"
            $body = @{ offset = $Offset; timeout = 10 }
            try {
                $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ErrorAction Stop
                return $response.result
            }
            catch { return @() }
        }
        
        # Command listener logic
        $lastUpdateId = 0
        $updateFile = Join-Path $ScriptRoot "last_update.txt"
        
        if (Test-Path $updateFile) {
            $lastUpdateId = [int](Get-Content $updateFile -ErrorAction SilentlyContinue)
        }
        
        while ($true) {
            $updates = Get-TelegramUpdates -BotToken $BotToken -Offset ($lastUpdateId + 1)
            
            foreach ($update in $updates) {
                $lastUpdateId = $update.update_id
                
                if ($update.message.chat.id -eq $ChatId) {
                    $messageText = $update.message.text
                    
                    if ($messageText -match '^/cmd\s+(.+)$') {
                        $command = $matches[1]
                        Send-TelegramMessage -Message "🔄 Executing command: ``$command``" -BotToken $BotToken -ChatId $ChatId
                        $result = Execute-Command -Command $command
                        Send-TelegramMessage -Message $result -BotToken $BotToken -ChatId $ChatId
                    }
                    elseif ($messageText -eq "/help") {
                        $helpMessage = @"
🤖 **PC Remote Control Commands**

**/cmd [command]** - Execute command line command
Example: ``/cmd dir C:\``
Example: ``/cmd Get-Process | Select-Object -First 5``

**/help** - Show this help message

⚠️ **Security Note**: Only use trusted commands. Avoid commands that might hang or require user input.
"@
                        Send-TelegramMessage -Message $helpMessage -BotToken $BotToken -ChatId $ChatId
                    }
                }
            }
            
            $lastUpdateId | Out-File -FilePath $updateFile -Encoding utf8
            Start-Sleep -Seconds 10
        }
    } -ArgumentList $botToken, $chatId, $PSScriptRoot
}

# Wait for specified time (default 30 seconds)
Start-Sleep -Seconds $sleepTime

# Check if any user is logged in (not on lock screen)
$activeSession = quser 2>$null | Where-Object { $_ -match "Active" -and $_ -notmatch "Disc" }

if (-not $activeSession) {
    # No active user session, send sleep message
    Send-TelegramMessage -Message "😴 PC going to sleep" -BotToken $botToken -ChatId $chatId
    
    # Stop command listener job if running
    if ($commandListenerJob) {
        Stop-Job -Job $commandListenerJob -ErrorAction SilentlyContinue
        Remove-Job -Job $commandListenerJob -ErrorAction SilentlyContinue
    }
    
    # Put PC to sleep
    Start-Sleep -Seconds 5  # Brief delay to ensure message is sent
    rundll32.exe powrprof.dll,SetSuspendState 0,1,0
    exit
} else {
    # Active user session found, send debug message
    Send-TelegramMessage -Message "👤 Active user session detected" -BotToken $botToken -ChatId $chatId
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
    Send-TelegramMessage -Message "😴 PC going to sleep" -BotToken $botToken -ChatId $chatId
    
    # Stop command listener job if running
    if ($commandListenerJob) {
        Stop-Job -Job $commandListenerJob -ErrorAction SilentlyContinue
        Remove-Job -Job $commandListenerJob -ErrorAction SilentlyContinue
    }
    
    # Put PC to sleep
    Start-Sleep -Seconds 5  # Brief delay to ensure message is sent
    rundll32.exe powrprof.dll,SetSuspendState 0,1,0
    exit
} else {
    # Desktop is unlocked and active, send debug message
    Send-TelegramMessage -Message "👤 Desktop is unlocked and active" -BotToken $botToken -ChatId $chatId
}

# Keep command listener running and wait indefinitely
if ($commandListenerJob) {
    Send-TelegramMessage -Message "💻 PC staying awake - Command listener active" -BotToken $botToken -ChatId $chatId
    
    # Wait for the command listener job to complete (which it never will unless stopped)
    try {
        Wait-Job -Job $commandListenerJob
    }
    catch {
        Write-Host "Command listener stopped: $_"
    }
    finally {
        # Clean up job
        Remove-Job -Job $commandListenerJob -ErrorAction SilentlyContinue
    }
}
