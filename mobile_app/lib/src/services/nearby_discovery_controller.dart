import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/promotion.dart';
import '../utils/merchant_hours.dart';
import 'api_service.dart';
import 'browsing_area.dart';
import 'location_service.dart';

class NearbyDiscoveryController extends ChangeNotifier {
  NearbyDiscoveryController({ApiService? api}) : _api = api ?? ApiService();
  final ApiService _api;
  BrowsingArea area = BrowsingArea.initial;
  double radius = 3;
  String? category;
  String query = '';
  bool openOnly = false;
  bool loading = false;
  bool failed = false;
  bool cached = false;
  bool cacheMismatch = false;
  String? selectedId;
  List<Promotion> _offers = [];
  Map<String, Map<String, dynamic>> _hours = {};
  List<Map<String, dynamic>> merchants = [];
  int _generation = 0;
  bool _disposed = false;
  DateTime? cachedAt;

  List<Promotion> get offers {
    final offers = _offers
        .where((p) =>
            p.hasStarted &&
            !p.isExpired &&
            p.supportsVisit &&
            p.latitude != null &&
            p.longitude != null &&
            (category == null || p.category == category) &&
            (query.isEmpty ||
                '${p.title} ${p.merchantName ?? ''}'
                    .toLowerCase()
                    .contains(query.toLowerCase())) &&
            (!openOnly || MerchantHours.isOpen(_hours[p.merchantId]) == true))
        .map((p) => p.copyWith(
            distance: LocationService.calculateDistance(
                    area.latitude, area.longitude, p.latitude!, p.longitude!) *
                1000))
        .where((p) => p.distance! <= radius * 1000)
        .toList();
    offers.sort((a, b) => a.distance!.compareTo(b.distance!));
    // Selection stays valid as categories, hours, or radius change.
    return offers;
  }

  Promotion? get selected {
    for (final offer in offers) {
      if (offer.id == selectedId) return offer;
    }
    return null;
  }

  Future<void> initialize() async {
    area = await BrowsingArea.read() ?? BrowsingArea.initial;
    final prefs = await SharedPreferences.getInstance();
    final savedRadius = prefs.getDouble('nearby_radius');
    if ([1.0, 3.0, 5.0, 10.0].contains(savedRadius)) radius = savedRadius!;
    if (_disposed) return;
    await Future.wait([search(area, persist: false), loadMerchants()]);
  }

  Future<void> loadMerchants() async {
    try {
      final records = await _api.fetchMerchants();
      if (_disposed) return;
      merchants = records;
      _hours = {
        for (final m in records)
          if (m['openingHours'] is Map)
            (m['_id'] ?? m['id']).toString():
                Map<String, dynamic>.from(m['openingHours'] as Map)
      };
      notifyListeners();
    } catch (_) {}
  }

  Future<void> search(BrowsingArea next, {bool persist = true}) async {
    final request = ++_generation;
    final requestedRadius = radius;
    area = next;
    selectedId = null;
    _offers = [];
    loading = true;
    failed = false;
    cacheMismatch = false;
    cached = false;
    cachedAt = null;
    notifyListeners();
    try {
      if (persist) await BrowsingArea.select(next);
      if (_disposed || request != _generation) return;
      final result = await _api.fetchNearbyPromotionsWithCache(
          next.latitude, next.longitude,
          radiusKm: requestedRadius, locationName: next.label);
      if (_disposed || request != _generation) return;
      // Never present cached offers from another area as results for this one.
      _offers = result.locationChanged ? [] : result.promotions;
      cacheMismatch = result.locationChanged;
      cached = result.fromCache;
      cachedAt = result.cachedAt;
    } catch (_) {
      if (_disposed || request != _generation) return;
      failed = true;
    }
    loading = false;
    notifyListeners();
  }

  Future<void> setRadius(double value) async {
    radius = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('nearby_radius', value);
    await search(area);
  }

  void filter(
      {String? categoryId,
      bool? onlyOpen,
      String? searchQuery,
      bool clearCategory = false}) {
    if (clearCategory) category = null;
    if (categoryId != null) category = categoryId;
    if (onlyOpen != null) openOnly = onlyOpen;
    if (searchQuery != null) query = searchQuery;
    if (selected == null) selectedId = null;
    notifyListeners();
  }

  void select(String id) {
    selectedId = id;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
