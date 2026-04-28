const Promotion = require('../models/Promotion');
const PromotionClick = require('../models/PromotionClick');
const SectionAssignment = require('../models/SectionAssignment');
const User = require('../models/User');
const Merchant = require('../models/Merchant');

const SECTION_KEYS = ['banner', 'hot_deals', 'new_this_week', 'flash_sales'];

const SECTION_CONFIG = {
  banner: {
    key: 'banner',
    label: 'Banner',
    maxItems: 5,
    mode: 'manual_only',
    description: 'Manual hero/banner curation for the mobile carousel.',
  },
  hot_deals: {
    key: 'hot_deals',
    label: 'Hot Deals',
    maxItems: 8,
    mode: 'hybrid',
    description: 'Manual pins plus auto-fill from trending performance.',
  },
  new_this_week: {
    key: 'new_this_week',
    label: 'New This Week',
    maxItems: 10,
    mode: 'hybrid',
    description: 'Recent deals with force-show and hide overrides.',
  },
  flash_sales: {
    key: 'flash_sales',
    label: 'Flash Sales',
    maxItems: 10,
    mode: 'hybrid',
    description: 'Urgent short-lived deals with manual pins and ending-soon auto-fill.',
  },
  nearby: {
    key: 'nearby',
    label: 'Nearby',
    maxItems: 20,
    mode: 'automatic',
    description: 'Geo-ranked deals automatically based on the user location.',
  },
};

const sectionCache = new Map();
const SECTION_CACHE_TTL = 2 * 60 * 1000;

function getSectionConfig(sectionKey) {
  return SECTION_CONFIG[sectionKey];
}

function invalidateSectionCaches() {
  sectionCache.clear();
}

function getCached(key) {
  const entry = sectionCache.get(key);
  if (!entry) return null;
  if (Date.now() - entry.ts > SECTION_CACHE_TTL) {
    sectionCache.delete(key);
    return null;
  }
  return entry.data;
}

function setCached(key, data) {
  sectionCache.set(key, { data, ts: Date.now() });
}

function getNowActivePromotionQuery(now = new Date()) {
  return {
    status: { $in: ['active', 'approved'] },
    startDate: { $lte: now },
    endDate: { $gte: now },
  };
}

function isAssignmentActive(assignment, now = new Date()) {
  if (!assignment || assignment.enabled === false) return false;
  if (assignment.startAt && assignment.startAt > now) return false;
  if (assignment.endAt && assignment.endAt < now) return false;
  return true;
}

function deriveAssignmentStatus(assignment, now = new Date()) {
  if (!assignment.enabled) return 'paused';
  if (assignment.startAt && assignment.startAt > now) return 'scheduled';
  if (assignment.endAt && assignment.endAt < now) return 'expired';
  return 'active';
}

function sortAssignments(a, b) {
  if ((b.priority || 0) !== (a.priority || 0)) {
    return (b.priority || 0) - (a.priority || 0);
  }
  return new Date(b.updatedAt || 0).getTime() - new Date(a.updatedAt || 0).getTime();
}

function withSectionFields(promotionDoc, assignment) {
  if (!promotionDoc) return null;
  const promotion = promotionDoc.toObject ? promotionDoc.toObject() : { ...promotionDoc };
  promotion.sectionAssignment = {
    id: assignment._id,
    sectionKey: assignment.sectionKey,
    mode: assignment.mode,
    priority: assignment.priority || 0,
    status: deriveAssignmentStatus(assignment),
    startAt: assignment.startAt || null,
    endAt: assignment.endAt || null,
    bannerImageUrl: assignment.bannerImageUrl || null,
    radiusKm: assignment.radiusKm ?? null,
    minDistanceKm: assignment.minDistanceKm ?? null,
    maxDistanceKm: assignment.maxDistanceKm ?? null,
    excludeFromAuto: assignment.excludeFromAuto === true,
    metadata: assignment.metadata || {},
  };
  if (assignment.bannerImageUrl) {
    promotion.sectionImage = assignment.bannerImageUrl;
  }
  return promotion;
}

async function getAssignmentsForSection(sectionKey) {
  return SectionAssignment.find({ sectionKey })
    .populate({
      path: 'promotion',
      match: getNowActivePromotionQuery(),
      populate: { path: 'merchant', select: 'name logo currency location address contactInfo' },
    })
    .populate('updatedBy', 'name email')
    .sort({ priority: -1, updatedAt: -1 })
    .lean(false);
}

async function resolveBannerSection() {
  const cacheKey = 'section:banner';
  const cached = getCached(cacheKey);
  if (cached) return cached;

  const config = getSectionConfig('banner');
  const assignments = (await getAssignmentsForSection('banner'))
    .filter((assignment) => isAssignmentActive(assignment) && assignment.promotion)
    .sort(sortAssignments)
    .slice(0, config.maxItems);

  const items = assignments.map((assignment) => withSectionFields(assignment.promotion, assignment));
  const response = { section: config, items };
  setCached(cacheKey, response);
  return response;
}

async function getFavoriteCounts(promotionIds) {
  if (!promotionIds.length) return new Map();
  const rows = await User.aggregate([
    { $match: { favorites: { $in: promotionIds } } },
    { $unwind: '$favorites' },
    { $match: { favorites: { $in: promotionIds } } },
    { $group: { _id: '$favorites', count: { $sum: 1 } } },
  ]);

  return new Map(rows.map((row) => [String(row._id), row.count]));
}

async function getTrendingDeals(limit) {
  const now = new Date();
  const since = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  const baseQuery = getNowActivePromotionQuery(now);

  const promotions = await Promotion.find(baseQuery)
    .select('-comments -ratings')
    .populate('merchant', 'name logo currency location address contactInfo')
    .lean();

  if (!promotions.length) return [];

  const promotionIds = promotions.map((promotion) => promotion._id);
  const [clickRows, favoriteCounts] = await Promise.all([
    PromotionClick.aggregate([
      { $match: { promotion: { $in: promotionIds }, createdAt: { $gte: since } } },
      {
        $group: {
          _id: '$promotion',
          clicks: { $sum: 1 },
          views: {
            $sum: {
              $cond: [{ $eq: ['$type', 'view'] }, 1, 0],
            },
          },
          directions: {
            $sum: {
              $cond: [{ $eq: ['$type', 'direction'] }, 1, 0],
            },
          },
        },
      },
    ]),
    getFavoriteCounts(promotionIds),
  ]);

  const clickMap = new Map(clickRows.map((row) => [String(row._id), row]));
  return promotions
    .map((promotion) => {
      const metrics = clickMap.get(String(promotion._id)) || {};
      const views = metrics.views || 0;
      const clicks = metrics.clicks || 0;
      const directions = metrics.directions || 0;
      const favorites = favoriteCounts.get(String(promotion._id)) || 0;
      return {
        ...promotion,
        trendingScore: views + clicks * 3 + directions * 4 + favorites * 5,
        trendingMetrics: { views, clicks, directions, favorites },
      };
    })
    .filter((promotion) => promotion.trendingScore > 0)
    .sort((a, b) => b.trendingScore - a.trendingScore)
    .slice(0, limit);
}

async function resolveHotDealsSection() {
  const cacheKey = 'section:hot_deals';
  const cached = getCached(cacheKey);
  if (cached) return cached;

  const config = getSectionConfig('hot_deals');
  const assignments = await getAssignmentsForSection('hot_deals');
  const activeAssignments = assignments.filter((assignment) => assignment.promotion && isAssignmentActive(assignment));
  const hiddenIds = new Set(
    activeAssignments
      .filter((assignment) => ['hidden', 'excluded'].includes(assignment.mode) || assignment.excludeFromAuto)
      .map((assignment) => String(assignment.promotion._id))
  );

  const manualItems = activeAssignments
    .filter((assignment) => !['hidden', 'excluded'].includes(assignment.mode))
    .sort(sortAssignments)
    .map((assignment) => withSectionFields(assignment.promotion, assignment));

  const usedIds = new Set(manualItems.map((item) => String(item._id)));
  const trendingDeals = await getTrendingDeals(config.maxItems * 2);
  const autoItems = trendingDeals
    .filter((promotion) => !usedIds.has(String(promotion._id)) && !hiddenIds.has(String(promotion._id)))
    .slice(0, Math.max(config.maxItems - manualItems.length, 0))
    .map((promotion) => ({
      ...promotion,
      sectionAssignment: {
        sectionKey: 'hot_deals',
        mode: 'auto',
        priority: 0,
        status: 'active',
        metadata: { source: 'trending', trendingMetrics: promotion.trendingMetrics },
      },
    }));

  const items = [...manualItems, ...autoItems].slice(0, config.maxItems);
  const response = { section: config, items };
  setCached(cacheKey, response);
  return response;
}

async function resolveNewThisWeekSection() {
  const cacheKey = 'section:new_this_week';
  const cached = getCached(cacheKey);
  if (cached) return cached;

  const config = getSectionConfig('new_this_week');
  const assignments = await getAssignmentsForSection('new_this_week');
  const activeAssignments = assignments.filter((assignment) => assignment.promotion && isAssignmentActive(assignment));

  const hiddenIds = new Set(
    activeAssignments
      .filter((assignment) => assignment.mode === 'hidden')
      .map((assignment) => String(assignment.promotion._id))
  );

  const manualForcedItems = activeAssignments
    .filter((assignment) => assignment.mode === 'forced')
    .sort(sortAssignments)
    .map((assignment) => withSectionFields(assignment.promotion, assignment));

  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
  const autoDeals = await Promotion.find({
    ...getNowActivePromotionQuery(),
    createdAt: { $gte: sevenDaysAgo },
    _id: { $nin: Array.from(hiddenIds) },
  })
    .select('-comments -ratings')
    .populate('merchant', 'name logo currency location address contactInfo')
    .sort({ createdAt: -1, _id: -1 })
    .limit(config.maxItems * 2)
    .lean();

  const usedIds = new Set(manualForcedItems.map((item) => String(item._id)));
  const autoItems = autoDeals
    .filter((promotion) => !usedIds.has(String(promotion._id)))
    .map((promotion) => ({
      ...promotion,
      sectionAssignment: {
        sectionKey: 'new_this_week',
        mode: 'auto',
        priority: 0,
        status: 'active',
        metadata: { indicator: 'auto' },
      },
    }))
    .slice(0, Math.max(config.maxItems - manualForcedItems.length, 0));

  const items = [...manualForcedItems, ...autoItems].slice(0, config.maxItems);
  const response = { section: config, items };
  setCached(cacheKey, response);
  return response;
}

async function resolveFlashSalesSection() {
  const cacheKey = 'section:flash_sales';
  const cached = getCached(cacheKey);
  if (cached) return cached;

  const config = getSectionConfig('flash_sales');
  const assignments = await getAssignmentsForSection('flash_sales');
  const activeAssignments = assignments.filter((assignment) => assignment.promotion && isAssignmentActive(assignment));

  const hiddenIds = new Set(
    activeAssignments
      .filter((assignment) => ['hidden', 'excluded'].includes(assignment.mode) || assignment.excludeFromAuto)
      .map((assignment) => String(assignment.promotion._id))
  );

  const manualItems = activeAssignments
    .filter((assignment) => !['hidden', 'excluded'].includes(assignment.mode))
    .sort(sortAssignments)
    .map((assignment) => withSectionFields(assignment.promotion, assignment));

  const usedIds = new Set(manualItems.map((item) => String(item._id)));
  const now = new Date();
  const nextDay = new Date(now.getTime() + 24 * 60 * 60 * 1000);
  const endingSoonDeals = await Promotion.find({
    ...getNowActivePromotionQuery(now),
    endDate: { $gte: now, $lte: nextDay },
    _id: { $nin: Array.from(hiddenIds) },
  })
    .select('-comments -ratings')
    .populate('merchant', 'name logo currency location address contactInfo')
    .sort({ endDate: 1, createdAt: -1 })
    .limit(config.maxItems * 2)
    .lean();

  const autoItems = endingSoonDeals
    .filter((promotion) => !usedIds.has(String(promotion._id)))
    .slice(0, Math.max(config.maxItems - manualItems.length, 0))
    .map((promotion) => ({
      ...promotion,
      sectionAssignment: {
        sectionKey: 'flash_sales',
        mode: 'auto',
        priority: 0,
        status: 'active',
        metadata: { source: 'ending_soon' },
      },
    }));

  const items = [...manualItems, ...autoItems].slice(0, config.maxItems);
  const response = { section: config, items };
  setCached(cacheKey, response);
  return response;
}

async function resolveNearbySection({ latitude, longitude, radiusKm = 10 }) {
  const lat = Number(latitude);
  const lon = Number(longitude);
  const radius = Number(radiusKm) || 10;

  if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
    return { section: getSectionConfig('nearby'), items: [] };
  }

  const cacheKey = `section:nearby:${lat.toFixed(3)}:${lon.toFixed(3)}:${radius}`;
  const cached = getCached(cacheKey);
  if (cached) return cached;

  const config = getSectionConfig('nearby');

  const merchants = await Merchant.aggregate([
    {
      $geoNear: {
        near: { type: 'Point', coordinates: [lon, lat] },
        distanceField: 'distance',
        maxDistance: radius * 1000,
        spherical: true,
        query: { 'location.type': 'Point' },
      },
    },
    { $limit: 50 },
    {
      $lookup: {
        from: 'promotions',
        let: { merchantId: '$_id' },
        pipeline: [
          {
            $match: {
              $expr: { $eq: ['$merchant', '$$merchantId'] },
              ...getNowActivePromotionQuery(),
            },
          },
          { $sort: { createdAt: -1, _id: -1 } },
          { $limit: 10 },
        ],
        as: 'promotions',
      },
    },
    { $unwind: '$promotions' },
    {
      $replaceRoot: {
        newRoot: {
          $mergeObjects: [
            '$promotions',
            {
              merchant: {
                _id: '$_id',
                name: '$name',
                logo: '$logo',
                location: '$location',
                address: '$address',
                contactInfo: '$contactInfo',
                currency: '$currency',
                distance: '$distance',
              },
            },
          ],
        },
      },
    },
  ]);

  const ranked = merchants
    .map((promotion) => {
      return {
        ...promotion,
        sectionAssignment: {
          sectionKey: 'nearby',
          mode: 'auto',
          priority: 0,
          status: 'active',
          metadata: {},
        },
      };
    })
    .filter(Boolean)
    .sort((a, b) => (a.merchant?.distance || 0) - (b.merchant?.distance || 0))
    .slice(0, config.maxItems);

  const response = { section: config, items: ranked };
  setCached(cacheKey, response);
  return response;
}

async function resolveSection(sectionKey, options = {}) {
  switch (sectionKey) {
    case 'banner':
      return resolveBannerSection();
    case 'hot_deals':
      return resolveHotDealsSection();
    case 'new_this_week':
      return resolveNewThisWeekSection();
    case 'flash_sales':
      return resolveFlashSalesSection();
    case 'nearby':
      return resolveNearbySection(options);
    default:
      throw new Error(`Unsupported section key: ${sectionKey}`);
  }
}

async function resolveHomepageSections() {
  const [banner, hotDeals, newThisWeek, flashSales] = await Promise.all([
    resolveBannerSection(),
    resolveHotDealsSection(),
    resolveNewThisWeekSection(),
    resolveFlashSalesSection(),
  ]);

  return {
    banner: banner.items,
    hotDeals: hotDeals.items,
    newThisWeek: newThisWeek.items,
    flashSales: flashSales.items,
    sections: {
      banner,
      hot_deals: hotDeals,
      new_this_week: newThisWeek,
      flash_sales: flashSales,
    },
  };
}

async function getSectionManagerSnapshot() {
  const assignments = await SectionAssignment.find({})
    .populate({
      path: 'promotion',
      populate: { path: 'merchant', select: 'name logo currency' },
    })
    .populate('updatedBy', 'name email')
    .sort({ sectionKey: 1, priority: -1, updatedAt: -1 });

  return SECTION_KEYS.map((sectionKey) => ({
    ...getSectionConfig(sectionKey),
    assignments: assignments
      .filter((assignment) => assignment.sectionKey === sectionKey)
      .map((assignment) => ({
        _id: assignment._id,
        sectionKey: assignment.sectionKey,
        promotion: assignment.promotion,
        enabled: assignment.enabled,
        mode: assignment.mode,
        priority: assignment.priority || 0,
        startAt: assignment.startAt || null,
        endAt: assignment.endAt || null,
        bannerImageUrl: assignment.bannerImageUrl || null,
        radiusKm: assignment.radiusKm ?? null,
        minDistanceKm: assignment.minDistanceKm ?? null,
        maxDistanceKm: assignment.maxDistanceKm ?? null,
        excludeFromAuto: assignment.excludeFromAuto === true,
        metadata: assignment.metadata || {},
        updatedAt: assignment.updatedAt,
        updatedBy: assignment.updatedBy,
        status: deriveAssignmentStatus(assignment),
      })),
  }));
}

async function getConflicts() {
  const now = new Date();
  const assignments = await SectionAssignment.find({ enabled: true, sectionKey: { $in: SECTION_KEYS } })
    .populate('promotion', 'title')
    .sort({ updatedAt: -1 })
    .lean();

  const grouped = new Map();
  for (const assignment of assignments) {
    if (!assignment.promotion) continue;
    if (!isAssignmentActive(assignment, now)) continue;
    const key = String(assignment.promotion._id);
    const bucket = grouped.get(key) || [];
    bucket.push(assignment);
    grouped.set(key, bucket);
  }

  return Array.from(grouped.entries())
    .filter(([, bucket]) => bucket.length > 1)
    .map(([promotionId, bucket]) => ({
      promotionId,
      title: bucket[0].promotion.title,
      sections: bucket.map((assignment) => assignment.sectionKey),
      assignments: bucket.map((assignment) => ({
        id: assignment._id,
        sectionKey: assignment.sectionKey,
        mode: assignment.mode,
        startAt: assignment.startAt || null,
        endAt: assignment.endAt || null,
      })),
    }));
}

module.exports = {
  SECTION_KEYS,
  SECTION_CONFIG,
  getSectionConfig,
  invalidateSectionCaches,
  resolveSection,
  resolveHomepageSections,
  getSectionManagerSnapshot,
  getConflicts,
};
