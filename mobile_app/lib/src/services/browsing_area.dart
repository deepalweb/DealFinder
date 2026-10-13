import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BrowsingArea {
  const BrowsingArea(
      {required this.latitude,
      required this.longitude,
      required this.label,
      this.source = 'manual',
      this.approximate = false});
  final double latitude;
  final double longitude;
  final String label;
  final String source;
  final bool approximate;
  static const initial = BrowsingArea(
      latitude: 6.911,
      longitude: 79.854,
      label: 'Colombo 03',
      source: 'preset');
  static final changes = ValueNotifier<BrowsingArea?>(null);
  static const _key = 'browsingArea.v1';

  static Future<BrowsingArea?> read() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final json = jsonDecode(prefs.getString(_key) ?? 'null');
      if (json is! Map) return null;
      final lat = (json['latitude'] as num).toDouble();
      final lng = (json['longitude'] as num).toDouble();
      if (!lat.isFinite || !lng.isFinite || lat.abs() > 90 || lng.abs() > 180) {
        return null;
      }
      return BrowsingArea(
          latitude: lat,
          longitude: lng,
          label: json['label'] as String,
          source: json['source'] as String? ?? 'manual',
          approximate: json['approximate'] == true);
    } catch (_) {
      return null;
    }
  }

  static Future<void> select(BrowsingArea area) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key,
        jsonEncode({
          'latitude': area.latitude,
          'longitude': area.longitude,
          'label': area.label,
          'source': area.source,
          'approximate': area.approximate
        }));
    changes.value = area;
  }
}
