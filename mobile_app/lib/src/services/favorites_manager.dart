import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/promotion.dart';

class FavoriteRecord {
  final String id;
  final Promotion? promotion;
  final DateTime savedAt;

  const FavoriteRecord({
    required this.id,
    required this.savedAt,
    this.promotion,
  });

  factory FavoriteRecord.fromPromotion(Promotion promotion) {
    return FavoriteRecord(
      id: promotion.id,
      promotion: promotion,
      savedAt: DateTime.now(),
    );
  }

  factory FavoriteRecord.idOnly(String id) {
    return FavoriteRecord(
      id: id,
      savedAt: DateTime.now(),
    );
  }

  factory FavoriteRecord.fromJson(Map<String, dynamic> json) {
    final promotionJson = json['promotion'];
    return FavoriteRecord(
      id: json['id'] as String? ?? '',
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      promotion: promotionJson is Map
          ? Promotion.fromJson(Map<String, dynamic>.from(promotionJson))
          : null,
    );
  }

  FavoriteRecord withPromotion(Promotion nextPromotion) {
    return FavoriteRecord(
      id: id,
      promotion: nextPromotion,
      savedAt: savedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'savedAt': savedAt.toIso8601String(),
      if (promotion != null) 'promotion': promotion!.toJson(),
    };
  }
}

class FavoritesManager {
  static const String _recordsKey = 'favoriteRecords.v2';
  static const String _legacyIdsKey = 'favoriteDeals';
  static const String _legacySnapshotsKey = 'favoriteDealSnapshots';

  static Future<List<String>> getFavorites() async {
    final records = await getFavoriteRecords();
    return records.map((record) => record.id).toList();
  }

  static Future<List<FavoriteRecord>> getFavoriteRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final records = _decodeRecords(prefs.getString(_recordsKey));
    if (records.isNotEmpty) return _sort(records);

    final migrated = _migrateLegacyFavorites(prefs);
    if (migrated.isNotEmpty) {
      await _saveRecords(prefs, migrated);
    }
    return _sort(migrated);
  }

  static Future<List<Promotion>> getFavoritePromotions() async {
    final records = await getFavoriteRecords();
    return records
        .map((record) => record.promotion)
        .whereType<Promotion>()
        .toList();
  }

  static Future<bool> isFavorite(String dealId) async {
    final records = await getFavoriteRecords();
    return records.any((record) => record.id == dealId);
  }

  static Future<void> addFavorite(String dealId) async {
    if (dealId.trim().isEmpty) return;
    await _upsert(FavoriteRecord.idOnly(dealId));
  }

  static Future<void> addFavoritePromotion(Promotion promotion) async {
    await _upsert(FavoriteRecord.fromPromotion(promotion));
  }

  static Future<void> removeFavorite(String dealId) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getFavoriteRecords();
    records.removeWhere((record) => record.id == dealId);
    await _saveRecords(prefs, records);
  }

  static Future<void> replaceAll(Iterable<Promotion> promotions) async {
    final prefs = await SharedPreferences.getInstance();
    final records = promotions
        .map(FavoriteRecord.fromPromotion)
        .fold<Map<String, FavoriteRecord>>(
          <String, FavoriteRecord>{},
          (map, record) => map..[record.id] = record,
        )
        .values
        .toList();
    await _saveRecords(prefs, records);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recordsKey);
    await prefs.remove(_legacyIdsKey);
    await prefs.remove(_legacySnapshotsKey);
  }

  static Future<void> _upsert(FavoriteRecord nextRecord) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getFavoriteRecords();
    final index = records.indexWhere((record) => record.id == nextRecord.id);

    if (index == -1) {
      records.insert(0, nextRecord);
    } else {
      final existing = records[index];
      records[index] = FavoriteRecord(
        id: existing.id,
        savedAt: existing.savedAt,
        promotion: nextRecord.promotion ?? existing.promotion,
      );
    }

    await _saveRecords(prefs, records);
  }

  static List<FavoriteRecord> _decodeRecords(String? raw) {
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => FavoriteRecord.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .where((record) => record.id.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static List<FavoriteRecord> _migrateLegacyFavorites(
    SharedPreferences prefs,
  ) {
    final ids = prefs.getStringList(_legacyIdsKey) ?? const <String>[];
    if (ids.isEmpty) return [];

    final snapshots = _decodeLegacySnapshots(prefs.getString(
      _legacySnapshotsKey,
    ));

    final orderedIds = ids.reversed.toList();
    return orderedIds.asMap().entries.map((entry) {
      final id = entry.value;
      final snapshot = snapshots[id];
      return FavoriteRecord(
        id: id,
        savedAt: DateTime.fromMillisecondsSinceEpoch(
          orderedIds.length - entry.key,
        ),
        promotion: snapshot,
      );
    }).toList();
  }

  static Map<String, Promotion> _decodeLegacySnapshots(String? raw) {
    if (raw == null || raw.isEmpty) return <String, Promotion>{};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, Promotion>{};
      final snapshots = <String, Promotion>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is Map) {
          snapshots[entry.key.toString()] = Promotion.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      }
      return snapshots;
    } catch (_) {
      return <String, Promotion>{};
    }
  }

  static List<FavoriteRecord> _sort(List<FavoriteRecord> records) {
    records.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return records;
  }

  static Future<void> _saveRecords(
    SharedPreferences prefs,
    List<FavoriteRecord> records,
  ) async {
    final unique = <String, FavoriteRecord>{};
    for (final record in records) {
      if (record.id.isNotEmpty) {
        unique[record.id] = record;
      }
    }
    final sorted = _sort(unique.values.toList());
    await prefs.setString(
      _recordsKey,
      jsonEncode(sorted.map((record) => record.toJson()).toList()),
    );
    await prefs.setStringList(
      _legacyIdsKey,
      sorted.map((record) => record.id).toList(),
    );
  }
}
