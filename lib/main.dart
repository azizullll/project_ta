import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/splash_screen.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'utils/age_range_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  // Debug: Check if .env loaded correctly
  print('🔍 DEBUG .env loaded');
  print('🔍 SMTP_EMAIL from dotenv: ${dotenv.env['SMTP_EMAIL']}');
  print('🔍 SMTP_PASSWORD from dotenv: ${dotenv.env['SMTP_PASSWORD']}');
  print('🔍 SMTP_PASSWORD length: ${dotenv.env['SMTP_PASSWORD']?.length ?? 0}');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase Service for real-time data
  FirebaseService().initialize();
  print('🔥 Firebase Real-time Database Service initialized');

  // Initialize Notification Service for push notifications
  try {
    await NotificationService().initialize();
    print('🔔 Notification Service initialized');
  } catch (e) {
    print('⚠️ Error initializing notification service: $e');
  }

  // Initialize default age ranges in Firebase
  try {
    await AgeRangeHelper.initializeDefaultRanges();
    print('📊 Default age ranges initialized in Firebase');
  } catch (e) {
    print('⚠️ Error initializing age ranges: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BroodGuard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}
