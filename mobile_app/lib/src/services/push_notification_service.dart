import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
import 'location_permission_service.dart';

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? navigatorKey;

  static Future<void> initialize({GlobalKey<NavigatorState>? navKey}) async {
    navigatorKey = navKey;

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) _handlePayload(response.payload!);
      },
    );

    final token = await _messaging.getToken();
    if (token != null) await _saveTokenToPrefs(token);
    _messaging.onTokenRefresh.listen(_saveTokenToPrefs);

    // Foreground FCM messages → show local notification
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // App opened from background via notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handlePayload(jsonEncode(message.data));
    });

    // App launched from terminated state via notification tap
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      // Delay to let the widget tree mount
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handlePayload(jsonEncode(initial.data));
      });
    }
  }

  static Future<void> _saveTokenToPrefs(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _showLocalNotification(
      title: message.notification?.title ?? 'New Deal',
      body: message.notification?.body ?? 'Check out this deal!',
      payload: jsonEncode(message.data),
    );
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'nearby_deals',
      'Nearby Deals',
      channelDescription: 'Notifications for nearby deals',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails()),
      payload: payload,
    );
  }

  /// Parses payload and navigates to DealDetailScreen if dealId is present.
  static Future<void> _handlePayload(String payload) async {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final dealId = data['dealId'] as String?;
      if (dealId == null || dealId.isEmpty) return;

      final navigator = navigatorKey?.currentState;
      if (navigator == null) return;

      final promotion = await ApiService().fetchPromotionById(dealId);

      // Avoid circular import by using a dynamic route name approach
      navigator.pushNamed('/deal', arguments: promotion);
    } catch (_) {}
  }

  static Future<void> checkNearbyDealsAndNotify() async {
    try {
      final position = await LocationPermissionService.getCurrentLocation();
      if (position == null) return;

      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt('last_nearby_check') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastCheck < 30 * 60 * 1000) return;

      final nearbyDeals = await ApiService().fetchNearbyPromotions(
        position.latitude,
        position.longitude,
        radiusKm: 5,
      );

      if (nearbyDeals.isNotEmpty) {
        final deal = nearbyDeals.first;
        await _showLocalNotification(
          title: '🎯 New Deal Nearby!',
          body: '${deal.title} - ${deal.discount} off at ${deal.merchantName}',
          payload: jsonEncode({'dealId': deal.id, 'type': 'nearby_deal'}),
        );
      }

      await prefs.setInt('last_nearby_check', now);
    } catch (_) {}
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }
}
