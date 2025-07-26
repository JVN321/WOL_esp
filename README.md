# ESP32 Wake-on-LAN with Telegram Bot

This project allows you to wake up a PC remotely using an ESP32 and Telegram bot commands.

## Configuration

The project uses environment variables stored in a `.env` file for easy configuration management.

### Setup

1. **Copy and edit the `.env` file** with your specific values:
   ```
   # WiFi Configuration
   WIFI_SSID=YourWiFiName
   WIFI_PASSWORD=YourWiFiPassword

   # Telegram Bot Configuration
   BOT_TOKEN=YourBotTokenFromBotFather
   CHAT_ID=YourTelegramChatID

   # Target PC MAC Address (format: B4:2E:99:1C:03:34)
   MAC_ADDRESS=YourPCMacAddress
   ```

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

### Getting Required Values

#### Telegram Bot Token
1. Message [@BotFather](https://t.me/botfather) on Telegram
2. Create a new bot with `/newbot`
3. Copy the provided token

#### Chat ID
1. Message [@userinfobot](https://t.me/userinfobot) on Telegram
2. Copy your Chat ID

#### MAC Address
Run this in Windows Command Prompt:
```cmd
getmac /v
```
Or check in Network adapter properties.

### Usage

Send `/wake` to your Telegram bot to wake up the target PC.

### Files

- `.env` - Configuration file (edit this to change settings)
- `config.h` - Auto-generated header file (don't edit manually)
- `generate_config.py` - Script to generate config.h from .env
- `update_config.bat` - Windows batch file to update configuration
- `WOL_ESP32.ino` - Main Arduino sketch

### Security Notes

- Keep your `.env` file secure and don't commit it to version control
- The `config.h` file contains your credentials, so be careful when sharing code
