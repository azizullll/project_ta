# 🔐 Cara Mengkonfigurasi Firebase di File .env

## 📖 Overview

Aplikasi ini mendukung 2 cara konfigurasi Firebase:

### Cara 1: FlutterFire CLI (RECOMMENDED) ⭐
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
File `firebase_options.dart` akan otomatis di-generate.

### Cara 2: Manual via .env file
Isi file `.env` dengan nilai dari Firebase Console. Panduan lengkap di bawah ini.

---

## 🚀 Langkah-langkah Mengisi .env

### Step 1: Akses Firebase Console

1. Buka https://console.firebase.google.com/
2. Pilih project Anda (atau buat project baru)
3. Klik icon **⚙️ Settings** (gear icon) di sidebar kiri
4. Pilih **Project settings**

### Step 2: Dapatkan Konfigurasi untuk Setiap Platform

#### 📱 Untuk Android

1. Di Firebase Console → **Project settings** → scroll ke **Your apps**
2. Jika belum ada Android app, klik **Add app** → pilih **Android** icon
3. **Android package name**: `com.example.project_ta` (atau sesuai dengan package name Anda di `android/app/build.gradle.kts`)
4. Klik **Register app**
5. Download `google-services.json` → **Letakkan di `android/app/google-services.json`**
6. Klik **Continue** sampai selesai
7. Kembali ke **Project settings** → Your apps → pilih Android app
8. Scroll ke **SDK setup and configuration** → pilih **Configuration**
9. Copy nilai-nilai berikut ke `.env`:

```env
FIREBASE_ANDROID_API_KEY=AIzaSy_copy_dari_firebase_console
FIREBASE_ANDROID_APP_ID=1:123456789:android:abc123def456
FIREBASE_ANDROID_MESSAGING_SENDER_ID=123456789
FIREBASE_ANDROID_PROJECT_ID=your-project-id
FIREBASE_ANDROID_STORAGE_BUCKET=your-project-id.appspot.com
```

**⚠️ SHA-1 Fingerprint (PENTING untuk Google Sign-In):**
```bash
cd android
./gradlew signingReport
# Copy SHA-1 dari output
```
Tambahkan SHA-1 di Firebase Console → Project settings → Your apps → Android app → **Add fingerprint**

---

#### 🌐 Untuk Web

1. Di Firebase Console → **Project settings** → Your apps
2. Jika belum ada Web app, klik **Add app** → pilih **Web** icon `</>`
3. **App nickname**: `BroodGuard Web` (atau sesuai keinginan)
4. Centang **Also set up Firebase Hosting** (optional)
5. Klik **Register app**
6. Copy nilai dari **Firebase SDK snippet** → **Config**
7. Paste ke `.env`:

```env
FIREBASE_WEB_API_KEY=AIzaSy_copy_dari_firebase_console
FIREBASE_WEB_APP_ID=1:123456789:web:abc123def456
FIREBASE_WEB_MESSAGING_SENDER_ID=123456789
FIREBASE_WEB_PROJECT_ID=your-project-id
FIREBASE_WEB_AUTH_DOMAIN=your-project-id.firebaseapp.com
FIREBASE_WEB_STORAGE_BUCKET=your-project-id.appspot.com
FIREBASE_WEB_MEASUREMENT_ID=G-XXXXXXXXXX
```

---

#### 🍎 Untuk iOS

1. Di Firebase Console → **Project settings** → Your apps
2. Jika belum ada iOS app, klik **Add app** → pilih **iOS** icon
3. **iOS bundle ID**: `com.example.projectTa` (lihat di `ios/Runner/Info.plist`)
4. Klik **Register app**
5. Download `GoogleService-Info.plist`
6. **Letakkan di iOS project:**
   - Buka `ios/Runner.xcworkspace` di Xcode
   - Drag `GoogleService-Info.plist` ke folder **Runner**
   - Pastikan **Copy items if needed** dicentang
7. Kembali ke Firebase Console
8. Copy nilai konfigurasi ke `.env`:

```env
FIREBASE_IOS_API_KEY=AIzaSy_copy_dari_firebase_console
FIREBASE_IOS_APP_ID=1:123456789:ios:abc123def456
FIREBASE_IOS_MESSAGING_SENDER_ID=123456789
FIREBASE_IOS_PROJECT_ID=your-project-id
FIREBASE_IOS_STORAGE_BUCKET=your-project-id.appspot.com
FIREBASE_IOS_BUNDLE_ID=com.example.projectTa
```

---

#### 🖥️ Untuk MacOS (Optional)

Sama seperti iOS, gunakan bundle ID yang sama atau berbeda.

```env
FIREBASE_MACOS_API_KEY=AIzaSy_copy_dari_firebase_console
FIREBASE_MACOS_APP_ID=1:123456789:ios:abc123def456
FIREBASE_MACOS_MESSAGING_SENDER_ID=123456789
FIREBASE_MACOS_PROJECT_ID=your-project-id
FIREBASE_MACOS_STORAGE_BUCKET=your-project-id.appspot.com
FIREBASE_MACOS_BUNDLE_ID=com.example.projectTa
```

---

### Step 3: Dapatkan Google Client IDs (untuk Google Sign-In)

1. Firebase Console → **Authentication** → **Sign-in method** tab
2. Klik **Google** provider
3. Enable Google sign-in
4. Pilih **Support email**
5. Klik **Save**
6. Expand **Web SDK configuration** section
7. Copy **Web client ID**:

```env
GOOGLE_CLIENT_ID_WEB=123456789-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com
```

8. Untuk Android & iOS, nilai tersebut sudah ada di `google-services.json` dan `GoogleService-Info.plist`

---

## 📝 Contoh File .env Lengkap

```env
# ===================================================
# FIREBASE CONFIGURATION
# ===================================================

# Firebase Web Configuration
FIREBASE_WEB_API_KEY=AIzaSyDaBC123-XyZ456_example_api_key
FIREBASE_WEB_APP_ID=1:123456789012:web:abc123def456ghi789
FIREBASE_WEB_MESSAGING_SENDER_ID=123456789012
FIREBASE_WEB_PROJECT_ID=broodguard-app
FIREBASE_WEB_AUTH_DOMAIN=broodguard-app.firebaseapp.com
FIREBASE_WEB_STORAGE_BUCKET=broodguard-app.appspot.com
FIREBASE_WEB_MEASUREMENT_ID=G-ABC1234XYZ

# Firebase Android Configuration
FIREBASE_ANDROID_API_KEY=AIzaSyDaBC123-XyZ456_example_android_key
FIREBASE_ANDROID_APP_ID=1:123456789012:android:abc123def456ghi789
FIREBASE_ANDROID_MESSAGING_SENDER_ID=123456789012
FIREBASE_ANDROID_PROJECT_ID=broodguard-app
FIREBASE_ANDROID_STORAGE_BUCKET=broodguard-app.appspot.com

# Firebase iOS Configuration
FIREBASE_IOS_API_KEY=AIzaSyDaBC123-XyZ456_example_ios_key
FIREBASE_IOS_APP_ID=1:123456789012:ios:abc123def456ghi789
FIREBASE_IOS_MESSAGING_SENDER_ID=123456789012
FIREBASE_IOS_PROJECT_ID=broodguard-app
FIREBASE_IOS_STORAGE_BUCKET=broodguard-app.appspot.com
FIREBASE_IOS_BUNDLE_ID=com.example.projectTa

# Google Sign-In Configuration
GOOGLE_CLIENT_ID_WEB=123456789012-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com
GOOGLE_CLIENT_ID_ANDROID=123456789012-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com
GOOGLE_CLIENT_ID_IOS=123456789012-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com
```

---

## ✅ Verifikasi Konfigurasi

### 1. Cek di Console saat startup

Jalankan aplikasi:
```bash
flutter run
```

Jika konfigurasi belum lengkap, akan muncul warning:
```
⚠️ WARNING: Firebase configuration belum diisi di .env file!
Silakan isi file .env dengan nilai dari Firebase Console
atau jalankan: flutterfire configure
```

### 2. Test Firebase Authentication

1. **Enable Authentication:**
   - Firebase Console → **Authentication** → **Sign-in method**
   - Enable **Email/Password**
   - Enable **Google**

2. **Test Login:**
   - Buat user test di Firebase Console → Authentication → Users
   - Atau langsung test Google Sign-In (auto-register)

---

## 🔒 Security Best Practices

### ✅ DO:
- ✅ Gunakan `.env` untuk development
- ✅ Copy `.env.example` → `.env` untuk setiap developer
- ✅ Tambahkan `.env` ke `.gitignore` (sudah ditambahkan ✓)
- ✅ Gunakan environment variables berbeda untuk dev/staging/production

### ❌ DON'T:
- ❌ Jangan commit file `.env` ke git public repository
- ❌ Jangan share file `.env` di Slack/Discord/Email
- ❌ Jangan hardcode API keys di source code
- ❌ Jangan commit `google-services.json` atau `GoogleService-Info.plist` ke git public

---

## 🐛 Troubleshooting

### Error: "Firebase configuration belum diisi"
**Solusi:** Isi nilai di `.env` atau jalankan `flutterfire configure`

### Error: "No Firebase App '[DEFAULT]' has been created"
**Solusi:** 
```bash
flutter clean
flutter pub get
flutter run
```

### Google Sign-In tidak berfungsi
**Solusi:**
1. Pastikan SHA-1 sudah ditambahkan (Android)
2. Download ulang `google-services.json` setelah add SHA-1
3. Enable Google provider di Firebase Console
4. `flutter clean && flutter run`

### Nilai dari .env tidak terbaca
**Solusi:**
1. Pastikan file bernama `.env` (bukan `.env.txt`)
2. Restart aplikasi
3. Cek apakah `flutter_dotenv` sudah di-load di `main.dart`

---

## 📚 Resources

- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Google Sign-In Setup](https://pub.dev/packages/google_sign_in)
- [flutter_dotenv Package](https://pub.dev/packages/flutter_dotenv)

---

## 💡 Tips

1. **Gunakan FlutterFire CLI** untuk konfigurasi otomatis (lebih mudah)
2. **Backup `.env`** Anda di tempat aman (password manager, encrypted storage)
3. **Gunakan Firebase projects berbeda** untuk development dan production
4. **Test di emulator** dulu sebelum deploy ke device fisik

---

Sudah siap? Isi file `.env` Anda dan jalankan `flutter run`! 🚀
