import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  
  static final ApiService _apiService = ApiService();

  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Send Google token to your backend
      final response = await _apiService.googleSignIn(googleAuth.idToken!);
      
      if (response['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userToken', response['token']);
        await prefs.setString('userId', response['id'] ?? response['_id']);
        await prefs.setString('userName', response['name'] ?? googleUser.displayName ?? '');
        await prefs.setString('userEmail', response['email'] ?? googleUser.email);
        await prefs.setString('userRole', response['role'] ?? 'user');
        
        return response;
      }
      
      return null;
    } catch (error) {
      throw Exception('Google Sign-In failed: $error');
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}