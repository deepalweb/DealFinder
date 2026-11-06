const {
  expandNaturalLanguageQuery,
  extractMatchedCategories,
  normalizeCategoryId,
  tokenizeText,
} = require('./searchTaxonomy');

const QUERY_CACHE_TTL_MS = 5 * 60 * 1000;
const queryUnderstandingCache = new Map();
function cacheResult(key,data){
 if(queryUnderstandingCache.size>=500)queryUnderstandingCache.delete(queryUnderstandingCache.keys().next().value);
 queryUnderstandingCache.set(key,{timestamp:Date.now(),data});
}

function parsePriceIntent(query) {
  const value = String(query || '').toLowerCase();
  const maxMatch = value.match(/(?:under|below|less than|max)\s+(\d+(?:\.\d+)?)/);
  const minMatch = value.match(/(?:over|above|more than|min)\s+(\d+(?:\.\d+)?)/);
  return {
    minPrice: minMatch ? Number(minMatch[1]) : null,
    maxPrice: maxMatch ? Number(maxMatch[1]) : null,
  };
}

function parseDiscountIntent(query) {
  const value = String(query || '').toLowerCase();
  const match = value.match(/(\d{1,3})\s*%/);
  return match ? Number(match[1]) : null;
}

function parseNearbyIntent(query) {
  const value = String(query || '').toLowerCase();
  return [
    'near me',
    'nearby',
    'closest',
    'nearest',
    'around me',
    'near eka',
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
    'நெருக்கம்',
  ].some((term) => value.includes(term));
}

function parseUrgencyIntent(query) {
  const value = String(query || '').toLowerCase();
  return [
    'ending today',
    'ending soon',
    'expires today',
    'today',
    'අද',
    'இன்று',
  ].some((term) => value.includes(term));
}

function heuristicQueryUnderstanding(query) {
  const normalizedQuery = String(query || '').trim().toLowerCase();
  const expanded = expandNaturalLanguageQuery(normalizedQuery);
  const categories = [
    ...extractMatchedCategories(normalizedQuery),
    ...expanded.categories,
  ].map(normalizeCategoryId);
  const priceIntent = parsePriceIntent(normalizedQuery);
  const minDiscountPercent = parseDiscountIntent(normalizedQuery);
  const wantsNearby = parseNearbyIntent(normalizedQuery);
  const wantsUrgency = parseUrgencyIntent(normalizedQuery);
  const expandedQuery = [
    normalizedQuery,
    ...expanded.terms,
  ].filter(Boolean).join(' ');

  return {
    normalizedQuery: expandedQuery,
    intent: {
      type: 'deal_search',
      wantsNearby,
      wantsUrgency,
      wantsFeatured: normalizedQuery.includes('best') || normalizedQuery.includes('top'),
    },
    filters: {
      categories: [...new Set(categories)],
      merchantQuery: '',
      minPrice: priceIntent.minPrice,
      maxPrice: priceIntent.maxPrice,
      minDiscountPercent,
      featuredOnly: normalizedQuery.includes('featured'),
      expiringWithinDays: wantsUrgency ? 2 : null,
      radiusKm: wantsNearby ? 10 : null,
      sortBy: wantsNearby ? 'distance' : wantsUrgency ? 'ending_soon' : 'relevance',
    },
    aiUsed: false,
    fallbackUsed: true,
    source: 'heuristic',
  };
}

function sanitizeAiFilters(parsed) {
  const filters = parsed && typeof parsed === 'object' ? parsed : {};
  const categories = Array.isArray(filters.filters?.categories || filters.categories)
    ? (filters.filters?.categories || filters.categories).map(normalizeCategoryId).filter(value=>['bank_cards','food_dining','daily_essentials','shopping_retail','electronics','beauty_salon','health_wellness','travel','entertainment','other'].includes(value))
    : [];
  const numericOrNull = (value, max=1000000000) => {
    const parsedValue = Number(value);
    if (!Number.isFinite(parsedValue) || parsedValue <= 0) return null;
    return Math.min(parsedValue,max);
  };

  return {
    normalizedQuery: String(filters.normalizedQuery || '').trim().toLowerCase(),
    intent: {
      type: 'deal_search',
      wantsNearby: filters.intent?.wantsNearby === true,
      wantsUrgency: filters.intent?.wantsUrgency === true,
      wantsFeatured: filters.intent?.wantsFeatured === true,
    },
    filters: {
      categories: [...new Set(categories)],
      merchantQuery: String(filters.filters?.merchantQuery || '').trim(),
      minPrice: numericOrNull(filters.filters?.minPrice),
      maxPrice: numericOrNull(filters.filters?.maxPrice),
      minDiscountPercent: numericOrNull(filters.filters?.minDiscountPercent,100),
      featuredOnly: filters.filters?.featuredOnly === true,
      expiringWithinDays: numericOrNull(filters.filters?.expiringWithinDays,365),
      radiusKm: numericOrNull(filters.filters?.radiusKm,100),
      sortBy: (['relevance','distance','ending_soon','discount','price_low','price_high','rating','recent'].includes(filters.filters?.sortBy) ? filters.filters.sortBy : 'relevance'),
    },
  };
}

async function understandSearchQuery({ query, location }) {
  const heuristic = heuristicQueryUnderstanding(query);
  const normalizedQuery = heuristic.normalizedQuery;

  if (!normalizedQuery) {
    return heuristic;
  }

  const cacheKey = JSON.stringify({
    query: normalizedQuery,
    lat: location?.latitude || null,
    lon: location?.longitude || null,
  });
  const cached = queryUnderstandingCache.get(cacheKey);
  if (cached && Date.now() - cached.timestamp < QUERY_CACHE_TTL_MS) {
    return cached.data;
  }

  cacheResult(cacheKey, heuristic);
  return heuristic;
}

module.exports = {
  sanitizeAiFilters,
  heuristicQueryUnderstanding,
  understandSearchQuery,
};
