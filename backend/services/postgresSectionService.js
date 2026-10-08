// Postgres-backed home sections (Hot Deals / New This Week / Flash Sales / Banner),
// matching the JSON shape sectionService.js returns closely enough for the mobile
// app's curated home screen. Gated behind DATA_SOURCE=postgres.
//
// Unlike the Mongo version, there is no admin manual-curation (SectionAssignment)
// table in Postgres yet, so every section is auto-filled from the same heuristics
// the Mongo version uses as its auto-fill fallback: Banner stays empty (it was
// manual-only to begin with), the rest are computed straight from promotion dates.
const { Op } = require('sequelize');
const pg = require('../models-pg');
const { serializePromotion } = require('./postgresPromotionService');
const { getColomboDayRange } = require('../utils/promotionLifecycle');
const { SECTION_CONFIG } = require('./sectionService');

function withAutoAssignment(promotion, sectionKey, metadata = {}) {
  return {
    ...serializePromotion(promotion),
    sectionAssignment: {
      sectionKey,
      mode: 'auto',
      priority: 0,
      status: 'active',
      metadata,
    },
  };
}

const ACTIVE_STATUSES = ['active', 'approved', 'pending_approval', 'scheduled'];

async function resolveBannerSectionPg() {
  // Manual-only section with no Postgres curation table yet — always empty.
  return { section: SECTION_CONFIG.banner, items: [], hasActiveAssignments: false };
}

async function resolveHotDealsSectionPg() {
  const config = SECTION_CONFIG.hot_deals;
  const now = new Date();
  const { endExclusive } = getColomboDayRange(now);

  const promotions = await pg.Promotion.findAll({
    where: {
      status: { [Op.in]: ACTIVE_STATUSES },
      startDate: { [Op.lte]: now },
      endDate: { [Op.gte]: now, [Op.lt]: endExclusive },
    },
    include: [{ model: pg.Merchant }],
    order: [['endDate', 'ASC']],
    limit: config.maxItems,
  });

  const items = promotions.map((p) => withAutoAssignment(p, 'hot_deals', { source: 'ending_today' }));
  return { section: config, items, hasActiveAssignments: false };
}

async function resolveNewThisWeekSectionPg() {
  const config = SECTION_CONFIG.new_this_week;
  const now = new Date();
  const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

  const promotions = await pg.Promotion.findAll({
    where: {
      status: { [Op.in]: ACTIVE_STATUSES },
      startDate: { [Op.lte]: now },
      endDate: { [Op.gte]: now },
      [Op.or]: [
        { createdAt: { [Op.gte]: sevenDaysAgo } },
        { updatedAt: { [Op.gte]: sevenDaysAgo } },
      ],
    },
    include: [{ model: pg.Merchant }],
    order: [['updatedAt', 'DESC'], ['createdAt', 'DESC']],
    limit: config.maxItems,
  });

  const items = promotions.map((p) => withAutoAssignment(p, 'new_this_week', { indicator: 'auto' }));
  return { section: config, items, hasActiveAssignments: false };
}

async function resolveFlashSalesSectionPg() {
  const config = SECTION_CONFIG.flash_sales;
  const now = new Date();
  const nextDay = new Date(now.getTime() + 24 * 60 * 60 * 1000);

  const promotions = await pg.Promotion.findAll({
    where: {
      status: { [Op.in]: ACTIVE_STATUSES },
      startDate: { [Op.lte]: now },
      endDate: { [Op.gte]: now, [Op.lte]: nextDay },
    },
    include: [{ model: pg.Merchant }],
    order: [['endDate', 'ASC']],
    limit: config.maxItems,
  });

  const items = promotions.map((p) => withAutoAssignment(p, 'flash_sales', { source: 'ending_soon' }));
  return { section: config, items, hasActiveAssignments: false };
}

async function resolveNearbySectionPg({ latitude, longitude, radiusKm = 10 } = {}) {
  const config = SECTION_CONFIG.nearby;
  const lat = Number(latitude);
  const lon = Number(longitude);
  const radius = Number(radiusKm) || 10;

  if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
    return { section: config, items: [], hasActiveAssignments: false };
  }

  const now = new Date();
  const rows = await pg.sequelize.query(
    `SELECT p.id,
            ST_Distance(m.location_geog, ST_MakePoint(:lon, :lat)::geography) AS distance_m
     FROM promotions p
     JOIN merchants m ON m.id = p.merchant_id
     WHERE p.status IN (:statuses)
       AND p.start_date <= :now
       AND p.end_date >= :now
       AND m.location_geog IS NOT NULL
       AND ST_DWithin(m.location_geog, ST_MakePoint(:lon, :lat)::geography, :radiusMeters)
     ORDER BY distance_m ASC
     LIMIT :limit`,
    {
      replacements: {
        lon, lat, now, statuses: ACTIVE_STATUSES,
        radiusMeters: radius * 1000, limit: config.maxItems,
      },
      type: pg.sequelize.QueryTypes.SELECT,
    },
  );

  if (!rows.length) {
    return { section: config, items: [], hasActiveAssignments: false };
  }

  const distanceById = new Map(rows.map((row) => [row.id, row.distance_m]));
  const promotions = await pg.Promotion.findAll({
    where: { id: { [Op.in]: rows.map((row) => row.id) } },
    include: [{ model: pg.Merchant }],
  });

  const items = promotions
    .map((p) => {
      const serialized = withAutoAssignment(p, 'nearby', {});
      const distanceM = distanceById.get(p.id);
      if (serialized.merchant) serialized.merchant.distance = distanceM;
      return serialized;
    })
    .sort((a, b) => (distanceById.get(a._id) || 0) - (distanceById.get(b._id) || 0));

  return { section: config, items, hasActiveAssignments: false };
}

async function resolveSectionFromPostgres(sectionKey, options = {}) {
  switch (sectionKey) {
    case 'banner':
      return resolveBannerSectionPg();
    case 'hot_deals':
      return resolveHotDealsSectionPg();
    case 'new_this_week':
      return resolveNewThisWeekSectionPg();
    case 'flash_sales':
      return resolveFlashSalesSectionPg();
    case 'nearby':
      return resolveNearbySectionPg(options);
    default:
      throw new Error(`Unsupported section key: ${sectionKey}`);
  }
}

async function resolveHomepageSectionsFromPostgres() {
  const [banner, hotDeals, newThisWeek, flashSales] = await Promise.all([
    resolveBannerSectionPg(),
    resolveHotDealsSectionPg(),
    resolveNewThisWeekSectionPg(),
    resolveFlashSalesSectionPg(),
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

module.exports = {
  resolveSectionFromPostgres,
  resolveHomepageSectionsFromPostgres,
};
