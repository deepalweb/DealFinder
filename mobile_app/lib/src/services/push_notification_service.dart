import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';
import 'api_service.dart';
import 'location_permission_service.dart';

const AndroidNotificationChannel _defaultNotificationChannel =
    AndroidNotificationChannel(
  'dealfinder_general',
  'DealFinder Notifications',
  description: 'General notifications for DealFinder updates and deals',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final plugin = FlutterLocalNotificationsPlugin();
  await PushNotificationService.ensureLocalNotificationsInitialized(
    plugin: plugin,
  );

  if (message.notification == null) {
    final title = message.data['title']?.toString() ?? 'DealFinder';
    final body = message.data['body']?.toString() ?? 'You have a new update';
    await PushNotificationService.showLocalNotification(
      title: title,
      body: body,
      payload: jsonEncode(message.data),
      plugin: plugin,
    );
  }
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final ApiService _api = ApiService();

  static GlobalKey<NavigatorState>? navigatorKey;
  static bool _localNotificationsInitialized = false;

  static Future<void> initialize({GlobalKey<NavigatorState>? navKey}) async {
    navigatorKey = navKey;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await ensureLocalNotificationsInitialized();
    await _requestLocalNotificationPermissions();

    final token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToPrefs(token);
      await syncTokenWithServer(token);
    }
    _messaging.onTokenRefresh.listen((token) async {
      await _saveTokenToPrefs(token);
      await syncTokenWithServer(token);
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      await syncAppIconBadgeWithServer();
      _handlePayload(jsonEncode(message.data));
    });

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handlePayload(jsonEncode(initial.data));
      });
    }

    await syncAppIconBadgeWithServer();
  }

  static Future<void> ensureLocalNotificationsInitialized({
    FlutterLocalNotificationsPlugin? plugin,
  }) async {
    if (_localNotificationsInitialized && plugin == null) return;

    final notificationsPlugin = plugin ?? _localNotifications;
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await notificationsPlugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) _handlePayload(response.payload!);
      },
    );

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_defaultNotificationChannel);

    if (plugin == null) {
      _localNotificationsInitialized = true;
    }
  }

  static Future<void> _requestLocalNotificationPermissions() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> _saveTokenToPrefs(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  static Future<void> syncTokenWithServer([String? token]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentToken = token ?? prefs.getString('fcm_token');
      final userToken = prefs.getString('userToken');

      if (currentToken == null ||
          currentToken.isEmpty ||
          userToken == null ||
          userToken.isEmpty) {
        return;
      }

      await _api.subscribeToNotifications(currentToken, 'push');
      await syncAppIconBadgeWithServer();
    } catch (_) {}
  }

  static Future<void> unsubscribeFromServer() async {
    try {
      await _api.unsubscribeFromNotifications('push');
      await clearAppIconBadge();
    } catch (_) {}
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'DealFinder';
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        'You have a new update';

    await showLocalNotification(
      title: title,
      body: body,
      payload: jsonEncode(message.data),
    );
    await syncAppIconBadgeWithServer();
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    FlutterLocalNotificationsPlugin? plugin,
  }) async {
    final notificationsPlugin = plugin ?? _localNotifications;
    const androidDetails = AndroidNotificationDetails(
      'dealfinder_general',
      'DealFinder Notifications',
      channelDescription: 'General notifications for DealFinder updates and deals',
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
    );

    await notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  static Future<void> _handlePayload(String payload) async {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final dealId = data['dealId'] as String?;
      if (dealId == null || dealId.isEmpty) return;

      final navigator = navigatorKey?.currentState;
      if (navigator == null) return;

      final promotion = await _api.fetchPromotionById(dealId);
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

      final nearbyDeals = await _api.fetchNearbyPromotions(
        position.latitude,
        position.longitude,
        radiusKm: 5,
      );

      if (nearbyDeals.isNotEmpty) {
        final deal = nearbyDeals.first;
        await showLocalNotification(
          title: 'New Deal Nearby!',
          body: '${deal.title} - ${deal.discount} off at ${deal.merchantName}',
          payload: jsonEncode({'dealId': deal.id, 'type': 'nearby_deal'}),
        );
      }

      await prefs.setInt('last_nearby_check', now);
    } catch (_) {}
  }

  static Future<void> syncAppIconBadgeWithServer() async {
    try {
      final count = await _api.fetchUnreadNotificationCount();
      await setAppIconBadgeCount(count);
    } catch (_) {}
  }

  static Future<void> setAppIconBadgeCount(int count) async {
    try {
      if (!await FlutterAppBadger.isAppBadgeSupported()) return;
      if (count <= 0) {
        await FlutterAppBadger.removeBadge();
      } else {
        await FlutterAppBadger.updateBadgeCount(count);
      }
    } catch (_) {}
  }

  static Future<void> clearAppIconBadge() async {
    try {
      if (!await FlutterAppBadger.isAppBadgeSupported()) return;
      await FlutterAppBadger.removeBadge();
    } catch (_) {}
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }
}
