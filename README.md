# ESP32 Wake-on-LAN with Telegram Bot & Auto-Sleep System

This project provides a comprehensive remote PC management solution using an ESP32 microcontroller and Telegram bot integration. It consists of two main components:

1. **ESP32 Wake-on-LAN Controller** - Remotely wake up your PC via Telegram commands
2. **PowerShell Auto-Sleep Script** - Automatically puts PC to sleep when not in use, with smart detection

## 🚀 Features

### ESP32 Wake-on-LAN Controller
- Wake up your PC remotely via Telegram bot commands
- OTA (Over-The-Air) firmware updates
- WiFi connectivity with automatic reconnection
- Secure configuration management via environment variables

### PowerShell Auto-Sleep System
- **Telegram Integration**: Sends notifications when PC turns on/off
- **Smart Sleep Detection**: Multiple methods to detect if PC should sleep:
  - Active user session detection
  - Desktop lock screen detection
  - Screen saver detection
  - User inactivity monitoring
- **Configurable Sleep Timer**: Customizable delay before sleep check
- **Safe Sleep Mode**: Only sleeps when no active user is detected
- **Remote Command Execution**: Execute command-line commands via Telegram (optional)

## 📋 Configuration

The project uses environment variables stored in a `.env` file for easy configuration management.

### Environment Variables

Create a `.env` file in the project root with the following variables:

```env
# WiFi Configuration
WIFI_SSID=YourWiFiName
WIFI_PASSWORD=YourWiFiPassword

# Telegram Bot Configuration
BOT_TOKEN=YourBotTokenFromBotFather
CHAT_ID=YourTelegramChatID

# Target PC MAC Address (format: B4:2E:99:1C:03:34)
MAC_ADDRESS=YourPCMacAddress

# PowerShell Script Configuration
SLEEP_TIME=30  # Time in seconds to wait before checking if PC should sleep (default: 30)
ENABLE_COMMAND_LISTENER=false  # Set to "true" to enable remote command execution via Telegram (default: false)
```

### Setup Instructions

1. **Copy and edit the `.env` file** with your specific values (see above)

2. **Generate the configuration header** (required after any `.env` changes):
   
   **Option A - Using Python:**
   ```bash
   python generate_config.py
   ```
   
   **Option B - Using the batch file (Windows):**
   ```bash
   update_config.bat
   ```

3. **Upload to ESP32** using Arduino IDE or PlatformIO

4. **Set up auto-sleep script** (Windows):
   - Place `StartupSleep.ps1` in your desired location
   - Configure it to run at startup (see Usage section below)

### Getting Required Values

#### Telegram Bot Token
1. Message [@BotFather](https://t.me/botfather) on Telegram
2. Create a new bot with `/newbot`
3. Copy the provided token

#### Chat ID
1. Message [@userinfobot](https://t.me/userinfobot) on Telegram
2. Copy your Chat ID

#### MAC Address
#### MAC Address

Run this in Windows Command Prompt:

```cmd
getmac /v
```

Or check in Network adapter properties.

## 🎯 Usage

### ESP32 Wake-on-LAN

1. Send `/wake` to your Telegram bot to wake up the target PC
2. The ESP32 will send a Wake-on-LAN magic packet to your PC
3. You'll receive a confirmation message via Telegram

### PowerShell Auto-Sleep Script

#### Automatic Startup (Recommended)

**Method 1: Task Scheduler**
1. Open Task Scheduler (Run: `taskschd.msc`)
2. Create Basic Task
3. Set trigger to "When the computer starts"
4. Set action to start a program:
   
   **Option A - Visible PowerShell Window:**
   - Program: `powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File "C:\path\to\StartupSleep.ps1"`
   
   **Option B - Hidden (No Window):**
   - Program: `wscript.exe`
   - Arguments: `"C:\path\to\StartupSleep_Silent.vbs"`

**Method 2: Startup Folder**
1. Press `Win+R`, type `shell:startup`
2. Choose one of these options:
   
   **Option A - Create a batch file:**
   ```bat
   @echo off
   powershell.exe -ExecutionPolicy Bypass -File "C:\path\to\StartupSleep.ps1"
   ```
   
   **Option B - Copy the hidden launcher:**
   - Copy `StartupSleep_Silent.vbs` to the startup folder for silent execution

**Method 3: Hidden Execution (Recommended)**
- **Double-click `StartupSleep_Silent.vbs`** to run the script completely hidden
- **No terminal window** - Script runs silently in background
- **No taskbar icon** - Completely invisible execution
- **Automatic path detection** - Works from any location

#### Manual Execution

Run the script manually:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "StartupSleep.ps1"
```

#### Script Behavior

1. **Startup**: Sends "🔥PC turned on" notification
2. **Wait Period**: Waits for configured time (default: 30 seconds)
3. **User Detection**: Checks for:
   - Active user sessions
   - Desktop lock status
   - Screen saver activity
4. **Smart Sleep**: Only sleeps if no user activity detected
5. **Command Listener**: If enabled, listens for Telegram commands (when PC stays awake)
6. **Notifications**: Sends appropriate Telegram messages

### Remote Command Execution (Optional)

When `ENABLE_COMMAND_LISTENER=true` in your `.env` file, you can execute commands remotely:

#### Available Commands

- **/cmd [command]** - Execute any command-line command
- **/help** - Show help message with available commands

#### Command Examples

```
/cmd dir C:\
/cmd Get-Process | Select-Object -First 5
/cmd systeminfo
/cmd ipconfig /all
/cmd Get-Service | Where-Object {$_.Status -eq "Running"}
```

#### Security Considerations

⚠️ **IMPORTANT SECURITY NOTES**:
- Commands run with the same privileges as the PowerShell script
- Only enable this feature if you trust your Telegram bot security
- Avoid commands that require user input or might hang
- Output is limited to 4000 characters to prevent Telegram message limits
- Consider the security implications of remote command execution

#### Disabling Command Execution

Set `ENABLE_COMMAND_LISTENER=false` (or remove the line) in your `.env` file to disable this feature.

## 📁 Project Structure

```
WOL_esp/
├── .env                    # Configuration file (create this)
├── README.md              # This file
├── generate_config.py     # Python script to generate config.h
├── update_config.bat      # Windows batch file to update configuration
├── StartupSleep.ps1       # PowerShell auto-sleep script
├── StartupSleep_Silent.vbs  # VBScript launcher for silent execution
└── WOL_ESP32/
    ├── config.h          # Auto-generated header file (don't edit manually)
    └── WOL_ESP32.ino     # Main Arduino sketch
```

### File Descriptions

#### Core Files
- **`.env`** - Configuration file containing all environment variables (edit this to change settings)
- **`config.h`** - Auto-generated header file containing C/C++ definitions (don't edit manually)
- **`WOL_ESP32.ino`** - Main Arduino sketch for ESP32 Wake-on-LAN functionality

#### Configuration Management
- **`generate_config.py`** - Python script to generate config.h from .env file
- **`update_config.bat`** - Windows batch file wrapper for the Python script

#### Auto-Sleep System
- **`StartupSleep.ps1`** - PowerShell script for automatic PC sleep management with Telegram integration
- **`StartupSleep_Silent.vbs`** - VBScript launcher to run PowerShell script silently (no visible window)

## ⚙️ Hardware Requirements & BIOS Setup

### Critical BIOS/UEFI Settings

For Wake-on-LAN to work properly, you **MUST** configure these settings:

#### 1. **Power Management Settings**
- **AC Recovery/AC Power Loss**: Set to `Power On` or `Last State`
  - This ensures your PC turns on automatically when power is restored
  - **Why this matters**: Wake-on-LAN only works on PCs that are in sleep/hibernate mode, not completely powered off

#### 2. **Wake-on-LAN Settings**
- **Wake on LAN**: Enable
- **Wake on PCI-E**: Enable  
- **Wake on PME**: Enable
- **Deep Sleep**: Disable (or set to S1-S3 only)

#### 3. **Network Adapter Settings**
In Windows Device Manager → Network Adapter → Properties → Power Management:
- ✅ **Allow this device to wake the computer**
- ✅ **Only allow a magic packet to wake the computer**

### Why Sleep Instead of Shutdown?

The PowerShell script puts your PC to **sleep** rather than **shutdown** for a critical reason:

- **Sleep Mode**: PC maintains minimal power, network adapter stays partially active → Wake-on-LAN works ✅
- **Complete Shutdown**: PC is completely off, network adapter has no power → Wake-on-LAN fails ❌
- **With AC Recovery**: When power returns after an outage, PC boots up automatically, then can be put to sleep for remote wake capability

### Power Outage Scenario

1. **Power goes out** → PC shuts down
2. **Power returns** → PC automatically boots (due to AC Recovery setting)
3. **StartupSleep.ps1 runs** → PC goes to sleep after checking for user activity
4. **Wake-on-LAN ready** → You can now wake the PC remotely via Telegram

## 🔧 Advanced Configuration

### Sleep Timer Adjustment

Modify the `SLEEP_TIME` variable in your `.env` file:

```env
SLEEP_TIME=60  # Wait 60 seconds before checking sleep conditions
```

### Customizing Sleep Conditions

The PowerShell script uses multiple detection methods. You can modify `StartupSleep.ps1` to adjust:

- Session detection logic
- Lock screen detection
- Inactivity thresholds
- Notification messages

### ESP32 Customization

Modify `WOL_ESP32.ino` to add:

- Additional Telegram commands
- Status monitoring
- Multiple PC support
- Custom responses

## 🛡️ Security Notes

- **Keep your `.env` file secure** and don't commit it to version control
- **The `config.h` file contains your credentials**, so be careful when sharing code
- **Use strong bot tokens** and keep them private
- **Limit bot access** to your specific chat ID only
- **Review PowerShell execution policy** settings for security

## 🐛 Troubleshooting

### ESP32 Issues
- **WiFi connection fails**: Check SSID and password in `.env`
- **Bot doesn't respond**: Verify bot token and chat ID
- **PC doesn't wake**: 
  - Ensure Wake-on-LAN is enabled in BIOS/UEFI and network adapter
  - Verify PC is in sleep mode (not completely shutdown)
  - Check AC Recovery setting is enabled in BIOS
  - Confirm network adapter power management settings allow wake

### PowerShell Script Issues
- **Script doesn't run**: Check execution policy: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- **No notifications**: Verify Telegram bot token and chat ID
- **PC doesn't sleep**: Check if user sessions are properly detected
- **PC doesn't auto-start after power outage**: Verify AC Recovery/AC Power Loss is set to "Power On" in BIOS
- **Command execution not working**: Ensure `ENABLE_COMMAND_LISTENER=true` in `.env` file
- **Commands hang or timeout**: Avoid interactive commands or those requiring user input
- **Permission errors**: Commands run with script privileges; may need elevated permissions for system commands

### Configuration Issues
- **config.h not generated**: Ensure Python is installed and run `generate_config.py`
- **Environment variables not loaded**: Check `.env` file format and syntax
- **Wake-on-LAN not working after power outage**: PC must boot first, then go to sleep for WOL to function

## 📝 License

This project is open-source. Feel free to modify and distribute according to your needs.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

---

**⚠️ IMPORTANT**: Ensure your PC supports Wake-on-LAN and configure the **AC Recovery/AC Power Loss** setting in your BIOS to **"Power On"** or **"Last State"**. This allows your PC to automatically boot after power outages, then go to sleep, making remote wake functionality possible. Without this setting, Wake-on-LAN will not work after the PC has been completely powered off.
