# Android Configuration untuk Firebase

## Update Android Build Files

### 1. Update `android/build.gradle.kts`

Tambahkan Google Services plugin di `dependencies`:

```kotlin
buildscript {
    ext.kotlin_version = '1.9.0'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:8.0.2'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        // Tambahkan baris ini untuk Google Services
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

### 2. Update `android/app/build.gradle.kts`

Tambahkan plugin di **AKHIR** file:

```kotlin
// ... kode lainnya ...

apply plugin: 'com.google.gms.google-services'
```

Atau jika menggunakan Kotlin DSL:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Tambahkan ini
}
```

### 3. Pastikan minSdkVersion Sesuai

Di `android/app/build.gradle.kts`, pastikan:

```kotlin
android {
    defaultConfig {
        minSdkVersion 21  // Minimal untuk Firebase
        targetSdkVersion 34
    }
}
```

### 4. File `google-services.json`

Letakkan di: `android/app/google-services.json`

Struktur folder:
```
android/
  app/
    google-services.json  ← Letakkan di sini
    build.gradle.kts
```

## Troubleshooting

### Error: "google-services.json not found"
- Pastikan file ada di `android/app/google-services.json`
- Download ulang dari Firebase Console jika perlu

### Error: "FirebaseApp not initialized"
- Pastikan `google-services.json` sudah diletakkan dengan benar
- Jalankan `flutter clean` lalu `flutter run`

### Google Sign-In tidak berfungsi
- Pastikan SHA-1 fingerprint sudah ditambahkan di Firebase Console
- Untuk debug build, dapatkan SHA-1 dengan: `./gradlew signingReport`
- Untuk release build, gunakan SHA-1 dari keystore Anda
