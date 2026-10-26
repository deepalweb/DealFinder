import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../models/promotion.dart';
import '../services/api_service.dart';
import 'search_matcher.dart';
import 'browsing_area.dart';
import '../utils/offer_presentation.dart';
import '../utils/bank_card_promotion_support.dart';

class SearchService {
  static const String _searchHistoryKey = 'searchHistory';
  static const String _savedSearchesKey = 'savedSearches';
  static const List<String> _nearbyIntentTerms = [
    'near me',
    'nearby',
    'closest',
    'nearest',
    'around me',
    'lagama',
    'langama',
    'laga',
    'ළගම',
    'ලගම',
    'ළඟම',
    'ලඟම',
    'අසල',
    'කිට්ටුව',
    'கிட்ட',
    'அருகில்',
    'பக்கத்தில்',
  ];

  static double _discountSignal(Promotion deal) {
    return OfferPresentation(deal).percentage;
  }

  static bool _looksLikeNearbySearch(String query, String sortBy) {
    final normalized = query.toLowerCase();
    return sortBy == 'distance' ||
        _nearbyIntentTerms.any((term) => normalized.contains(term));
  }

  static Future<Position?> _tryGetSearchLocation({
    required String query,
    required String sortBy,
    double? latitude,
    double? longitude,
  }) async {
    if (latitude != null && longitude != null) return null;

    final area = await BrowsingArea.read();
    if (area == null) return null;
    return Position(
        latitude: area.latitude,
        longitude: area.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0);
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
      final inferredPosition = await _tryGetSearchLocation(
        query: query,
        sortBy: sortBy,
        latitude: latitude,
        longitude: longitude,
      );
      final searchLatitude = latitude ?? inferredPosition?.latitude;
      final searchLongitude = longitude ?? inferredPosition?.longitude;
      final shouldUseNaturalApi = query.trim().isNotEmpty ||
          category != null ||
          sortBy != 'relevance' ||
          searchLatitude != null ||
          searchLongitude != null;

      if (shouldUseNaturalApi) {
        try {
          final apiResults = await ApiService().naturalSearchPromotions(
            query: query,
            category: category,
            sortBy: sortBy,
            latitude: searchLatitude,
            longitude: searchLongitude,
            radiusKm:
                radiusKm ?? (_looksLikeNearbySearch(query, sortBy) ? 10 : null),
          );
          if (apiResults.isNotEmpty || query.trim().isNotEmpty) {
            return apiResults;
          }
        } catch (_) {
          // Fall through to local cached search so search still works offline.
        }
      }

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
              (deal) => BankCardPromotionSupport.matchesCategory(
                  deal, normalizedCategory),
            )
            .toList();
      }

      // Price range filter
      if (minPrice != null || maxPrice != null) {
        results = results.where((deal) {
          final price = OfferPresentation(deal).price;
          if (price == null) return false;
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

      if (searchLatitude != null &&
          searchLongitude != null &&
          radiusKm != null) {
        final radiusMeters = radiusKm * 1000;
        results = results
            .where((deal) => deal.latitude != null && deal.longitude != null)
            .map((deal) {
              final distanceMeters = Geolocator.distanceBetween(
                searchLatitude,
                searchLongitude,
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
          results.sort(OfferPresentation.comparePrices);
          break;
        case 'price_high':
          results.sort((a, b) =>
              OfferPresentation.comparePrices(a, b, descending: true));
          break;
        case 'discount':
          results
              .sort((a, b) => _discountSignal(b).compareTo(_discountSignal(a)));
          break;
        case 'highest_rated':
        case 'rating':
          results.sort((a, b) {
            final ratingCompare =
                (b.averageRating ?? 0).compareTo(a.averageRating ?? 0);
            if (ratingCompare != 0) return ratingCompare;
            return b.ratingsCount.compareTo(a.ratingsCount);
          });
          break;
        case 'newest':
        case 'latest':
          results.sort((a, b) => (b.startDate ?? DateTime(1970))
              .compareTo(a.startDate ?? DateTime(1970)));
          break;
        case 'expiry':
        case 'ending_soon':
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
