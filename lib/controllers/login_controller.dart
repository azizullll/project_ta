import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool validateForm() {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      return false;
    }

    // Basic email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(emailController.text)) {
      return false;
    }

    return true;
  }

  // Login dengan Email dan Password Firebase
  Future<Map<String, dynamic>> loginWithEmailPassword() async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text,
          );
      return {
        'success': true,
        'user': userCredential.user,
        'message': 'Login successful',
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Email tidak terdaftar. Silakan periksa kembali email Anda.';
          break;
        case 'wrong-password':
          message = 'Password yang Anda masukkan salah. Silakan coba lagi.';
          break;
        case 'invalid-email':
          message = 'Format email tidak valid. Silakan masukkan email yang benar.';
          break;
        case 'user-disabled':
          message = 'Akun Anda telah dinonaktifkan. Hubungi administrator.';
          break;
        case 'invalid-credential':
          message = 'Email atau password yang Anda masukkan salah.';
          break;
        case 'too-many-requests':
          message = 'Terlalu banyak percobaan login. Silakan coba lagi nanti.';
          break;
        case 'network-request-failed':
          message = 'Koneksi internet bermasalah. Periksa koneksi Anda.';
          break;
        case 'operation-not-allowed':
          message = 'Login dengan email dan password tidak diizinkan.';
          break;
        default:
          message = 'Login gagal. Silakan periksa email dan password Anda.';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan. Silakan coba lagi.'};
    }
  }

  // Login dengan Google Sign-In
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      print('🔵 Starting Google Sign-In...');
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('🔵 Google user selected: ${googleUser?.email ?? "null"}');

      if (googleUser == null) {
        print('⚠️ User cancelled Google Sign-In');
        return {'success': false, 'message': 'Login Google dibatalkan'};
      }

      print('🔵 Getting Google authentication...');
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      print('🔵 Access token: ${googleAuth.accessToken != null ? "✓" : "✗"}');
      print('🔵 ID token: ${googleAuth.idToken != null ? "✓" : "✗"}');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('🔵 Firebase credential created');

      print('🔵 Signing in to Firebase...');
      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      print('✅ Firebase sign-in successful!');
      print('✅ User: ${userCredential.user?.email}');

      return {
        'success': true,
        'user': userCredential.user,
        'message': 'Login dengan Google berhasil',
      };
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      String message;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          message = 'Email sudah terdaftar dengan metode login lain.';
          break;
        case 'invalid-credential':
          message = 'Kredensial Google tidak valid. Silakan coba lagi.';
          break;
        case 'operation-not-allowed':
          message = 'Login dengan Google tidak diizinkan.';
          break;
        case 'user-disabled':
          message = 'Akun Anda telah dinonaktifkan.';
          break;
        case 'user-not-found':
          message = 'Akun tidak ditemukan.';
          break;
        default:
          message = 'Login dengan Google gagal. Silakan coba lagi.';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      print('❌ Exception: $e');
      return {'success': false, 'message': 'Terjadi kesalahan saat login dengan Google.'};
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}
