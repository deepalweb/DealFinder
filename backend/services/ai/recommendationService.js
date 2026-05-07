const Merchant = require('../../models/Merchant');
const Promotion = require('../../models/Promotion');
const SearchQueryLog = require('../../models/SearchQueryLog');
const UserBehaviorEvent = require('../../models/UserBehaviorEvent');
const { ensureUserPreferenceProfile, refreshUserPreferenceProfile } = require('./userProfileService');
const { expandCategoryQueryValues, normalizeCategoryId, tokenizeText } = require('./searchTaxonomy');

function getColomboDayRange(value = new Date()) {
  const formatter = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Colombo',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  });
  const dateKey = formatter.format(value);
  const start = new Date(`${dateKey}T00:00:00.000+05:30`);
  const endExclusive = new Date(start.getTime() + 24 * 60 * 60 * 1000);
  return { start, endExclusive };
}

function escapeRegex(value) {
  return String(value || '').replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function parseNumber(value) {
  if (value === null || value === undefined || value === '') return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function parseDiscountPercent(discount) {
  if (discount === null || discount === undefined) return 0;
  const match = String(discount).match(/(\d+(?:\.\d+)?)/);
  return match ? Number(match[1]) : 0;
}

function normalizeLocation(location, fallbackRadiusKm = 10) {
  if (!location || typeof location !== 'object') return null;
  const latitude = parseNumber(location.latitude);
  const longitude = parseNumber(location.longitude);
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return null;

  return {
    latitude,
    longitude,
    radiusKm: parseNumber(location.radiusKm) || fallbackRadiusKm,
  };
}

function haversineDistanceKm(from, to) {
  if (!from || !to) return null;
  const toRadians = (degrees) => (degrees * Math.PI) / 180;
  const earthRadiusKm = 6371;
  const deltaLat = toRadians(to.latitude - from.latitude);
  const deltaLon = toRadians(to.longitude - from.longitude);
  const a = Math.sin(deltaLat / 2) ** 2
    + Math.cos(toRadians(from.latitude))
    * Math.cos(toRadians(to.latitude))
    * Math.sin(deltaLon / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return earthRadiusKm * c;
}

function mergeSearchFilters({ explicitFilters = {}, aiFilters = {} }) {
  const explicitCategories = Array.isArray(explicitFilters.categories)
    ? explicitFilters.categories.map(normalizeCategoryId).filter(Boolean)
    : [];
  const aiCategories = Array.isArray(aiFilters.categories)
    ? aiFilters.categories.map(normalizeCategoryId).filter(Boolean)
    : [];

  return {
    categories: explicitCategories.length ? explicitCategories : [...new Set(aiCategories)],
    merchantQuery: String(explicitFilters.merchantQuery || explicitFilters.merchant || aiFilters.merchantQuery || '').trim(),
    minPrice: parseNumber(explicitFilters.minPrice) ?? parseNumber(aiFilters.minPrice),
    maxPrice: parseNumber(explicitFilters.maxPrice) ?? parseNumber(aiFilters.maxPrice),
    minDiscountPercent: parseNumber(explicitFilters.minDiscountPercent) ?? parseNumber(aiFilters.minDiscountPercent),
    featuredOnly: explicitFilters.featuredOnly !== undefined
      ? Boolean(explicitFilters.featuredOnly)
      : Boolean(aiFilters.featuredOnly),
    expiringWithinDays: parseNumber(explicitFilters.expiringWithinDays) ?? parseNumber(aiFilters.expiringWithinDays),
    radiusKm: parseNumber(explicitFilters.radiusKm) ?? parseNumber(aiFilters.radiusKm),
    sortBy: String(explicitFilters.sortBy || aiFilters.sortBy || 'relevance'),
  };
}

async function resolveMerchantIdsByQuery(merchantQuery) {
  if (!merchantQuery) return [];
  const merchants = await Merchant.find({
    name: { $regex: escapeRegex(merchantQuery), $options: 'i' },
  }).select('_id').limit(20).lean();
  return merchants.map((merchant) => merchant._id);
}

function buildPromotionQuery({ normalizedQuery, filters }) {
  const { start, endExclusive } = getColomboDayRange();
  const query = {
    status: { $in: ['active', 'approved'] },
    startDate: { $lt: endExclusive },
    endDate: { $gte: start },
  };

  if (filters.categories?.length) {
    query.category = { $in: expandCategoryQueryValues(filters.categories) };
  }

  if (filters.featuredOnly) {
    query.featured = true;
  }

  const tokens = tokenizeText(normalizedQuery).slice(0, 5);
  if (tokens.length) {
    const regex = new RegExp(tokens.map(escapeRegex).join('|'), 'i');
    query.$or = [
      { title: regex },
      { description: regex },
      { category: regex },
      { code: regex },
    ];
  }

  return query;
}

function matchesNumericFilters(promotion, filters) {
  const candidatePrice = promotion.discountedPrice ?? promotion.originalPrice ?? null;
  if (filters.minPrice != null && (!Number.isFinite(candidatePrice) || candidatePrice < filters.minPrice)) {
    return false;
  }
  if (filters.maxPrice != null && (!Number.isFinite(candidatePrice) || candidatePrice > filters.maxPrice)) {
    return false;
  }

  const discountPercent = parseDiscountPercent(promotion.discount);
  if (filters.minDiscountPercent != null && discountPercent < filters.minDiscountPercent) {
    return false;
  }

  if (filters.expiringWithinDays != null) {
    const cutoff = Date.now() + filters.expiringWithinDays * 24 * 60 * 60 * 1000;
    if (!promotion.endDate || new Date(promotion.endDate).getTime() > cutoff) {
      return false;
    }
  }

  return true;
}

function scorePromotion({
  promotion,
  normalizedQuery,
  filters,
  userProfile,
  userFavorites,
  userLocation,
}) {
  let score = 0;
  const reasons = [];
  const breakdown = {};

  const promotionCategory = normalizeCategoryId(promotion.category);
  const merchantId = String(promotion.merchant?._id || promotion.merchant || '');
  const searchTokens = tokenizeText(normalizedQuery);
  const haystack = [
    promotion.title,
    promotion.description,
    promotion.category,
    promotion.code,
    promotion.merchant?.name,
  ].join(' ').toLowerCase();

  if (searchTokens.length) {
    const title = String(promotion.title || '').toLowerCase();
    const description = String(promotion.description || '').toLowerCase();
    const merchantName = String(promotion.merchant?.name || '').toLowerCase();
    let textScore = 0;

    for (const token of searchTokens) {
      if (title.includes(token)) textScore += 14;
      else if (merchantName.includes(token)) textScore += 12;
      else if (description.includes(token)) textScore += 8;
      else if (haystack.includes(token)) textScore += 4;
    }

    if (textScore > 0) {
      score += textScore;
      breakdown.textMatch = textScore;
      reasons.push('Strong search match');
    }
  }

  if (filters.categories?.includes(promotionCategory)) {
    score += 18;
    breakdown.categoryFilter = 18;
    reasons.push('Matches your selected category');
  }

  const categoryAffinity = Number(userProfile?.categoryAffinity?.[promotionCategory] || 0);
  if (categoryAffinity > 0) {
    const categoryScore = Math.min(categoryAffinity * 2, 18);
    score += categoryScore;
    breakdown.categoryAffinity = categoryScore;
    reasons.push('Aligned with your interests');
  }

  const merchantAffinity = Number(userProfile?.merchantAffinity?.[merchantId] || 0);
  if (merchantAffinity > 0) {
    const merchantScore = Math.min(merchantAffinity * 2, 20);
    score += merchantScore;
    breakdown.merchantAffinity = merchantScore;
    reasons.push('From a merchant you engage with');
  }

  if (userFavorites.has(String(promotion._id))) {
    score += 30;
    breakdown.favorite = 30;
    reasons.push('Already saved by you');
  }

  if (promotion.featured) {
    score += 8;
    breakdown.featured = 8;
    reasons.push('Featured deal');
  }

  const discountPercent = parseDiscountPercent(promotion.discount);
  if (discountPercent > 0) {
    const discountScore = Math.min(discountPercent / 5, 15);
    score += discountScore;
    breakdown.discount = Number(discountScore.toFixed(1));
    if (discountPercent >= 25) {
      reasons.push('High discount');
    }
  }

  const startDateMs = promotion.startDate ? new Date(promotion.startDate).getTime() : null;
  if (startDateMs) {
    const daysSinceStart = (Date.now() - startDateMs) / (24 * 60 * 60 * 1000);
    if (daysSinceStart <= 7) {
      score += 6;
      breakdown.freshness = 6;
      reasons.push('Recently added');
    }
  }

  const endDateMs = promotion.endDate ? new Date(promotion.endDate).getTime() : null;
  if (endDateMs) {
    const daysLeft = (endDateMs - Date.now()) / (24 * 60 * 60 * 1000);
    if (daysLeft >= 0 && daysLeft <= 2) {
      score += 10;
      breakdown.urgency = 10;
      reasons.push('Ending soon');
    }
  }

  let distanceKm = null;
  if (userLocation && Array.isArray(promotion.merchant?.location?.coordinates) && promotion.merchant.location.coordinates.length === 2) {
    distanceKm = haversineDistanceKm(userLocation, {
      latitude: promotion.merchant.location.coordinates[1],
      longitude: promotion.merchant.location.coordinates[0],
    });

    if (distanceKm != null) {
      const withinRadius = !filters.radiusKm || distanceKm <= filters.radiusKm;
      if (!withinRadius) {
        return { score: Number.NEGATIVE_INFINITY, reasons, breakdown, distanceKm };
      }

      const distanceScore = Math.max(0, 15 - distanceKm);
      if (distanceScore > 0) {
        score += distanceScore;
        breakdown.distance = Number(distanceScore.toFixed(1));
        reasons.push('Close to you');
      }
    }
  }

  const averageRating = Array.isArray(promotion.ratings) && promotion.ratings.length
    ? promotion.ratings.reduce((sum, rating) => sum + (rating.value || 0), 0) / promotion.ratings.length
    : 0;
  if (averageRating > 0) {
    const ratingScore = Number((averageRating * 1.5).toFixed(1));
    score += ratingScore;
    breakdown.rating = ratingScore;
  }

  return {
    score: Number(score.toFixed(2)),
    reasons: [...new Set(reasons)].slice(0, 3),
    breakdown,
    distanceKm: distanceKm == null ? null : Number(distanceKm.toFixed(2)),
  };
}

function applySort(results, sortBy) {
  switch (sortBy) {
    case 'ending_soon':
      results.sort((a, b) => new Date(a.promotion.endDate) - new Date(b.promotion.endDate));
      break;
    case 'highest_discount':
      results.sort((a, b) => parseDiscountPercent(b.promotion.discount) - parseDiscountPercent(a.promotion.discount));
      break;
    case 'newest':
      results.sort((a, b) => new Date(b.promotion.createdAt) - new Date(a.promotion.createdAt));
      break;
    default:
      results.sort((a, b) => b.score - a.score);
      break;
  }
  return results;
}

async function searchPromotions({
  userId,
  sessionId,
  query,
  explicitFilters,
  interpretedQuery,
  location,
  limit = 20,
}) {
  const startedAt = Date.now();
  const filters = mergeSearchFilters({
    explicitFilters,
    aiFilters: interpretedQuery?.filters || {},
  });
  const userLocation = normalizeLocation(location, filters.radiusKm || 10);
  const normalizedQuery = interpretedQuery?.normalizedQuery || String(query || '').trim().toLowerCase();
  const candidateQuery = buildPromotionQuery({ normalizedQuery, filters });

  if (filters.merchantQuery) {
    const merchantIds = await resolveMerchantIdsByQuery(filters.merchantQuery);
    if (merchantIds.length) {
      candidateQuery.merchant = { $in: merchantIds };
    }
  }

  const [userProfile, userFavorites, promotions] = await Promise.all([
    userId ? ensureUserPreferenceProfile(userId) : Promise.resolve(null),
    userId
      ? require('../../models/User').findById(userId).select('favorites').lean().then((user) => new Set((user?.favorites || []).map((id) => String(id))))
      : Promise.resolve(new Set()),
    Promotion.find(candidateQuery)
      .populate('merchant', 'name logo address currency location category')
      .select('-comments.text')
      .sort({ featured: -1, createdAt: -1 })
      .limit(160)
      .lean(),
  ]);

  const filtered = promotions.filter((promotion) => matchesNumericFilters(promotion, filters));

  const scored = filtered
    .map((promotion) => {
      const scoredPromotion = scorePromotion({
        promotion,
        normalizedQuery,
        filters,
        userProfile,
        userFavorites,
        userLocation,
      });

      return {
        promotion,
        score: scoredPromotion.score,
        reasons: scoredPromotion.reasons,
        distanceKm: scoredPromotion.distanceKm,
        breakdown: scoredPromotion.breakdown,
      };
    })
    .filter((item) => Number.isFinite(item.score));

  applySort(scored, filters.sortBy);
  const finalResults = scored.slice(0, Math.min(Math.max(Number(limit) || 20, 1), 50));

  const resultPayload = finalResults.map((item) => ({
    ...item.promotion,
    recommendationReasons: item.reasons,
    aiMeta: {
      score: item.score,
      distanceKm: item.distanceKm,
      breakdown: item.breakdown,
    },
  }));

  const latencyMs = Date.now() - startedAt;
  const logPayload = {
    userId: userId || undefined,
    sessionId: sessionId || undefined,
    query: String(query || ''),
    normalizedQuery,
    explicitFilters,
    interpretedFilters: {
      ...filters,
      aiUsed: Boolean(interpretedQuery?.aiUsed),
      source: interpretedQuery?.source || 'heuristic',
    },
    location: userLocation || undefined,
    resultCount: resultPayload.length,
    aiUsed: Boolean(interpretedQuery?.aiUsed),
    fallbackUsed: Boolean(interpretedQuery?.fallbackUsed),
    latencyMs,
    topPromotionIds: resultPayload.slice(0, 10).map((promotion) => promotion._id),
  };

  await SearchQueryLog.create(logPayload);

  if (userId) {
    await UserBehaviorEvent.create({
      userId,
      sessionId,
      platform: 'web',
      eventType: userLocation ? 'nearby_search_used' : 'search_submitted',
      query: String(query || ''),
      filters,
      location: userLocation || undefined,
      metadata: {
        aiUsed: Boolean(interpretedQuery?.aiUsed),
        resultCount: resultPayload.length,
      },
    });

    refreshUserPreferenceProfile(userId).catch((error) => {
      console.warn('[AI Search] Profile refresh failed:', error.message);
    });
  }

  return {
    meta: {
      query: String(query || ''),
      normalizedQuery,
      aiUsed: Boolean(interpretedQuery?.aiUsed),
      fallbackUsed: Boolean(interpretedQuery?.fallbackUsed),
      source: interpretedQuery?.source || 'heuristic',
      resultCount: resultPayload.length,
      latencyMs,
      filters,
    },
    results: resultPayload,
  };
}

module.exports = {
  mergeSearchFilters,
  normalizeLocation,
  searchPromotions,
};
