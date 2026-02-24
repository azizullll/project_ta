import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Helper class untuk membaca konfigurasi Firebase dari .env file
/// 
/// CATATAN: Anda bisa menggunakan cara ini ATAU firebase_options.dart
/// Cara yang direkomendasikan adalah menggunakan FlutterFire CLI:
/// $ flutterfire configure
/// 
/// Namun jika ingin menggunakan .env, gunakan class ini.
class FirebaseEnvConfig {
  // Web Configuration
  static String get webApiKey => 
      dotenv.env['FIREBASE_WEB_API_KEY'] ?? '';
  static String get webAppId => 
      dotenv.env['FIREBASE_WEB_APP_ID'] ?? '';
  static String get webMessagingSenderId => 
      dotenv.env['FIREBASE_WEB_MESSAGING_SENDER_ID'] ?? '';
  static String get webProjectId => 
      dotenv.env['FIREBASE_WEB_PROJECT_ID'] ?? '';
  static String get webAuthDomain => 
      dotenv.env['FIREBASE_WEB_AUTH_DOMAIN'] ?? '';
  static String get webStorageBucket => 
      dotenv.env['FIREBASE_WEB_STORAGE_BUCKET'] ?? '';
  static String get webMeasurementId => 
      dotenv.env['FIREBASE_WEB_MEASUREMENT_ID'] ?? '';

  // Android Configuration
  static String get androidApiKey => 
      dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? '';
  static String get androidAppId => 
      dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? '';
  static String get androidMessagingSenderId => 
      dotenv.env['FIREBASE_ANDROID_MESSAGING_SENDER_ID'] ?? '';
  static String get androidProjectId => 
      dotenv.env['FIREBASE_ANDROID_PROJECT_ID'] ?? '';
  static String get androidStorageBucket => 
      dotenv.env['FIREBASE_ANDROID_STORAGE_BUCKET'] ?? '';

  // iOS Configuration
  static String get iosApiKey => 
      dotenv.env['FIREBASE_IOS_API_KEY'] ?? '';
  static String get iosAppId => 
      dotenv.env['FIREBASE_IOS_APP_ID'] ?? '';
  static String get iosMessagingSenderId => 
      dotenv.env['FIREBASE_IOS_MESSAGING_SENDER_ID'] ?? '';
  static String get iosProjectId => 
      dotenv.env['FIREBASE_IOS_PROJECT_ID'] ?? '';
  static String get iosStorageBucket => 
      dotenv.env['FIREBASE_IOS_STORAGE_BUCKET'] ?? '';
  static String get iosBundleId => 
      dotenv.env['FIREBASE_IOS_BUNDLE_ID'] ?? 'com.example.projectTa';

  // MacOS Configuration
  static String get macosApiKey => 
      dotenv.env['FIREBASE_MACOS_API_KEY'] ?? '';
  static String get macosAppId => 
      dotenv.env['FIREBASE_MACOS_APP_ID'] ?? '';
  static String get macosMessagingSenderId => 
      dotenv.env['FIREBASE_MACOS_MESSAGING_SENDER_ID'] ?? '';
  static String get macosProjectId => 
      dotenv.env['FIREBASE_MACOS_PROJECT_ID'] ?? '';
  static String get macosStorageBucket => 
      dotenv.env['FIREBASE_MACOS_STORAGE_BUCKET'] ?? '';
  static String get macosBundleId => 
      dotenv.env['FIREBASE_MACOS_BUNDLE_ID'] ?? 'com.example.projectTa';

  // Google Sign-In Configuration
  static String get googleClientIdWeb => 
      dotenv.env['GOOGLE_CLIENT_ID_WEB'] ?? '';
  static String get googleClientIdAndroid => 
      dotenv.env['GOOGLE_CLIENT_ID_ANDROID'] ?? '';
  static String get googleClientIdIos => 
      dotenv.env['GOOGLE_CLIENT_ID_IOS'] ?? '';

  /// Validasi apakah konfigurasi Firebase sudah diisi
  static bool get isConfigured {
    // Cek minimal ada project ID untuk salah satu platform
    return webProjectId.isNotEmpty || 
           androidProjectId.isNotEmpty || 
           iosProjectId.isNotEmpty;
  }

  /// Print warning jika konfigurasi belum lengkap
  static void validateConfig() {
    if (!isConfigured) {
      print('⚠️ WARNING: Firebase configuration belum diisi di .env file!');
      print('Silakan isi file .env dengan nilai dari Firebase Console');
      print('atau jalankan: flutterfire configure');
    }
  }
}
