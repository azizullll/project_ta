import 'dart:convert';
import 'package:http/http.dart' as http;
import '../firebase_options.dart';

/// Firebase Auth REST API Service
/// Untuk update password menggunakan Firebase REST API
class FirebaseAuthRestService {
  // Get API key from FirebaseOptions
  static String get _apiKey {
    // Use Android API key since it's already configured
    return 'AIzaSyDtcLTrhHMrhKQIkadH572ELpsDHzoEQt4';
  }
  
  static const String _baseUrl = 'https://identitytoolkit.googleapis.com/v1';
  
  /// Send password reset OOB code via Firebase REST API
  /// This generates a reset code that can be used to reset password
  Future<Map<String, dynamic>> sendPasswordResetOobCode(String email) async {
    try {
      final url = Uri.parse('$_baseUrl/accounts:sendOobCode?key=$_apiKey');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requestType': 'PASSWORD_RESET',
          'email': email,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Password reset OOB code sent');
        return {
          'success': true,
          'email': data['email'],
        };
      } else {
        final error = jsonDecode(response.body);
        print('❌ Failed to send OOB code: ${error['error']['message']}');
        return {
          'success': false,
          'message': _parseFirebaseError(error['error']['message']),
        };
      }
    } catch (e) {
      print('❌ Error sending OOB code: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  /// Get user data by email
  /// This helps verify if user exists
  Future<Map<String, dynamic>> getUserByEmail(String email) async {
    try {
      // Note: This endpoint requires Firebase Admin SDK or should be called from backend
      // For security reasons, we shouldn't expose this in production
      return {
        'success': false,
        'message': 'This operation requires backend implementation',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  /// Parse Firebase error messages to user-friendly Indonesian
  String _parseFirebaseError(String errorMessage) {
    final message = errorMessage.toUpperCase();
    
    if (message.contains('EMAIL_NOT_FOUND')) {
      return 'Email tidak terdaftar';
    } else if (message.contains('INVALID_EMAIL')) {
      return 'Format email tidak valid';
    } else if (message.contains('TOO_MANY_ATTEMPTS')) {
      return 'Terlalu banyak percobaan. Silakan coba lagi nanti.';
    } else if (message.contains('USER_DISABLED')) {
      return 'Akun telah dinonaktifkan';
    } else {
      return 'Gagal mengirim email: $errorMessage';
    }
  }
}
