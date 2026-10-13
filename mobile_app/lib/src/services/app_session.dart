import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSession {
  const AppSession({this.userId = '', this.token = ''});
  final String userId;
  final String token;
  bool get isSignedIn => userId.isNotEmpty && token.isNotEmpty;

  static final changes = ValueNotifier<AppSession>(const AppSession());

  static Future<AppSession> read() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSession(
      userId: prefs.getString('userId') ?? '',
      token: prefs.getString('userToken') ?? '',
    );
  }

  static Future<void> refresh() async => changes.value = await read();
}
