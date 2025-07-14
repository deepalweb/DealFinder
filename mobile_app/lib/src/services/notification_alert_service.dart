import 'package:shared_preferences/shared_preferences.dart';
import '../models/promotion.dart';
import '../services/favorites_manager.dart';
import '../services/api_service.dart';

class NotificationAlertService {
  static const String _priceAlertsKey = 'priceAlerts';
  static const String _expiryAlertsKey = 'expiryAlerts';

  static Future<void> checkAndSendAlerts() async {
    await _checkExpiryAlerts();
    await _checkPriceAlerts();
  }

  static Future<void> _checkExpiryAlerts() async {
    try {
      final favorites = await FavoritesManager.getFavorites();
      if (favorites.isEmpty) return;

      final allDeals = await ApiService().fetchPromotions();
      final favoriteDeals = allDeals.where((deal) => favorites.contains(deal.id)).toList();
      
      final now = DateTime.now();
      final alerts = <String>[];

      for (final deal in favoriteDeals) {
        if (deal.endDate != null) {
          final timeLeft = deal.endDate!.difference(now);
          
          if (timeLeft.inHours <= 24 && timeLeft.inHours > 0) {
            alerts.add('⏰ "${deal.title}" expires in ${timeLeft.inHours}h!');
          } else if (timeLeft.inDays == 1) {
            alerts.add('📅 "${deal.title}" expires tomorrow!');
          } else if (timeLeft.inDays <= 3 && timeLeft.inDays > 1) {
            alerts.add('⚠️ "${deal.title}" expires in ${timeLeft.inDays} days!');
          }
        }
      }

      if (alerts.isNotEmpty) {
        await _saveAlerts(_expiryAlertsKey, alerts);
      }
    } catch (e) {
      print('Error checking expiry alerts: $e');
    }
  }

  static Future<void> _checkPriceAlerts() async {
    try {
      final priceAlerts = await _getPriceAlerts();
      if (priceAlerts.isEmpty) return;

      final allDeals = await ApiService().fetchPromotions();
      final alerts = <String>[];

      for (final alert in priceAlerts) {
        final deal = allDeals.firstWhere((d) => d.id == alert['dealId'], orElse: () => Promotion(id: '', title: '', description: ''));
        if (deal.id.isNotEmpty) {
          final currentPrice = deal.discountedPrice ?? deal.price ?? 0;
          final targetPrice = alert['targetPrice'] as double;
          
          if (currentPrice <= targetPrice) {
            alerts.add('💰 "${deal.title}" is now Rs.${currentPrice.toStringAsFixed(2)}!');
          }
        }
      }

      if (alerts.isNotEmpty) {
        await _saveAlerts(_priceAlertsKey, alerts);
      }
    } catch (e) {
      print('Error checking price alerts: $e');
    }
  }

  static Future<void> setPriceAlert(String dealId, double targetPrice) async {
    final prefs = await SharedPreferences.getInstance();
    final alerts = await _getPriceAlerts();
    
    // Remove existing alert for this deal
    alerts.removeWhere((alert) => alert['dealId'] == dealId);
    
    // Add new alert
    alerts.add({'dealId': dealId, 'targetPrice': targetPrice});
    
    final alertStrings = alerts.map((alert) => '${alert['dealId']}:${alert['targetPrice']}').toList();
    await prefs.setStringList(_priceAlertsKey, alertStrings);
  }

  static Future<List<Map<String, dynamic>>> _getPriceAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final alertStrings = prefs.getStringList(_priceAlertsKey) ?? [];
    
    return alertStrings.map((alertString) {
      final parts = alertString.split(':');
      return {
        'dealId': parts[0],
        'targetPrice': double.tryParse(parts[1]) ?? 0.0,
      };
    }).toList();
  }

  static Future<void> _saveAlerts(String key, List<String> alerts) async {
    final prefs = await SharedPreferences.getInstance();
    final existingAlerts = prefs.getStringList(key) ?? [];
    existingAlerts.addAll(alerts);
    await prefs.setStringList(key, existingAlerts);
  }

  static Future<List<String>> getRecentAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryAlerts = prefs.getStringList(_expiryAlertsKey) ?? [];
    final priceAlerts = prefs.getStringList(_priceAlertsKey) ?? [];
    
    final allAlerts = [...expiryAlerts, ...priceAlerts];
    return allAlerts.take(10).toList();
  }

  static Future<void> clearAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_expiryAlertsKey);
    await prefs.remove(_priceAlertsKey);
  }
}