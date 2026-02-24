# 🔥 Setup Firebase - Cara Paling Mudah

## ✅ Yang Perlu Anda Lakukan (2 Langkah Saja!)

### Langkah 1: Copy File google-services.json

Anda sudah punya file `google-services.json` di Downloads. Sekarang:

1. Copy file tersebut
2. Paste ke folder: `android/app/google-services.json`

```
project_ta/
  android/
    app/
      google-services.json  ← Letakkan di sini
```

### Langkah 2: Generate Firebase Config

**Pilih salah satu:**

#### CARA A: Otomatis dengan FlutterFire CLI (RECOMMENDED) ⭐

```bash
# Install CLI
dart pub global activate flutterfire_cli

# Auto-generate config
flutterfire configure
```

File `firebase_options.dart` akan otomatis di-update dengan nilai yang benar!

#### CARA B: Manual dari Firebase Console

1. Buka https://console.firebase.google.com/
2. Pilih project Anda
3. **Project Settings** → **Your apps** → Pilih Android app
4. Scroll ke **SDK setup and configuration**
5. Copy nilai-nilai berikut:

```dart
// Buka lib/firebase_options.dart
// Ganti bagian android:

static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSy...paste dari console',
  appId: '1:123456789:android:abc...paste dari console',
  messagingSenderId: '123456789...paste dari console',
  projectId: 'your-project-id...paste dari console',
  storageBucket: 'your-project-id.appspot.com...paste dari console',
);
```

---

## 🚀 Selesai! Test Aplikasi

```bash
flutter clean
flutter pub get
flutter run
```

---

## 🔐 Enable Authentication

1. Firebase Console → **Authentication**
2. Tab **Sign-in method**
3. Enable:
   - ✅ **Email/Password**
   - ✅ **Google**

---

## 🔑 SHA-1 untuk Google Sign-In (Android)

Agar Google Sign-In berfungsi:

```bash
cd android
./gradlew signingReport
```

Copy **SHA-1** dari output, lalu:
1. Firebase Console → Project Settings
2. Your apps → Android app
3. **Add fingerprint** → Paste SHA-1

---

## 🧪 Test User

### Opsi 1: Buat di Firebase Console
1. Firebase Console → Authentication → Users
2. **Add user** → Email: `test@test.com`, Password: `test123`

### Opsi 2: Google Sign-In (Auto-register)
Langsung klik tombol "Google" di aplikasi!

---

## ❓ Troubleshooting

### "google-services.json not found"
→ Pastikan file ada di `android/app/google-services.json`

### "Firebase not configured"
→ Jalankan `flutterfire configure`

### Google Sign-In tidak work
→ Pastikan SHA-1 sudah ditambahkan di Firebase Console

---

That's it! Sesimple itu 🎉
