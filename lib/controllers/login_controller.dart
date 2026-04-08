import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Login dengan Google Sign-In
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      print('Starting Google Sign-In...');
      // Paksa tampil account picker setiap kali tombol login ditekan.
      await _googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('Google user selected: ${googleUser?.email ?? "null"}');

      if (googleUser == null) {
        print('User cancelled Google Sign-In');
        return {'success': false, 'message': 'Login Google dibatalkan'};
      }

      print('Getting Google authentication...');
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      print('Access token: ${googleAuth.accessToken != null ? "ok" : "missing"}');
      print('ID token: ${googleAuth.idToken != null ? "ok" : "missing"}');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('Firebase credential created');

      print('Signing in to Firebase...');
      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      print('Firebase sign-in successful');
      print('User: ${userCredential.user?.email}');

      // Tolak akun baru: hanya akun yang memang sudah ada di Authentication
      // sebelum proses login ini yang diizinkan masuk.
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      if (isNewUser) {
        await userCredential.user?.delete();
        await _auth.signOut();
        await _googleSignIn.signOut();
        return {
          'success': false,
          'message':
              'Email Google ini belum terdaftar pada sistem. Gunakan email yang sudah terdaftar.',
        };
      }

      return {
        'success': true,
        'user': userCredential.user,
        'message': 'Login dengan Google berhasil',
      };
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      String message;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          message =
              'Email sudah terdaftar, tetapi belum terhubung dengan Google Sign-In.';
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
        case 'network-request-failed':
          message = 'Koneksi internet bermasalah. Periksa koneksi Anda.';
          break;
        default:
          message = 'Login dengan Google gagal. Silakan coba lagi.';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      print('Exception: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat login dengan Google.',
      };
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  void dispose() {}
}
