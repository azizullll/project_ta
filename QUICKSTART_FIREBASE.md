# Quick Start - Firebase Authentication Setup

## ⚡ Langkah Cepat (Recommended)

### 1. Install FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### 2. Konfigurasi Firebase
```bash
# Di root project
flutterfire configure
```
Pilih/buat Firebase project, CLI akan otomatis generate `firebase_options.dart` dengan konfigurasi yang benar.

### 3. Enable Authentication
1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Pilih project Anda
3. Buka **Authentication** → **Sign-in method**
4. Enable:
   - ✅ **Email/Password**
   - ✅ **Google**

### 4. Untuk Android - Tambahkan SHA-1
```bash
cd android
./gradlew signingReport
```
Copy SHA-1 fingerprint, lalu tambahkan di:
Firebase Console → Project Settings → Your apps → Android app → Add fingerprint

### 5. Download File Konfigurasi

**Android:**
- Download `google-services.json` dari Firebase Console
- Letakkan di: `android/app/google-services.json`

**iOS:**
- Download `GoogleService-Info.plist` dari Firebase Console
- Drag ke Xcode project di folder Runner

### 6. Test!
```bash
flutter run
```

## 📱 Cara Test Aplikasi

### Test 1: Login dengan Email/Password
1. Buka Firebase Console → Authentication → Users
2. Klik "Add user" → Masukkan email & password
3. Di aplikasi, login dengan kredensial tersebut

### Test 2: Login dengan Google
1. Klik tombol "Sign in with Google"
2. Pilih akun Google
3. Selesai! (User otomatis terdaftar)

### Test 3: Forgot Password
1. Klik "Forgot Password?"
2. Masukkan email yang terdaftar
3. Cek inbox email → Klik link reset password
4. Set password baru → Login dengan password baru

## 📚 Dokumentasi Lengkap
Lihat [FIREBASE_SETUP.md](FIREBASE_SETUP.md) untuk panduan detail dan troubleshooting.

## ⚠️ Note
- Logo Google optional: Tambahkan `google_logo.png` di folder `assets/` atau biarkan menggunakan icon default
- File `firebase_options.dart` sudah ada di `.gitignore` untuk keamanan
- **Jangan** commit file `google-services.json` atau `GoogleService-Info.plist` ke repository public!
