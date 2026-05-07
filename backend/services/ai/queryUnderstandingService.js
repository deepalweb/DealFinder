const { createResponse } = require('./azureOpenAIClient');
const { getAiConfig, isAzureOpenAIConfigured } = require('./config');
const {
  extractMatchedCategories,
  normalizeCategoryId,
  tokenizeText,
} = require('./searchTaxonomy');

const QUERY_CACHE_TTL_MS = 5 * 60 * 1000;
const queryUnderstandingCache = new Map();

function extractJsonObject(text) {
  const raw = String(text || '').trim();
  if (!raw) return null;

  try {
    return JSON.parse(raw);
  } catch (_) {
    const match = raw.match(/\{[\s\S]*\}/);
    if (!match) return null;
    try {
      return JSON.parse(match[0]);
    } catch {
      return null;
    }
  }
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

function heuristicQueryUnderstanding(query) {
  const normalizedQuery = String(query || '').trim().toLowerCase();
  const categories = extractMatchedCategories(normalizedQuery).map(normalizeCategoryId);
  const priceIntent = parsePriceIntent(normalizedQuery);
  const minDiscountPercent = parseDiscountIntent(normalizedQuery);
  const wantsNearby = normalizedQuery.includes('near me') || normalizedQuery.includes('nearby');
  const wantsUrgency = normalizedQuery.includes('ending today')
    || normalizedQuery.includes('ending soon')
    || normalizedQuery.includes('expires today')
    || normalizedQuery.includes('today');

  return {
    normalizedQuery,
    intent: {
      type: 'deal_search',
      wantsNearby,
      wantsUrgency,
      wantsFeatured: normalizedQuery.includes('best') || normalizedQuery.includes('top'),
    },
    filters: {
      categories,
      merchantQuery: '',
      minPrice: priceIntent.minPrice,
      maxPrice: priceIntent.maxPrice,
      minDiscountPercent,
      featuredOnly: normalizedQuery.includes('featured'),
      expiringWithinDays: wantsUrgency ? 2 : null,
      radiusKm: wantsNearby ? 10 : null,
      sortBy: wantsUrgency ? 'ending_soon' : 'relevance',
    },
    aiUsed: false,
    fallbackUsed: true,
    source: 'heuristic',
  };
}

function sanitizeAiFilters(parsed) {
  const filters = parsed && typeof parsed === 'object' ? parsed : {};
  const categories = Array.isArray(filters.categories)
    ? filters.categories.map(normalizeCategoryId).filter(Boolean)
    : [];
  const numericOrNull = (value) => {
    const parsedValue = Number(value);
    if (!Number.isFinite(parsedValue) || parsedValue <= 0) return null;
    return parsedValue;
  };

  return {
    normalizedQuery: String(filters.normalizedQuery || '').trim().toLowerCase(),
    intent: {
      type: 'deal_search',
      wantsNearby: Boolean(filters.intent?.wantsNearby),
      wantsUrgency: Boolean(filters.intent?.wantsUrgency),
      wantsFeatured: Boolean(filters.intent?.wantsFeatured),
    },
    filters: {
      categories: [...new Set(categories)],
      merchantQuery: String(filters.filters?.merchantQuery || '').trim(),
      minPrice: numericOrNull(filters.filters?.minPrice),
      maxPrice: numericOrNull(filters.filters?.maxPrice),
      minDiscountPercent: numericOrNull(filters.filters?.minDiscountPercent),
      featuredOnly: Boolean(filters.filters?.featuredOnly),
      expiringWithinDays: numericOrNull(filters.filters?.expiringWithinDays),
      radiusKm: numericOrNull(filters.filters?.radiusKm),
      sortBy: String(filters.filters?.sortBy || 'relevance'),
    },
  };
}

async function understandSearchQuery({ query, location, model }) {
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

  const config = getAiConfig();
  if (!config.aiSearchEnabled || !isAzureOpenAIConfigured()) {
    queryUnderstandingCache.set(cacheKey, { timestamp: Date.now(), data: heuristic });
    return heuristic;
  }

  const systemPrompt = [
    'You are a search query understanding service for a deals marketplace.',
    'Convert the user query into compact JSON only.',
    'Never add markdown fences or explanation.',
    'Supported categories: fashion, electronics, food_bev, travel, beauty_health, home_garden, entertainment, services, pets, education, other.',
    'Use this JSON shape exactly:',
    '{"normalizedQuery":"","intent":{"wantsNearby":false,"wantsUrgency":false,"wantsFeatured":false},"filters":{"categories":[],"merchantQuery":"","minPrice":null,"maxPrice":null,"minDiscountPercent":null,"featuredOnly":false,"expiringWithinDays":null,"radiusKm":null,"sortBy":"relevance"}}',
    'Keep unknown fields null or empty.',
  ].join(' ');

  const userPayload = {
    query,
    location: location || null,
    hintTokens: tokenizeText(query).slice(0, 12),
  };

  try {
    const completion = await createResponse({
      model,
      instructions: systemPrompt,
      input: [
        {
          role: 'user',
          content: [
            {
              type: 'input_text',
              text: JSON.stringify(userPayload),
            },
          ],
        },
      ],
      temperature: 0.1,
      maxOutputTokens: 350,
      metadata: { feature: 'ai_search_query_understanding' },
    });

    const parsed = extractJsonObject(completion.outputText);
    if (!parsed) {
      queryUnderstandingCache.set(cacheKey, { timestamp: Date.now(), data: heuristic });
      return heuristic;
    }

    const sanitized = sanitizeAiFilters(parsed);
    const merged = {
      normalizedQuery: sanitized.normalizedQuery || heuristic.normalizedQuery,
      intent: {
        type: 'deal_search',
        wantsNearby: Boolean(sanitized.intent.wantsNearby || heuristic.intent.wantsNearby),
        wantsUrgency: Boolean(sanitized.intent.wantsUrgency || heuristic.intent.wantsUrgency),
        wantsFeatured: Boolean(sanitized.intent.wantsFeatured || heuristic.intent.wantsFeatured),
      },
      filters: {
        categories: [...new Set([...(sanitized.filters.categories || []), ...(heuristic.filters.categories || [])])],
        merchantQuery: sanitized.filters.merchantQuery || heuristic.filters.merchantQuery,
        minPrice: sanitized.filters.minPrice ?? heuristic.filters.minPrice,
        maxPrice: sanitized.filters.maxPrice ?? heuristic.filters.maxPrice,
        minDiscountPercent: sanitized.filters.minDiscountPercent ?? heuristic.filters.minDiscountPercent,
        featuredOnly: Boolean(sanitized.filters.featuredOnly || heuristic.filters.featuredOnly),
        expiringWithinDays: sanitized.filters.expiringWithinDays ?? heuristic.filters.expiringWithinDays,
        radiusKm: sanitized.filters.radiusKm ?? heuristic.filters.radiusKm,
        sortBy: sanitized.filters.sortBy || heuristic.filters.sortBy,
      },
    };
    const result = {
      ...merged,
      aiUsed: true,
      fallbackUsed: false,
      source: 'azure_openai+heuristic',
    };

    queryUnderstandingCache.set(cacheKey, { timestamp: Date.now(), data: result });
    return result;
  } catch (error) {
    console.warn('[AI Search] Query understanding fallback:', error.message);
    queryUnderstandingCache.set(cacheKey, { timestamp: Date.now(), data: heuristic });
    return heuristic;
  }
}

module.exports = {
  heuristicQueryUnderstanding,
  understandSearchQuery,
};
