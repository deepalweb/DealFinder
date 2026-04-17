import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/promotion.dart';

class CacheService {
  static const _keyPromotions = 'cache_promotions';
  static const _keyPromotionsTs = 'cache_promotions_ts';
  static const _keyMerchants = 'cache_merchants';
  static const _keyMerchantsTs = 'cache_merchants_ts';
  static const _ttl = Duration(minutes: 10); // Cache valid for 10 minutes

  // ── Promotions ────────────────────────────────────────────────────────────

  static Future<void> savePromotions(List<Promotion> promotions) async {
    final prefs = await SharedPreferences.getInstance();
    // Keep HTTP URLs, strip base64 images (too large for SharedPreferences)
    // Base64 images will be re-fetched from network but HTTP URLs are cached by CachedNetworkImage
    final stripped = promotions.map((p) {
      final json = p.toJson();
      final img = json['imageUrl'] as String?;
      if (img != null && img.startsWith('data:image')) {
        json['imageUrl'] = null;
        json['imageDataString'] = null;
      }
      // Also strip merchant logo if base64
      final logo = json['merchantLogoUrl'] as String?;
      if (logo != null && logo.startsWith('data:image')) {
        json['merchantLogoUrl'] = null;
      }
      return json;
    }).toList();
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

  // ── Clear ─────────────────────────────────────────────────────────────────

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPromotions);
    await prefs.remove(_keyPromotionsTs);
    await prefs.remove(_keyMerchants);
    await prefs.remove(_keyMerchantsTs);
  }
}
