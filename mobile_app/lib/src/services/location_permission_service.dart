import 'package:geolocator/geolocator.dart';
import 'location_service.dart';

class LocationPermissionService {
  static Future<bool> requestLocationPermission() async {
    return LocationService.requestLocationPermission();
  }

  static Future<Position?> getCurrentLocation({bool requestPermission = true}) async {
    return LocationService.getCurrentLocation(
      requestPermission: requestPermission,
    );
  }
}
