import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
import 'location_permission_service.dart';

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  static Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(settings);
    
    // Get FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToPrefs(token);
    }
    
    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveTokenToPrefs);
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }
  
  static Future<void> _saveTokenToPrefs(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }
  
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _showLocalNotification(
      title: message.notification?.title ?? 'New Deal',
      body: message.notification?.body ?? 'Check out this nearby deal!',
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
    
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }
  
  static Future<void> checkNearbyDealsAndNotify() async {
    try {
      final position = await LocationPermissionService.getCurrentLocation();
      if (position == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt('last_nearby_check') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Check only every 30 minutes
      if (now - lastCheck < 30 * 60 * 1000) return;
      
      final apiService = ApiService();
      final nearbyDeals = await apiService.fetchNearbyPromotions(
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
    } catch (e) {
      print('Error checking nearby deals: $e');
    }
  }
  
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }
}