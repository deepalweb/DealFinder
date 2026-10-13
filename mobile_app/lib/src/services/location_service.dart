import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

enum LocationFetchStatus {
  success,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unavailable,
}

class LocationFetchResult {
  const LocationFetchResult({
    required this.status,
    this.position,
    this.usedLastKnownPosition = false,
  });

  final LocationFetchStatus status;
  final Position? position;
  final bool usedLastKnownPosition;

  bool get isSuccess => position != null;

  String get message {
    switch (status) {
      case LocationFetchStatus.serviceDisabled:
        return 'Turn on device location to discover nearby deals.';
      case LocationFetchStatus.permissionDenied:
        return 'Allow location access to discover nearby deals.';
      case LocationFetchStatus.permissionDeniedForever:
        return 'Location permission is blocked. Enable it from app settings.';
      case LocationFetchStatus.timeout:
        return 'Location is taking too long to load. Try again outdoors or near a window.';
      case LocationFetchStatus.unavailable:
        return 'We could not detect your location right now. Please try again.';
      case LocationFetchStatus.success:
        if (usedLastKnownPosition) {
          return 'Using your recent location while we refresh GPS.';
        }
        return 'Location detected.';
    }
  }
}

class LocationService {
  static Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  static Future<bool> requestLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  static Future<LocationFetchResult> resolveCurrentLocation({
    bool requestPermission = true,
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeLimit = const Duration(seconds: 10),
    bool allowLastKnownFallback = true,
  }) async {
    if (!await isLocationServiceEnabled()) {
      return const LocationFetchResult(
        status: LocationFetchStatus.serviceDisabled,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestPermission) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationFetchResult(
        status: LocationFetchStatus.permissionDenied,
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationFetchResult(
        status: LocationFetchStatus.permissionDeniedForever,
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: timeLimit,
      );
      return LocationFetchResult(
        status: LocationFetchStatus.success,
        position: position,
      );
    } on TimeoutException {
      final fallback = allowLastKnownFallback
          ? await _getFreshEnoughLastKnownPosition()
          : null;
      if (fallback != null) {
        return LocationFetchResult(
          status: LocationFetchStatus.success,
          position: fallback,
          usedLastKnownPosition: true,
        );
      }
      return const LocationFetchResult(
        status: LocationFetchStatus.timeout,
      );
    } on LocationServiceDisabledException {
      return const LocationFetchResult(
        status: LocationFetchStatus.serviceDisabled,
      );
    } catch (_) {
      final fallback = allowLastKnownFallback
          ? await _getFreshEnoughLastKnownPosition()
          : null;
      if (fallback != null) {
        return LocationFetchResult(
          status: LocationFetchStatus.success,
          position: fallback,
          usedLastKnownPosition: true,
        );
      }
      return const LocationFetchResult(
        status: LocationFetchStatus.unavailable,
      );
    }
  }

  static Future<Position?> getCurrentLocation({
    bool requestPermission = true,
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeLimit = const Duration(seconds: 10),
    bool allowLastKnownFallback = true,
  }) async {
    final result = await resolveCurrentLocation(
      requestPermission: requestPermission,
      accuracy: accuracy,
      timeLimit: timeLimit,
      allowLastKnownFallback: allowLastKnownFallback,
    );
    return result.position;
  }

  static Future<Position?> _getFreshEnoughLastKnownPosition() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;

      final timestamp = position.timestamp;
      final age = DateTime.now().difference(timestamp);
      if (age <= const Duration(minutes: 30)) {
        return position;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  // Get location name from coordinates using reverse geocoding
  static Future<String?> getLocationName(double lat, double lng) async {
    try {
      // Check cache first (24 hour TTL)
      final prefs = await SharedPreferences.getInstance();
      final cacheKey =
          'location_name_${lat.toStringAsFixed(4)}_${lng.toStringAsFixed(4)}';
      final cachedName = prefs.getString(cacheKey);
      final cacheTime = prefs.getInt('${cacheKey}_time');

      if (cachedName != null && cacheTime != null) {
        final age = DateTime.now().millisecondsSinceEpoch - cacheTime;
        if (age < 24 * 60 * 60 * 1000) {
          // 24 hours
          return cachedName;
        }
      }

      final places = await Geocoding()
          .placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 5));
      if (places.isEmpty) return null;
      final place = places.first;
      final parts = <String>{
        if ((place.subLocality ?? '').trim().isNotEmpty)
          place.subLocality!.trim(),
        if ((place.locality ?? '').trim().isNotEmpty) place.locality!.trim(),
      };
      final locationName =
          parts.isNotEmpty ? parts.join(', ') : place.administrativeArea;
      if (locationName != null && locationName.isNotEmpty) {
        await prefs.setString(cacheKey, locationName);
        await prefs.setInt(
            '${cacheKey}_time', DateTime.now().millisecondsSinceEpoch);
        return locationName;
      }
    } catch (_) {}
    return null;
  }

  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // km
  }

  static Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  static Future<bool> openAppSettings() async {
    return Geolocator.openAppSettings();
  }

  static Future<bool> openLocationSettings() async {
    return Geolocator.openLocationSettings();
  }
}
