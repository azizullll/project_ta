#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <DHT.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <RTClib.h>

// Provide the token generation process info.
#include "addons/TokenHelper.h"
// Provide the RTDB payload printing info and other helper functions.
#include "addons/RTDBHelper.h"

// Konfigurasi WiFi
const char* ssid = "OYI";
const char* password = "warkopoyi";

// Konfigurasi Firebase (Firebase ESP Client v4.4.x)
#define API_KEY "AIzaSyDtcLTrhHMrhKQIkadH572ELpsDHzoEQt4"
// Database URL: harus diawali https://
#define DATABASE_URL "https://broodguard-ff9f7-default-rtdb.asia-southeast1.firebasedatabase.app/"

FirebaseData firebaseData;
FirebaseConfig config;
FirebaseAuth auth;

// Pin Configuration untuk ESP32
#define DHTPIN 15          // DHT22 di pin 15
#define RELAY_TEMP 26      // Relay 3 untuk suhu (kipas)
#define RELAY_HUMIDITY 27  // Relay 4 untuk kelembapan (lampu)
#define DHTTYPE DHT22      // DHT22 sensor

DHT dht(DHTPIN, DHTTYPE);
LiquidCrystal_I2C lcd(0x27, 16, 2);
RTC_DS3231 rtc;

int ageInWeeks = 1;

// Variabel untuk mode kontrol
bool autoModeFan = true;
bool autoModeLight = true;
bool fanStatus = false;
bool lightStatus = false;

// Variabel untuk rentang suhu dan kelembapan dinamis
struct Range {
  float min;
  float max;
  float target;
};

Range tempRanges[4] = {
  {33, 35, 34},    // Minggu 1
  {30, 33, 31.5},  // Minggu 2
  {28, 30, 29},    // Minggu 3
  {25, 28, 26.5}   // Minggu 4
};

Range humidityRanges[4] = {
  {60, 70, 65},    // Minggu 1
  {60, 65, 62.5},  // Minggu 2
  {60, 65, 62.5},  // Minggu 3
  {55, 60, 57.5}   // Minggu 4
};

// Variabel untuk pengaturan tampilan LCD
unsigned long lastDisplayToggle = 0;
bool showMainDisplay = true;

// Variabel untuk reconnect
unsigned long lastReconnectAttempt = 0;
const unsigned long reconnectInterval = 30000;

// Variabel untuk menyimpan status koneksi WiFi sebelumnya
bool previousWiFiStatus = false;

// Flag apakah Firebase sudah siap
bool firebaseReady = false;

// Fungsi untuk mendapatkan waktu dari RTC
String getCurrentTimestamp() {
  if (!rtc.lostPower()) {
    DateTime now = rtc.now();
    char timestamp[32];
    sprintf(timestamp, "%04d-%02d-%02d %02d:%02d:%02d",
            now.year(), now.month(), now.day(),
            now.hour(), now.minute(), now.second());
    return String(timestamp);
  }
  return String(millis() / 1000);
}

// Fungsi untuk logging ke Firebase dengan timestamp dari RTC
void logToFirebase(const String& path, const String& message) {
  if (!firebaseReady || !Firebase.ready()) return;
  String timestamp = getCurrentTimestamp();
  String logMessage = timestamp + ": " + message;
  Firebase.RTDB.setString(&firebaseData, path, logMessage);
}

// Variabel untuk memeriksa koneksi WiFi
unsigned long lastWiFiCheck = 0;
const unsigned long wifiCheckInterval = 2000;

// Fungsi untuk memeriksa dan memulihkan koneksi WiFi
void checkWiFiConnection() {
  if (WiFi.status() != WL_CONNECTED) {
    unsigned long currentMillis = millis();

    if (currentMillis - lastReconnectAttempt >= reconnectInterval) {
      Serial.println("WiFi Disconnected. Attempting to Reconnect...");
      WiFi.disconnect();
      delay(1000);
      WiFi.begin(ssid, password);
      lastReconnectAttempt = currentMillis;
    }

    if (previousWiFiStatus) {
      Serial.println("WiFi Connection Failed");
      logToFirebase("/logs/wifi", "wifi terputus silahkan cek dikandang anda");
      previousWiFiStatus = false;
    }
  } else {
    if (!previousWiFiStatus) {
      Serial.println("\nWiFi connected");
      logToFirebase("/logs/wifi", "wifi tersambung kembali");
      previousWiFiStatus = true;
    }
  }
}

void setup() {
  Serial.begin(115200);

  // Inisialisasi pin relay
  pinMode(RELAY_TEMP, OUTPUT);
  pinMode(RELAY_HUMIDITY, OUTPUT);
  digitalWrite(RELAY_TEMP, HIGH);
  digitalWrite(RELAY_HUMIDITY, HIGH);

  // Inisialisasi RTC
  Wire.begin();
  if (!rtc.begin()) {
    Serial.println("Couldn't find RTC");
  } else {
    if (rtc.lostPower()) {
      Serial.println("RTC lost power, setting the time!");
      rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
    } else {
      Serial.println("RTC initialized successfully");
    }
  }

  // Inisialisasi LCD
  Wire.beginTransmission(0x27);
  byte error = Wire.endTransmission();

  if (error == 0) {
    lcd.init();
    lcd.backlight();
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Initializing...");
    Serial.println("LCD initialized successfully");
  } else {
    Serial.println("LCD initialization failed! Check wiring (GND, VCC, SDA, SCL)");
  }

  // Inisialisasi WiFi
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi connected");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
    previousWiFiStatus = true;
  } else {
    Serial.println("\nWiFi connection failed");
  }

  // Inisialisasi DHT22
  dht.begin();
  Serial.println("DHT22 Sensor Initialized");

  // Konfigurasi Firebase ESP Client v4.4.x
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  
  // Set untuk anonymous authentication
  config.signer.anonymous = true;
  
  // Assign token callback
  config.token_status_callback = tokenStatusCallback; // see addons/TokenHelper.h

  // Aktifkan reconnect WiFi otomatis
  Firebase.reconnectNetwork(true);

  // Mulai Firebase dengan konfigurasi anonymous
  Firebase.begin(&config, &auth);
  
  Serial.println("Firebase config set for anonymous access");

  // Tunggu Firebase siap
  Serial.print("Waiting for Firebase...");
  unsigned long fbTimeout = millis();
  while (!Firebase.ready() && millis() - fbTimeout < 10000) {
    Serial.print(".");
    delay(300);
  }

  if (Firebase.ready()) {
    firebaseReady = true;
    Serial.println("\nFirebase Ready!");
    logToFirebase("/logs/system", "System Started Successfully");
  } else {
    Serial.println("\nFirebase not ready, continuing offline...");
  }

  // Inisialisasi variabel kontrol di Firebase
  if (firebaseReady) {
    Firebase.RTDB.setBool(&firebaseData, "/control/fan/auto", autoModeFan);
    Firebase.RTDB.setBool(&firebaseData, "/control/light/auto", autoModeLight);
    Firebase.RTDB.setBool(&firebaseData, "/control/fan/status", fanStatus);
    Firebase.RTDB.setBool(&firebaseData, "/control/light/status", lightStatus);

    // Inisialisasi rentang di Firebase
    for (int i = 0; i < 4; i++) {
      String tempPath = "/ranges/week" + String(i + 1) + "/temperature";
      String humidityPath = "/ranges/week" + String(i + 1) + "/humidity";

      Firebase.RTDB.setFloat(&firebaseData, tempPath + "/min", tempRanges[i].min);
      Firebase.RTDB.setFloat(&firebaseData, tempPath + "/max", tempRanges[i].max);
      Firebase.RTDB.setFloat(&firebaseData, tempPath + "/target", tempRanges[i].target);

      Firebase.RTDB.setFloat(&firebaseData, humidityPath + "/min", humidityRanges[i].min);
      Firebase.RTDB.setFloat(&firebaseData, humidityPath + "/max", humidityRanges[i].max);
      Firebase.RTDB.setFloat(&firebaseData, humidityPath + "/target", humidityRanges[i].target);
    }
  }
}

void loop() {
  unsigned long currentMillis = millis();

  // Update status Firebase ready
  firebaseReady = Firebase.ready();

  // Periksa koneksi WiFi setiap 2 detik
  if (currentMillis - lastWiFiCheck >= wifiCheckInterval) {
    checkWiFiConnection();
    lastWiFiCheck = currentMillis;
  }

  // Periksa koneksi LCD secara berkala
  checkLCDConnection();

  // Baca sensor suhu dan kelembapan
  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();

  // Periksa pembacaan sensor
  if (isnan(temperature) || isnan(humidity)) {
    logToFirebase("/logs/sensor", "Failed to Read from DHT22 Sensor");

    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Sensor Error!");
    lcd.setCursor(0, 1);
    lcd.print("Check DHT22");
    delay(2000);
    return;
  } else {
    static unsigned long lastSensorLog = 0;
    if (millis() - lastSensorLog > 2000) {
      logToFirebase("/logs/sensor", "DHT22 Sensor Reading Successful");
      lastSensorLog = millis();
    }
  }

  // Ambil umur ayam dari Firebase
  if (firebaseReady) {
    if (Firebase.RTDB.getInt(&firebaseData, "/chicken_age")) {
      if (firebaseData.dataType() == "int") {
        ageInWeeks = firebaseData.intData();
        // Pastikan index tidak keluar batas array
        if (ageInWeeks < 1) ageInWeeks = 1;
        if (ageInWeeks > 4) ageInWeeks = 4;
        Serial.print("Age: ");
        Serial.println(ageInWeeks);
      }
    } else {
      Serial.print("Failed to get age from Firebase: ");
      Serial.println(firebaseData.errorReason());
      Firebase.RTDB.setInt(&firebaseData, "/chicken_age", 1);
    }
  }

  // Periksa mode kontrol (manual atau otomatis)
  checkControlMode();

  // Ganti tampilan LCD setiap 5 detik
  if (currentMillis - lastDisplayToggle >= 5000) {
    showMainDisplay = !showMainDisplay;
    lastDisplayToggle = currentMillis;
  }

  if (showMainDisplay) {
    updateMainDisplay(temperature, humidity);
  } else {
    updateModeDisplay();
  }

  // Kontrol suhu dan kelembapan
  if (autoModeFan) {
    controlTemperature(temperature);
  } else {
    digitalWrite(RELAY_TEMP, fanStatus ? LOW : HIGH);
  }

  if (autoModeLight) {
    controlHumidity(humidity, temperature);
  } else {
    digitalWrite(RELAY_HUMIDITY, lightStatus ? LOW : HIGH);
  }

  // Kirim data ke Firebase
  if (firebaseReady) {
    Firebase.RTDB.setFloat(&firebaseData, "/sensor/temperature", temperature);
    Firebase.RTDB.setFloat(&firebaseData, "/sensor/Humidity", humidity);
    Firebase.RTDB.setBool(&firebaseData, "/relay/Kipas", digitalRead(RELAY_TEMP) == LOW);
    Firebase.RTDB.setBool(&firebaseData, "/relay/Lampu", digitalRead(RELAY_HUMIDITY) == LOW);
    Firebase.RTDB.setString(&firebaseData, "/sensor/timestamp", getCurrentTimestamp());

    // Perbarui rentang dari Firebase
    updateRangesFromFirebase();
  }

  delay(1000);
}

// Fungsi untuk tampilan utama (Temp, Hum, Age, Time)
void updateMainDisplay(float temperature, float humidity) {
  lcd.clear();

  lcd.setCursor(0, 0);
  lcd.print("T:");
  lcd.print(temperature, 1);
  lcd.print((char)223);
  lcd.print("C H:");
  lcd.print(humidity, 0);
  lcd.print("%");

  lcd.setCursor(0, 1);
  lcd.print("Age:");
  lcd.print(ageInWeeks);
  lcd.print("w ");

  if (!rtc.lostPower()) {
    DateTime now = rtc.now();
    if (now.hour() < 10) lcd.print("0");
    lcd.print(now.hour());
    lcd.print(":");
    if (now.minute() < 10) lcd.print("0");
    lcd.print(now.minute());
  }
}

// Fungsi untuk tampilan mode (Auto/Manual)
void updateModeDisplay() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Fan:");
  lcd.print(autoModeFan ? "AUTO" : "MAN");
  lcd.print(" ");
  lcd.print(digitalRead(RELAY_TEMP) == LOW ? "ON" : "OFF");

  lcd.setCursor(0, 1);
  lcd.print("Lmp:");
  lcd.print(autoModeLight ? "AUTO" : "MAN");
  lcd.print(" ");
  lcd.print(digitalRead(RELAY_HUMIDITY) == LOW ? "ON" : "OFF");
}

// Definisi fungsi fuzzy logic untuk kontrol suhu
void controlTemperature(float temp) {
  float minTemp = tempRanges[ageInWeeks - 1].min;
  float maxTemp = tempRanges[ageInWeeks - 1].max;
  float targetTemp = tempRanges[ageInWeeks - 1].target;

  float veryLow = 0;
  float tooLow = 0;
  float optimal = 0;
  float tooHigh = 0;
  float veryHigh = 0;

  if (temp < minTemp - 2) {
    veryLow = 1.0;
  } else if (temp >= minTemp - 2 && temp < minTemp - 1) {
    veryLow = constrain(minTemp - 1 - temp, 0, 1);
  }

  if (temp >= minTemp - 1.5 && temp < minTemp) {
    tooLow = constrain((minTemp - temp) / 1.5, 0, 1);
  }

  if (temp >= minTemp && temp <= maxTemp) {
    optimal = constrain(1.0 - abs(temp - targetTemp) / ((maxTemp - minTemp) / 2.0), 0, 1);
  }

  if (temp > maxTemp && temp <= maxTemp + 1.5) {
    tooHigh = constrain((temp - maxTemp) / 1.5, 0, 1);
  }

  if (temp > maxTemp + 2) {
    veryHigh = 1.0;
  } else if (temp > maxTemp + 1 && temp <= maxTemp + 2) {
    veryHigh = constrain((temp - (maxTemp + 1)) / 1.0, 0, 1);
  }

  if (firebaseReady) {
    Firebase.RTDB.setFloat(&firebaseData, "/fuzzy/temperature/veryLow", veryLow);
    Firebase.RTDB.setFloat(&firebaseData, "/fuzzy/temperature/tooLow", tooLow);
    Firebase.RTDB.setFloat(&firebaseData, "/fuzzy/temperature/optimal", optimal);
    Firebase.RTDB.setFloat(&firebaseData, "/fuzzy/temperature/tooHigh", tooHigh);
    Firebase.RTDB.setFloat(&firebaseData, "/fuzzy/temperature/veryHigh", veryHigh);
  }

  if (veryHigh > 0.3) {
    digitalWrite(RELAY_TEMP, LOW);
    if (firebaseReady) {
      Firebase.RTDB.setString(&firebaseData, "/status/temperature", "Sangat Tinggi - Kipas ON (Kritis)");
      Firebase.RTDB.setBool(&firebaseData, "/emergency/high_temperature", true);
    }
  } else if (veryLow > 0.3) {
    digitalWrite(RELAY_TEMP, HIGH);
    digitalWrite(RELAY_HUMIDITY, LOW);
    if (firebaseReady) {
      Firebase.RTDB.setString(&firebaseData, "/status/temperature", "Sangat Rendah - Kipas OFF, Lampu ON");
      Firebase.RTDB.setBool(&firebaseData, "/emergency/low_temperature", true);
      Firebase.RTDB.setBool(&firebaseData, "/emergency/high_temperature", false);
    }
  } else if (tooHigh > 0.3) {
    digitalWrite(RELAY_TEMP, LOW);
    if (firebaseReady) {
      Firebase.RTDB.setString(&firebaseData, "/status/temperature", "Tinggi - Kipas ON");
      Firebase.RTDB.setBool(&firebaseData, "/emergency/low_temperature", false);
      Firebase.RTDB.setBool(&firebaseData, "/emergency/high_temperature", false);
    }
  } else if (optimal > 0.7) {
    digitalWrite(RELAY_TEMP, HIGH);
    if (firebaseReady) {
      Firebase.RTDB.setString(&firebaseData, "/status/temperature", "Optimal - Kipas OFF");
      Firebase.RTDB.setBool(&firebaseData, "/emergency/low_temperature", false);
      Firebase.RTDB.setBool(&firebaseData, "/emergency/high_temperature", false);
    }
  } else if (tooLow > 0.3) {
    digitalWrite(RELAY_TEMP, HIGH);
    if (firebaseReady) {
      Firebase.RTDB.setString(&firebaseData, "/status/temperature", "Rendah - Kipas OFF");
      Firebase.RTDB.setBool(&firebaseData, "/emergency/low_temperature", true);
      Firebase.RTDB.setBool(&firebaseData, "/emergency/high_temperature", false);
    }
  } else {
    float distanceToMax = maxTemp - temp;
    if (distanceToMax < 1.0) {
      digitalWrite(RELAY_TEMP, LOW);
      if (firebaseReady) Firebase.RTDB.setString(&firebaseData, "/status/temperature", "Mendekati Tinggi - Kipas ON");
    } else {
      digitalWrite(RELAY_TEMP, HIGH);
      if (firebaseReady) Firebase.RTDB.setString(&firebaseData, "/status/temperature", "Normal - Kipas OFF");
    }
    if (firebaseReady) {
      Firebase.RTDB.setBool(&firebaseData, "/emergency/low_temperature", false);
      Firebase.RTDB.setBool(&firebaseData, "/emergency/high_temperature", false);
    }
  }
}

// Definisi fungsi fuzzy logic untuk kontrol kelembapan
void controlHumidity(float humidity, float temperature) {
  float minHumidity = humidityRanges[ageInWeeks - 1].min;
  float maxHumidity = humidityRanges[ageInWeeks - 1].max;
  float targetHumidity = humidityRanges[ageInWeeks - 1].target;
  float minTemp = tempRanges[ageInWeeks - 1].min;

  bool isTemperatureEmergency = (temperature < minTemp - 1.5);

  float veryLow = 0;
  float tooLow = 0;
  float optimal = 0;
  float tooHigh = 0;
  float veryHigh = 0;

  if (humidity < minHumidity - 5) {
    veryLow = 1.0;
  } else if (humidity >= minHumidity - 5 && humidity < minHumidity - 3) {
    veryLow = constrain((minHumidity - 3 - humidity) / 2.0, 0, 1);
  }

  if (humidity >= minHumidity - 3 && humidity < minHumidity) {
    tooLow = constrain((minHumidity - humidity) / 3.0, 0, 1);
  }

  if (humidity >= minHumidity && humidity <= maxHumidity) {
    optimal = constrain(1.0 - abs(humidity - targetHumidity) / ((maxHumidity - minHumidity) / 2.0), 0, 1);
  }

  if (humidity > maxHumidity && humidity <= maxHumidity + 3) {
    tooHigh = constrain((humidity - maxHumidity) / 3.0, 0, 1);
  }

  if (humidity > maxHumidity + 5) {
    veryHigh = 1.0;
  } else if (humidity > maxHumidity + 3 && humidity <= maxHumidity + 5) {
    veryHigh = constrain((humidity - (maxHumidity + 3)) / 2.0, 0, 1);
  }

  if (firebaseReady) {
    Firebase.RTDB.setFloat(&firebaseData, "/fuzzy/humidity/veryLow", veryLow);
    Firebase.RTDB.setFloat(&firebaseData, "/fuzzy/humidity/tooLow", tooLow);
    Firebase.RTDB.setFloat(&firebaseData, "/fuzzy/humidity/optimal", optimal);
    Firebase.RTDB.setFloat(&firebaseData, "/fuzzy/humidity/tooHigh", tooHigh);
    Firebase.RTDB.setFloat(&firebaseData, "/fuzzy/humidity/veryHigh", veryHigh);
  }

  if (isTemperatureEmergency) {
    digitalWrite(RELAY_HUMIDITY, LOW);
    if (firebaseReady) {
      Firebase.RTDB.setString(&firebaseData, "/status/humidity", "Suhu Darurat - Lampu ON untuk Pemanasan");
      Firebase.RTDB.setBool(&firebaseData, "/emergency/low_humidity", false);
      Firebase.RTDB.setBool(&firebaseData, "/emergency/high_humidity", false);
    }
    return;
  }

  if (veryHigh > 0.3) {
    digitalWrite(RELAY_HUMIDITY, LOW);
    if (firebaseReady) {
      Firebase.RTDB.setString(&firebaseData, "/status/humidity", "Sangat Tinggi - Lampu ON (Kritis)");
      Firebase.RTDB.setBool(&firebaseData, "/emergency/high_humidity", true);
      Firebase.RTDB.setBool(&firebaseData, "/emergency/low_humidity", false);
    }
  } else if (veryLow > 0.3) {
    digitalWrite(RELAY_HUMIDITY, HIGH);
    if (firebaseReady) {
      Firebase.RTDB.setString(&firebaseData, "/status/humidity", "Sangat Rendah - Lampu OFF");
      Firebase.RTDB.setBool(&firebaseData, "/emergency/low_humidity", true);
      Firebase.RTDB.setBool(&firebaseData, "/emergency/high_humidity", false);
    }
  } else if (tooHigh > 0.4) {
    digitalWrite(RELAY_HUMIDITY, LOW);
    if (firebaseReady) {
      Firebase.RTDB.setString(&firebaseData, "/status/humidity", "Tinggi - Lampu ON");
      Firebase.RTDB.setBool(&firebaseData, "/emergency/low_humidity", false);
      Firebase.RTDB.setBool(&firebaseData, "/emergency/high_humidity", false);
    }
  } else if (optimal > 0.6) {
    if (temperature < minTemp) {
      digitalWrite(RELAY_HUMIDITY, LOW);
      if (firebaseReady) Firebase.RTDB.setString(&firebaseData, "/status/humidity", "Optimal, Suhu Rendah - Lampu ON");
    } else if (humidity > targetHumidity + ((maxHumidity - minHumidity) / 4)) {
      digitalWrite(RELAY_HUMIDITY, LOW);
      if (firebaseReady) Firebase.RTDB.setString(&firebaseData, "/status/humidity", "Optimal Tinggi - Lampu ON");
    } else {
      digitalWrite(RELAY_HUMIDITY, HIGH);
      if (firebaseReady) Firebase.RTDB.setString(&firebaseData, "/status/humidity", "Optimal - Lampu OFF");
    }
    if (firebaseReady) {
      Firebase.RTDB.setBool(&firebaseData, "/emergency/low_humidity", false);
      Firebase.RTDB.setBool(&firebaseData, "/emergency/high_humidity", false);
    }
  } else if (tooLow > 0.3) {
    if (temperature < minTemp - 1) {
      digitalWrite(RELAY_HUMIDITY, LOW);
      if (firebaseReady) Firebase.RTDB.setString(&firebaseData, "/status/humidity", "Rendah, Suhu Sangat Rendah - Lampu ON");
    } else {
      digitalWrite(RELAY_HUMIDITY, HIGH);
      if (firebaseReady) Firebase.RTDB.setString(&firebaseData, "/status/humidity", "Rendah - Lampu OFF");
    }
    if (firebaseReady) {
      Firebase.RTDB.setBool(&firebaseData, "/emergency/low_humidity", true);
      Firebase.RTDB.setBool(&firebaseData, "/emergency/high_humidity", false);
    }
  } else {
    if (temperature < minTemp) {
      digitalWrite(RELAY_HUMIDITY, LOW);
      if (firebaseReady) Firebase.RTDB.setString(&firebaseData, "/status/humidity", "Normal, Suhu Rendah - Lampu ON");
    } else if (humidity > maxHumidity - 1.5) {
      digitalWrite(RELAY_HUMIDITY, LOW);
      if (firebaseReady) Firebase.RTDB.setString(&firebaseData, "/status/humidity", "Mendekati Tinggi - Lampu ON");
    } else {
      digitalWrite(RELAY_HUMIDITY, HIGH);
      if (firebaseReady) Firebase.RTDB.setString(&firebaseData, "/status/humidity", "Normal - Lampu OFF");
    }
    if (firebaseReady) {
      Firebase.RTDB.setBool(&firebaseData, "/emergency/low_humidity", false);
      Firebase.RTDB.setBool(&firebaseData, "/emergency/high_humidity", false);
    }
  }
}

// Fungsi untuk memeriksa mode kontrol dari Firebase
void checkControlMode() {
  if (!firebaseReady) return;

  if (Firebase.RTDB.getBool(&firebaseData, "/control/fan/auto")) {
    if (firebaseData.dataType() == "boolean") {
      autoModeFan = firebaseData.boolData();
    }
  }

  if (Firebase.RTDB.getBool(&firebaseData, "/control/light/auto")) {
    if (firebaseData.dataType() == "boolean") {
      autoModeLight = firebaseData.boolData();
    }
  }

  if (!autoModeFan) {
    if (Firebase.RTDB.getBool(&firebaseData, "/control/fan/status")) {
      if (firebaseData.dataType() == "boolean") {
        fanStatus = firebaseData.boolData();
      }
    }
  }

  if (!autoModeLight) {
    if (Firebase.RTDB.getBool(&firebaseData, "/control/light/status")) {
      if (firebaseData.dataType() == "boolean") {
        lightStatus = firebaseData.boolData();
      }
    }
  }
}

// Fungsi untuk memeriksa LCD secara berkala
void checkLCDConnection() {
  static unsigned long lastLCDCheck = 0;
  static bool lastLCDStatus = true;

  if (millis() - lastLCDCheck > 30000) {
    Wire.beginTransmission(0x27);
    byte error = Wire.endTransmission();
    bool currentLCDStatus = (error == 0);

    if (currentLCDStatus != lastLCDStatus) {
      if (currentLCDStatus) {
        logToFirebase("/logs/lcd", "LCD Connection Restored - Reinitializing");
        lcd.init();
        lcd.backlight();
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Reconnected...");
        logToFirebase("/logs/lcd", "LCD Ready and Initialized");
        Serial.println("LCD reinitialized successfully");
      } else {
        logToFirebase("/logs/lcd", "LCD Connection Lost - Check Wiring");
        Serial.println("LCD connection lost!");
      }
      lastLCDStatus = currentLCDStatus;
    }

    lastLCDCheck = millis();
  }
}

// Fungsi untuk memperbarui rentang dari Firebase
void updateRangesFromFirebase() {
  static unsigned long lastUpdate = 0;
  if (!firebaseReady) return;
  if (millis() - lastUpdate > 5000) {
    String path = "/ranges/week" + String(ageInWeeks);

    if (Firebase.RTDB.getFloat(&firebaseData, path + "/temperature/min")) {
      if (firebaseData.dataType() == "float" || firebaseData.dataType() == "double") {
        tempRanges[ageInWeeks - 1].min = firebaseData.floatData();
      }
    }
    if (Firebase.RTDB.getFloat(&firebaseData, path + "/temperature/max")) {
      if (firebaseData.dataType() == "float" || firebaseData.dataType() == "double") {
        tempRanges[ageInWeeks - 1].max = firebaseData.floatData();
      }
    }
    if (Firebase.RTDB.getFloat(&firebaseData, path + "/temperature/target")) {
      if (firebaseData.dataType() == "float" || firebaseData.dataType() == "double") {
        tempRanges[ageInWeeks - 1].target = firebaseData.floatData();
      }
    }

    if (Firebase.RTDB.getFloat(&firebaseData, path + "/humidity/min")) {
      if (firebaseData.dataType() == "float" || firebaseData.dataType() == "double") {
        humidityRanges[ageInWeeks - 1].min = firebaseData.floatData();
      }
    }
    if (Firebase.RTDB.getFloat(&firebaseData, path + "/humidity/max")) {
      if (firebaseData.dataType() == "float" || firebaseData.dataType() == "double") {
        humidityRanges[ageInWeeks - 1].max = firebaseData.floatData();
      }
    }
    if (Firebase.RTDB.getFloat(&firebaseData, path + "/humidity/target")) {
      if (firebaseData.dataType() == "float" || firebaseData.dataType() == "double") {
        humidityRanges[ageInWeeks - 1].target = firebaseData.floatData();
      }
    }

    lastUpdate = millis();
  }
}
