import 'package:shared_preferences/shared_preferences.dart';
import '../models/promotion.dart';
import '../services/api_service.dart';

class DealComparisonService {
  static const String _comparisonKey = 'dealComparison';
  static const int _maxComparisons = 5;

  static Future<void> addToComparison(String dealId) async {
    final prefs = await SharedPreferences.getInstance();
    final comparisonIds = prefs.getStringList(_comparisonKey) ?? [];
    
    if (!comparisonIds.contains(dealId)) {
      comparisonIds.add(dealId);
      
      // Keep only last 5 deals for comparison
      if (comparisonIds.length > _maxComparisons) {
        comparisonIds.removeAt(0);
      }
      
      await prefs.setStringList(_comparisonKey, comparisonIds);
    }
  }

  static Future<void> removeFromComparison(String dealId) async {
    final prefs = await SharedPreferences.getInstance();
    final comparisonIds = prefs.getStringList(_comparisonKey) ?? [];
    comparisonIds.remove(dealId);
    await prefs.setStringList(_comparisonKey, comparisonIds);
  }

  static Future<List<Promotion>> getComparisonDeals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final comparisonIds = prefs.getStringList(_comparisonKey) ?? [];
      
      if (comparisonIds.isEmpty) return [];
      
      final allDeals = await ApiService().fetchPromotions();
      final comparisonDeals = <Promotion>[];
      
      for (final id in comparisonIds) {
        final deal = allDeals.firstWhere((d) => d.id == id, orElse: () => Promotion(id: '', title: '', description: ''));
        if (deal.id.isNotEmpty) {
          comparisonDeals.add(deal);
        }
      }
      
      return comparisonDeals;
    } catch (e) {
      return [];
    }
  }

  static Future<bool> isInComparison(String dealId) async {
    final prefs = await SharedPreferences.getInstance();
    final comparisonIds = prefs.getStringList(_comparisonKey) ?? [];
    return comparisonIds.contains(dealId);
  }

  static Future<int> getComparisonCount() async {
    final prefs = await SharedPreferences.getInstance();
    final comparisonIds = prefs.getStringList(_comparisonKey) ?? [];
    return comparisonIds.length;
  }

  static Future<void> clearComparison() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_comparisonKey);
  }

  static Future<Map<String, dynamic>> getComparisonSummary() async {
    final deals = await getComparisonDeals();
    if (deals.isEmpty) return {};

    final prices = deals.map((d) => d.discountedPrice ?? d.price ?? 0).where((p) => p > 0).toList();
    final discounts = deals.map((d) => d.discount).where((d) => d != null && d.contains('%')).toList();
    
    return {
      'count': deals.length,
      'avgPrice': prices.isNotEmpty ? prices.reduce((a, b) => a + b) / prices.length : 0,
      'bestDiscount': discounts.isNotEmpty ? discounts.map((d) => double.tryParse(d!.replaceAll('%', '')) ?? 0).reduce((a, b) => a > b ? a : b) : 0,
      'cheapest': prices.isNotEmpty ? deals.firstWhere((d) => (d.discountedPrice ?? d.price ?? 0) == prices.reduce((a, b) => a < b ? a : b)) : null,
    };
  }
}