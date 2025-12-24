#include <WiFi.h>
#include <PubSubClient.h>
#include "soc/soc.h"
#include "soc/rtc_cntl_reg.h"
#include "esp_camera.h"

const char* ssid = "";
const char* password = "";

const char* serverName = "34.165.138.144";
const int serverPort = 4000;
const char* pathUpload = "/upload";
const char* pathMotion = "/motion-upload";

const char* mqtt_server = "34.165.138.144";
const int mqtt_port = 1883;
const char* mqtt_topic = "bitki/kamera";

WiFiClient wifiClient;
WiFiClient httpClient;
PubSubClient mqttClient(wifiClient);

#define PIR_PIN 13
unsigned long lastMotionTime = 0;
const long motionCooldown = 15000;

#define BUZZER_PIN 12
#define BUZZER_CHANNEL 2

#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM     0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27
#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM       5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22
#define FLASH_LED_PIN     4

#define FLASH_BRIGHTNESS 15

String sendPhotoToServer(const char* endpoint);
void mqttCallback(char* topic, byte* payload, unsigned int length);
void reconnectMQTT();
void flashOn();
void flashOff();
void blinkAck();
void blinkSuccess();
void blinkError();
void buzzerBeep(int count, int duration);
void buzzerAlarm();

void setup() {
  WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0);
  Serial.begin(115200);

  pinMode(PIR_PIN, INPUT_PULLDOWN);

  ledcAttach(BUZZER_PIN, 2000, 8);
  ledcWrite(BUZZER_PIN, 0);

  ledcAttach(FLASH_LED_PIN, 5000, 8);
  ledcWrite(FLASH_LED_PIN, 0);

  WiFi.mode(WIFI_STA);
  Serial.print("WiFi Bağlanıyor: ");
  Serial.println(ssid);
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("\n✅ WiFi Bağlandı!");
  Serial.print("📡 IP: ");
  Serial.println(WiFi.localIP());

  mqttClient.setServer(mqtt_server, mqtt_port);
  mqttClient.setCallback(mqttCallback);

  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sccb_sda = SIOD_GPIO_NUM;
  config.pin_sccb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;

  if (psramFound()) {
    config.frame_size = FRAMESIZE_VGA;
    config.jpeg_quality = 12;
    config.fb_count = 2;
    Serial.println("✅ PSRAM bulundu");
  } else {
    config.frame_size = FRAMESIZE_QVGA;
    config.jpeg_quality = 15;
    config.fb_count = 1;
  }

  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("❌ Kamera Hatası: 0x%x\n", err);
    blinkError();
    delay(1000);
    ESP.restart();
  }

  Serial.println("📷 Kamera Hazır!");
  Serial.println("🔌 PIR: GPIO13 | Buzzer: GPIO12");
  
  buzzerBeep(2, 100);
  blinkSuccess();
}

void mqttCallback(char* topic, byte* payload, unsigned int length) {
  String mesaj = "";
  for (int i = 0; i < length; i++) {
    mesaj += (char)payload[i];
  }
  
  Serial.print("📨 MQTT: ");
  Serial.println(mesaj);

  if (mesaj == "FOTO_ISTEK") {
    Serial.println("📸 AI Analiz isteği!");
    buzzerBeep(1, 50);
    blinkAck();
    
    if (WiFi.status() == WL_CONNECTED) {
      flashOn();
      delay(100);
      String response = sendPhotoToServer(pathUpload);
      flashOff();
      
      if (response.indexOf("ISLEM TAMAM") >= 0) {
        buzzerBeep(2, 100);
        blinkSuccess();
      } else {
        blinkError();
      }
    }
  }
}

void reconnectMQTT() {
  if (!mqttClient.connected()) {
    String clientId = "ESP32CAM-" + String(random(0xffff), HEX);
    if (mqttClient.connect(clientId.c_str())) {
      Serial.println("✅ MQTT Bağlandı");
      mqttClient.subscribe(mqtt_topic);
    }
  }
}

void loop() {
  if (!mqttClient.connected()) {
    reconnectMQTT();
  }
  mqttClient.loop();

  int pirState = digitalRead(PIR_PIN);
  
  if (pirState == HIGH && (millis() - lastMotionTime > motionCooldown)) {
    Serial.println("\n🚨 HAREKET ALGILANDI!");
    
    buzzerAlarm();
    blinkAck();
    
    if (WiFi.status() == WL_CONNECTED) {
      flashOn();
      delay(100);
      String response = sendPhotoToServer(pathMotion);
      flashOff();
      
      if (response.indexOf("ISLEM TAMAM") >= 0) {
        Serial.println("✅ Fotoğraf gönderildi");
        blinkSuccess();
      } else {
        Serial.println("❌ Gönderim başarısız");
        blinkError();
      }
    } else {
      Serial.println("⚠️ WiFi yok!");
      WiFi.reconnect();
    }
    
    lastMotionTime = millis();
  }

  if (Serial.available()) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();
    
    if (cmd == "TEST") {
      Serial.println("🧪 AI Test...");
      buzzerBeep(1, 50);
      flashOn();
      delay(100);
      sendPhotoToServer(pathUpload);
      flashOff();
    } 
    else if (cmd == "MOTION") {
      Serial.println("🧪 Hareket Testi...");
      buzzerAlarm();
      flashOn();
      delay(100);
      sendPhotoToServer(pathMotion);
      flashOff();
    }
    else if (cmd == "BEEP") {
      buzzerBeep(3, 200);
    }
  }
}

void buzzerBeep(int count, int duration) {
  for (int i = 0; i < count; i++) {
    ledcWriteTone(BUZZER_PIN, 2000);
    delay(duration);
    ledcWriteTone(BUZZER_PIN, 0);
    if (i < count - 1) delay(100);
  }
}

void buzzerAlarm() {
  for (int cycle = 0; cycle < 5; cycle++) {
    for (int freq = 1000; freq <= 3000; freq += 50) {
      ledcWriteTone(BUZZER_PIN, freq);
      delay(15);
    }
    for (int freq = 3000; freq >= 1000; freq -= 50) {
      ledcWriteTone(BUZZER_PIN, freq);
      delay(15);
    }
  }
  for (int i = 0; i < 5; i++) {
    ledcWriteTone(BUZZER_PIN, 3500);
    delay(100);
    ledcWriteTone(BUZZER_PIN, 0);
    delay(50);
  }
  ledcWriteTone(BUZZER_PIN, 0);
}

void flashOn() {
  ledcWrite(FLASH_LED_PIN, FLASH_BRIGHTNESS);
}

void flashOff() {
  ledcWrite(FLASH_LED_PIN, 0);
}

void blinkAck() {
  ledcWrite(FLASH_LED_PIN, FLASH_BRIGHTNESS);
  delay(50);
  ledcWrite(FLASH_LED_PIN, 0);
}

void blinkSuccess() {
  for (int i = 0; i < 3; i++) {
    ledcWrite(FLASH_LED_PIN, FLASH_BRIGHTNESS);
    delay(100);
    ledcWrite(FLASH_LED_PIN, 0);
    delay(100);
  }
}

void blinkError() {
  for (int i = 0; i < 2; i++) {
    ledcWrite(FLASH_LED_PIN, FLASH_BRIGHTNESS);
    delay(500);
    ledcWrite(FLASH_LED_PIN, 0);
    delay(500);
  }
}

String sendPhotoToServer(const char* endpoint) {
  String responseBody = "";

  camera_fb_t* fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println("❌ Kamera Buffer Hatası");
    return "Camera capture failed";
  }

  Serial.print("📷 ");
  Serial.print(fb->len);
  Serial.print(" bytes → ");
  Serial.println(endpoint);

  if (httpClient.connect(serverName, serverPort)) {
    String boundary = "ESP32CAMBoundary";
    String head = "--" + boundary + "\r\nContent-Disposition: form-data; name=\"image\"; filename=\"cam.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n";
    String tail = "\r\n--" + boundary + "--\r\n";

    uint32_t totalLen = head.length() + fb->len + tail.length();

    httpClient.println("POST " + String(endpoint) + " HTTP/1.1");
    httpClient.println("Host: " + String(serverName));
    httpClient.println("Content-Length: " + String(totalLen));
    httpClient.println("Content-Type: multipart/form-data; boundary=" + boundary);
    httpClient.println();
    httpClient.print(head);

    uint8_t* fbBuf = fb->buf;
    size_t fbLen = fb->len;

    for (size_t n = 0; n < fbLen; n += 1024) {
      if (n + 1024 < fbLen) {
        httpClient.write(fbBuf, 1024);
        fbBuf += 1024;
      } else {
        httpClient.write(fbBuf, fbLen - n);
      }
    }

    httpClient.print(tail);
    esp_camera_fb_return(fb);

    long timeout = millis();
    boolean headerEnded = false;

    while ((millis() - timeout) < 15000) {
      while (httpClient.available()) {
        char c = httpClient.read();
        if (headerEnded) responseBody += c;
        if (c == '\n' && responseBody.length() == 0 && !headerEnded) {
          headerEnded = true;
        }
        timeout = millis();
      }
      if (responseBody.length() > 0) break;
      delay(10);
    }

    httpClient.stop();
    Serial.print("📩 ");
    Serial.println(responseBody.substring(0, 60));

  } else {
    Serial.println("❌ Sunucu bağlantı hatası");
    esp_camera_fb_return(fb);
  }

  return responseBody;
}
