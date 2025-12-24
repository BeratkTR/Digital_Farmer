# 🌱 Digital Farmer - IoT Plant Monitoring System
An IoT-based real-time plant monitoring application that tracks environmental conditions and provides AI-powered plant health analysis.
<div style="display: flex; gap: 50px;">
    <img src="zimages/System%20Photo.jpeg" width="460" alt="Mobile App">
    <img src="zimages/Mobile%20App.jpeg" width="300" alt="Mobile App">
</div>

## 📱 Overview

**Digital Farmer** (Digital Farmer) is a comprehensive plant monitoring system that combines IoT sensors, mobile app, and AI analysis to help you keep track of your plant's health in real-time.

## ✨ Features

- **Real-time Sensor Monitoring**
  - Temperature tracking
  - Humidity levels
  - Soil moisture percentage
  - Light intensity

- **AI-Powered Plant Analysis**
  - On-demand plant health analysis using Google Gemini AI
  - Image-based disease and health detection
  - Detailed analysis reports with recommendations

- **Motion Detection**
  - Automatic motion alerts
  - Security monitoring with photo capture
  - Push notifications for detected movement

- **Smart Notifications**
  - High temperature alerts
  - Motion detection notifications
  - Analysis completion notifications

## 🏗️ System Architecture
<img src="zimages/System%20Design.png" width="700" alt="Mobile App">

The system consists of three main components:

1. **Flutter Mobile App** - User interface for monitoring and control
2. **Node.js Server** - Backend server handling MQTT, AI analysis, and Firebase integration
3. **ESP32 IoT Devices** - Sensor nodes collecting environmental data

## 🛠️ Tech Stack

### Mobile App
- **Flutter** - Cross-platform mobile framework
- **Firebase** - Cloud Firestore for data storage
- **Firebase Cloud Messaging** - Push notifications
- **WebSocket** - Real-time data streaming

### Backend Server
- **Node.js** - Server runtime
- **Express.js** - Web framework
- **MQTT** - IoT communication protocol
- **Google Gemini AI** - Plant health analysis
- **Firebase Admin SDK** - Server-side Firebase operations

### IoT Devices
- **ESP32** - Main microcontroller with sensors
- **ESP32-CAM** - Camera module for image capture
- **DHT11** - Temperature and humidity sensor
- **Soil Moisture Sensor** - Soil moisture detection
- **LDR** - Light dependent resistor
- **PIR Sensor** - Motion detection

## 📋 Prerequisites

- Flutter SDK (3.9.0+)
- Node.js and npm
- Firebase project with Firestore and Cloud Messaging enabled
- Google Gemini API key
- MQTT broker (Mosquitto)
- ESP32 development board
- ESP32-CAM module

## 🔔 Notifications

The app sends push notifications for:
- High temperature warnings (>30°C)
- Motion detection events
- AI analysis completion

## 👨‍💻 Development
### 1. Flutter App Setup

```bash
cd /path/to/project
flutter pub get
```

**Firebase Configuration:**
- Set up Firebase project (firebase_options.dart)

### 2. Server Setup

```bash
cd server
npm install
```

**Configuration:**
- Get `serviceAccountKey.json` from Firebase Console
- Add your Google Gemini API key

**Run the server:**
```bash
node server.js
```

### 3. IoT Device Setup

**ESP32 Main Board:**
- Update WiFi credentials (SSID and password)

**ESP32-CAM:**
- Configure WiFi and server settings

---