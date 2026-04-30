import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_service.dart';
import 'auth_service.dart';

class GoogleAuthService {
  static final ApiService _apiService = ApiService();

  static GoogleSignIn _buildGoogleSignInClient() {
    final serverClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim() ?? '';

    return GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
    );
  }

  static String _missingConfigMessage() {
    return 'Google Sign-In is not configured yet. Add GOOGLE_WEB_CLIENT_ID to mobile_app/.env and install the Firebase mobile config files for your app.';
  }

  static String _friendlyGoogleError(Object error) {
    final text = error.toString();
    if (text.contains('sign_in_failed')) {
      return 'Google Sign-In failed. Check that your app package/bundle ID and SHA keys match the Firebase project.';
    }
    if (text.contains('network_error')) {
      return 'Google Sign-In needs an internet connection.';
    }
    if (text.contains('10:')) {
      return 'Google Sign-In configuration mismatch. Re-download Firebase config files and confirm the mobile app IDs are registered correctly.';
    }
    return 'Google Sign-In failed: $text';
  }

  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    final serverClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim() ?? '';
    if (serverClientId.isEmpty) {
      throw Exception(_missingConfigMessage());
    }

    final googleSignIn = _buildGoogleSignInClient();

    try {
      // 1. Google Sign-In flow
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final googleIdToken = googleAuth.idToken;

      if (googleIdToken == null || googleIdToken.isEmpty) {
        throw Exception(
          'Google did not return an ID token. Verify GOOGLE_WEB_CLIENT_ID and Firebase OAuth setup.',
        );
      }

      // 2. Prefer Firebase sync when available, but fall back to the backend
      // Google token exchange if Firebase mobile configuration is incomplete.
      try {
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleIdToken,
        );
        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);

        final firebaseIdToken = await userCredential.user!.getIdToken();
        if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
          throw Exception('Firebase did not return an auth token.');
        }

        final response = await _apiService.firebaseAuthSync(
          idToken: firebaseIdToken,
          name: googleUser.displayName,
        );

        await AuthService.saveSession(response);
        return response;
      } catch (firebaseError) {
        if (kDebugMode) {
          debugPrint(
            'Firebase Google auth failed, falling back to backend Google Sign-In: $firebaseError',
          );
        }

        final response = await _apiService.googleSignIn(googleIdToken);
        await AuthService.saveSession(response);
        return response;
      }
    } catch (e) {
      throw Exception(_friendlyGoogleError(e));
    }
  }

  static Future<void> signOut() async {
    await _buildGoogleSignInClient().signOut();
    await AuthService.signOut();
  }
}
