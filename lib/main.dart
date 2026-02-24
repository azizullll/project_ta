import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/splash_screen.dart';

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
