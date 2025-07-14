import '../models/promotion.dart';
import '../services/favorites_manager.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecommendationService {
  static const String _viewHistoryKey = 'viewHistory';
  static const String _categoryPrefsKey = 'categoryPreferences';

  static Future<List<Promotion>> getRecommendations() async {
    try {
      final allDeals = await ApiService().fetchPromotions();
      final favorites = await FavoritesManager.getFavorites();
      final viewHistory = await _getViewHistory();
      final categoryPrefs = await _getCategoryPreferences();
      
      // Score deals based on user behavior
      final scoredDeals = allDeals.map((deal) {
        double score = 0;
        
        // Category preference scoring
        if (categoryPrefs.containsKey(deal.category)) {
          score += categoryPrefs[deal.category]! * 3;
        }
        
        // View history scoring
        if (viewHistory.contains(deal.id)) {
          score += 2;
        }
        
        // Favorite merchant scoring
        final merchantDeals = allDeals.where((d) => d.merchantId == deal.merchantId).length;
        if (favorites.any((fav) => allDeals.any((d) => d.id == fav && d.merchantId == deal.merchantId))) {
          score += 4;
        }
        
        // Recency scoring
        if (deal.startDate != null) {
          final daysSinceStart = DateTime.now().difference(deal.startDate!).inDays;
          if (daysSinceStart < 7) score += 1;
        }
        
        // Discount scoring
        if (deal.discount != null && deal.discount!.contains('%')) {
          final discountValue = double.tryParse(deal.discount!.replaceAll('%', '')) ?? 0;
          score += discountValue / 20; // Higher discounts get more points
        }
        
        return {'deal': deal, 'score': score};
      }).toList();
      
      // Sort by score and return top recommendations
      scoredDeals.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
      return scoredDeals.take(10).map((item) => item['deal'] as Promotion).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> trackView(String dealId, String? category) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Track view history
    final viewHistory = prefs.getStringList(_viewHistoryKey) ?? [];
    if (!viewHistory.contains(dealId)) {
      viewHistory.add(dealId);
      if (viewHistory.length > 50) viewHistory.removeAt(0); // Keep last 50
      await prefs.setStringList(_viewHistoryKey, viewHistory);
    }
    
    // Track category preferences
    if (category != null) {
      final categoryPrefs = await _getCategoryPreferences();
      categoryPrefs[category] = (categoryPrefs[category] ?? 0) + 1;
      await _saveCategoryPreferences(categoryPrefs);
    }
  }

  static Future<List<String>> _getViewHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_viewHistoryKey) ?? [];
  }

  static Future<Map<String, double>> _getCategoryPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final prefsString = prefs.getString(_categoryPrefsKey) ?? '{}';
    try {
      final Map<String, dynamic> prefsMap = Map<String, dynamic>.from(
        Uri.splitQueryString(prefsString.replaceAll('{', '').replaceAll('}', ''))
      );
      return prefsMap.map((key, value) => MapEntry(key, double.tryParse(value.toString()) ?? 0));
    } catch (e) {
      return {};
    }
  }

  static Future<void> _saveCategoryPreferences(Map<String, double> prefs) async {
    final prefsInstance = await SharedPreferences.getInstance();
    final prefsString = prefs.entries.map((e) => '${e.key}=${e.value}').join('&');
    await prefsInstance.setString(_categoryPrefsKey, '{$prefsString}');
  }
}