# Firestore Security Rules untuk Password Reset

Tambahkan rules berikut ke Firestore Security Rules Anda di Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ... existing rules ...
    
    // Password Reset OTPs Collection
    match /password_reset_otps/{email} {
      // Allow create and update for OTP operations
      allow create: if true; // Anyone can request OTP
      allow update: if true; // Allow verification updates
      allow read: if true;   // Allow reading for verification
      allow delete: if true; // Allow cleanup
    }
    
    // Password Reset Requests Collection
    match /password_reset_requests/{email} {
      // Allow anyone to create reset request (after OTP verification in app logic)
      allow create: if true;
      
      // Only Cloud Functions can update
      allow update: if false;
      
      // Only Cloud Functions can read (through admin SDK)
      allow read: if false;
      
      // Only Cloud Functions can delete
      allow delete: if false;
    }
  }
}
```

## Penjelasan Rules

### password_reset_otps
- **Create**: Diizinkan untuk semua user agar bisa request OTP
- **Update**: Diizinkan untuk proses verifikasi OTP
- **Read**: Diizinkan untuk mengecek status verifikasi
- **Delete**: Diizinkan untuk cleanup setelah reset password

### password_reset_requests
- **Create**: Diizinkan untuk user yang sudah verifikasi OTP (validasi di app logic)
- **Update/Read/Delete**: Hanya Cloud Function yang bisa mengakses (menggunakan Admin SDK)

## Apply Rules

1. Buka Firebase Console
2. Pilih project Anda
3. Pergi ke **Firestore Database**
4. Klik tab **Rules**
5. Paste rules di atas dan merge dengan rules existing
6. Klik **Publish** untuk apply rules

## Security Best Practices

1. **Password Storage**: Password baru di-store sementara di Firestore dan langsung dihapus setelah diproses oleh Cloud Function
2. **OTP Expiry**: OTP expired setelah 10 menit
3. **Reset Session**: Session reset password expired setelah 30 menit
4. **Token Verification**: Reset token di-generate secara random dan divalidasi sebelum update password

## Alternatif (More Secure)

Jika ingin lebih secure, ubah rule `password_reset_requests` menjadi:

```javascript
match /password_reset_requests/{email} {
  // Require authentication and email match
  allow create: if request.auth != null && 
                   request.auth.token.email == email;
  allow update, read, delete: if false;
}
```

Note: Dengan rule ini, user harus login dulu sebelum bisa reset password, yang mungkin tidak sesuai dengan use case forgot password.
