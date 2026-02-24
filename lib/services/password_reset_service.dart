import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class PasswordResetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Store password reset request in Firestore
  /// This will be processed by a Cloud Function or backend service
  Future<Map<String, dynamic>> storePasswordResetRequest(
    String email,
    String newPassword,
  ) async {
    try {
      // Generate a unique reset token
      final resetToken = _generateResetToken();
      
      // Store the password reset request
      await _firestore.collection('password_reset_requests').doc(email).set({
        'email': email,
        'newPassword': newPassword, // In production, this should be hashed
        'resetToken': resetToken,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, completed, failed
        'processedAt': null,
      });
      
      return {
        'success': true,
        'message': 'Password reset request submitted',
        'resetToken': resetToken,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error storing reset request: $e',
      };
    }
  }
  
  /// Check  the status of a password reset request
  Future<Map<String, dynamic>> checkResetStatus(String email) async {
    try {
      final doc = await _firestore
          .collection('password_reset_requests')
          .doc(email)
          .get();
      
      if (!doc.exists) {
        return {
          'success': false,
          'message': 'Reset request not found',
        };
      }
      
      final data = doc.data()!;
      return {
        'success': true,
        'status': data['status'],
        'data': data,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error checking status: $e',
      };
    }
  }
  
  /// Delete password reset request after completion
  Future<void> deleteResetRequest(String email) async {
    await _firestore.collection('password_reset_requests').doc(email).delete();
  }
  
  /// Generate a random reset token
  String _generateResetToken() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(32, (index) => chars[random.nextInt(chars.length)]).join();
  }
}
