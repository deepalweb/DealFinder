const STOP_WORDS = new Set([
  'a', 'an', 'and', 'best', 'by', 'deal', 'deals', 'find', 'for', 'from', 'in',
  'is', 'me', 'near', 'on', 'or', 'of', 'offer', 'offers', 'show', 'that', 'the',
  'to', 'today', 'under', 'with',
]);

const CATEGORY_ALIAS_MAP = {
  food_dining: ['food', 'foods', 'restaurant', 'restaurants', 'cafe', 'cafes', 'coffee', 'dessert', 'drink', 'drinks', 'beverage', 'beverages', 'food bev', 'food and bev', 'budget meal', 'quick bites', 'family pack', 'takeaway', 'fast food', 'buffet'],
  beauty_salon: ['beauty', 'health', 'wellness', 'salon', 'spa', 'cosmetics', 'skincare', 'grooming', 'haircut', 'hair', 'spa day', 'bridal'],
  repairs_services: ['services', 'service', 'repair', 'repairs', 'cleaning', 'consulting', 'mobile repair', 'laptop repair', 'printer repair', 'electrical', 'same day service'],
  shopping_retail: ['shopping', 'retail', 'fashion', 'clothes', 'clothing', 'apparel', 'wear', 'shirts', 'dress', 'dresses', 'shoes', 'electronics', 'electronic', 'gadgets', 'gadget', 'phone', 'phones', 'laptop', 'laptops', 'tv', 'accessories'],
  health_wellness: ['health', 'wellness', 'clinic', 'clinics', 'dental', 'fitness', 'yoga', 'pharmacy', 'medical', 'healthcare'],
  daily_essentials: ['grocery', 'groceries', 'household', 'daily essentials', 'essentials', 'fresh', 'supermarket'],
  auto_services: ['auto', 'car wash', 'service center', 'service centres', 'bike repair', 'garage', 'vehicle service'],
  education_courses: ['education', 'school', 'course', 'courses', 'class', 'classes', 'tuition', 'skill training', 'it courses'],
  entertainment_activities: ['entertainment', 'movie', 'movies', 'cinema', 'games', 'gaming', 'concert', 'events', 'kids activities', 'activity'],
  other: ['other', 'misc'],
};

function normalizeCategoryId(value) {
  const raw = String(value || '').trim().toLowerCase();
  switch (raw) {
    case 'food_dining':
    case 'food':
    case 'food and dining':
    case 'food bev':
    case 'food beverage':
    case 'food and bev':
      return 'food_dining';
    case 'beauty_salon':
    case 'health':
    case 'beauty':
    case 'beauty and health':
    case 'beauty_health':
      return 'beauty_salon';
    case 'daily_essentials':
    case 'home':
    case 'garden':
    case 'home and garden':
    case 'home_garden':
      return 'daily_essentials';
    case 'repairs_services':
    case 'service':
    case 'services':
      return 'repairs_services';
    case 'shopping':
    case 'shopping_retail':
    case 'fashion':
    case 'electronics':
      return 'shopping_retail';
    case 'health_wellness':
      return 'health_wellness';
    case 'auto_services':
      return 'auto_services';
    case 'travel':
    case 'entertainment':
    case 'entertainment_activities':
      return 'entertainment_activities';
    case 'education':
    case 'education_courses':
      return 'education_courses';
    case 'pets':
      return 'other';
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
      case 'food_dining':
        values.add('food');
        values.add('food bev');
        values.add('food beverage');
        break;
      case 'beauty_salon':
        values.add('beauty');
        values.add('health');
        break;
      case 'daily_essentials':
        values.add('home');
        values.add('garden');
        break;
      case 'repairs_services':
        values.add('service');
        break;
      case 'shopping_retail':
        values.add('fashion');
        values.add('electronics');
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
