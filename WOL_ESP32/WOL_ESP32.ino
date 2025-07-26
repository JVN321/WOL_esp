#include <WiFi.h>
#include <WiFiUdp.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <ArduinoOTA.h>
#include <ESPmDNS.h>
#include "config.h"

// Wi-Fi credentials from config
const char* ssid = WIFI_SSID;
const char* password = WIFI_PASSWORD;

// Telegram Bot Token from config
String botToken = BOT_TOKEN;
String chat_id = CHAT_ID;

WiFiUDP udp;
String lastUpdateId = "";

// MAC address of the PC to wake from config
byte mac[] = MAC_ADDRESS;

// Telegram polling interval
unsigned long telegramInterval = 3000;
unsigned long lastTelegramPoll = 0;

void setup() {
  Serial.begin(115200);

  WiFi.begin(ssid, password);
  Serial.println("Connecting to WiFi...");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nWiFi connected.");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());
  udp.begin(9); // Bind UDP to a port for broadcast to work
  // OTA setup
  ArduinoOTA.setHostname("ESP32_Telegram_WoL");
  ArduinoOTA.begin();
  Serial.println("OTA ready.");

  // mDNS setup
  if (!MDNS.begin("esp32-wol")) {
    Serial.println("Error starting mDNS");
  } else {
    Serial.println("mDNS responder started");
  }
}

void loop() {
  // Check WiFi connection and reconnect if needed
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi disconnected. Attempting to reconnect...");
    WiFi.begin(ssid, password);

    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {
      delay(500);
      Serial.print(".");
      attempts++;
    }

    if (WiFi.status() == WL_CONNECTED) {
      Serial.println("\nWiFi reconnected.");
      Serial.print("IP Address: ");
      Serial.println(WiFi.localIP());

      // Re-init UDP and OTA/mDNS after reconnect
      udp.begin(9);
      ArduinoOTA.begin();
      if (!MDNS.begin("esp32-wol")) {
        Serial.println("mDNS restart failed");
      } else {
        Serial.println("mDNS restarted");
      }
    } else {
      Serial.println("\nFailed to reconnect to WiFi. Will try again later.");
      delay(5000);
      return;
    }
  }

  // Regular background handlers
  ArduinoOTA.handle();

  if (millis() - lastTelegramPoll > telegramInterval) {
    lastTelegramPoll = millis();
    handleTelegram();
  }
}


void handleTelegram() {
  HTTPClient http;
  String url = "https://api.telegram.org/bot" + botToken + "/getUpdates?offset=" + lastUpdateId;
  http.begin(url);
  int httpCode = http.GET();

  if (httpCode == 200) {
    String payload = http.getString();
    DynamicJsonDocument doc(2048);
    deserializeJson(doc, payload);

    JsonArray result = doc["result"];
    for (JsonObject update : result) {
      lastUpdateId = String((int)update["update_id"] + 1);
      String message = update["message"]["text"];
      String from_id = update["message"]["chat"]["id"].as<String>();

      if (from_id == chat_id && message == "/wake") {
        Serial.println("Wake command received from Telegram.");
        Serial.print("Current network info - IP: ");
        Serial.print(WiFi.localIP());
        Serial.print(", Subnet: ");
        Serial.print(WiFi.subnetMask());
        Serial.print(", Gateway: ");
        Serial.println(WiFi.gatewayIP());
        
        sendWakeSignal(mac);
        sendTelegramMessage(chat_id, "🟢 Wake signal sent to PC.");
      }
    }
  } else {
    Serial.printf("Telegram GET failed: %d\n", httpCode);
  }

  http.end();
}

void sendTelegramMessage(String chatId, String text) {
  HTTPClient http;
  String url = "https://api.telegram.org/bot" + botToken + "/sendMessage";
  String payload = "chat_id=" + chatId + "&text=" + text;

  http.begin(url);
  http.addHeader("Content-Type", "application/x-www-form-urlencoded");
  int code = http.POST(payload);
  if (code > 0) {
    Serial.println("Telegram message sent.");
  } else {
    Serial.println("Failed to send message.");
  }
  http.end();
}

void sendWakeSignal(byte* mac) {
  byte magicPacket[102];

  // Create magic packet: 6 bytes of 0xFF + 16 repetitions of MAC address
  for (int i = 0; i < 6; i++) magicPacket[i] = 0xFF;
  for (int i = 6; i < 102; i++) magicPacket[i] = mac[(i - 6) % 6];

  // Send to multiple ports and addresses for better compatibility
  // Port 9 (standard WoL port)
  udp.beginPacket("255.255.255.255", 9);
  udp.write(magicPacket, sizeof(magicPacket));
  udp.endPacket();
  
  // Port 7 (alternative WoL port)
  udp.beginPacket("255.255.255.255", 7);
  udp.write(magicPacket, sizeof(magicPacket));
  udp.endPacket();
  
  // Send to local subnet broadcast as well
  IPAddress localIP = WiFi.localIP();
  IPAddress subnet = WiFi.subnetMask();
  IPAddress broadcast = IPAddress(
    localIP[0] | (~subnet[0]),
    localIP[1] | (~subnet[1]), 
    localIP[2] | (~subnet[2]),
    localIP[3] | (~subnet[3])
  );
  
  udp.beginPacket(broadcast, 9);
  udp.write(magicPacket, sizeof(magicPacket));
  udp.endPacket();
  
  udp.beginPacket(broadcast, 7);
  udp.write(magicPacket, sizeof(magicPacket));
  udp.endPacket();

  Serial.println("Wake-on-LAN magic packets sent to multiple ports and addresses.");
  Serial.print("Broadcast addresses used: 255.255.255.255 and ");
  Serial.println(broadcast);
}
