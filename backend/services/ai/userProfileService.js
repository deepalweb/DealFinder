const mongoose = require('mongoose');
const Promotion = require('../../models/Promotion');
const User = require('../../models/User');
const UserBehaviorEvent = require('../../models/UserBehaviorEvent');
const UserPreferenceProfile = require('../../models/UserPreferenceProfile');
const { normalizeCategoryId, tokenizeText } = require('./searchTaxonomy');

function addScore(map, key, value) {
  if (!key) return;
  map.set(String(key), (map.get(String(key)) || 0) + value);
}

function toTopEntries(map, limit = 5) {
  return [...map.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, limit);
}

function deriveSegment(stats, topCategories) {
  const totalSignals = stats.searchCount + stats.viewCount + stats.clickCount + stats.favoriteCount;
  if (totalSignals < 3) {
    return { name: 'cold_start', confidence: 0.25 };
  }
  if (stats.nearbySearchCount >= 3) {
    return { name: 'nearby_hunter', confidence: 0.75 };
  }
  if (topCategories.length === 1 || (topCategories[0] && topCategories[1] && topCategories[0][1] >= topCategories[1][1] * 1.7)) {
    return { name: 'category_specialist', confidence: 0.7 };
  }
  return { name: 'general_browser', confidence: 0.55 };
}

async function refreshUserPreferenceProfile(userId) {
  if (!userId || !mongoose.Types.ObjectId.isValid(userId)) {
    return null;
  }

  const [user, events] = await Promise.all([
    User.findById(userId).populate({
      path: 'favorites',
      select: 'category merchant',
    }).lean(),
    UserBehaviorEvent.find({ userId })
      .sort({ createdAt: -1 })
      .limit(500)
      .lean(),
  ]);

  if (!user) {
    return null;
  }

  const categoryAffinity = new Map();
  const merchantAffinity = new Map();
  const queryTerms = new Map();
  const stats = {
    searchCount: 0,
    viewCount: 0,
    clickCount: 0,
    favoriteCount: 0,
    nearbySearchCount: 0,
  };

  let lastKnownLocation = null;
  const radiusSamples = [];
  const promotionIds = [...new Set(
    events
      .map((event) => event.promotionId)
      .filter(Boolean)
      .map((id) => String(id))
  )];

  const promotions = promotionIds.length
    ? await Promotion.find({ _id: { $in: promotionIds } }).select('category merchant').lean()
    : [];
  const promotionMap = new Map(promotions.map((promotion) => [String(promotion._id), promotion]));

  const favoritePromotions = Array.isArray(user.favorites) ? user.favorites : [];
  for (const favorite of favoritePromotions) {
    addScore(categoryAffinity, normalizeCategoryId(favorite.category), 5);
    addScore(merchantAffinity, favorite.merchant, 5);
    stats.favoriteCount += 1;
  }

  for (const event of events) {
    if (!lastKnownLocation && event.location?.latitude != null && event.location?.longitude != null) {
      lastKnownLocation = {
        latitude: event.location.latitude,
        longitude: event.location.longitude,
        updatedAt: event.createdAt,
      };
    }

    if (Number.isFinite(event.location?.radiusKm)) {
      radiusSamples.push(event.location.radiusKm);
    }

    const eventPromotion = event.promotionId ? promotionMap.get(String(event.promotionId)) : null;
    const category = normalizeCategoryId(event.category || eventPromotion?.category);
    const merchantId = event.merchantId || eventPromotion?.merchant;

    switch (event.eventType) {
      case 'search_submitted':
        stats.searchCount += 1;
        tokenizeText(event.query).slice(0, 8).forEach((token) => addScore(queryTerms, token, 1));
        break;
      case 'nearby_search_used':
        stats.nearbySearchCount += 1;
        break;
      case 'promotion_viewed':
        stats.viewCount += 1;
        addScore(categoryAffinity, category, 2);
        addScore(merchantAffinity, merchantId, 2);
        break;
      case 'promotion_clicked':
      case 'search_result_clicked':
      case 'direction_requested':
        stats.clickCount += 1;
        addScore(categoryAffinity, category, 3);
        addScore(merchantAffinity, merchantId, 3);
        break;
      case 'promotion_favorited':
        stats.favoriteCount += 1;
        addScore(categoryAffinity, category, 5);
        addScore(merchantAffinity, merchantId, 5);
        break;
      case 'category_filter_used':
        addScore(categoryAffinity, category, 3);
        break;
      default:
        break;
    }
  }

  const topCategories = toTopEntries(categoryAffinity, 5);
  const topMerchants = toTopEntries(merchantAffinity, 5);
  const topTerms = toTopEntries(queryTerms, 10);
  const preferredRadiusKm = radiusSamples.length
    ? Number((radiusSamples.reduce((sum, value) => sum + value, 0) / radiusSamples.length).toFixed(1))
    : 10;
  const segment = deriveSegment(stats, topCategories);

  const update = {
    userId,
    categoryAffinity: Object.fromEntries(categoryAffinity.entries()),
    merchantAffinity: Object.fromEntries(merchantAffinity.entries()),
    topCategories: topCategories.map(([categoryId]) => categoryId),
    topMerchantIds: topMerchants.map(([merchantId]) => merchantId),
    topQueryTerms: topTerms.map(([term]) => term),
    preferredRadiusKm,
    lastKnownLocation,
    segment,
    stats,
    lastActiveAt: events[0]?.createdAt || user.createdAt || new Date(),
    updatedAt: new Date(),
  };

  return UserPreferenceProfile.findOneAndUpdate(
    { userId },
    update,
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );
}

async function ensureUserPreferenceProfile(userId) {
  if (!userId || !mongoose.Types.ObjectId.isValid(userId)) {
    return null;
  }

  const profile = await UserPreferenceProfile.findOne({ userId }).lean();
  if (profile) {
    return profile;
  }
  return refreshUserPreferenceProfile(userId);
}

module.exports = {
  ensureUserPreferenceProfile,
  refreshUserPreferenceProfile,
};
