# 🎯 QUICK REFERENCE - Firebase .env Configuration

## 📋 Checklist Setup Firebase

```
[ ] 1. Copy .env.example → .env
[ ] 2. Buka Firebase Console (https://console.firebase.google.com/)
[ ] 3. Pilih/Buat project
[ ] 4. Dapatkan konfigurasi untuk platform yang digunakan
[ ] 5. Isi nilai di .env
[ ] 6. Download google-services.json (Android) / GoogleService-Info.plist (iOS)
[ ] 7. Enable Authentication (Email/Password & Google)
[ ] 8. Tambahkan SHA-1 fingerprint (Android)
[ ] 9. flutter clean && flutter pub get
[ ] 10. flutter run
```

---

## 🔑 Dimana Menemukan Nilai .env

| Nilai | Lokasi di Firebase Console |
|-------|---------------------------|
| API_KEY | Project Settings → Your apps → SDK setup |
| APP_ID | Project Settings → Your apps → SDK setup |
| PROJECT_ID | Project Settings → General → Project ID |
| MESSAGING_SENDER_ID | Project Settings → Your apps → SDK setup |
| AUTH_DOMAIN | Project Settings → Your apps → SDK setup |
| STORAGE_BUCKET | Project Settings → Your apps → SDK setup |
| GOOGLE_CLIENT_ID | Authentication → Sign-in method → Google → Web SDK configuration |

---

## ⚡ Quick Commands

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Auto-configure (RECOMMENDED)
flutterfire configure

# Get Android SHA-1
cd android && ./gradlew signingReport

# Clean & Run
flutter clean && flutter pub get && flutter run
```

---

## 🎨 File Structure

```
project_ta/
├── .env                          ← ISI INI dengan nilai Firebase
├── .env.example                  ← Template (sudah ada)
├── lib/
│   ├── firebase_options.dart     ← Baca dari .env otomatis
│   ├── config/
│   │   └── firebase_env_config.dart  ← Helper untuk baca .env
│   └── main.dart                 ← Initialize Firebase
└── android/
    └── app/
        └── google-services.json  ← Download dari Firebase
```

---

## 🚨 Common Issues & Quick Fix

| Issue | Quick Fix |
|-------|-----------|
| "Firebase config belum diisi" | Isi .env atau run `flutterfire configure` |
| "MissingPluginException" | `flutter clean && flutter pub get` |
| Google Sign-In tidak work | Add SHA-1, download ulang google-services.json |
| ".env not found" | Copy .env.example → .env |

---

## 📞 Need Help?

Lihat dokumentasi lengkap:
- **FIREBASE_ENV_GUIDE.md** - Panduan lengkap isi .env
- **IMPLEMENTATION_STATUS.md** - Status & checklist
- **QUICKSTART_FIREBASE.md** - Quick start guide
