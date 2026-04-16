import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final ApiService _apiService = ApiService();

  static Future<Map<String, dynamic>> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String role,
    String? businessName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user!.updateDisplayName(name);
      final idToken = await credential.user!.getIdToken();
      final response = await _apiService.firebaseAuthSync(
        idToken: idToken!,
        name: name,
        role: role,
        businessName: businessName,
      );
      await saveSession(response);
      return response;
    } on FirebaseAuthException catch (e) {
      throw Exception('Firebase Auth error [${e.code}]: ${e.message}');
    }
  }

  static Future<Map<String, dynamic>> loginWithEmail(
      String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      final idToken = await credential.user!.getIdToken();
      final response = await _apiService.firebaseAuthSync(idToken: idToken!);
      await saveSession(response);
      return response;
    } on FirebaseAuthException catch (e) {
      throw Exception('Firebase Auth error [${e.code}]: ${e.message}');
    }
  }

  static Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userToken');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('userRole');
    await prefs.remove('userBusinessName');
    await prefs.remove('merchantId');
  }

  static Future<void> saveSession(Map<String, dynamic> response) async {
    final token = response['token'] as String?;
    final userId = response['id'] as String? ?? response['_id'] as String?;
    if (token == null || userId == null) {
      throw Exception('Invalid response from server');
    }
    
    // Debug: Print the entire response to see what we're getting
    print('🔍 Login Response: $response');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userToken', token);
    await prefs.setString('userId', userId);
    await prefs.setString('userName', response['name'] as String? ?? '');
    await prefs.setString('userEmail', response['email'] as String? ?? '');
    final role = response['role'] as String? ?? 'user';
    await prefs.setString('userRole', role);
    
    // Save merchant-specific data
    if (role == 'merchant') {
      if (response['businessName'] != null) {
        await prefs.setString('userBusinessName', response['businessName'] as String);
      }
      // Save merchantId if available
      final merchantId = response['merchantId'] as String?;
      print('🔍 MerchantId from response: $merchantId');
      if (merchantId != null) {
        await prefs.setString('merchantId', merchantId);
        print('✅ Saved merchantId: $merchantId');
      } else {
        print('❌ No merchantId in response');
      }
    } else {
      await prefs.remove('userBusinessName');
      await prefs.remove('merchantId');
    }
  }
}
