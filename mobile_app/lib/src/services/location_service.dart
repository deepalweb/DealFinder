import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

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

      // Using OpenStreetMap Nominatim (free, no API key required)
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1');

      final response = await http.get(
        url,
        headers: {'User-Agent': 'DealFinder-Mobile-App'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        final locationName = _buildLocationLabel(address);

        // Cache the result
        if (locationName != null) {
          await prefs.setString(cacheKey, locationName);
          await prefs.setInt(
              '${cacheKey}_time', DateTime.now().millisecondsSinceEpoch);
        }

        return locationName;
      }
    } catch (_) {}
    return null;
  }

  static String? _buildLocationLabel(Map<String, dynamic>? address) {
    if (address == null) return null;

    String? pick(List<String> keys) {
      for (final key in keys) {
        final value = address[key]?.toString().trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
      return null;
    }

    final road = pick([
      'road',
      'pedestrian',
      'footway',
      'residential',
    ]);
    final localArea = pick([
      'neighbourhood',
      'suburb',
      'quarter',
      'city_district',
      'hamlet',
    ]);
    final city = pick([
      'city',
      'town',
      'village',
      'municipality',
      'county',
      'state_district',
    ]);

    if (road != null && localArea != null) {
      return '$road, $localArea';
    }
    if (localArea != null && city != null && localArea != city) {
      return '$localArea, $city';
    }
    return localArea ?? city ?? road;
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
