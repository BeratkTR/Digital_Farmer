#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>

const char* ssid = "Xiaomi 14T";           
const char* password = "01000101";     

const char* mqtt_server = "34.165.138.144"; 
const int mqtt_port = 1883;

const char* topic_sensor_veri = "bitki/sensor"; 
const char* topic_kamera_emir = "bitki/kamera"; 

#define PIN_TOPRAK 34  
#define PIN_LDR    35  
#define PIN_DHT    4   
#define PIN_PIR    13
#define PIN_BUZZER 18  

#define RX_PIN 16 
#define TX_PIN 17 

#define DHTTYPE DHT11
DHT dht(PIN_DHT, DHTTYPE);
WiFiClient espClient;
PubSubClient client(espClient);

unsigned long lastMsg = 0;
const long interval = 5000; 

unsigned long lastMotionTime = 0;
const long motionCooldown = 15000;

void callback(char* topic, byte* payload, unsigned int length) {
  String mesaj = "";
  for (int i = 0; i < length; i++) {
    mesaj += (char)payload[i];
  }
  
  if (String(topic) == topic_kamera_emir && mesaj == "FOTO_ISTEK") {
     Serial.println("📸 Emir Geldi -> Kamera Tetikleniyor...");
     Serial2.println("FOTO_CEK"); 
  }
}

void setup() {
  Serial.begin(115200);
  Serial2.begin(115200, SERIAL_8N1, RX_PIN, TX_PIN); 

  pinMode(PIN_PIR, INPUT);
  pinMode(PIN_BUZZER, OUTPUT);
  pinMode(PIN_DHT, INPUT_PULLUP);
  dht.begin();
  
  setup_wifi();
  
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback); 

  digitalWrite(PIN_BUZZER, HIGH); delay(100); digitalWrite(PIN_BUZZER, LOW);
  Serial.println("--- SİSTEM HAZIR ---");
}

void setup_wifi() {
  delay(10);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
  }
}

void reconnect() {
  while (!client.connected()) {
    String clientId = "ESP32AnaKart-" + String(random(0xffff), HEX);
    if (client.connect(clientId.c_str())) {
      client.subscribe(topic_kamera_emir); 
    } else {
      delay(2000);
    }
  }
}

void loop() {
  if (!client.connected()) { reconnect(); }
  client.loop(); 

  int motionState = digitalRead(PIN_PIR);
  
  if (motionState == HIGH && (millis() - lastMotionTime > motionCooldown)) {
    Serial.println("🚨 HAREKET ALGILANDI! Kamera tetikleniyor...");
    
    digitalWrite(PIN_BUZZER, HIGH); delay(200); digitalWrite(PIN_BUZZER, LOW);

    String alertPayload = "{\"motion\": true}";
    client.publish(topic_sensor_veri, alertPayload.c_str());

    Serial2.println("FOTO_CEK_MOTION");
    Serial.println("📸 Kameraya FOTO_CEK_MOTION komutu gönderildi");

    lastMotionTime = millis();
  }

  unsigned long now = millis();
  if (now - lastMsg > interval) {
    lastMsg = now; 

    float temp = dht.readTemperature();
    float hum = dht.readHumidity();
    int rawSoil = analogRead(PIN_TOPRAK);
    int rawLight = analogRead(PIN_LDR); 
    
    int soilPercent = map(rawSoil, 4095, 1500, 0, 100);
    if(soilPercent < 0) soilPercent = 0; if(soilPercent > 100) soilPercent = 100;

    if (isnan(temp) || isnan(hum)) return;

    String payload = "{";
    payload += "\"temp\":";     payload += String(temp); payload += ",";
    payload += "\"humidity\":"; payload += String(hum);  payload += ",";
    payload += "\"soil\":";     payload += String(soilPercent); payload += ",";
    payload += "\"light\":";    payload += String(rawLight);
    payload += "}";

    client.publish(topic_sensor_veri, payload.c_str());
  }
}
