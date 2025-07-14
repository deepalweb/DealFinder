import 'package:shared_preferences/shared_preferences.dart';
import '../models/promotion.dart';
import '../services/api_service.dart';

class DealHistoryService {
  static const String _historyKey = 'dealHistory';
  static const String _usedDealsKey = 'usedDeals';

  static Future<void> addToHistory(String dealId) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? [];
    
    // Remove if already exists to move to front
    history.remove(dealId);
    history.insert(0, dealId);
    
    // Keep only last 100 items
    if (history.length > 100) {
      history.removeRange(100, history.length);
    }
    
    await prefs.setStringList(_historyKey, history);
  }

  static Future<List<Promotion>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyIds = prefs.getStringList(_historyKey) ?? [];
      
      if (historyIds.isEmpty) return [];
      
      final allDeals = await ApiService().fetchPromotions();
      final historyDeals = <Promotion>[];
      
      for (final id in historyIds) {
        final deal = allDeals.firstWhere((d) => d.id == id, orElse: () => Promotion(id: '', title: '', description: ''));
        if (deal.id.isNotEmpty) {
          historyDeals.add(deal);
        }
      }
      
      return historyDeals;
    } catch (e) {
      return [];
    }
  }

  static Future<void> markAsUsed(String dealId) async {
    final prefs = await SharedPreferences.getInstance();
    final usedDeals = prefs.getStringList(_usedDealsKey) ?? [];
    
    if (!usedDeals.contains(dealId)) {
      usedDeals.add(dealId);
      await prefs.setStringList(_usedDealsKey, usedDeals);
    }
  }

  static Future<bool> isUsed(String dealId) async {
    final prefs = await SharedPreferences.getInstance();
    final usedDeals = prefs.getStringList(_usedDealsKey) ?? [];
    return usedDeals.contains(dealId);
  }

  static Future<List<String>> getUsedDeals() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_usedDealsKey) ?? [];
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}