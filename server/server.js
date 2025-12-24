const express = require('express');
const multer = require('multer');
const mqtt = require('mqtt');
const admin = require("firebase-admin");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const fs = require('fs');
const path = require('path');

const GEMINI_API_KEY = "";
const SERVICE_ACCOUNT = require("./serviceAccountKey.json");

const SERVER_IP = "http://34.165.138.144:4000"; 

const MQTT_HOST = 'mqtt://localhost:1883';
const TOPIC_SENSOR_VERI = 'bitki/sensor';
const TOPIC_KAMERA_EMIR = 'bitki/kamera';

let lastTempAlertTime = 0;
let lastMotionAlertTime = 0;
const ALERT_COOLDOWN = 60 * 1000;
const MOTION_COOLDOWN = 15 * 1000;

admin.initializeApp({
  credential: admin.credential.cert(SERVICE_ACCOUNT)
});
const db = admin.firestore();
const messaging = admin.messaging();

const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

const app = express();
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const dir = './uploads';
    if (!fs.existsSync(dir)) fs.mkdirSync(dir);
    cb(null, dir);
  },
  filename: function (req, file, cb) {
    cb(null, 'plant-' + Date.now() + '.jpg'); 
  }
});
const upload = multer({ storage: storage });

const mqttClient = mqtt.connect(MQTT_HOST);

mqttClient.on('connect', () => {
  console.log('✅ MQTT Bağlandı (Mosquitto)');
  mqttClient.subscribe(TOPIC_SENSOR_VERI);
  console.log(`📡 Dinleniyor: ${TOPIC_SENSOR_VERI}`);
});

mqttClient.on('message', async (topic, message) => {
  if (topic === TOPIC_SENSOR_VERI) {
    try {
      const payloadStr = message.toString();
      const data = JSON.parse(payloadStr);

      if (data.motion === true) {
         console.log("\n🚨 MQTT'den Hareket Bilgisi Geldi!");
         checkAndSendMotionAlert();
         return;
      }

      if (data.temp === undefined) return;

      process.stdout.write(`\r🌱 T:${data.temp}°C | H:%${data.humidity} | S:%${data.soil} | L:${data.light}   `);

      await db.collection("sensors").doc("main_plant").collection("readings").add({
        temp: parseFloat(data.temp),
        humidity: parseInt(data.humidity),
        soil: parseInt(data.soil),
        light: parseInt(data.light),
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });

      if (parseFloat(data.temp) > 30.0) {
        checkAndSendTempAlert(data.temp);
      }

    } catch (e) {
      console.error("\n❌ MQTT JSON Hatası:", e.message);
    }
  }
});

app.get('/analyze', (req, res) => {
  console.log("\n📲 Flutter'dan Analiz İsteği Geldi!");
  
  mqttClient.publish(TOPIC_KAMERA_EMIR, "FOTO_ISTEK");
  
  res.json({ 
    status: "success", 
    message: "ESP32'ye emir gönderildi. Kamera açılıyor..." 
  });
});

app.post('/upload', upload.single('image'), async (req, res) => {
  console.log("\n📸 Kamera Fotoğraf Yükledi!");

  if (!req.file) {
    return res.status(400).send("Dosya yüklenemedi.");
  }

  try {
    const localFilePath = req.file.path; 
    const publicUrl = `${SERVER_IP}/uploads/${req.file.filename}`;

    console.log("🧠 Yapay Zeka (Gemini) Analizi Başlıyor...");
    
    const aiResponse = await analyzeImageWithGemini(localFilePath);
    console.log("🤖 AI Sonucu:", aiResponse);

    await db.collection("analyses").add({
      imageUrl: publicUrl,
      aiResult: aiResponse,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    sendPushNotification("🤖 Analiz Tamamlandı", "Bitkinizin sağlık raporu hazır. Görmek için dokunun.");

    res.send("ISLEM TAMAM: " + aiResponse);

  } catch (error) {
    console.error("Analiz Hatası:", error);
    res.status(500).send("Sunucu Hatası: " + error.message);
  }
});

app.post('/motion-upload', upload.single('image'), async (req, res) => {
  console.log("\n🚨 Hareket Fotoğrafı Geldi!");

  if (!req.file) {
    return res.status(400).send("Dosya yüklenemedi.");
  }

  try {
    const publicUrl = `${SERVER_IP}/uploads/${req.file.filename}`;

    await db.collection("motion_captures").add({
      imageUrl: publicUrl,
      type: "motion_detected",
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    sendPushNotification(
      "🚨 Hareket Algılandı!", 
      "Sera çevresinde hareket tespit edildi. Fotoğraf kaydedildi."
    );

    console.log("📸 Hareket fotoğrafı kaydedildi:", publicUrl);
    res.send("ISLEM TAMAM: Hareket fotoğrafı kaydedildi");

  } catch (error) {
    console.error("Hareket Kayıt Hatası:", error);
    res.status(500).send("Sunucu Hatası: " + error.message);
  }
});

function fileToGenerativePart(path, mimeType) {
  return {
    inlineData: {
      data: fs.readFileSync(path).toString("base64"),
      mimeType
    },
  };
}

async function analyzeImageWithGemini(filePath) {
  const prompt = `Sen uzman bir ziraat mühendisisin. 
  Bu bitkinin fotoğrafını analiz et.
  1. Bitki sağlıklı görünüyor mu?
  2. Yapraklarında herhangi bir renk değişimi, leke veya hastalık belirtisi var mı?
  3. Toprak durumu (görülebiliyorsa) nasıl?
  
  Cevabı Türkçe, samimi bir dille, emojiler kullanarak ve çok uzun olmayan maddeler halinde ver.`;

  const imagePart = fileToGenerativePart(filePath, "image/jpeg");
  const result = await model.generateContent([prompt, imagePart]);
  const response = await result.response;
  return response.text();
}

async function checkAndSendTempAlert(currentTemp) {
  const now = Date.now();
  if (now - lastTempAlertTime < ALERT_COOLDOWN) return;

  sendPushNotification("🔥 Yüksek Sıcaklık Uyarısı!", `Sıcaklık ${currentTemp}°C oldu! Lütfen kontrol edin.`);
  lastTempAlertTime = now;
}

async function checkAndSendMotionAlert() {
    const now = Date.now();
    if (now - lastMotionAlertTime < MOTION_COOLDOWN) return;

    sendPushNotification("🚨 Hareket Algılandı!", "Sera çevresinde hareket tespit edildi.");
    lastMotionAlertTime = now;
}

async function sendPushNotification(title, body) {
  const tokensSnapshot = await db.collection('fcm_tokens').get();
  if (tokensSnapshot.empty) return;

  const tokens = tokensSnapshot.docs.map(doc => doc.data().token);
  
  const message = {
    notification: { title, body },
    android: { notification: { channelId: "high_importance_channel", priority: "high" } },
    tokens: tokens
  };

  try {
    await messaging.sendEachForMulticast(message);
    console.log(`🔔 Bildirim gönderildi: ${title}`);
  } catch (e) {
    console.log("Bildirim hatası:", e);
  }
}

app.listen(4000, () => {
  console.log(`🚀 IoT Sunucusu Çalışıyor: Port 4000`);
});
