import 'package:shared_preferences/shared_preferences.dart';
import '../models/promotion.dart';
import '../services/api_service.dart';

class DealComparisonService {
  static String _comparisonKey(SharedPreferences prefs) =>
      'dealComparison:${prefs.getString('userId') ?? 'guest'}';
  static const int _maxComparisons = 5;

  static Future<void> addToComparison(String dealId) async {
    final prefs = await SharedPreferences.getInstance();
    final comparisonIds = prefs.getStringList(_comparisonKey(prefs)) ?? [];

    if (!comparisonIds.contains(dealId)) {
      comparisonIds.add(dealId);

      // Keep only last 5 deals for comparison
      if (comparisonIds.length > _maxComparisons) {
        comparisonIds.removeAt(0);
      }

      await prefs.setStringList(_comparisonKey(prefs), comparisonIds);
    }
  }

  static Future<void> removeFromComparison(String dealId) async {
    final prefs = await SharedPreferences.getInstance();
    final comparisonIds = prefs.getStringList(_comparisonKey(prefs)) ?? [];
    comparisonIds.remove(dealId);
    await prefs.setStringList(_comparisonKey(prefs), comparisonIds);
  }

  static Future<List<String>> getComparisonIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_comparisonKey(prefs)) ?? [];
  }

  static Future<List<Promotion>> getComparisonDeals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final comparisonIds = prefs.getStringList(_comparisonKey(prefs)) ?? [];

      if (comparisonIds.isEmpty) return [];

      return await ApiService().resolveFavoritePromotionsByIds(comparisonIds);
    } catch (e) {
      return [];
    }
  }

  static Future<bool> isInComparison(String dealId) async {
    final prefs = await SharedPreferences.getInstance();
    final comparisonIds = prefs.getStringList(_comparisonKey(prefs)) ?? [];
    return comparisonIds.contains(dealId);
  }

  static Future<int> getComparisonCount() async {
    final prefs = await SharedPreferences.getInstance();
    final comparisonIds = prefs.getStringList(_comparisonKey(prefs)) ?? [];
    return comparisonIds.length;
  }

  static Future<void> clearComparison() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_comparisonKey(prefs));
  }

  static Future<Map<String, dynamic>> getComparisonSummary() async {
    final deals = await getComparisonDeals();
    if (deals.isEmpty) return {};

    final prices = deals
        .map((d) => d.discountedPrice ?? d.price ?? 0)
        .where((p) => p > 0)
        .toList();
    final discounts = deals
        .map((d) => d.discount)
        .where((d) => d != null && d.contains('%'))
        .toList();

    return {
      'count': deals.length,
      'avgPrice': prices.isNotEmpty
          ? prices.reduce((a, b) => a + b) / prices.length
          : 0,
      'bestDiscount': discounts.isNotEmpty
          ? discounts
              .map((d) => double.tryParse(d!.replaceAll('%', '')) ?? 0)
              .reduce((a, b) => a > b ? a : b)
          : 0,
      'cheapest': prices.isNotEmpty
          ? deals.firstWhere((d) =>
              (d.discountedPrice ?? d.price ?? 0) ==
              prices.reduce((a, b) => a < b ? a : b))
          : null,
    };
  }
}
