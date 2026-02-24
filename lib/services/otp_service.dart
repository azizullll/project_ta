import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../config/env_config.dart';

class OTPService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Generate random 6-digit OTP code
  String generateOTP() {
    final random = Random();
    final otp = random.nextInt(900000) + 100000; // Range: 100000-999999
    return otp.toString();
  }
  
  /// Save OTP to Firestore
  Future<void> saveOTP(String email, String otp) async {
    await _firestore.collection('password_reset_otps').doc(email).set({
      'otp': otp,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch,
      'verified': false,
    });
  }
  
  /// Verify OTP
  Future<Map<String, dynamic>> verifyOTP(String email, String otp) async {
    try {
      final doc = await _firestore.collection('password_reset_otps').doc(email).get();
      
      if (!doc.exists) {
        return {'success': false, 'message': 'Kode OTP tidak ditemukan'};
      }
      
      final data = doc.data()!;
      final savedOTP = data['otp'] as String;
      final expiresAt = data['expiresAt'] as int;
      final verified = data['verified'] as bool;
      
      // Check if already verified
      if (verified) {
        return {'success': false, 'message': 'Kode OTP sudah digunakan'};
      }
      
      // Check if expired
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        return {'success': false, 'message': 'Kode OTP sudah expired'};
      }
      
      // Check if OTP matches
      if (savedOTP != otp) {
        return {'success': false, 'message': 'Kode OTP salah'};
      }
      
      // Mark as verified
      await _firestore.collection('password_reset_otps').doc(email).update({
        'verified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      });
      
      return {'success': true, 'message': 'Kode OTP valid'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  /// Delete OTP after password reset
  Future<void> deleteOTP(String email) async {
    await _firestore.collection('password_reset_otps').doc(email).delete();
  }
  
  /// Get OTP document for verification check
  Future<Map<String, dynamic>?> getOTPDoc(String email) async {
    try {
      final doc = await _firestore.collection('password_reset_otps').doc(email).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting OTP doc: $e');
      return null;
    }
  }
  
  /// Send OTP via email using SMTP
  Future<Map<String, dynamic>> sendOTPEmail(String email, String otp) async {
    try {
      print('📧 Sending OTP to $email via SMTP');
      print('🔑 OTP Code: $otp');
      
      // Check if SMTP is configured
      final smtpEmail = EnvConfig.smtpEmail;
      final smtpPassword = EnvConfig.smtpPassword;
      
      print('🔍 SMTP Email from config: $smtpEmail');
      print('🔍 SMTP Password length: ${smtpPassword.length}');
      
      if (smtpEmail.isEmpty || smtpPassword.isEmpty) {
        print('⚠️ SMTP not configured. Returning OTP for development.');
        print('   Email empty: ${smtpEmail.isEmpty}, Password empty: ${smtpPassword.isEmpty}');
        // Development mode: return OTP in response
        return {
          'success': true,
          'message': 'Kode OTP berhasil digenerate (SMTP belum dikonfigurasi)',
          'otp': otp,
        };
      }
      
      // Configure SMTP
      final smtpServer = SmtpServer(
        EnvConfig.smtpHost,
        port: EnvConfig.smtpPort,
        username: smtpEmail,
        password: smtpPassword,
        ssl: false, // Use STARTTLS for port 587
        allowInsecure: true,
      );
      
      // Create email message
      final message = Message()
        ..from = Address(smtpEmail, EnvConfig.smtpFromName)
        ..recipients.add(email)
        ..subject = 'Reset Password - Kode OTP BroodGuard'
        ..html = '''
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="UTF-8">
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background-color: #FF9800; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
              .content { background-color: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
              .otp-box { background-color: white; border: 3px solid #FF9800; padding: 20px; text-align: center; margin: 20px 0; border-radius: 8px; }
              .otp-code { font-size: 36px; font-weight: bold; color: #FF9800; letter-spacing: 8px; }
              .warning { color: #666; font-size: 14px; margin-top: 20px; }
              .footer { text-align: center; margin-top: 20px; color: #999; font-size: 12px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>🔐 Reset Password</h1>
              </div>
              <div class="content">
                <p>Halo,</p>
                <p>Anda telah meminta untuk mereset password akun BroodGuard Anda. Gunakan kode OTP berikut:</p>
                
                <div class="otp-box">
                  <div class="otp-code">$otp</div>
                </div>
                
                <p class="warning">
                  ⏰ Kode OTP ini berlaku selama <strong>10 menit</strong>.<br>
                  🔒 Jangan bagikan kode ini kepada siapapun.<br>
                  ❓ Jika Anda tidak meminta reset password, abaikan email ini.
                </p>
              </div>
              <div class="footer">
                <p>© 2025 BroodGuard - Sistem Otomasi Kandang Anak Ayam</p>
              </div>
            </div>
          </body>
          </html>
        ''';
      
      // Send email
      final sendReport = await send(message, smtpServer);
      print('✅ Email sent: ${sendReport.toString()}');
      
      return {
        'success': true,
        'message': 'Kode OTP telah dikirim ke email Anda',
      };
      
    } on MailerException catch (e) {
      print('❌ Failed to send email: ${e.toString()}');
      
      // Development fallback: return OTP if email fails
      if (EnvConfig.debugMode) {
        return {
          'success': true,
          'message': 'Email gagal dikirim, kode OTP ditampilkan (debug mode)',
          'otp': otp,
        };
      }
      
      return {
        'success': false,
        'message': 'Gagal mengirim email. Silakan coba lagi.',
      };
    } catch (e) {
      print('❌ Error sending OTP: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }
  
  /// Send Firebase Password Reset Link via SMTP
  /// This generates official Firebase reset link and sends via custom email
  Future<Map<String, dynamic>> sendPasswordResetLink(String email) async {
    try {
      print('🔗 Generating Firebase password reset link for: $email');
      
      // Generate Firebase password reset link
      // Using default Firebase domain (no custom actionCodeSettings)
      await _auth.sendPasswordResetEmail(email: email);
      
      print('✅ Firebase reset email sent successfully');
      
      // Send custom SMTP notification (optional, for better UX)
      final emailResult = await _sendPasswordResetEmailViaSMTP(email);
      
      return emailResult;
      
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Email tidak terdaftar';
          break;
        case 'invalid-email':
          message = 'Format email tidak valid';
          break;
        case 'too-many-requests':
          message = 'Terlalu banyak percobaan. Silakan coba lagi nanti.';
          break;
        case 'unauthorized-domain':
          message = 'Konfigurasi domain error. Menggunakan default Firebase domain.';
          break;
        default:
          message = 'Gagal mengirim link reset: ${e.message}';
      }
      
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      print('❌ Error generating reset link: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }
  
  /// Send password reset notification via SMTP
  /// This sends a custom email telling user to check their Firebase reset email
  Future<Map<String, dynamic>> _sendPasswordResetEmailViaSMTP(String email) async {
    try {
      // Check if SMTP is configured
      final smtpEmail = EnvConfig.smtpEmail;
      final smtpPassword = EnvConfig.smtpPassword;
      
      if (smtpEmail.isEmpty || smtpPassword.isEmpty) {
        print('⚠️ SMTP not configured. Using Firebase default email.');
        return {
          'success': true,
          'message': 'Email reset password telah dikirim via Firebase',
        };
      }
      
      // Configure SMTP
      final smtpServer = SmtpServer(
        EnvConfig.smtpHost,
        port: EnvConfig.smtpPort,
        username: smtpEmail,
        password: smtpPassword,
        ssl: false,
        allowInsecure: true,
      );
      
      // Create custom email message
      final message = Message()
        ..from = Address(smtpEmail, EnvConfig.smtpFromName)
        ..recipients.add(email)
        ..subject = 'Reset Password - BroodGuard'
        ..html = '''
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="UTF-8">
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background-color: #FF9800; color: white; padding: 30px 20px; text-align: center; border-radius: 8px 8px 0 0; }
              .content { background-color: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
              .button { 
                display: inline-block;
                background-color: #FF9800;
                color: white !important;
                padding: 15px 40px;
                text-decoration: none;
                border-radius: 25px;
                font-weight: bold;
                margin: 20px 0;
                font-size: 16px;
              }
              .info-box { 
                background-color: white;
                border-left: 4px solid #FF9800;
                padding: 15px;
                margin: 20px 0;
              }
              .footer { text-align: center; margin-top: 20px; color: #999; font-size: 12px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>🔐 Reset Password</h1>
                <p style="margin: 0; font-size: 16px;">BroodGuard - Sistem Otomasi Kandang</p>
              </div>
              <div class="content">
                <p>Halo,</p>
                <p>Anda telah berhasil melakukan verifikasi OTP untuk reset password akun BroodGuard Anda.</p>
                
                <div class="info-box">
                  <strong>✅ Verifikasi OTP Berhasil</strong><br>
                  Sekarang Anda dapat mengatur password baru untuk akun Anda.
                </div>
                
                <p><strong>Email reset password akan segera dikirim dari Firebase.</strong> Silakan cek email Anda (termasuk folder spam) untuk email dari <strong>noreply@[your-project].firebaseapp.com</strong> yang berisi link reset password.</p>
                
                <p style="margin-top: 30px;"><strong>Langkah Selanjutnya:</strong></p>
                <ol style="line-height: 2;">
                  <li>📧 Cek email dari <strong>Firebase (noreply@...)</strong></li>
                  <li>🔗 Klik link "Reset Password" di email tersebut</li>
                  <li>🔐 Masukkan password baru Anda di halaman Firebase</li>
                  <li>✅ Login dengan password baru di aplikasi BroodGuard</li>
                </ol>
                
                <div class="info-box">
                  <strong>⏰ Link berlaku selama 1 jam</strong><br>
                  Jika link expired, silakan ulangi proses forgot password.
                </div>
                
                <p style="color: #666; font-size: 14px; margin-top: 30px;">
                  ❓ Jika Anda tidak meminta reset password, abaikan email ini dan password Anda tidak akan berubah.
                </p>
              </div>
              <div class="footer">
                <p>© 2026 BroodGuard - Smart Brooding System</p>
                <p>Email ini dikirim secara otomatis, mohon tidak membalas.</p>
              </div>
            </div>
          </body>
          </html>
        ''';
      
      // Send email
      final sendReport = await send(message, smtpServer);
      print('✅ Custom notification email sent: ${sendReport.toString()}');
      
      return {
        'success': true,
        'message': 'Link reset password telah dikirim ke email Anda via Firebase. Silakan cek inbox Anda.',
      };
      
    } on MailerException catch (e) {
      print('❌ Failed to send custom notification: ${e.toString()}');
      
      // Email notification failed, but Firebase email should still be sent
      return {
        'success': true,
        'message': 'Link reset password telah dikirim via Firebase',
      };
    } catch (e) {
      print('❌ Error sending notification: $e');
      return {
        'success': true,
        'message': 'Link reset password telah dikirim via Firebase',
      };
    }
  }
}
