# Firebase Integration - Flutter & ESP32 BroodGuard

## 🔥 Integrasi Firebase Realtime Database

Integrasi Firebase telah berhasil ditambahkan ke aplikasi Flutter BroodGuard untuk menampilkan data real-time dari ESP32 dan mengontrol perangkat jarak jauh.

## 📋 Fitur yang Ditambahkan

### 1. **Firebase Service** (`lib/services/firebase_service.dart`)
- Koneksi real-time ke Firebase Realtime Database
- Stream data sensor (suhu, kelembapan)
- Stream status relay (kipas, lampu)
- Stream kontrol mode (otomatis/manual)
- Stream emergency alerts
- Fungsi kontrol perangkat (kirim perintah ke ESP32)

### 2. **Dashboard Controller** (Diperbarui)
- Menggunakan Firebase sebagai sumber data real-time
- Menggantikan data simulasi dengan data sebenarnya dari ESP32
- Penanganan status koneksi
- Alert system untuk kondisi darurat

### 3. **Real-Time Monitor Page** (`lib/pages/real_time_monitor_page.dart`)
- Halaman monitoring data Firebase secara detail
- Menampilkan status koneksi ESP32
- Data sensor real-time
- Status perangkat (relay)
- Alert darurat
- Data fuzzy logic (untuk debugging)

### 4. **Connection Status Indicators**
- Indikator koneksi di Dashboard dan Control Page
- Waktu update terakhir dari ESP32
- Status online/offline ESP32

## 🛠️ Konfigurasi Firebase

### 1. **google-services.json** - ✅ Selesai
File telah diperbarui dengan konfigurasi lengkap termasuk `firebase_url` untuk Realtime Database.

### 2. **firebase_options.dart** - ✅ Selesai  
Ditambahkan `databaseURL` untuk koneksi Realtime Database.

### 3. **Dependencies** - ✅ Sudah Ada
```yaml
firebase_core: ^3.15.2
firebase_database: ^11.3.10
```

## 🔄 Alur Data

### ESP32 → Firebase → Flutter
```
ESP32 Sensor → Firebase Realtime DB → Flutter App (Real-time Stream)
```

### Flutter → Firebase → ESP32
```
Flutter Control → Firebase Realtime DB → ESP32 (Listen for changes)
```

## 📡 Struktur Data Firebase

```
broodguard-ff9f7/
├── sensor/
│   ├── temperature: 28.5
│   ├── Humidity: 65
│   └── timestamp: "2026-03-07 14:30:25"
├── relay/
│   ├── Kipas: true/false
│   └── Lampu: true/false
├── control/
│   ├── fan/
│   │   ├── auto: true/false
│   │   └── status: true/false
│   └── light/
│       ├── auto: true/false
│       └── status: true/false
├── chicken_age: 1-4
├── emergency/
│   ├── high_temperature: true/false
│   ├── low_temperature: true/false
│   ├── high_humidity: true/false
│   └── low_humidity: true/false
└── status/
    ├── temperature: "Status message"
    └── humidity: "Status message"
```

## 🎮 Cara Menggunakan

### 1. **Dashboard**
- Lihat data suhu dan kelembapan real-time
- Status koneksi ESP32
- Umur ayam
- Mode kontrol (Otomatis/Manual)
- Akses Real-Time Monitor (ikon monitor di AppBar)

### 2. **Control Page**
- Toggle mode Otomatis/Manual
- Kontrol manual kipas dan lampu (hanya saat mode Manual)
- Status koneksi ESP32
- Info waktu update terakhir

### 3. **Real-Time Monitor**
- Data lengkap dari Firebase
- Status emergency alerts
- Debug data fuzzy logic
- Logs sistem ESP32

## ⚠️ Troubleshooting

### ESP32 Tidak Terhubung
1. Periksa koneksi WiFi ESP32
2. Pastikan Firebase Rules mengizinkan akses
3. Cek Serial Monitor ESP32 untuk error

### Data Tidak Update
1. Refresh dengan pull-to-refresh di dashboard
2. Periksa koneksi internet
3. Restart aplikasi Flutter

### Kontrol Tidak Berfungsi
1. Pastikan mode Manual aktif untuk kontrol manual
2. Periksa koneksi ESP32 ke Firebase
3. Lihat Real-Time Monitor untuk debug

## 🚀 Deployment

1. **Build APK**:
   ```bash
   flutter build apk --release
   ```

2. **Install di Device**:
   ```bash
   flutter install
   ```

3. **ESP32**: Upload kode Arduino yang sudah diperbarui dengan Firebase integration

## 📱 Screenshot Fitur

- ✅ Dashboard dengan status koneksi
- ✅ Control page dengan Firebase integration  
- ✅ Real-time monitor page
- ✅ Emergency alerts
- ✅ Connection indicators

## 🔧 Technical Details

- **Real-time Streams**: Menggunakan Firebase Realtime Database streams
- **Error Handling**: Try-catch blocks untuk Firebase operations
- **Singleton Pattern**: DashboardController menggunakan singleton pattern
- **Stream Subscriptions**: Proper cleanup untuk mencegah memory leaks
- **Async Operations**: Control methods menggunakan async/await pattern

---

## 📞 Support

Jika ada masalah dengan integrasi Firebase, periksa:
1. Console log di Flutter (`flutter logs`)
2. Serial monitor ESP32
3. Firebase Console untuk data structure
4. Real-Time Monitor page untuk debug information