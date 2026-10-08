// Postgres-backed promotion list + create, matching the JSON shape the Mongo-backed
// GET/POST /api/promotions routes return, for both frontend-next and the mobile app.
// Gated behind DATA_SOURCE=postgres — not used unless that env var is set.
const { Op } = require('sequelize');
const { v4: uuidv4 } = require('uuid');
const pg = require('../models-pg');

function toMongoLikeGeoJSON(locationGeog) {
  if (!locationGeog) return null;
  // Sequelize GEOGRAPHY(POINT) comes back as GeoJSON-shaped already: { type: 'Point', coordinates: [lng, lat] }
  if (locationGeog.coordinates) return locationGeog;
  return null;
}

// Sequelize DECIMAL columns come back as strings from the pg driver (unlike Mongoose,
// which always returned real numbers) — mobile/web clients do strict numeric casts.
function toNumberOrNull(value) {
  if (value === null || value === undefined) return null;
  const n = Number(value);
  return Number.isNaN(n) ? null : n;
}

function serializePromotion(promotion) {
  const p = promotion.toJSON();
  const merchant = p.Merchant
    ? {
        _id: p.Merchant.id,
        name: p.Merchant.name,
        logo: p.Merchant.logo,
        address: p.Merchant.address,
        contactInfo: p.Merchant.contactInfo,
        currency: p.Merchant.currency,
        location: toMongoLikeGeoJSON(p.Merchant.locationGeog),
        website: p.Merchant.website,
        merchantType: p.Merchant.merchantType,
        orderLink: p.Merchant.orderLink,
        deliveryAvailable: p.Merchant.deliveryAvailable,
        pickupAvailable: p.Merchant.pickupAvailable,
      }
    : null;

  return {
    _id: p.id,
    title: p.title,
    description: p.description,
    discount: p.discount,
    code: p.code,
    category: p.category,
    merchant,
    startDate: p.startDate,
    endDate: p.endDate,
    images: p.images,
    image: p.image,
    url: p.url,
    fulfillmentType: p.fulfillmentType,
    orderLink: p.orderLink,
    visitAvailable: p.visitAvailable,
    deliveryAvailable: p.deliveryAvailable,
    pickupAvailable: p.pickupAvailable,
    featured: p.featured,
    originalPrice: toNumberOrNull(p.originalPrice),
    discountedPrice: toNumberOrNull(p.discountedPrice),
    bankName: p.bankName,
    cardTypes: p.cardTypes,
    offerType: p.offerType,
    minimumSpend: toNumberOrNull(p.minimumSpend),
    maximumBenefit: toNumberOrNull(p.maximumBenefit),
    status: p.status,
    adminVerified: p.adminVerified,
    createdAt: p.createdAt,
    updatedAt: p.updatedAt,
    ratings: [],
    averageRating: 0,
    ratingsCount: 0,
    trustSummary: { status: 'unverified', reportCount: 0, redeemCount: 0 },
  };
}

async function getPromotionsFromPostgres({ limit = 0, skip = 0, category, sortBy = 'recent' } = {}) {
  const where = {
    status: { [Op.in]: ['active', 'approved', 'pending_approval', 'scheduled'] },
    endDate: { [Op.gte]: new Date() },
  };
  if (category) {
    where.category = { [Op.iLike]: `%${category}%` };
  }

  const order = (() => {
    switch (sortBy) {
      case 'discount':
      case 'highest_rated':
      case 'rating':
        return [['featured', 'DESC'], ['updatedAt', 'DESC']];
      case 'ending_soon':
        return [['endDate', 'ASC']];
      case 'price_low':
        return [['discountedPrice', 'ASC']];
      case 'price_high':
        return [['discountedPrice', 'DESC']];
      case 'recent':
      default:
        return [['updatedAt', 'DESC'], ['createdAt', 'DESC']];
    }
  })();

  const promotions = await pg.Promotion.findAll({
    where,
    include: [{ model: pg.Merchant }],
    order,
    limit: limit > 0 ? limit : undefined,
    offset: skip > 0 ? skip : undefined,
  });

  return promotions.map(serializePromotion);
}

async function getPromotionByIdFromPostgres(id) {
  const promotion = await pg.Promotion.findByPk(id, { include: [{ model: pg.Merchant }] });
  return promotion ? serializePromotion(promotion) : null;
}

async function getPromotionsByMerchantFromPostgres(merchantId) {
  const promotions = await pg.Promotion.findAll({
    where: { merchantId },
    include: [{ model: pg.Merchant }],
    order: [['updatedAt', 'DESC'], ['createdAt', 'DESC']],
  });
  return promotions.map(serializePromotion);
}

async function createPromotionInPostgres(payload) {
  const promotion = await pg.Promotion.create({ id: uuidv4(), ...payload });
  return getPromotionByIdFromPostgres(promotion.id);
}

async function updatePromotionInPostgres(id, updateData) {
  const promotion = await pg.Promotion.findByPk(id);
  if (!promotion) return null;
  await promotion.update(updateData);
  return getPromotionByIdFromPostgres(id);
}

async function deletePromotionInPostgres(id) {
  const deletedCount = await pg.Promotion.destroy({ where: { id } });
  return deletedCount > 0;
}

module.exports = {
  serializePromotion,
  getPromotionsFromPostgres,
  getPromotionByIdFromPostgres,
  getPromotionsByMerchantFromPostgres,
  createPromotionInPostgres,
  updatePromotionInPostgres,
  deletePromotionInPostgres,
};
