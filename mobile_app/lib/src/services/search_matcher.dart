import '../models/category.dart';
import '../models/promotion.dart';

class SearchMatcher {
  static final Map<String, List<String>> _categoryAliases = {
    'food_dining': [
      'food',
      'dining',
      'restaurant',
      'restaurants',
      'cafe',
      'cafes',
      'coffee',
      'dessert',
      'fast food',
      'buffet',
      'meal',
      'budget meal',
      'takeaway',
      'hangout',
      'foods',
      'beverage',
      'beverages',
      'late night food',
      'family packs',
      'buy 1 get 1',
      'bogo',
      'ආහාර',
      'කෑම',
      'බීම',
      'රෙස්ටුරන්ට්',
      'කැෆේ',
    ],
    'beauty_salon': [
      'beauty',
      'salon',
      'spa',
      'grooming',
      'haircut',
      'bridal',
      'wellness',
      'skincare',
      'mens grooming',
      'womens beauty',
      'luxury spa',
      'සෞඛ්‍ය',
      'සුන්දරත්වය',
      'සැලෝන්',
    ],
    'repairs_services': [
      'services',
      'service',
      'repair',
      'repairs',
      'cleaning',
      'consulting',
      'mobile repair',
      'laptop repair',
      'printer repair',
      'electrical',
      'same day service',
      'express service',
      'urgent',
      'සේවා',
      'සර්විස්',
      'අලුත්වැඩියා',
    ],
    'shopping_retail': [
      'shopping',
      'retail',
      'electronics',
      'electronic',
      'tech',
      'gadget',
      'fashion',
      'clothing',
      'clothes',
      'apparel',
      'accessories',
      'mobile',
      'phone',
      'smartphone',
      'laptop',
      'computer',
      'විලාසිතා',
      'ඇඳුම්',
      'රෙදි',
      'ෆැෂන්',
      'ඉලෙක්ට්\u200dරොනික්',
    ],
    'health_wellness': [
      'health',
      'wellness',
      'clinic',
      'dental',
      'fitness',
      'yoga',
      'medical',
      'pharmacy',
      'healthcare',
      'සෞඛ්‍ය',
      'වෙල්නස්',
      'ඖෂධ',
    ],
    'daily_essentials': [
      'grocery',
      'groceries',
      'pharmacy',
      'household',
      'daily essentials',
      'essentials',
      'supermarket',
      'fresh',
      'ගෙදර',
      'අත්‍යවශ්‍ය',
    ],
    'auto_services': [
      'auto',
      'car wash',
      'service center',
      'bike repair',
      'garage',
      'vehicle',
    ],
    'education_courses': [
      'education',
      'course',
      'courses',
      'tuition',
      'skill training',
      'it courses',
      'class',
      'classes',
    ],
    'entertainment_activities': [
      'entertainment',
      'movie',
      'movies',
      'cinema',
      'event',
      'events',
      'kids activities',
      'activity',
      'fun',
      'gaming',
      'concert',
    ],
    'other': [
      'other',
      'misc',
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
      ...fields
          .whereType<String>()
          .map(normalize)
          .where((value) => value.isNotEmpty),
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
    final categoryTerms =
        SearchMatcher.categoryTerms(promotion.category).map(normalize).toList();

    var score = 0;
    if (title == normalizedQuery) score += 120;
    if (merchant == normalizedQuery) score += 110;
    if (title.contains(normalizedQuery)) score += 90;
    if (merchant.contains(normalizedQuery)) score += 80;
    if (categoryTerms.any((term) => term.contains(normalizedQuery))) {
      score += 70;
    }
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
