import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'app_session.dart';
import 'favorites_manager.dart';
import 'push_notification_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final ApiService _apiService = ApiService();

  // Email and password live in the backend, shared with the web app.
  static Future<Map<String, dynamic>> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String role,
    String? businessName,
  }) async {
    final response = await _apiService.registerUser({
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      if (businessName != null && businessName.isNotEmpty)
        'businessName': businessName,
    });
    await saveSession(response);
    return response;
  }

  static Future<Map<String, dynamic>> loginWithEmail(
    String email,
    String password,
  ) async {
    try {
      final response =
          await _apiService.directLogin(email: email, password: password);
      await saveSession(response);
      return response;
    } on InvalidCredentialsException {
      // Accounts registered in the app before passwords moved to the backend
      // only have a Firebase password. Verify it once and move it over.
      final response = await _moveFirebasePassword(email, password);
      if (response == null) rethrow;
      await saveSession(response);
      return response;
    }
  }

  static Future<Map<String, dynamic>?> _moveFirebasePassword(
      String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      final idToken = await credential.user!.getIdToken();
      return await _apiService.firebaseAuthSync(
          idToken: idToken!, password: password);
    } catch (_) {
      return null;
    } finally {
      try {
        await _auth.signOut();
      } catch (_) {}
    }
  }

  static Future<void> sendPasswordReset(String email) =>
      _apiService.requestPasswordReset(email);

  /// Deletes the account on the server, then clears local state.
  static Future<void> deleteAccount([ApiService? api]) async {
    await (api ?? _apiService).deleteAccount();
    try {
      await _auth.currentUser?.delete();
    } catch (_) {}
    await signOut();
  }

  static Future<void> signOut() async {
    try {
      await PushNotificationService.unsubscribeFromServer();
      await PushNotificationService.clearAppIconBadge();
    } catch (_) {}
    try {
      await _apiService.revokeSession();
    } catch (_) {}
    try {
      await _auth.signOut();
    } catch (_) {}
    // Local sign-out must still work when remote services are unavailable.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userToken');
    await prefs.remove('refreshToken');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('userRole');
    await prefs.remove('userBusinessName');
    await prefs.remove('merchantId');
    await prefs.remove('userProfilePicture');
    await prefs.remove('followingMerchants');
    await FavoritesManager.clear();
    await AppSession.refresh();
  }

  static Future<void> saveSession(Map<String, dynamic> response) async {
    final token = response['token'] as String?;
    final userId = response['id'] as String? ?? response['_id'] as String?;
    if (token == null || userId == null) {
      throw Exception('Invalid response from server');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userToken', token);
    if (response['refreshToken'] is String) {
      await prefs.setString('refreshToken', response['refreshToken']);
    }
    await prefs.setString('userId', userId);
    await prefs.setString('userName', response['name'] as String? ?? '');
    await prefs.setString('userEmail', response['email'] as String? ?? '');
    final role = response['role'] as String? ?? 'user';
    await prefs.setString('userRole', role);

    if (role == 'merchant') {
      if (response['businessName'] != null) {
        await prefs.setString(
          'userBusinessName',
          response['businessName'] as String,
        );
      }
      final merchantId = response['merchantId'] as String?;
      if (merchantId != null) {
        await prefs.setString('merchantId', merchantId);
      }
    } else {
      await prefs.remove('userBusinessName');
      await prefs.remove('merchantId');
    }

    final profilePicture = response['profilePicture'] as String?;
    if (profilePicture != null && profilePicture.isNotEmpty) {
      await prefs.setString('userProfilePicture', profilePicture);
    } else {
      await prefs.remove('userProfilePicture');
    }

    await AppSession.refresh();
    try {
      await PushNotificationService.syncTokenWithServer();
    } catch (_) {
      // Notification registration must not undo an accepted sign-in.
    }
  }
}
