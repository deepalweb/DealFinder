// Read-only Postgres-backed merchant lookup, matching the JSON shape the
// Mongo-backed GET /api/merchants/:id route returns closely enough for the
// mobile merchant dashboard. Gated behind DATA_SOURCE=postgres.
const { Op } = require('sequelize');
const pg = require('../models-pg');

function toMongoLikeGeoJSON(locationGeog) {
  if (!locationGeog) return null;
  if (locationGeog.coordinates) return locationGeog;
  return null;
}

async function serializeMerchant(merchant) {
  const m = merchant.toJSON();
  const ratingValues = (m.ratings || []).map((r) => r.value).filter((v) => typeof v === 'number');
  const averageRating = ratingValues.length
    ? ratingValues.reduce((sum, v) => sum + v, 0) / ratingValues.length
    : 0;

  const [followerRows, activeDeals] = await Promise.all([
    pg.sequelize.query(
      'SELECT COUNT(*)::int AS count FROM user_following_merchants WHERE merchant_id = :id',
      { replacements: { id: m.id }, type: pg.sequelize.QueryTypes.SELECT },
    ),
    pg.Promotion.count({
      where: { merchantId: m.id, status: 'active', endDate: { [Op.gte]: new Date() } },
    }),
  ]);
  const followers = followerRows[0]?.count || 0;

  return {
    _id: m.id,
    id: m.id,
    name: m.name,
    profile: m.profile,
    description: m.description,
    category: m.category,
    merchantType: m.merchantType,
    website: m.website,
    orderLink: m.orderLink,
    deliveryAvailable: m.deliveryAvailable,
    pickupAvailable: m.pickupAvailable,
    openingHours: m.openingHours,
    contactInfo: m.contactInfo,
    logo: m.logo,
    banner: m.banner,
    createdAt: m.createdAt,
    address: m.address,
    contactNumber: m.contactNumber,
    socialMedia: m.socialMedia,
    status: m.status,
    currency: m.currency,
    location: toMongoLikeGeoJSON(m.locationGeog),
    followers,
    activeDeals,
    averageRating,
    ratingsCount: ratingValues.length,
    ratings: [],
  };
}

async function getMerchantByIdFromPostgres(id) {
  const merchant = await pg.Merchant.findByPk(id, {
    include: [{ model: pg.MerchantRating, as: 'ratings' }],
  });
  if (!merchant) return null;
  return serializeMerchant(merchant);
}

const MERCHANT_UPDATABLE_FIELDS = [
  'name', 'profile', 'description', 'category', 'merchantType', 'website',
  'orderLink', 'deliveryAvailable', 'pickupAvailable', 'openingHours',
  'contactInfo', 'logo', 'banner', 'address', 'contactNumber', 'socialMedia',
  'status', 'currency',
];

async function updateMerchantInPostgres(id, payload) {
  const merchant = await pg.Merchant.findByPk(id);
  if (!merchant) return null;

  const updateData = {};
  for (const field of MERCHANT_UPDATABLE_FIELDS) {
    if (payload[field] !== undefined) updateData[field] = payload[field];
  }

  if (payload.location === null) {
    updateData.locationGeog = null;
  } else if (
    payload.location &&
    payload.location.type === 'Point' &&
    Array.isArray(payload.location.coordinates) &&
    payload.location.coordinates.length === 2
  ) {
    updateData.locationGeog = { type: 'Point', coordinates: payload.location.coordinates };
  }

  await merchant.update(updateData);
  return getMerchantByIdFromPostgres(id);
}

module.exports = { getMerchantByIdFromPostgres, updateMerchantInPostgres };
