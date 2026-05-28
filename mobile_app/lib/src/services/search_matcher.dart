import '../models/category.dart';
import '../models/promotion.dart';
import '../utils/bank_card_promotion_support.dart';

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
      'kema',
      'kaema',
      'kaama',
      'beema',
      'bima',
      'bath',
      'bath packet',
      'bath eka',
      'kottu',
      'koththu',
      'kotthu',
      'kothtthu',
      'kothu',
      'rice',
      'biryani',
      'pizza',
      'burger',
      'noodles',
      'fried rice',
      'submarine',
      'chicken',
      'cake',
      'tea',
      'juice',
      'ආහාර',
      'කෑම',
      'බීම',
      'කොත්තු',
      'බිරියානි',
      'පීසා',
      'බර්ගර්',
      'නූඩ්ල්ස්',
      'රයිස්',
      'කේක්',
      'ரெஸ்டாரண்ட்',
      'உணவு',
      'பானம்',
      'கொத்து',
      'பிரியாணி',
      'பீட்சா',
      'பர்கர்',
      'நூடுல்ஸ்',
      'சோறு',
      'கேக்',
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
      'saloon',
      'salon eka',
      'lassana',
      'සෞඛ්‍ය',
      'සුන්දරත්වය',
      'සැලෝන්',
      'அழகு',
      'சலூன்',
      'ஸ்பா',
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
      'சேவை',
      'பழுது',
      'சரிசெய்தல்',
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
      'edum',
      'andum',
      'redda',
      'fashion eka',
      'shopping yanna',
      'විලාසිතා',
      'ඇඳුම්',
      'රෙදි',
      'ෆැෂන්',
      'ඉලෙක්ට්රොනික්',
      'ஷாப்பிங்',
      'பேஷன்',
      'உடை',
      'மொபைல்',
      'தொலைபேசி',
      'லேப்டாப்',
    ],
    'electronics': [
      'electronics',
      'electronic',
      'tech',
      'gadget',
      'mobile',
      'phone',
      'smartphone',
      'laptop',
      'computer',
      'mobil',
      'mobail',
      'phone eka',
      'lap ekak',
      'ඉලෙක්ට්රොනික්',
      'மின்னணு',
      'மொபைல்',
      'தொலைபேசி',
      'லேப்டாப்',
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
      'beheth',
      'suwaya',
      'සෞඛ්‍ය',
      'වෙල්නස්',
      'ඖෂධ',
      'ஆரோக்கியம்',
      'மருத்துவம்',
      'மருந்தகம்',
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
      'badu',
      'gedara badu',
      'kade badu',
      'ගෙදර',
      'අත්යවශ්ය',
      'மளிகை',
      'அத்தியாவசியம்',
      'சூப்பர்மார்க்கெட்',
    ],
    'auto_services': [
      'auto',
      'car wash',
      'service center',
      'bike repair',
      'garage',
      'vehicle',
      'car eka',
      'bike eka',
      'wash eka',
      'වාහන',
      'கார்',
      'வாகனம்',
      'கேரேஜ்',
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
      'igenaganna',
      'course ekak',
      'panthiya',
      'අධ්යාපන',
      'පාඨමාලා',
      'கல்வி',
      'பாடநெறி',
      'வகுப்பு',
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
      'film',
      'fun eka',
      'විනෝදාස්වාදය',
      'චිත්රපට',
      'வேடிக்கை',
      'திரைப்படம்',
      'நிகழ்ச்சி',
    ],
    'other': [
      'other',
      'misc',
    ],
    'bank_cards': [
      'bank',
      'banks',
      'bank card',
      'bank cards',
      'credit card',
      'credit cards',
      'debit card',
      'debit cards',
      'cashback',
      'installment',
      'instalment',
      'emi',
      'visa',
      'mastercard',
      'card offer',
      'bank offer',
      'bank deals',
      'offers',
      'promo',
      'discount',
      'banku',
      'kaard',
      'card eka',
      'offer eka',
      'loan',
      'installment eka',
      'බැංකු',
      'කාඩ්',
      'අෆර්',
      'வங்கி',
      'அட்டை',
      'சலுகை',
    ],
  };

  static final List<List<String>> _conceptGroups = [
    [
      'food',
      'meal',
      'kema',
      'kaema',
      'kaama',
      'කෑම',
      'உணவு',
    ],
    [
      'drinks',
      'drink',
      'beverage',
      'beema',
      'bima',
      'බීම',
      'பானம்',
    ],
    [
      'kottu',
      'koththu',
      'kotthu',
      'kottu roti',
      'kothu',
      'කොත්තු',
      'කොත්තු රොටි',
      'கொத்து',
      'கொத்து ரொட்டி',
    ],
    [
      'clothes',
      'clothing',
      'fashion',
      'edum',
      'andum',
      'redda',
      'ඇඳුම්',
      'රෙදි',
      'உடை',
      'பேஷன்',
    ],
    [
      'shopping',
      'shop',
      'shopping yanna',
      'බඩු',
      'ஷாப்பிங்',
    ],
    [
      'biryani',
      'biriyani',
      'බිරියානි',
      'பிரியாணி',
    ],
    [
      'burger',
      'burgers',
      'බර්ගර්',
      'பர்கர்',
    ],
    [
      'pizza',
      'pizzas',
      'පීසා',
      'பீட்சா',
    ],
    [
      'submarine',
      'sub',
      'subs',
      'සබ්මැරීන්',
      'சப்',
    ],
    [
      'fried rice',
      'rice',
      'bath',
      'bath eka',
      'baath',
      'රයිස්',
      'சோறு',
      'ஃப்ரைட் ரைஸ்',
    ],
    [
      'noodles',
      'noodle',
      'නූඩ්ල්ස්',
      'நூடுல்ஸ்',
    ],
    [
      'cake',
      'cakes',
      'කේක්',
      'கேக்',
    ],
    [
      'coffee',
      'espresso',
      'latte',
      'කෝපි',
      'காபி',
    ],
    [
      'tea',
      'milk tea',
      'iced tea',
      'the',
      'තේ',
      'டீ',
      'தேநீர்',
    ],
    [
      'buffet',
      'buffets',
      'බෆේ',
      'பஃபெ',
    ],
    [
      'hotel',
      'hotels',
      'stay',
      'resort',
      'nawathinna',
      'හෝටල්',
      'ஹோட்டல்',
      'ரிசார்ட்',
    ],
    [
      'phone',
      'mobile',
      'smartphone',
      'cell phone',
      'mobil',
      'mobail',
      'phone eka',
      'දුරකථන',
      'මොබයිල්',
      'தொலைபேசி',
      'மொபைல்',
    ],
    [
      'laptop',
      'notebook',
      'computer',
      'laptop',
      'lap ekak',
      'ලැප්ටොප්',
      'கணினி',
      'லேப்டாப்',
    ],
    [
      'offer',
      'offers',
      'deal',
      'deals',
      'discount',
      'discounts',
      'promo',
      'promotion',
      'sale',
      'flash sale',
      'save',
      'saving',
      'offer ekak',
      'offer eka',
      'banku offer',
      'discount eka',
      'අෆර්',
      'ඩීල්',
      'වට්ටම්',
      'ප්රවර්ධන',
      'சலுகை',
      'தள்ளுபடி',
      'ப்ரமோ',
      'விற்பனை',
    ],
    [
      'near',
      'nearby',
      'closest',
      'around me',
      'near me',
      'laga',
      'langa',
      'issaraha',
      'අසල',
      'ලග',
      'அருகில்',
      'என் அருகில்',
    ],
  ];

  static final Set<String> _stopWords = {
    'a',
    'an',
    'and',
    'any',
    'best',
    'by',
    'deals',
    'deal',
    'discount',
    'discounts',
    'find',
    'for',
    'from',
    'get',
    'give',
    'have',
    'i',
    'in',
    'is',
    'me',
    'my',
    'eka',
    'ekak',
    'near',
    'nearby',
    'of',
    'on',
    'offer',
    'offers',
    'or',
    'please',
    'promo',
    'promotion',
    'sale',
    'search',
    'show',
    'something',
    'that',
    'the',
    'to',
    'today',
    'want',
    'with',
    'within',
    'mata',
    'one',
    'එක',
    'එකක්',
    'මට',
    'ලග',
    'අසල',
    'දෙන්න',
    'තියෙන',
    'உள்ள',
    'எனக்கு',
    'அருகில்',
    'வேண்டும்',
    'காட்டு',
  };

  static final Map<String, Set<String>> _synonymIndex = _buildSynonymIndex();

  static Map<String, Set<String>> _buildSynonymIndex() {
    final index = <String, Set<String>>{};

    void addGroup(Iterable<String> group) {
      final normalizedGroup = group
          .map(normalize)
          .where((value) => value.isNotEmpty)
          .toSet();
      for (final term in normalizedGroup) {
        index.putIfAbsent(term, () => <String>{}).addAll(normalizedGroup);
      }
    }

    for (final aliases in _categoryAliases.values) {
      addGroup(aliases);
    }
    for (final group in _conceptGroups) {
      addGroup(group);
    }

    return index;
  }

  static String normalize(String value) {
    final lower = value.toLowerCase();
    final cleaned = lower
        .replaceAll('&', ' and ')
        .replaceAll(
          RegExp(r'[^a-z0-9\u0D80-\u0DFF\u0B80-\u0BFF\s]'),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned;
  }

  static List<String> tokenize(String value) {
    final normalized = normalize(value);
    if (normalized.isEmpty) return const [];
    return normalized
        .split(' ')
        .where((token) => token.isNotEmpty && !_stopWords.contains(token))
        .toList();
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

  static Set<String> _expandNormalizedTerm(String term) {
    final normalized = normalize(term);
    if (normalized.isEmpty) return const <String>{};

    final expanded = <String>{normalized};
    final tokens = normalized.split(' ').where((token) => token.isNotEmpty);
    for (final token in tokens) {
      expanded.add(token);
      final synonyms = _synonymIndex[token];
      if (synonyms != null) expanded.addAll(synonyms);
    }

    final wholePhraseSynonyms = _synonymIndex[normalized];
    if (wholePhraseSynonyms != null) expanded.addAll(wholePhraseSynonyms);

    return expanded.where((value) => value.isNotEmpty).toSet();
  }

  static Set<String> expandQueryTerms(String query) {
    final normalized = normalize(query);
    if (normalized.isEmpty) return const <String>{};

    final expanded = <String>{normalized, ...tokenize(normalized)};
    expanded.addAll(_expandNormalizedTerm(normalized));

    for (final token in tokenize(normalized)) {
      expanded.addAll(_expandNormalizedTerm(token));
    }

    return expanded.where((value) => value.isNotEmpty).toSet();
  }

  static Set<String> expandCorpusTerms(Iterable<String?> values) {
    final corpus = <String>{};
    for (final value in values.whereType<String>()) {
      final normalized = normalize(value);
      if (normalized.isEmpty) continue;
      corpus.add(normalized);
      corpus.addAll(tokenize(normalized));
      corpus.addAll(_expandNormalizedTerm(normalized));
    }
    return corpus;
  }

  static bool matchesText(
    String query, {
    required Iterable<String?> fields,
    Iterable<String> extraTerms = const [],
  }) {
    final normalizedQuery = normalize(query);
    if (normalizedQuery.isEmpty) return true;

    final queryTerms = expandQueryTerms(normalizedQuery);
    final baseTokens = tokenize(normalizedQuery);
    final haystackTerms = expandCorpusTerms([
      ...fields,
      ...extraTerms,
    ]);

    if (haystackTerms.isEmpty) return false;

    final wholeCorpus = haystackTerms.join(' ');
    if (wholeCorpus.contains(normalizedQuery)) {
      return true;
    }

    for (final term in queryTerms.where((term) => term.length > 2)) {
      if (wholeCorpus.contains(term)) {
        return true;
      }
    }

    if (baseTokens.isEmpty) {
      return queryTerms.any((term) => haystackTerms.contains(term));
    }

    return baseTokens.every((token) {
      final expandedTokenTerms = _expandNormalizedTerm(token);
      return haystackTerms.any((candidate) {
        if (candidate.contains(token)) return true;
        return expandedTokenTerms.any(
          (variant) => candidate.contains(variant) || variant.contains(candidate),
        );
      });
    });
  }

  static List<String> promotionSearchTerms(Promotion promotion) {
    final effectiveCategory =
        BankCardPromotionSupport.effectiveCategoryId(promotion);
    final rawTerms = <String?>[
      promotion.title,
      promotion.description,
      promotion.merchantName,
      promotion.location,
      promotion.code,
      promotion.discount,
      promotion.bankName,
      promotion.offerType,
      effectiveCategory,
    ];

    final categoryAliasTerms = categoryTerms(effectiveCategory);
    final bankTerms = BankCardPromotionSupport.searchTerms(promotion);
    return expandCorpusTerms([
      ...rawTerms,
      ...categoryAliasTerms,
      ...bankTerms,
    ]).toList();
  }

  static int scorePromotion(Promotion promotion, String query) {
    final normalizedQuery = normalize(query);
    if (normalizedQuery.isEmpty) return 0;

    final title = normalize(promotion.title);
    final merchant = normalize(promotion.merchantName ?? '');
    final description = normalize(promotion.description);
    final location = normalize(promotion.location ?? '');
    final promotionTerms = promotionSearchTerms(promotion);
    final expandedQueryTerms = expandQueryTerms(normalizedQuery);
    final baseTokens = tokenize(normalizedQuery);

    var score = 0;

    if (title == normalizedQuery) score += 140;
    if (merchant == normalizedQuery) score += 125;
    if (title.contains(normalizedQuery)) score += 95;
    if (merchant.contains(normalizedQuery)) score += 85;
    if (description.contains(normalizedQuery)) score += 45;
    if (location.contains(normalizedQuery)) score += 35;

    for (final term in expandedQueryTerms) {
      if (term.isEmpty) continue;
      if (title.contains(term)) score += 32;
      if (merchant.contains(term)) score += 28;
      if (description.contains(term)) score += 14;
      if (location.contains(term)) score += 12;
      if (promotionTerms.any((candidate) => candidate.contains(term))) {
        score += 18;
      }
    }

    for (final token in baseTokens) {
      final tokenVariants = _expandNormalizedTerm(token);
      if (tokenVariants.any(title.contains)) score += 22;
      if (tokenVariants.any(merchant.contains)) score += 18;
      if (tokenVariants.any(description.contains)) score += 10;
      if (promotionTerms.any(
        (candidate) => tokenVariants.any(candidate.contains),
      )) {
        score += 16;
      }
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
        BankCardPromotionSupport.effectiveCategoryId(promotion),
        promotion.location,
        promotion.code,
        promotion.discount,
        promotion.bankName,
        promotion.offerType,
      ],
      extraTerms: promotionSearchTerms(promotion),
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
