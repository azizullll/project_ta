# Firebase Cloud Function untuk Password Reset

## Setup Instructions

### 1. Install Firebase CLI
```bash
npm install -g firebase-tools
```

### 2. Login to Firebase
```bash
firebase login
```

### 3. Initialize Cloud Functions
Di root project, jalankan:
```bash
firebase init functions
```

Pilih:
- TypeScript atau JavaScript
- Install dependencies

### 4. Copy Code ke functions/src/index.ts

Ganti isi file `functions/src/index.ts` dengan code dari `password_reset_function.js`

### 5. Install Dependencies
```bash
cd functions
npm install firebase-admin
npm install firebase-functions
```

### 6. Deploy Cloud Function
```bash
firebase deploy --only functions
```

## Cloud Function Code

Lihat file: `password_reset_function.js`

## Cara Kerja

1. User verifikasi OTP di app
2. User masukkan password baru
3. App menyimpan request ke Firestore collection `password_reset_requests`
4. Cloud Function otomatis terpanggil (trigger)
5. Function mengupdate password user menggunakan Firebase Admin SDK
6. Status di Firestore diupdate menjadi 'completed'

## Testing

Untuk testing tanpa Cloud Function, password akan tetap tersimpan di Firestore dan app akan menampilkan pesan sukses. Namun password belum benar-benar terupdate sampai Cloud Function di-deploy.

## Security Rules

Tambahkan di Firestore Rules:
```
match /password_reset_requests/{email} {
  allow write: if request.auth == null; // Allow unauthenticated writes
  allow read: if false; // Prevent reads
}
```
