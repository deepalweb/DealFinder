const express = require('express');
const router = express.Router();
const User = require('../../models/User');
const Merchant = require('../../models/Merchant');
const Promotion = require('../../models/Promotion');
const NotificationLog = require('../../models/NotificationLog');
const { authenticateJWT, authorizeAdmin } = require('../../middleware/auth');

function safeError(error) {
  if (process.env.NODE_ENV === 'production') {
    return { message: 'An error occurred' };
  }
  return { message: error.message, stack: error.stack };
}

function startOfDay(value = new Date()) {
  return new Date(value.getFullYear(), value.getMonth(), value.getDate());
}

function endOfDay(value = new Date()) {
  return new Date(value.getFullYear(), value.getMonth(), value.getDate() + 1);
}

function buildDateBuckets(days) {
  const today = startOfDay(new Date());
  return Array.from({ length: days }, (_, index) => {
    const date = new Date(today);
    date.setDate(today.getDate() - (days - 1 - index));
    return date;
  });
}

function formatBucketKey(date) {
  return date.toISOString().slice(0, 10);
}

async function aggregateDailyCounts(Model, dateField, days, match = {}) {
  const buckets = buildDateBuckets(days);
  const start = buckets[0];
  const results = await Model.aggregate([
    {
      $match: {
        ...match,
        [dateField]: { $gte: start },
      },
    },
    {
      $group: {
        _id: {
          $dateToString: {
            format: '%Y-%m-%d',
            date: `$${dateField}`,
          },
        },
        count: { $sum: 1 },
      },
    },
  ]);

  const map = new Map(results.map((entry) => [entry._id, entry.count]));
  return buckets.map((date) => ({
    label: date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
    key: formatBucketKey(date),
    count: map.get(formatBucketKey(date)) || 0,
  }));
}

async function getOverviewData() {
  const now = new Date();
  const todayStart = startOfDay(now);
  const todayEnd = endOfDay(now);
  const weekAgo = new Date(todayStart);
  weekAgo.setDate(weekAgo.getDate() - 6);

  const [
    totalUsers,
    totalMerchants,
    totalPromotions,
    activePromotions,
    pendingMerchants,
    pendingPromotions,
    usersThisWeek,
    merchantsThisWeek,
    promotionsThisWeek,
    notificationsThisWeek,
    deliveredPushThisWeek,
    openedPushThisWeek,
  ] = await Promise.all([
    User.countDocuments(),
    Merchant.countDocuments(),
    Promotion.countDocuments(),
    Promotion.countDocuments({
      status: { $in: ['active', 'approved'] },
      startDate: { $lte: now },
      endDate: { $gte: now },
    }),
    Merchant.countDocuments({ status: 'pending_approval' }),
    Promotion.countDocuments({ status: 'pending_approval' }),
    User.countDocuments({ createdAt: { $gte: weekAgo } }),
    Merchant.countDocuments({ createdAt: { $gte: weekAgo } }),
    Promotion.countDocuments({ createdAt: { $gte: weekAgo } }),
    NotificationLog.countDocuments({ createdAt: { $gte: weekAgo } }),
    NotificationLog.countDocuments({
      createdAt: { $gte: weekAgo },
      'status.push.delivered': true,
    }),
    NotificationLog.countDocuments({
      createdAt: { $gte: weekAgo },
      'status.push.opened': true,
    }),
  ]);

  const expiringToday = await Promotion.countDocuments({
    status: { $in: ['active', 'approved'] },
    startDate: { $lte: now },
    endDate: { $gte: todayStart, $lt: todayEnd },
  });

  const deliveryRate = notificationsThisWeek > 0 ? Math.round((deliveredPushThisWeek / notificationsThisWeek) * 100) : 0;
  const openRate = deliveredPushThisWeek > 0 ? Math.round((openedPushThisWeek / deliveredPushThisWeek) * 100) : 0;

  return {
    totals: {
      users: totalUsers,
      merchants: totalMerchants,
      promotions: totalPromotions,
      activePromotions,
    },
    thisWeek: {
      users: usersThisWeek,
      merchants: merchantsThisWeek,
      promotions: promotionsThisWeek,
      notifications: notificationsThisWeek,
    },
    pending: {
      merchants: pendingMerchants,
      promotions: pendingPromotions,
    },
    notifications: {
      total: notificationsThisWeek,
      delivered: deliveredPushThisWeek,
      opened: openedPushThisWeek,
      deliveryRate,
      openRate,
    },
    expiringToday,
  };
}

async function getTrendData() {
  const [userTrend, merchantTrend, promotionTrend, notificationTrend] = await Promise.all([
    aggregateDailyCounts(User, 'createdAt', 14),
    aggregateDailyCounts(Merchant, 'createdAt', 14),
    aggregateDailyCounts(Promotion, 'createdAt', 14),
    aggregateDailyCounts(NotificationLog, 'createdAt', 14),
  ]);

  return {
    users: userTrend,
    merchants: merchantTrend,
    promotions: promotionTrend,
    notifications: notificationTrend,
  };
}

async function getAlertData() {
  const now = new Date();
  const todayStart = startOfDay(now);
  const todayEnd = endOfDay(now);
  const in7Days = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
  const brokenPromotionFilter = {
    $or: [
      { image: { $in: [null, ''] } },
      { url: { $in: [null, ''] } },
    ],
  };
  const expiringSoonFilter = {
    status: { $in: ['active', 'approved'] },
    startDate: { $lte: now },
    endDate: { $gte: todayStart, $lte: in7Days },
  };
  const pausedPromotionFilter = { status: 'admin_paused' };

  const [
    pendingMerchantCount,
    pendingPromotionCount,
    brokenPromotionCount,
    expiringSoonCount,
    pausedPromotionCount,
    pendingMerchants,
    pendingPromotions,
    dormantMerchants,
    brokenPromotions,
    expiringSoon,
    pausedPromotions,
  ] = await Promise.all([
    Merchant.countDocuments({ status: 'pending_approval' }),
    Promotion.countDocuments({ status: 'pending_approval' }),
    Promotion.countDocuments(brokenPromotionFilter),
    Promotion.countDocuments(expiringSoonFilter),
    Promotion.countDocuments(pausedPromotionFilter),
    Merchant.find({ status: 'pending_approval' }).select('name createdAt status').sort({ createdAt: -1 }).limit(6).lean(),
    Promotion.find({ status: 'pending_approval' }).select('title createdAt status merchant').populate('merchant', 'name').sort({ createdAt: -1 }).limit(6).lean(),
    Merchant.find().select('name createdAt logo contactInfo').lean(),
    Promotion.find(brokenPromotionFilter).select('title image url status merchant createdAt').populate('merchant', 'name').sort({ createdAt: -1 }).limit(8).lean(),
    Promotion.find(expiringSoonFilter).select('title endDate merchant').populate('merchant', 'name').sort({ endDate: 1 }).limit(8).lean(),
    Promotion.find(pausedPromotionFilter).select('title updatedAt merchant').populate('merchant', 'name').sort({ updatedAt: -1 }).limit(8).lean(),
  ]);

  const dormantMerchantMatches = dormantMerchants.filter((merchant) => !merchant.logo && !merchant.contactInfo);
  const dormantMerchantList = dormantMerchantMatches.slice(0, 6);

  return {
    pendingMerchants: {
      count: pendingMerchantCount,
      items: pendingMerchants,
    },
    pendingPromotions: {
      count: pendingPromotionCount,
      items: pendingPromotions,
    },
    brokenPromotions: {
      count: brokenPromotionCount,
      items: brokenPromotions.map((promotion) => ({
        ...promotion,
        issue: !promotion.image && !promotion.url ? 'Missing image and URL' : !promotion.image ? 'Missing image' : 'Missing URL',
      })),
    },
    dormantMerchants: {
      count: dormantMerchantMatches.length,
      items: dormantMerchantList,
    },
    expiringSoon: {
      count: expiringSoonCount,
      items: expiringSoon,
    },
    pausedPromotions: {
      count: pausedPromotionCount,
      items: pausedPromotions,
    },
    expiringTodayCount: await Promotion.countDocuments({
      status: { $in: ['active', 'approved'] },
      startDate: { $lte: now },
      endDate: { $gte: todayStart, $lt: todayEnd },
    }),
  };
}

async function getLegacyStats() {
  const now = new Date();
  const in7Days = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

  const totalUsers = await User.countDocuments();
  const totalMerchants = await Merchant.countDocuments();
  const pendingMerchants = await Merchant.countDocuments({ status: 'pending_approval' });
  const activeMerchants = await Merchant.countDocuments({ status: 'active' });
  const totalPromotions = await Promotion.countDocuments();

  const [pending, active, scheduled, expired, rejected, paused, draft, activePromotions] = await Promise.all([
    Promotion.countDocuments({ status: 'pending_approval' }),
    Promotion.countDocuments({ status: 'active' }),
    Promotion.countDocuments({ status: 'scheduled' }),
    Promotion.countDocuments({ status: 'expired' }),
    Promotion.countDocuments({ status: 'rejected' }),
    Promotion.countDocuments({ status: 'admin_paused' }),
    Promotion.countDocuments({ status: 'draft' }),
    Promotion.countDocuments({
      status: { $in: ['active', 'approved'] },
      startDate: { $lte: now },
      endDate: { $gte: now },
    }),
  ]);

  const expiringSoon = await Promotion.find({
    status: { $in: ['active', 'approved'] },
    startDate: { $lte: now },
    endDate: { $gte: now, $lte: in7Days },
  }).populate('merchant', 'name').sort({ endDate: 1 }).limit(10).lean();

  const [recentUsers, recentMerchants, recentPromotions] = await Promise.all([
    User.find().sort({ createdAt: -1 }).limit(5).select('name email role createdAt').lean(),
    Merchant.find().sort({ createdAt: -1 }).limit(5).select('name status createdAt').lean(),
    Promotion.find().sort({ createdAt: -1 }).limit(5).select('title status createdAt merchant').populate('merchant', 'name').lean(),
  ]);

  const activity = [
    ...recentUsers.map((user) => ({ type: 'user', label: `${user.name} registered`, sub: user.role, time: user.createdAt })),
    ...recentMerchants.map((merchant) => ({ type: 'merchant', label: `${merchant.name} joined`, sub: merchant.status, time: merchant.createdAt })),
    ...recentPromotions.map((promotion) => ({
      type: 'promotion',
      label: promotion.title,
      sub: `${promotion.status} · ${typeof promotion.merchant === 'object' ? promotion.merchant?.name : ''}`,
      time: promotion.createdAt,
    })),
  ]
    .sort((a, b) => new Date(b.time).getTime() - new Date(a.time).getTime())
    .slice(0, 10);

  return {
    totalUsers,
    totalMerchants,
    merchantsByStatus: { pending_approval: pendingMerchants, active: activeMerchants },
    totalPromotions,
    activePromotions,
    promotionsByStatus: {
      active,
      scheduled,
      pending_approval: pending,
      expired,
      rejected,
      admin_paused: paused,
      draft,
    },
    expiringSoon,
    activity,
  };
}

router.get('/dashboard/overview', authenticateJWT, authorizeAdmin, async (_req, res) => {
  try {
    res.status(200).json(await getOverviewData());
  } catch (error) {
    console.error('Error fetching admin dashboard overview:', error);
    res.status(500).json(safeError(error));
  }
});

router.get('/dashboard/trends', authenticateJWT, authorizeAdmin, async (_req, res) => {
  try {
    res.status(200).json(await getTrendData());
  } catch (error) {
    console.error('Error fetching admin dashboard trends:', error);
    res.status(500).json(safeError(error));
  }
});

router.get('/dashboard/alerts', authenticateJWT, authorizeAdmin, async (_req, res) => {
  try {
    res.status(200).json(await getAlertData());
  } catch (error) {
    console.error('Error fetching admin dashboard alerts:', error);
    res.status(500).json(safeError(error));
  }
});

router.get('/dashboard/stats', authenticateJWT, authorizeAdmin, async (_req, res) => {
  try {
    const [legacy, overview, trends, alerts] = await Promise.all([
      getLegacyStats(),
      getOverviewData(),
      getTrendData(),
      getAlertData(),
    ]);

    res.status(200).json({
      ...legacy,
      overview,
      trends,
      alerts,
    });
  } catch (error) {
    console.error('Error fetching admin dashboard stats:', error);
    res.status(500).json(safeError(error));
  }
});

module.exports = router;
