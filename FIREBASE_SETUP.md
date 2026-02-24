# Panduan Konfigurasi Firebase untuk Login dengan Google

## Persiapan Firebase

### 1. Buat Firebase Project
1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Klik "Add project" atau "Tambahkan project"
3. Beri nama project Anda (misal: BroodGuard)
4. Ikuti langkah-langkah setup sampai selesai

### 2. Install FlutterFire CLI
```bash
# Install FlutterFire CLI globally
dart pub global activate flutterfire_cli

# Atau menggunakan npm
npm install -g firebase-tools
firebase login
```

### 3. Konfigurasi Firebase dengan FlutterFire CLI
```bash
# Jalankan di root project
flutterfire configure

# Pilih project Firebase yang sudah dibuat
# CLI akan otomatis membuat file firebase_options.dart dengan konfigurasi yang benar
```

**ATAU** konfigurasi manual:

### 4. Konfigurasi Manual (Alternatif)

#### Untuk Android:
1. Di Firebase Console, pilih project Anda
2. Klik icon Android untuk menambahkan aplikasi Android
3. Android package name: `com.example.project_ta` (sesuaikan dengan package name di `android/app/build.gradle.kts`)
4. Download file `google-services.json`
5. Letakkan file di: `android/app/google-services.json`
6. Update `android/build.gradle.kts` tambahkan:
```kotlin
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```
7. Update `android/app/build.gradle.kts` tambahkan di akhir file:
```kotlin
apply plugin: 'com.google.gms.google-services'
```

#### Untuk iOS:
1. Di Firebase Console, klik icon iOS untuk menambahkan aplikasi iOS
2. iOS bundle ID: `com.example.projectTa` (sesuaikan dengan Bundle ID di `ios/Runner.xcodeproj`)
3. Download file `GoogleService-Info.plist`
4. Buka project iOS di Xcode: `open ios/Runner.xcworkspace`
5. Drag file `GoogleService-Info.plist` ke folder Runner di Xcode
6. Pastikan "Copy items if needed" dicentang

#### Untuk Web:
1. Di Firebase Console, klik icon Web untuk menambahkan aplikasi Web
2. Copy konfigurasi Firebase
3. Update file `web/index.html` tambahkan sebelum `</body>`:
```html
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-auth-compat.js"></script>
<script>
  const firebaseConfig = {
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_AUTH_DOMAIN",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_STORAGE_BUCKET",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    appId: "YOUR_APP_ID"
  };
  firebase.initializeApp(firebaseConfig);
</script>
```

### 5. Aktifkan Authentication di Firebase Console
1. Di Firebase Console, buka **Authentication**
2. Klik tab **Sign-in method**
3. Enable **Email/Password**
4. Enable **Google** sign-in provider
   - Klik Google
   - Toggle untuk mengaktifkan
   - Pilih support email
   - Klik Save

### 6. Konfigurasi Google Sign-In

#### Untuk Android:
1. Dapatkan SHA-1 fingerprint:
```bash
cd android
./gradlew signingReport
# Copy SHA-1 dari variant debug
```
2. Di Firebase Console -> Project Settings -> Your apps -> Android app
3. Tambahkan SHA-1 fingerprint

#### Untuk iOS:
1. File `GoogleService-Info.plist` sudah mencakup konfigurasi yang diperlukan
2. Update `ios/Runner/Info.plist` tambahkan:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Reversed client ID dari GoogleService-Info.plist -->
            <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### 7. Update firebase_options.dart
Setelah menjalankan `flutterfire configure`, file `lib/firebase_options.dart` akan otomatis diupdate dengan konfigurasi yang benar untuk semua platform.

Atau update manual dengan nilai dari Firebase Console.

## Fitur yang Sudah Diimplementasi

### 1. Login dengan Email & Password
- User bisa login menggunakan email dan password yang terdaftar di Firebase
- Validasi email format
- Error handling untuk berbagai kasus (user tidak ditemukan, password salah, dll)

### 2. Login dengan Google Sign-In
- User bisa login menggunakan akun Google mereka
- Otomatis mendaftarkan user baru jika belum terdaftar
- UI dengan tombol "Sign in with Google"

### 3. Forgot Password (Reset Password)
- User bisa request link reset password
- Firebase akan mengirim email ke alamat yang terdaftar
- Email berisi link untuk reset password
- Link valid selama 1 jam

## Cara Membuat User untuk Testing

### Opsi 1: Melalui Firebase Console
1. Buka Firebase Console -> Authentication -> Users
2. Klik "Add user"
3. Masukkan email dan password
4. Klik "Add user"

### Opsi 2: Membuat halaman Register di aplikasi
Tambahkan fungsi register di `login_controller.dart`:
```dart
Future<Map<String, dynamic>> registerWithEmailPassword(String email, String password) async {
  try {
    final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return {'success': true, 'user': userCredential.user};
  } on FirebaseAuthException catch (e) {
    return {'success': false, 'message': e.message};
  }
}
```

### Opsi 3: Login dengan Google (Otomatis Register)
User baru otomatis terdaftar saat pertama kali login dengan Google.

## Testing

1. **Test Email/Password Login:**
   - Buat user di Firebase Console
   - Coba login dengan email dan password tersebut

2. **Test Google Sign-In:**
   - Klik tombol "Sign in with Google"
   - Pilih akun Google
   - Login akan berhasil dan user akan terdaftar otomatis

3. **Test Forgot Password:**
   - Masukkan email yang terdaftar
   - Klik "Reset Password"
   - Cek inbox email
   - Klik link di email untuk reset password
   - Gunakan password baru untuk login

## Troubleshooting

### Error: "MissingPluginException"
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean
cd ..
flutter run
```

### Google Sign-In tidak berfungsi di Android
- Pastikan SHA-1 fingerprint sudah ditambahkan di Firebase Console
- Download ulang `google-services.json` dan replace yang lama

### Email tidak terkirim (Forgot Password)
- Cek spam folder
- Pastikan email terdaftar di Firebase
- Cek Firebase Console -> Authentication -> Templates -> Password reset (customize jika perlu)

## Struktur Kode

- `lib/main.dart` - Inisialisasi Firebase
- `lib/firebase_options.dart` - Konfigurasi Firebase untuk semua platform
- `lib/controllers/login_controller.dart` - Logic login (Email & Google)
- `lib/controllers/forgot_password_controller.dart` - Logic reset password
- `lib/pages/login_page.dart` - UI halaman login
- `lib/pages/forgot_password_page.dart` - UI halaman forgot password

## Keamanan

⚠️ **PENTING:**
- Jangan commit file `google-services.json` atau `GoogleService-Info.plist` ke git public
- Tambahkan ke `.gitignore`:
```
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

## Resources
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
