import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'push_notification_service.dart';

class BackgroundLocationService {
  static Timer? _timer;
  
  static void startLocationChecking() {
    // Check every 30 minutes for nearby deals
    _timer = Timer.periodic(const Duration(minutes: 30), (timer) {
      PushNotificationService.checkNearbyDealsAndNotify();
    });
  }
  
  static void stopLocationChecking() {
    _timer?.cancel();
    _timer = null;
  }
}