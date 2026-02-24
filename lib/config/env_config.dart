import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // API Configuration
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api';
  static int get apiTimeout => int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30000') ?? 30000;
  
  // MQTT Configuration
  static String get mqttBroker => dotenv.env['MQTT_BROKER'] ?? '';
  static int get mqttPort => int.tryParse(dotenv.env['MQTT_PORT'] ?? '1883') ?? 1883;
  static String get mqttUsername => dotenv.env['MQTT_USERNAME'] ?? '';
  static String get mqttPassword => dotenv.env['MQTT_PASSWORD'] ?? '';
  
  // App Configuration
  static String get appName => dotenv.env['APP_NAME'] ?? 'BroodGuard';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  
  // Debug Mode
  static bool get debugMode => dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';
  
  // SMTP Configuration for Email
  static String get smtpHost => dotenv.env['SMTP_HOST'] ?? 'smtp.gmail.com';
  static int get smtpPort => int.tryParse(dotenv.env['SMTP_PORT'] ?? '587') ?? 587;
  static String get smtpEmail => dotenv.env['SMTP_EMAIL'] ?? '';
  static String get smtpPassword => dotenv.env['SMTP_PASSWORD'] ?? '';
  static String get smtpFromName => dotenv.env['SMTP_FROM_NAME'] ?? 'BroodGuard';
  
  // Firebase Configuration (jika diperlukan)
  static String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseMessagingSenderId => dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';
}
