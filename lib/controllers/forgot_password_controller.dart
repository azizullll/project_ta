import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/otp_service.dart';
import '../services/password_reset_service.dart';

class ForgotPasswordController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OTPService _otpService = OTPService();
  final PasswordResetService _passwordResetService = PasswordResetService();

  bool validateEmail() {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      return false;
    }
    // Basic email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Send OTP to email
  Future<Map<String, dynamic>> sendOTP() async {
    try {
      final email = emailController.text.trim();
      
      print('🔍 Checking if email exists in Firebase: $email');
      
      // Try to check if email exists by attempting to send reset email
      // This will throw an error if email doesn't exist
      try {
        // This is a dry-run check - we won't actually send Firebase reset email yet
        final methods = await _auth.fetchSignInMethodsForEmail(email);
        
        // If methods is empty but no error thrown, user might exist with different sign-in method
        // We'll proceed anyway and let Firebase handle it during actual reset
        print('📋 Sign-in methods for $email: ${methods.isEmpty ? "[]" : methods}');
        
        // Check if user actually exists by attempting sign-in (will fail but confirms user exists)
        // Skip this check and just proceed to send OTP
        
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          return {
            'success': false,
            'message': 'Email tidak terdaftar di Firebase. Pastikan Anda sudah pernah login.'
          };
        }
        // Other errors, continue to send OTP
        print('⚠️ Firebase check warning: ${e.code}');
      }
      
      // Generate OTP
      final otp = _otpService.generateOTP();
      print('🔑 Generated OTP for $email: $otp');
      
      // Save OTP to Firestore
      await _otpService.saveOTP(email, otp);
      
      // Send OTP via SMTP email
      final result = await _otpService.sendOTPEmail(email, otp);
      
      return result;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-email':
          message = 'Format email tidak valid';
          break;
        default:
          message = 'Gagal mengirim OTP: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Verify OTP code
  Future<Map<String, dynamic>> verifyOTP() async {
    try {
      final email = emailController.text.trim();
      final otp = otpController.text.trim();
      
      if (otp.length != 6) {
        return {'success': false, 'message': 'Kode OTP harus 6 digit'};
      }
      
      return await _otpService.verifyOTP(email, otp);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Reset password after OTP verification
  Future<Map<String, dynamic>> resetPassword() async {
    try {
      final email = emailController.text.trim();
      
      // Send password reset email as secure method
      await _auth.sendPasswordResetEmail(email: email);
      
      // Clean up OTP
      await _otpService.deleteOTP(email);
      
      return {
        'success': true,
        'message': 'Link reset password telah dikirim ke email Anda'
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': 'Gagal reset password: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Update password directly (called from reset password page)
  /// Generates Firebase password reset link and sends via SMTP
  Future<Map<String, dynamic>> updatePassword(String newPassword) async {
    try {
      final email = emailController.text.trim();
      
      // Check if OTP was verified by checking Firestore
      final otpDoc = await _otpService.getOTPDoc(email);
      if (otpDoc == null || !(otpDoc['verified'] as bool? ?? false)) {
        return {
          'success': false,
          'message': 'Verifikasi OTP tidak valid. Silakan ulangi proses.'
        };
      }
      
      // Check if OTP session is still valid (within 30 minutes of verification)
      if (otpDoc['verifiedAt'] != null) {
        final verifiedTime = (otpDoc['verifiedAt'] as Timestamp).toDate();
        final now = DateTime.now();
        final difference = now.difference(verifiedTime);
        
        if (difference.inMinutes > 30) {
          await _otpService.deleteOTP(email);
          return {
            'success': false,
            'message': 'Sesi reset password sudah expired. Silakan ulangi proses.'
          };
        }
      }
      
      print('🔗 Generating Firebase password reset link for: $email');
      
      // Generate Firebase password reset link
      // This link will be sent via SMTP with custom email template
      final result = await _otpService.sendPasswordResetLink(email);
      
      if (result['success']) {
        // Clean up OTP after successful process
        await _otpService.deleteOTP(email);
        
        return {
          'success': true,
          'message': 'Link reset password telah dikirim ke email Anda. Silakan cek email dan klik link untuk mengatur password baru Anda.'
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Gagal mengirim link reset password'
        };
      }
      
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Pengguna tidak ditemukan';
          break;
        case 'invalid-email':
          message = 'Email tidak valid';
          break;
        case 'too-many-requests':
          message = 'Terlalu banyak percobaan. Silakan coba lagi nanti.';
          break;
        default:
          message = 'Gagal mengirim link reset password: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      print('❌ Error in updatePassword: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
  
  /// Alternative: Update password directly using Cloud Functions
  /// Deploy the Cloud Function from password_reset_function.js first
  Future<Map<String, dynamic>> updatePasswordViaCloudFunction(String newPassword) async {
    try {
      final email = emailController.text.trim();
      
      // Check OTP verification
      final otpDoc = await _otpService.getOTPDoc(email);
      if (otpDoc == null || !(otpDoc['verified'] as bool? ?? false)) {
        return {
          'success': false,
          'message': 'Verifikasi OTP tidak valid.'
        };
      }
      
      // Store password reset request - will be processed by Cloud Function
      final storeResult = await _passwordResetService.storePasswordResetRequest(
        email,
        newPassword,
      );
      
      if (!storeResult['success']) {
        return storeResult;
      }
      
      // Wait for Cloud Function to process
      await Future.delayed(const Duration(seconds: 3));
      
      // Check if Cloud Function processed the request
      final statusResult = await _passwordResetService.checkResetStatus(email);
      
      if (statusResult['success'] && 
          statusResult['data']?['status'] == 'completed') {
        // Clean up
        await _otpService.deleteOTP(email);
        await _passwordResetService.deleteResetRequest(email);
        
        return {
          'success': true,
          'message': 'Password berhasil diubah! Silakan login dengan password baru Anda.'
        };
      } else if (statusResult['data']?['status'] == 'failed') {
        return {
          'success': false,
          'message': 'Gagal mengubah password. ${statusResult['data']?['errorMessage'] ?? ''}'
        };
      } else {
        // Still pending or Cloud Function not deployed
        return {
          'success': false,
          'message': 'Cloud Function belum dikonfigurasi. Menggunakan Firebase reset email sebagai alternatif.',
          'fallbackToEmail': true,
        };
      }
      
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  void dispose() {
    emailController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }
}
