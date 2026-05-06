import '../models/category.dart';
import '../models/promotion.dart';

class SearchMatcher {
  static final Map<String, List<String>> _categoryAliases = {
    'fashion': [
      'fashion',
      'clothing',
      'clothes',
      'apparel',
      'dress',
      'shirt',
      'style',
      'garment',
      'wear',
      'විලාසිතා',
      'ඇඳුම්',
      'රෙදි',
      'ෆැෂන්',
    ],
    'electronics': [
      'electronics',
      'electronic',
      'tech',
      'gadget',
      'device',
      'devices',
      'mobile',
      'phone',
      'smartphone',
      'laptop',
      'computer',
      'electrical',
      'ඉලෙක්ට්\u200dරොනික්',
      'ටෙක්',
      'ගැජට්',
      'ෆෝන්',
      'දුරකථන',
      'ලැප්ටොප්',
    ],
    'food': [
      'food',
      'foods',
      'beverage',
      'beverages',
      'restaurant',
      'cafe',
      'coffee',
      'tea',
      'pizza',
      'burger',
      'dining',
      'meal',
      'meals',
      'ආහාර',
      'කෑම',
      'බීම',
      'රෙස්ටුරන්ට්',
      'කැෆේ',
    ],
    'food_bev': [
      'food',
      'beverage',
      'restaurant',
      'cafe',
      'coffee',
      'tea',
      'dining',
      'ආහාර',
      'කෑම',
      'බීම',
      'කැෆේ',
    ],
    'travel': [
      'travel',
      'trip',
      'tour',
      'tourism',
      'holiday',
      'vacation',
      'hotel',
      'flight',
      'journey',
      'ගමන්',
      'සංචාර',
      'චාරිකා',
      'හෝටල්',
    ],
    'health': [
      'health',
      'wellness',
      'medical',
      'fitness',
      'pharmacy',
      'spa',
      'beauty',
      'healthcare',
      'සෞඛ්‍ය',
      'වෙල්නස්',
      'ඖෂධ',
      'ෆිට්නස්',
      'සුන්දරත්වය',
    ],
    'beauty_health': [
      'health',
      'wellness',
      'beauty',
      'spa',
      'pharmacy',
      'fitness',
      'සෞඛ්‍ය',
      'සුන්දරත්වය',
      'ඖෂධ',
    ],
    'home': [
      'home',
      'house',
      'living',
      'furniture',
      'kitchen',
      'decor',
      'household',
      'ගෙදර',
      'නිවස',
      'ගෘහ',
      'ගෘහභාණ්ඩ',
    ],
    'home_garden': [
      'home',
      'garden',
      'furniture',
      'decor',
      'household',
      'plants',
      'ගෙදර',
      'වත්ත',
      'ගෘහ',
      'ගෘහභාණ්ඩ',
    ],
    'entertainment': [
      'entertainment',
      'movie',
      'cinema',
      'music',
      'game',
      'gaming',
      'fun',
      'event',
      'විනෝදාස්වාද',
      'චිත්\u200dරපට',
      'සංගීත',
      'ගේම්',
      'විනෝදය',
    ],
    'services': [
      'services',
      'service',
      'repair',
      'cleaning',
      'delivery',
      'booking',
      'consulting',
      'සේවා',
      'සර්විස්',
      'අලුත්වැඩියා',
    ],
    'pets': [
      'pets',
      'pet',
      'animal',
      'dog',
      'cat',
      'veterinary',
      'සතුන්',
      'පෙට්',
      'බල්ලන්',
      'පූසා',
    ],
  };

  static String normalize(String value) {
    final lower = value.toLowerCase();
    final cleaned = lower
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'[^a-z0-9\u0D80-\u0DFF\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned;
  }

  static List<String> tokenize(String value) {
    final normalized = normalize(value);
    if (normalized.isEmpty) return const [];
    return normalized.split(' ').where((token) => token.isNotEmpty).toList();
  }

  static String normalizeCategory(String? category) {
    return normalizeCategoryId(normalize(category ?? ''));
  }

  static List<String> categoryTerms(String? category) {
    final normalizedCategory = normalizeCategory(category);
    if (normalizedCategory.isEmpty) return const [];
    final aliases = _categoryAliases[normalizedCategory] ?? const [];
    return <String>[normalizedCategory, ...aliases];
  }

  static bool matchesText(
    String query, {
    required Iterable<String?> fields,
    Iterable<String> extraTerms = const [],
  }) {
    final normalizedQuery = normalize(query);
    if (normalizedQuery.isEmpty) return true;

    final queryTokens = tokenize(normalizedQuery);
    final haystacks = [
      ...fields.whereType<String>().map(normalize).where((value) => value.isNotEmpty),
      ...extraTerms.map(normalize).where((value) => value.isNotEmpty),
    ];

    if (haystacks.isEmpty) return false;

    final wholeCorpus = haystacks.join(' ');
    if (wholeCorpus.contains(normalizedQuery)) {
      return true;
    }

    return queryTokens.every(
      (queryToken) => haystacks.any(
        (candidate) => candidate.contains(queryToken),
      ),
    );
  }

  static int scorePromotion(Promotion promotion, String query) {
    final normalizedQuery = normalize(query);
    if (normalizedQuery.isEmpty) return 0;

    final title = normalize(promotion.title);
    final merchant = normalize(promotion.merchantName ?? '');
    final description = normalize(promotion.description);
    final categoryTerms = SearchMatcher.categoryTerms(promotion.category)
        .map(normalize)
        .toList();

    var score = 0;
    if (title == normalizedQuery) score += 120;
    if (merchant == normalizedQuery) score += 110;
    if (title.contains(normalizedQuery)) score += 90;
    if (merchant.contains(normalizedQuery)) score += 80;
    if (categoryTerms.any((term) => term.contains(normalizedQuery))) score += 70;
    if (description.contains(normalizedQuery)) score += 40;

    for (final token in tokenize(normalizedQuery)) {
      if (title.contains(token)) score += 20;
      if (merchant.contains(token)) score += 18;
      if (description.contains(token)) score += 8;
      if (categoryTerms.any((term) => term.contains(token))) score += 16;
    }

    return score;
  }

  static bool matchesPromotion(Promotion promotion, String query) {
    return matchesText(
      query,
      fields: [
        promotion.title,
        promotion.description,
        promotion.merchantName,
        promotion.category,
        promotion.location,
        promotion.code,
      ],
      extraTerms: categoryTerms(promotion.category),
    );
  }

  static bool matchesMerchant(
    Map<String, dynamic> merchant,
    String query,
  ) {
    final category = (merchant['category'] ?? '').toString();
    return matchesText(
      query,
      fields: [
        merchant['name']?.toString(),
        merchant['description']?.toString(),
        merchant['profile']?.toString(),
        category,
        merchant['address']?.toString(),
        merchant['city']?.toString(),
      ],
      extraTerms: categoryTerms(category),
    );
  }
}
