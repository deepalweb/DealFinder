import 'package:shared_preferences/shared_preferences.dart';
import '../models/promotion.dart';
import '../services/api_service.dart';
import 'search_matcher.dart';

class SearchService {
  static const String _searchHistoryKey = 'searchHistory';
  static const String _savedSearchesKey = 'savedSearches';

  static Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_searchHistoryKey) ?? [];
  }

  static Future<void> addToSearchHistory(String query) async {
    final cleaned = query.trim();
    if (cleaned.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final history = await getSearchHistory();
    
    history.removeWhere(
      (item) => SearchMatcher.normalize(item) == SearchMatcher.normalize(cleaned),
    );
    history.insert(0, cleaned); // Add to front
    
    if (history.length > 20) history.removeRange(20, history.length);
    await prefs.setStringList(_searchHistoryKey, history);
  }

  static Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchHistoryKey);
  }

  static Future<List<String>> getSuggestions(String query) async {
    if (query.length < 2) return [];
    
    try {
      final allDeals = await ApiService().fetchPromotions();
      final suggestions = <String>{};
      
      // Add matching titles, merchants, and categories
      for (final deal in allDeals) {
        if (SearchMatcher.matchesPromotion(deal, query)) {
          suggestions.add(deal.title);
          if ((deal.merchantName ?? '').trim().isNotEmpty) {
            suggestions.add(deal.merchantName!);
          }
          final aliases = SearchMatcher.categoryTerms(deal.category);
          if (aliases.isNotEmpty) {
            suggestions.add(aliases.first);
          }
        }
      }
      
      return suggestions.take(8).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Promotion>> performAdvancedSearch({
    required String query,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? merchant,
    bool? hasDiscount,
    DateTime? expiresAfter,
    String sortBy = 'relevance',
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    try {
      List<Promotion> results = await ApiService().fetchPromotions();
      
      // Text search
      if (query.isNotEmpty) {
        results = results.where((deal) => SearchMatcher.matchesPromotion(deal, query)).toList()
          ..sort((a, b) => SearchMatcher.scorePromotion(b, query).compareTo(SearchMatcher.scorePromotion(a, query)));
      }
      
      // Category filter
      if (category != null && category.isNotEmpty) {
        final normalizedCategory = SearchMatcher.normalizeCategory(category);
        results = results.where((deal) => SearchMatcher.normalizeCategory(deal.category) == normalizedCategory).toList();
      }
      
      // Price range filter
      if (minPrice != null || maxPrice != null) {
        results = results.where((deal) {
          final price = deal.discountedPrice ?? deal.price ?? 0;
          return (minPrice == null || price >= minPrice) &&
                 (maxPrice == null || price <= maxPrice);
        }).toList();
      }
      
      // Merchant filter
      if (merchant != null && merchant.isNotEmpty) {
        results = results.where((deal) => 
          SearchMatcher.matchesText(
            merchant,
            fields: [deal.merchantName],
          )
        ).toList();
      }
      
      // Discount filter
      if (hasDiscount == true) {
        results = results.where((deal) => 
          deal.discount != null && deal.discount!.isNotEmpty
        ).toList();
      }
      
      // Expiry filter
      if (expiresAfter != null) {
        results = results.where((deal) => 
          deal.endDate != null && deal.endDate!.isAfter(expiresAfter)
        ).toList();
      }
      
      // Location filter (simplified)
      if (latitude != null && longitude != null && radiusKm != null) {
        // In a real app, you'd calculate distance
        // For now, just return results as-is
      }
      
      // Sorting
      switch (sortBy) {
        case 'price_low':
          results.sort((a, b) => 
            (a.discountedPrice ?? a.price ?? 0).compareTo(b.discountedPrice ?? b.price ?? 0));
          break;
        case 'price_high':
          results.sort((a, b) => 
            (b.discountedPrice ?? b.price ?? 0).compareTo(a.discountedPrice ?? a.price ?? 0));
          break;
        case 'discount':
          results.sort((a, b) {
            final aDiscount = double.tryParse(a.discount?.replaceAll('%', '') ?? '0') ?? 0;
            final bDiscount = double.tryParse(b.discount?.replaceAll('%', '') ?? '0') ?? 0;
            return bDiscount.compareTo(aDiscount);
          });
          break;
        case 'newest':
          results.sort((a, b) => 
            (b.startDate ?? DateTime(1970)).compareTo(a.startDate ?? DateTime(1970)));
          break;
        case 'expiry':
          results.sort((a, b) => 
            (a.endDate ?? DateTime(2100)).compareTo(b.endDate ?? DateTime(2100)));
          break;
      }
      
      return results;
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveSearch(String query, Map<String, dynamic> filters) async {
    final prefs = await SharedPreferences.getInstance();
    final savedSearches = prefs.getStringList(_savedSearchesKey) ?? [];
    
    final searchData = '$query|${filters.toString()}';
    savedSearches.remove(searchData);
    savedSearches.insert(0, searchData);
    
    if (savedSearches.length > 10) savedSearches.removeRange(10, savedSearches.length);
    await prefs.setStringList(_savedSearchesKey, savedSearches);
  }

  static Future<List<Map<String, dynamic>>> getSavedSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSearches = prefs.getStringList(_savedSearchesKey) ?? [];
    
    return savedSearches.map((search) {
      final parts = search.split('|');
      return {
        'query': parts[0],
        'filters': parts.length > 1 ? parts[1] : '{}',
      };
    }).toList();
  }
}
