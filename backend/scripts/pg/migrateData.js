// One-time (re-runnable) data lift: MongoDB -> Postgres.
// Usage: node scripts/pg/migrateData.js [--tables=merchants,users,...]
//
// Idempotent: primary keys are the original Mongo _id strings, and every write
// is an upsert (INSERT ... ON CONFLICT (id) DO UPDATE), so re-running is safe.
//
// IMPORTANT: once a table's owning route batch cuts writes over to Postgres,
// remove it from future --tables= runs. Re-syncing a cut-over table would read
// the now-stale Mongo copy and clobber live Postgres writes made after cutover.

require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });
const mongoose = require('mongoose');
const pg = require('../../models-pg');

const User = require('../../models/User');
const Merchant = require('../../models/Merchant');
const Promotion = require('../../models/Promotion');
const BankOffer = require('../../models/BankOffer');
const DealAlert = require('../../models/DealAlert');
const NotificationLog = require('../../models/NotificationLog');
const NotificationPreference = require('../../models/NotificationPreference');
const PromotionClick = require('../../models/PromotionClick');
const Redemption = require('../../models/Redemption');
const Report = require('../../models/Report');
const SearchQueryLog = require('../../models/SearchQueryLog');
const SectionAssignment = require('../../models/SectionAssignment');
const UserBehaviorEvent = require('../../models/UserBehaviorEvent');
const UserPreferenceProfile = require('../../models/UserPreferenceProfile');

const args = process.argv.slice(2);
const tablesArg = args.find((a) => a.startsWith('--tables='));
const allowlist = tablesArg ? new Set(tablesArg.split('=')[1].split(',')) : null;
const shouldRun = (table) => !allowlist || allowlist.has(table);

const id = (v) => (v == null ? null : String(v));
const geoPoint = (loc) => {
  if (!loc || !Array.isArray(loc.coordinates) || loc.coordinates.length !== 2) return null;
  const [lng, lat] = loc.coordinates;
  if (typeof lng !== 'number' || typeof lat !== 'number') return null;
  return { type: 'Point', coordinates: [lng, lat] };
};

async function upsert(model, rows, batchSize = 500) {
  if (rows.length === 0) return 0;
  for (let i = 0; i < rows.length; i += batchSize) {
    const batch = rows.slice(i, i + batchSize);
    await model.bulkCreate(batch, {
      updateOnDuplicate: Object.keys(batch[0]).filter((k) => k !== 'id'),
    });
  }
  return rows.length;
}

async function migrateMerchants() {
  if (!shouldRun('merchants')) return;
  const docs = await Merchant.find({}).lean();
  const rows = docs.map((m) => ({
    id: id(m._id),
    name: m.name,
    profile: m.profile,
    description: m.description,
    category: m.category,
    merchantType: m.merchantType || 'offline',
    website: m.website,
    orderLink: m.orderLink,
    deliveryAvailable: !!m.deliveryAvailable,
    pickupAvailable: !!m.pickupAvailable,
    openingHours: m.openingHours || null,
    contactInfo: m.contactInfo ? { value: m.contactInfo } : null,
    logo: m.logo,
    banner: m.banner,
    createdAt: m.createdAt || new Date(),
    address: m.address,
    contactNumber: m.contactNumber,
    socialMedia: m.socialMedia || null,
    status: m.status || 'active',
    currency: m.currency || 'USD',
    locationGeog: geoPoint(m.location),
  }));
  const n = await upsert(pg.Merchant, rows);
  console.log(`merchants: ${n} upserted`);

  // Embedded ratings/reviews -> child tables
  const ratingRows = [];
  const reviewRows = [];
  for (const m of docs) {
    for (const r of m.ratings || []) {
      ratingRows.push({
        id: id(r._id),
        merchantId: id(m._id),
        userId: id(r.user),
        value: r.value,
        createdAt: r.createdAt || new Date(),
      });
    }
    for (const rv of m.reviews || []) {
      reviewRows.push({
        id: id(rv._id),
        merchantId: id(m._id),
        userId: id(rv.user),
        text: rv.text,
        createdAt: rv.createdAt || new Date(),
      });
    }
  }
  if (shouldRun('merchant_ratings')) console.log(`merchant_ratings: ${await upsert(pg.MerchantRating, ratingRows)} upserted`);
  if (shouldRun('merchant_reviews')) console.log(`merchant_reviews: ${await upsert(pg.MerchantReview, reviewRows)} upserted`);
}

async function migrateUsers() {
  if (!shouldRun('users')) return;
  const docs = await User.find({}).lean();
  const rows = docs.map((u) => ({
    id: id(u._id),
    name: u.name,
    email: u.email,
    password: u.password,
    role: u.role || 'user',
    merchantId: id(u.merchantId),
    businessName: u.businessName,
    createdAt: u.createdAt || new Date(),
    logo: u.logo,
    resetPasswordToken: u.resetPasswordToken,
    resetPasswordExpires: u.resetPasswordExpires,
    profilePicture: u.profilePicture,
    pushSubscription: u.pushSubscription || null,
    preferences: u.preferences || null,
  }));
  console.log(`users: ${await upsert(pg.User, rows)} upserted`);

  if (shouldRun('user_favorites')) {
    const favRows = [];
    for (const u of docs) {
      for (const pid of u.favorites || []) {
        favRows.push({ user_id: id(u._id), promotion_id: id(pid) });
      }
    }
    if (favRows.length) {
      await pg.sequelize.getQueryInterface().bulkInsert('user_favorites', favRows, { ignoreDuplicates: true });
    }
    console.log(`user_favorites: ${favRows.length} upserted`);
  }

  if (shouldRun('user_following_merchants')) {
    const followRows = [];
    for (const u of docs) {
      for (const mid of u.followingMerchants || []) {
        followRows.push({ user_id: id(u._id), merchant_id: id(mid) });
      }
    }
    if (followRows.length) {
      await pg.sequelize.getQueryInterface().bulkInsert('user_following_merchants', followRows, { ignoreDuplicates: true });
    }
    console.log(`user_following_merchants: ${followRows.length} upserted`);
  }
}

async function migratePromotions() {
  if (!shouldRun('promotions')) return;
  const docs = await Promotion.find({}).lean();
  const rows = docs.map((p) => ({
    id: id(p._id),
    title: p.title,
    description: p.description,
    discount: p.discount,
    code: p.code,
    category: p.category,
    merchantId: id(p.merchant),
    startDate: p.startDate,
    endDate: p.endDate,
    images: p.images || null,
    image: p.image,
    url: p.url,
    fulfillmentType: p.fulfillmentType || 'visit',
    orderLink: p.orderLink,
    visitAvailable: p.visitAvailable !== false,
    deliveryAvailable: !!p.deliveryAvailable,
    pickupAvailable: !!p.pickupAvailable,
    featured: !!p.featured,
    originalPrice: p.originalPrice,
    discountedPrice: p.discountedPrice,
    bankName: p.bankName,
    cardTypes: p.cardTypes || null,
    offerType: p.offerType,
    minimumSpend: p.minimumSpend,
    maximumBenefit: p.maximumBenefit,
    status: p.status || 'draft',
    adminVerified: !!p.adminVerified,
    verifiedAt: p.verifiedAt,
    verifiedBy: id(p.verifiedBy),
    createdAt: p.createdAt || new Date(),
    updatedAt: p.updatedAt || new Date(),
  }));
  console.log(`promotions: ${await upsert(pg.Promotion, rows)} upserted`);

  const commentRows = [];
  const ratingRows = [];
  const feedbackRows = [];
  for (const p of docs) {
    for (const c of p.comments || []) {
      commentRows.push({ id: id(c._id), promotionId: id(p._id), userId: id(c.user), text: c.text, createdAt: c.createdAt || new Date() });
    }
    for (const r of p.ratings || []) {
      ratingRows.push({ id: id(r._id), promotionId: id(p._id), userId: id(r.user), value: r.value, createdAt: r.createdAt || new Date() });
    }
    for (const f of p.redemptionFeedback || []) {
      feedbackRows.push({ id: id(f._id), promotionId: id(p._id), userId: id(f.user), worked: !!f.worked, createdAt: f.createdAt || new Date() });
    }
  }
  if (shouldRun('promotion_comments')) console.log(`promotion_comments: ${await upsert(pg.PromotionComment, commentRows)} upserted`);
  if (shouldRun('promotion_ratings')) console.log(`promotion_ratings: ${await upsert(pg.PromotionRating, ratingRows)} upserted`);
  if (shouldRun('promotion_redemption_feedback')) console.log(`promotion_redemption_feedback: ${await upsert(pg.PromotionRedemptionFeedback, feedbackRows)} upserted`);
}

async function migrateBankOffers() {
  if (!shouldRun('bank_offers')) return;
  const docs = await BankOffer.find({}).lean();
  const rows = docs.map((b) => ({
    id: id(b._id),
    bankName: b.bankName,
    offerType: b.offerType,
    status: b.status || 'draft',
    createdBy: id(b.createdBy),
    updatedBy: id(b.updatedBy),
    category: b.category,
    createdAt: b.createdAt || new Date(),
    updatedAt: b.updatedAt || new Date(),
  }));
  console.log(`bank_offers: ${await upsert(pg.BankOffer, rows)} upserted`);

  if (shouldRun('bank_offer_applicable_merchants')) {
    const rel = [];
    for (const b of docs) {
      for (const mid of b.applicableMerchants || []) {
        rel.push({ bank_offer_id: id(b._id), merchant_id: id(mid) });
      }
    }
    if (rel.length) {
      await pg.sequelize.getQueryInterface().bulkInsert('bank_offer_applicable_merchants', rel, { ignoreDuplicates: true });
    }
    console.log(`bank_offer_applicable_merchants: ${rel.length} upserted`);
  }
}

async function migrateDealAlerts() {
  if (!shouldRun('deal_alerts')) return;
  const docs = await DealAlert.find({}).lean();
  const rows = docs.map((d) => ({
    id: id(d._id),
    userId: id(d.userId),
    promotionId: id(d.promotion),
    alertTypes: d.alertTypes || null,
    active: d.active !== false,
    lastExpiryNotifiedAt: d.lastExpiryNotifiedAt,
    lastPriceDropNotifiedAt: d.lastPriceDropNotifiedAt,
    createdAt: d.createdAt || new Date(),
    updatedAt: d.updatedAt || new Date(),
  }));
  console.log(`deal_alerts: ${await upsert(pg.DealAlert, rows)} upserted`);
}

async function migrateNotifications() {
  if (shouldRun('notification_logs')) {
    const docs = await NotificationLog.find({}).lean();
    const rows = docs.map((n) => ({
      id: id(n._id),
      userId: id(n.userId),
      type: n.type,
      title: n.title,
      body: n.body,
      data: n.data || {},
      channels: n.channels || null,
      statusPushSent: !!n.status?.push?.sent,
      statusPushDelivered: !!n.status?.push?.delivered,
      statusPushOpened: !!n.status?.push?.opened,
      statusPushError: n.status?.push?.error,
      statusEmailSent: !!n.status?.email?.sent,
      statusEmailOpened: !!n.status?.email?.opened,
      statusEmailError: n.status?.email?.error,
      statusWebSent: !!n.status?.web?.sent,
      statusWebClicked: !!n.status?.web?.clicked,
      statusWebError: n.status?.web?.error,
      priority: n.priority || 'normal',
      read: !!n.read,
      readAt: n.readAt,
      sentAt: n.sentAt,
      createdAt: n.createdAt || new Date(),
    }));
    console.log(`notification_logs: ${await upsert(pg.NotificationLog, rows)} upserted`);
  }

  if (shouldRun('notification_preferences')) {
    const docs = await NotificationPreference.find({}).lean();
    const rows = docs.map((n) => ({
      id: id(n._id),
      userId: id(n.userId),
      pushEnabled: !!n.channels?.push?.enabled,
      pushToken: n.channels?.push?.token,
      emailEnabled: n.channels?.email?.enabled !== false,
      webEnabled: !!n.channels?.web?.enabled,
      webSubscription: n.channels?.web?.subscription || null,
      preferences: n.preferences || null,
      quietHours: n.quietHours || null,
      createdAt: n.createdAt || new Date(),
      updatedAt: n.updatedAt || new Date(),
    }));
    console.log(`notification_preferences: ${await upsert(pg.NotificationPreference, rows)} upserted`);

    if (shouldRun('user_preference_categories')) {
      const catRows = [];
      for (const n of docs) {
        for (const cat of n.preferences?.categories || []) {
          catRows.push({ user_id: id(n.userId), category: cat });
        }
      }
      if (catRows.length) {
        await pg.sequelize.getQueryInterface().bulkInsert('user_preference_categories', catRows, { ignoreDuplicates: true });
      }
      console.log(`user_preference_categories: ${catRows.length} upserted`);
    }
  }
}

async function migratePromotionClicksAndRedemptions() {
  if (shouldRun('promotion_clicks')) {
    const docs = await PromotionClick.find({}).lean();
    const rows = docs.map((c) => ({
      id: id(c._id),
      promotionId: id(c.promotion),
      merchantId: id(c.merchant),
      userId: id(c.user),
      timestamp: c.timestamp || new Date(),
      type: c.type || 'click',
    }));
    console.log(`promotion_clicks: ${await upsert(pg.PromotionClick, rows)} upserted`);
  }

  if (shouldRun('redemptions')) {
    const docs = await Redemption.find({}).lean();
    const rows = docs.map((r) => ({
      id: id(r._id),
      promotionId: id(r.promotion),
      merchantId: id(r.merchant),
      userId: id(r.user),
      token: r.token,
      status: r.status || 'issued',
      expiresAt: r.expiresAt,
      redeemedBy: id(r.redeemedBy),
      createdAt: r.createdAt || new Date(),
      updatedAt: r.updatedAt || new Date(),
    }));
    console.log(`redemptions: ${await upsert(pg.Redemption, rows)} upserted`);
  }
}

async function migrateReports() {
  if (!shouldRun('reports')) return;
  const docs = await Report.find({}).lean();
  const rows = docs.map((r) => ({
    id: id(r._id),
    targetType: r.targetType,
    promotionId: id(r.promotion),
    merchantId: id(r.merchant),
    reporter: id(r.reporter),
    resolvedBy: id(r.resolvedBy),
    reason: r.reason,
    status: r.status,
    createdAt: r.createdAt || new Date(),
    updatedAt: r.updatedAt || new Date(),
  }));
  console.log(`reports: ${await upsert(pg.Report, rows)} upserted`);
}

async function migrateSearchQueryLogs() {
  if (!shouldRun('search_query_logs')) return;
  const docs = await SearchQueryLog.find({}).lean();
  const rows = docs.map((s) => ({
    id: id(s._id),
    userId: id(s.userId),
    sessionId: s.sessionId,
    explicitFilters: s.explicitFilters || null,
    interpretedFilters: s.interpretedFilters || null,
    latitude: s.location?.latitude,
    longitude: s.location?.longitude,
    radiusKm: s.location?.radiusKm,
    topPromotionIds: (s.topPromotionIds || []).map(id),
    normalizedQuery: s.normalizedQuery,
    createdAt: s.createdAt || new Date(),
  }));
  console.log(`search_query_logs: ${await upsert(pg.SearchQueryLog, rows)} upserted`);
}

async function migrateSectionAssignments() {
  if (!shouldRun('section_assignments')) return;
  const docs = await SectionAssignment.find({}).lean();
  const rows = docs.map((s) => ({
    id: id(s._id),
    sectionKey: s.sectionKey,
    promotionId: id(s.promotion),
    mode: s.mode,
    metadata: s.metadata || {},
    updatedBy: id(s.updatedBy),
    enabled: s.enabled !== false,
    priority: s.priority || 0,
    startAt: s.startAt,
    endAt: s.endAt,
    createdAt: s.createdAt || new Date(),
    updatedAt: s.updatedAt || new Date(),
  }));
  console.log(`section_assignments: ${await upsert(pg.SectionAssignment, rows)} upserted`);
}

async function migrateUserBehaviorEvents() {
  if (!shouldRun('user_behavior_events')) return;
  const docs = await UserBehaviorEvent.find({}).lean();
  const rows = docs.map((e) => ({
    id: id(e._id),
    userId: id(e.userId),
    sessionId: e.sessionId,
    platform: e.platform,
    eventType: e.eventType,
    promotionId: id(e.promotionId),
    merchantId: id(e.merchantId),
    category: e.category,
    filters: e.filters || null,
    metadata: e.metadata || null,
    latitude: e.location?.latitude,
    longitude: e.location?.longitude,
    radiusKm: e.location?.radiusKm,
    label: e.location?.label,
    createdAt: e.createdAt || new Date(),
  }));
  console.log(`user_behavior_events: ${await upsert(pg.UserBehaviorEvent, rows)} upserted`);
}

async function migrateUserPreferenceProfiles() {
  if (!shouldRun('user_preference_profiles')) return;
  const docs = await UserPreferenceProfile.find({}).lean();
  const rows = docs.map((u) => ({
    id: id(u._id),
    userId: id(u.userId),
    categoryAffinity: u.categoryAffinity ? Object.fromEntries(u.categoryAffinity instanceof Map ? u.categoryAffinity : Object.entries(u.categoryAffinity)) : null,
    merchantAffinity: u.merchantAffinity ? Object.fromEntries(u.merchantAffinity instanceof Map ? u.merchantAffinity : Object.entries(u.merchantAffinity)) : null,
    topMerchantIds: (u.topMerchantIds || []).map(id),
    latitude: u.lastKnownLocation?.latitude,
    longitude: u.lastKnownLocation?.longitude,
    locationUpdatedAt: u.lastKnownLocation?.updatedAt,
    segmentName: u.segment?.name,
    segmentConfidence: u.segment?.confidence,
    statsSearchCount: u.stats?.searchCount || 0,
    statsViewCount: u.stats?.viewCount || 0,
    statsClickCount: u.stats?.clickCount || 0,
    statsFavoriteCount: u.stats?.favoriteCount || 0,
    statsNearbySearchCount: u.stats?.nearbySearchCount || 0,
    updatedAt: u.updatedAt || new Date(),
  }));
  console.log(`user_preference_profiles: ${await upsert(pg.UserPreferenceProfile, rows)} upserted`);
}

async function verifyCounts() {
  console.log('\n--- Row-count verification (Mongo vs Postgres) ---');
  const checks = [
    [Merchant, pg.Merchant, 'merchants'],
    [User, pg.User, 'users'],
    [Promotion, pg.Promotion, 'promotions'],
    [BankOffer, pg.BankOffer, 'bank_offers'],
    [DealAlert, pg.DealAlert, 'deal_alerts'],
    [NotificationLog, pg.NotificationLog, 'notification_logs'],
    [NotificationPreference, pg.NotificationPreference, 'notification_preferences'],
    [PromotionClick, pg.PromotionClick, 'promotion_clicks'],
    [Redemption, pg.Redemption, 'redemptions'],
    [Report, pg.Report, 'reports'],
    [SearchQueryLog, pg.SearchQueryLog, 'search_query_logs'],
    [SectionAssignment, pg.SectionAssignment, 'section_assignments'],
    [UserBehaviorEvent, pg.UserBehaviorEvent, 'user_behavior_events'],
    [UserPreferenceProfile, pg.UserPreferenceProfile, 'user_preference_profiles'],
  ];
  for (const [mongoModel, pgModel, name] of checks) {
    if (allowlist && !allowlist.has(name)) continue;
    const mongoCount = await mongoModel.countDocuments();
    const pgCount = await pgModel.count();
    const flag = mongoCount === pgCount ? 'OK' : 'MISMATCH';
    console.log(`${name}: mongo=${mongoCount} postgres=${pgCount} [${flag}]`);
  }
}

async function run() {
  const mongoUri = process.env.MONGO_URI;
  if (!mongoUri) {
    console.error('MONGO_URI not set in backend/.env. Aborting.');
    process.exit(1);
  }

  await mongoose.connect(mongoUri, { serverSelectionTimeoutMS: 10000 });
  console.log('Connected to MongoDB');

  const pgSequelize = pg.sequelize;
  if (!pgSequelize) {
    console.error('DATABASE_URL not set. Aborting.');
    process.exit(1);
  }
  await pgSequelize.authenticate();
  console.log('Connected to Postgres\n');

  await migrateMerchants();
  await migrateUsers();
  await migratePromotions();
  await migrateBankOffers();
  await migrateDealAlerts();
  await migrateNotifications();
  await migratePromotionClicksAndRedemptions();
  await migrateReports();
  await migrateSearchQueryLogs();
  await migrateSectionAssignments();
  await migrateUserBehaviorEvents();
  await migrateUserPreferenceProfiles();

  await verifyCounts();

  await mongoose.disconnect();
  await pgSequelize.close();
  console.log('\nDone.');
}

run().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
