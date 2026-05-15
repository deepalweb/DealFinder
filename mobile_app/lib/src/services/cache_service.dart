import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/promotion.dart';

class NearbyCacheMatch {
  final List<Promotion> promotions;
  final DateTime cachedAt;
  final double cachedLatitude;
  final double cachedLongitude;
  final double radiusKm;
  final String? locationName;
  final double distanceFromCurrentKm;
  final double sameAreaThresholdKm;

  const NearbyCacheMatch({
    required this.promotions,
    required this.cachedAt,
    required this.cachedLatitude,
    required this.cachedLongitude,
    required this.radiusKm,
    required this.distanceFromCurrentKm,
    required this.sameAreaThresholdKm,
    this.locationName,
  });

  bool get isSameArea => distanceFromCurrentKm <= sameAreaThresholdKm;
}

class CacheService {
  static const _keyPromotions = 'cache_promotions';
  static const _keyPromotionsTs = 'cache_promotions_ts';
  static const _keyMerchants = 'cache_merchants';
  static const _keyMerchantsTs = 'cache_merchants_ts';
  static const _keyNearbySearches = 'cache_nearby_searches';
  static const _keyCuratedSections = 'cache_curated_sections';
  static const _keyCuratedSectionsTs = 'cache_curated_sections_ts';
  static const _ttl = Duration(minutes: 10); // Cache valid for 10 minutes
  static const _maxNearbyEntries = 8;
  static const _maxNearbyFallbackDistanceKm = 250.0;

  static Map<String, dynamic> _stripPromotionJson(Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    final img = copy['imageUrl'] as String?;
    if (img != null && img.startsWith('data:image')) {
      copy['imageUrl'] = null;
      copy['imageDataString'] = null;
    }
    final logo = copy['merchantLogoUrl'] as String?;
    if (logo != null && logo.startsWith('data:image')) {
      copy['merchantLogoUrl'] = null;
    }
    return copy;
  }

  // ── Promotions ────────────────────────────────────────────────────────────

  static Future<void> savePromotions(List<Promotion> promotions) async {
    final prefs = await SharedPreferences.getInstance();
    final stripped = promotions.map((p) => _stripPromotionJson(p.toJson())).toList();
    await prefs.setString(_keyPromotions, jsonEncode(stripped));
    await prefs.setInt(_keyPromotionsTs, DateTime.now().millisecondsSinceEpoch);
  }

  /// Returns cached promotions.
  /// [forceStale] = true returns data even if TTL expired (used when offline).
  static Future<List<Promotion>?> loadPromotions({bool forceStale = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_keyPromotions);
    if (encoded == null) return null;
    if (!forceStale) {
      final ts = prefs.getInt(_keyPromotionsTs);
      if (ts == null) return null;
      if (DateTime.now().millisecondsSinceEpoch - ts > _ttl.inMilliseconds) return null;
    }
    final List<dynamic> data = jsonDecode(encoded);
    return data.map((e) => Promotion.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<bool> hasPromotions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyPromotions);
  }

  // ── Merchants ─────────────────────────────────────────────────────────────

  static Future<void> saveMerchants(List<Map<String, dynamic>> merchants) async {
    final prefs = await SharedPreferences.getInstance();
    // Strip base64 images (logo and banner) before caching
    final stripped = merchants.map((m) {
      final copy = Map<String, dynamic>.from(m);
      final logo = copy['logo'] as String?;
      if (logo != null && logo.startsWith('data:image')) {
        copy['logo'] = null;
      }
      final banner = copy['banner'] as String?;
      if (banner != null && banner.startsWith('data:image')) {
        copy['banner'] = null;
      }
      return copy;
    }).toList();
    await prefs.setString(_keyMerchants, jsonEncode(stripped));
    await prefs.setInt(_keyMerchantsTs, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<List<Map<String, dynamic>>?> loadMerchants({bool forceStale = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_keyMerchants);
    if (encoded == null) return null;
    if (!forceStale) {
      final ts = prefs.getInt(_keyMerchantsTs);
      if (ts == null) return null;
      if (DateTime.now().millisecondsSinceEpoch - ts > _ttl.inMilliseconds) return null;
    }
    final List<dynamic> data = jsonDecode(encoded);
    return data.cast<Map<String, dynamic>>();
  }

  static Future<bool> hasMerchants() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyMerchants);
  }

  // ── Nearby Deals ───────────────────────────────────────────────────────────

  static Future<void> saveNearbyPromotions({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required List<Promotion> promotions,
    String? locationName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final rawEntries = prefs.getString(_keyNearbySearches);
    final List<dynamic> entries =
        rawEntries == null ? <dynamic>[] : (jsonDecode(rawEntries) as List<dynamic>);

    final bucketLat = double.parse(latitude.toStringAsFixed(2));
    final bucketLng = double.parse(longitude.toStringAsFixed(2));

    entries.removeWhere((entry) {
      if (entry is! Map) return false;
      final entryLat = (entry['bucketLat'] as num?)?.toDouble();
      final entryLng = (entry['bucketLng'] as num?)?.toDouble();
      final entryRadius = (entry['radiusKm'] as num?)?.toDouble();
      return entryLat == bucketLat &&
          entryLng == bucketLng &&
          entryRadius == radiusKm;
    });

    entries.insert(0, {
      'bucketLat': bucketLat,
      'bucketLng': bucketLng,
      'latitude': latitude,
      'longitude': longitude,
      'radiusKm': radiusKm,
      'locationName': locationName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'promotions': promotions.map((p) => _stripPromotionJson(p.toJson())).toList(),
    });

    if (entries.length > _maxNearbyEntries) {
      entries.removeRange(_maxNearbyEntries, entries.length);
    }

    await prefs.setString(_keyNearbySearches, jsonEncode(entries));
  }

  static Future<NearbyCacheMatch?> loadNearbyPromotions({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final rawEntries = prefs.getString(_keyNearbySearches);
    if (rawEntries == null) return null;

    final entries = jsonDecode(rawEntries) as List<dynamic>;
    NearbyCacheMatch? bestMatch;

    for (final rawEntry in entries) {
      if (rawEntry is! Map<String, dynamic>) continue;
      final entryRadius = (rawEntry['radiusKm'] as num?)?.toDouble();
      final entryLat = (rawEntry['latitude'] as num?)?.toDouble();
      final entryLng = (rawEntry['longitude'] as num?)?.toDouble();
      final timestamp = rawEntry['timestamp'] as int?;
      final rawPromotions = rawEntry['promotions'] as List<dynamic>?;

      if (entryRadius == null ||
          entryLat == null ||
          entryLng == null ||
          timestamp == null ||
          rawPromotions == null ||
          (entryRadius - radiusKm).abs() > 0.01) {
        continue;
      }

      final distanceKm = Geolocator.distanceBetween(
            latitude,
            longitude,
            entryLat,
            entryLng,
          ) /
          1000;
      if (distanceKm > _maxNearbyFallbackDistanceKm) continue;

      final promotions = rawPromotions
          .whereType<Map<String, dynamic>>()
          .map(Promotion.fromJson)
          .toList();
      final sameAreaThresholdKm = radiusKm <= 10 ? 5.0 : radiusKm * 0.5;
      final candidate = NearbyCacheMatch(
        promotions: promotions,
        cachedAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
        cachedLatitude: entryLat,
        cachedLongitude: entryLng,
        radiusKm: entryRadius,
        locationName: rawEntry['locationName'] as String?,
        distanceFromCurrentKm: distanceKm,
        sameAreaThresholdKm: sameAreaThresholdKm,
      );

      if (bestMatch == null ||
          candidate.distanceFromCurrentKm < bestMatch.distanceFromCurrentKm ||
          (candidate.distanceFromCurrentKm == bestMatch.distanceFromCurrentKm &&
              candidate.cachedAt.isAfter(bestMatch.cachedAt))) {
        bestMatch = candidate;
      }
    }

    return bestMatch;
  }

  // ── Curated Home Sections ──────────────────────────────────────────────────

  static Future<void> saveCuratedHomeSections(
      Map<String, dynamic> rawSections) async {
    final prefs = await SharedPreferences.getInstance();
    final copy = Map<String, dynamic>.from(rawSections);

    for (final key in ['banner', 'hotDeals', 'newThisWeek', 'flashSales']) {
      final rawList = copy[key];
      if (rawList is List) {
        copy[key] = rawList
            .whereType<Map<String, dynamic>>()
            .map(_stripPromotionJson)
            .toList();
      }
    }

    await prefs.setString(_keyCuratedSections, jsonEncode(copy));
    await prefs.setInt(
        _keyCuratedSectionsTs, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<Map<String, dynamic>?> loadCuratedHomeSections(
      {bool forceStale = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_keyCuratedSections);
    if (encoded == null) return null;
    if (!forceStale) {
      final ts = prefs.getInt(_keyCuratedSectionsTs);
      if (ts == null) return null;
      if (DateTime.now().millisecondsSinceEpoch - ts > _ttl.inMilliseconds) {
        return null;
      }
    }
    return (jsonDecode(encoded) as Map).cast<String, dynamic>();
  }

  // ── Clear ─────────────────────────────────────────────────────────────────

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPromotions);
    await prefs.remove(_keyPromotionsTs);
    await prefs.remove(_keyMerchants);
    await prefs.remove(_keyMerchantsTs);
    await prefs.remove(_keyNearbySearches);
    await prefs.remove(_keyCuratedSections);
    await prefs.remove(_keyCuratedSectionsTs);
  }
}
