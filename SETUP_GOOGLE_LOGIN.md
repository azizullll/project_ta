# ✅ Setup Google Login - Langkah Final

## 🎉 Yang Sudah Selesai:
- ✅ Google Sign-In button di login page (tombol utama)
- ✅ File `google-services.json` sudah di tempat yang benar
- ✅ Firebase configuration untuk Android sudah diupdate
- ✅ Login controller sudah support Google Sign-In
- ✅ Email/password login sebagai alternatif

---

## 🚀 Yang Harus Dilakukan (3 Langkah):

### 1. Enable Authentication di Firebase Console

1. Buka https://console.firebase.google.com/
2. Pilih project: **broodguard-ff9f7**
3. Klik **Authentication** di menu kiri
4. Tab **Sign-in method**
5. **Enable Google:**
   - Klik pada **Google**
   - Toggle untuk enable
   - Pilih **support email** (email Anda)
   - Klik **Save**
6. **Enable Email/Password** (optional, untuk alternatif):
   - Klik pada **Email/Password**
   - Toggle untuk enable
   - Klik **Save**

### 2. Tambahkan SHA-1 Fingerprint (Penting untuk Google Sign-In!)

```bash
# Buka terminal di folder project
cd f:\Bismillah_TA\project_ta

# Dapatkan SHA-1 fingerprint
cd android
./gradlew signingReport
```

**Copy SHA-1** dari output (cari yang bagian `:app:signingReport` → `Variant: debug` → `SHA1`), contoh:
```
SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD
```

**Tambahkan ke Firebase:**
1. Firebase Console → **Project Settings** (icon gear)
2. Scroll ke **Your apps** section
3. Pilih Android app (com.example.project_ta)
4. **Add fingerprint** → Paste SHA-1
5. Klik **Save**

### 3. Run Aplikasi!

```bash
cd f:\Bismillah_TA\project_ta
flutter clean
flutter pub get
flutter run
```

---

## 📱 Cara Test Google Login

1. **Buka aplikasi**
2. **Klik tombol "Sign in with Google"** (tombol putih besar di bagian atas)
3. **Pilih akun Google** Anda
4. **Selesai!** User otomatis terdaftar dan login

### Alternatif: Login dengan Email/Password
1. Buat user di Firebase Console → Authentication → Users → **Add user**
2. Masukkan email dan password
3. Di aplikasi, scroll ke bawah, masukkan email & password
4. Klik tombol **Login**

---

## 🎨 Tampilan Login Page Sekarang:

```
┌─────────────────────────┐
│     [LOGO]              │
├─────────────────────────┤
│  We Say Hello!          │
│  Sign in with your      │
│  Google account         │
│                         │
│  [🔵 Sign in with      │
│     Google]  ← UTAMA   │
│                         │
│  ────── OR ──────      │
│                         │
│  [Email field]          │
│  [Password field]       │
│  [Login button]         │
│                         │
│  Forgot Password?       │
└─────────────────────────┘
```

**Google Sign-In adalah metode UTAMA** (tombol besar di atas)
Email/Password adalah **ALTERNATIF** (di bawah)

---

## ⚠️ Troubleshooting

### "Sign in with Google" tidak berfungsi
**Solusi:**
1. Pastikan SHA-1 sudah ditambahkan di Firebase Console
2. Enable Google provider di Authentication → Sign-in method
3. Jalankan: `flutter clean && flutter pub get && flutter run`

### "PlatformException: sign_in_failed"
**Solusi:**
1. Cek SHA-1 sudah benar (jalankan `./gradlew signingReport` lagi)
2. Download ulang `google-services.json` dari Firebase Console
3. Replace file lama di `android/app/google-services.json`
4. Restart aplikasi

### Email/Password login tidak work
**Solusi:**
1. Enable Email/Password di Firebase Console → Authentication → Sign-in method
2. Buat user test di Firebase Console → Authentication → Users

---

## 🎯 Summary

**Login Method Utama:** Google Sign-In (Gmail)
**Login Method Alternatif:** Email/Password

Setelah langkah 1-3 selesai, aplikasi Anda siap digunakan dengan Google login! 🚀
