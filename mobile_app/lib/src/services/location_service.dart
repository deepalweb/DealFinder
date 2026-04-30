import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  static Future<Position?> getCurrentLocation() async {
    if (!await isLocationServiceEnabled()) return null;
    final hasPermission = await requestLocationPermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      return null;
    }
  }

  // Get location name from coordinates using reverse geocoding
  static Future<String?> getLocationName(double lat, double lng) async {
    try {
      // Check cache first (24 hour TTL)
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'location_name_${lat.toStringAsFixed(2)}_${lng.toStringAsFixed(2)}';
      final cachedName = prefs.getString(cacheKey);
      final cacheTime = prefs.getInt('${cacheKey}_time');
      
      if (cachedName != null && cacheTime != null) {
        final age = DateTime.now().millisecondsSinceEpoch - cacheTime;
        if (age < 24 * 60 * 60 * 1000) { // 24 hours
          return cachedName;
        }
      }
      
      // Using OpenStreetMap Nominatim (free, no API key required)
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=10&addressdetails=1'
      );
      
      final response = await http.get(
        url,
        headers: {'User-Agent': 'DealFinder-Mobile-App'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        
        // Try to get city, town, or village name
        String? locationName = address['city'] ?? 
                               address['town'] ?? 
                               address['village'] ?? 
                               address['suburb'] ?? 
                               address['county'];
        
        // Cache the result
        if (locationName != null) {
          await prefs.setString(cacheKey, locationName);
          await prefs.setInt('${cacheKey}_time', DateTime.now().millisecondsSinceEpoch);
        }
        
        return locationName;
      }
    } catch (_) {}
    return null;
  }

  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
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
