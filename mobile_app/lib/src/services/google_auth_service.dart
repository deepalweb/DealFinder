import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_service.dart';
import 'auth_service.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
  );

  static final ApiService _apiService = ApiService();

  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // 1. Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 2. Sign in to Firebase with Google credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // 3. Get Firebase ID token
      final idToken = await userCredential.user!.getIdToken();

      // 4. Sync with backend using Firebase Auth endpoint
      final response = await _apiService.firebaseAuthSync(
        idToken: idToken!,
        name: googleUser.displayName,
      );

      // 5. Save session
      await AuthService.saveSession(response);
      return response;
    } catch (e) {
      print('Google Sign-In error: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await AuthService.signOut();
  }
}
