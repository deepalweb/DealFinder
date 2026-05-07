const STOP_WORDS = new Set([
  'a', 'an', 'and', 'best', 'by', 'deal', 'deals', 'find', 'for', 'from', 'in',
  'is', 'me', 'near', 'on', 'or', 'of', 'offer', 'offers', 'show', 'that', 'the',
  'to', 'today', 'under', 'with',
]);

const CATEGORY_ALIAS_MAP = {
  fashion: ['fashion', 'clothes', 'clothing', 'apparel', 'wear', 'shirts', 'dress', 'dresses', 'shoes'],
  electronics: ['electronics', 'electronic', 'gadgets', 'gadget', 'phone', 'phones', 'laptop', 'laptops', 'tv'],
  food_bev: ['food', 'foods', 'restaurant', 'restaurants', 'cafe', 'cafes', 'coffee', 'drink', 'drinks', 'beverage', 'beverages', 'food bev', 'food and bev'],
  travel: ['travel', 'trip', 'trips', 'flight', 'flights', 'hotel', 'hotels', 'holiday', 'holidays'],
  beauty_health: ['beauty', 'health', 'wellness', 'salon', 'spa', 'cosmetics', 'skincare'],
  home_garden: ['home', 'garden', 'furniture', 'kitchen', 'decor', 'household'],
  entertainment: ['entertainment', 'movie', 'movies', 'cinema', 'games', 'gaming', 'concert'],
  services: ['services', 'service', 'repair', 'cleaning', 'consulting'],
  pets: ['pets', 'pet', 'dog', 'dogs', 'cat', 'cats', 'veterinary'],
  education: ['education', 'school', 'course', 'courses', 'class', 'classes', 'tuition'],
  other: ['other', 'misc'],
};

function normalizeCategoryId(value) {
  const raw = String(value || '').trim().toLowerCase();
  switch (raw) {
    case 'food':
    case 'food bev':
    case 'food beverage':
    case 'food and bev':
      return 'food_bev';
    case 'health':
    case 'beauty':
    case 'beauty and health':
      return 'beauty_health';
    case 'home':
    case 'garden':
    case 'home and garden':
      return 'home_garden';
    case 'service':
      return 'services';
    case '':
      return '';
    default:
      return raw;
  }
}

function extractMatchedCategories(text) {
  const normalizedText = String(text || '').trim().toLowerCase();
  if (!normalizedText) return [];

  const matches = [];
  for (const [categoryId, aliases] of Object.entries(CATEGORY_ALIAS_MAP)) {
    if (aliases.some((alias) => normalizedText.includes(alias))) {
      matches.push(categoryId);
    }
  }
  return [...new Set(matches)];
}

function expandCategoryQueryValues(categories) {
  const values = new Set();

  for (const category of categories || []) {
    const normalized = normalizeCategoryId(category);
    if (!normalized) continue;

    values.add(normalized);

    switch (normalized) {
      case 'food_bev':
        values.add('food');
        values.add('food bev');
        values.add('food beverage');
        break;
      case 'beauty_health':
        values.add('beauty');
        values.add('health');
        break;
      case 'home_garden':
        values.add('home');
        values.add('garden');
        break;
      case 'services':
        values.add('service');
        break;
      default:
        break;
    }
  }

  return [...values];
}

function tokenizeText(value) {
  return String(value || '')
    .toLowerCase()
    .replace(/[^a-z0-9\s_]/g, ' ')
    .split(/\s+/)
    .map((token) => token.trim())
    .filter((token) => token && !STOP_WORDS.has(token));
}

module.exports = {
  CATEGORY_ALIAS_MAP,
  STOP_WORDS,
  expandCategoryQueryValues,
  extractMatchedCategories,
  normalizeCategoryId,
  tokenizeText,
};
