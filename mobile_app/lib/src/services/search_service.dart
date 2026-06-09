import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../models/promotion.dart';
import '../services/api_service.dart';
import 'search_matcher.dart';
import '../utils/bank_card_promotion_support.dart';

class SearchService {
  static const String _searchHistoryKey = 'searchHistory';
  static const String _savedSearchesKey = 'savedSearches';

  static double _effectivePrice(Promotion deal) {
    return deal.discountedPrice ?? deal.price ?? deal.originalPrice ?? 0;
  }

  static double _discountSignal(Promotion deal) {
    final percentage = deal.discountPercentage;
    if (percentage != null) return percentage.toDouble();

    final rawDiscount = deal.discount;
    if (rawDiscount == null || rawDiscount.isEmpty) return 0;

    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(rawDiscount);
    return match != null ? double.tryParse(match.group(1)!) ?? 0 : 0;
  }

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
      (item) =>
          SearchMatcher.normalize(item) == SearchMatcher.normalize(cleaned),
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
      final suggestionScores = <String, int>{};

      for (final deal in allDeals) {
        final score = SearchMatcher.scorePromotion(deal, query);
        if (score <= 0 || !SearchMatcher.matchesPromotion(deal, query)) {
          continue;
        }

        void addSuggestion(String? value, int bonus) {
          final cleaned = value?.trim();
          if (cleaned == null || cleaned.isEmpty) return;
          final current = suggestionScores[cleaned] ?? 0;
          suggestionScores[cleaned] =
              current > score + bonus ? current : score + bonus;
        }

        addSuggestion(deal.title, 30);
        addSuggestion(deal.merchantName, 22);

        final aliases = SearchMatcher.categoryTerms(
          BankCardPromotionSupport.effectiveCategoryId(deal),
        );
        if (aliases.isNotEmpty) {
          addSuggestion(aliases.first, 12);
        }
      }

      final normalizedQuery = SearchMatcher.normalize(query);
      final sorted = suggestionScores.entries.toList()
        ..sort((a, b) {
          final byScore = b.value.compareTo(a.value);
          if (byScore != 0) return byScore;

          final aNormalized = SearchMatcher.normalize(a.key);
          final bNormalized = SearchMatcher.normalize(b.key);
          final aStarts = aNormalized.startsWith(normalizedQuery) ? 1 : 0;
          final bStarts = bNormalized.startsWith(normalizedQuery) ? 1 : 0;
          return bStarts.compareTo(aStarts);
        });

      return sorted.take(8).map((entry) => entry.key).toList();
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
        results = results
            .where((deal) => SearchMatcher.matchesPromotion(deal, query))
            .toList()
          ..sort((a, b) => SearchMatcher.scorePromotion(b, query)
              .compareTo(SearchMatcher.scorePromotion(a, query)));
      }

      // Category filter
      if (category != null && category.isNotEmpty) {
        final normalizedCategory = SearchMatcher.normalizeCategory(category);
        results = results
            .where(
              (deal) =>
                  BankCardPromotionSupport.effectiveCategoryId(deal) ==
                  normalizedCategory,
            )
            .toList();
      }

      // Price range filter
      if (minPrice != null || maxPrice != null) {
        results = results.where((deal) {
          final price = _effectivePrice(deal);
          return (minPrice == null || price >= minPrice) &&
              (maxPrice == null || price <= maxPrice);
        }).toList();
      }

      // Merchant filter
      if (merchant != null && merchant.isNotEmpty) {
        results = results
            .where((deal) => SearchMatcher.matchesText(
                  merchant,
                  fields: [deal.merchantName],
                ))
            .toList();
      }

      // Discount filter
      if (hasDiscount == true) {
        results = results
            .where((deal) => deal.discount != null && deal.discount!.isNotEmpty)
            .toList();
      }

      // Expiry filter
      if (expiresAfter != null) {
        results = results
            .where((deal) =>
                deal.endDate != null && deal.endDate!.isAfter(expiresAfter))
            .toList();
      }

      if (latitude != null && longitude != null && radiusKm != null) {
        final radiusMeters = radiusKm * 1000;
        results = results
            .where((deal) => deal.latitude != null && deal.longitude != null)
            .map((deal) {
              final distanceMeters = Geolocator.distanceBetween(
                latitude,
                longitude,
                deal.latitude!,
                deal.longitude!,
              );
              return deal.copyWith(distance: distanceMeters);
            })
            .where((deal) => (deal.distance ?? double.infinity) <= radiusMeters)
            .toList();
      }

      // Sorting
      switch (sortBy) {
        case 'price_low':
          results
              .sort((a, b) => _effectivePrice(a).compareTo(_effectivePrice(b)));
          break;
        case 'price_high':
          results
              .sort((a, b) => _effectivePrice(b).compareTo(_effectivePrice(a)));
          break;
        case 'discount':
          results
              .sort((a, b) => _discountSignal(b).compareTo(_discountSignal(a)));
          break;
        case 'newest':
          results.sort((a, b) => (b.startDate ?? DateTime(1970))
              .compareTo(a.startDate ?? DateTime(1970)));
          break;
        case 'expiry':
          results.sort((a, b) => (a.endDate ?? DateTime(2100))
              .compareTo(b.endDate ?? DateTime(2100)));
          break;
        case 'distance':
          results.sort((a, b) => (a.distance ?? double.infinity)
              .compareTo(b.distance ?? double.infinity));
          break;
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveSearch(
      String query, Map<String, dynamic> filters) async {
    final prefs = await SharedPreferences.getInstance();
    final savedSearches = prefs.getStringList(_savedSearchesKey) ?? [];

    final searchData = '$query|${filters.toString()}';
    savedSearches.remove(searchData);
    savedSearches.insert(0, searchData);

    if (savedSearches.length > 10) {
      savedSearches.removeRange(10, savedSearches.length);
    }
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
