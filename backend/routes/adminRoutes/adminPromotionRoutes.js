const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();
const Promotion = require('../../models/Promotion');
const Merchant = require('../../models/Merchant');
const PromotionClick = require('../../models/PromotionClick');
const User = require('../../models/User');
const { authenticateJWT, authorizeAdmin } = require('../../middleware/auth');

function safeError(error) {
  if (process.env.NODE_ENV === 'production') {
    return { message: 'An error occurred' };
  }
  return { message: error.message, stack: error.stack };
}

function parseBoolean(value) {
  if (value === undefined || value === null || value === '' || value === 'all') return undefined;
  if (value === true || value === 'true') return true;
  if (value === false || value === 'false') return false;
  return undefined;
}

function parseDateValue(value, endOfDay = false) {
  if (!value) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  if (endOfDay) {
    date.setHours(23, 59, 59, 999);
  } else {
    date.setHours(0, 0, 0, 0);
  }
  return date;
}

function toNumber(value, fallback) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function normalizeValue(value) {
  return String(value || '').trim().toLowerCase();
}

function getEffectivePromotionStatus(promotion) {
  const rawStatus = promotion.status || 'draft';
  if (['pending_approval', 'rejected', 'admin_paused', 'draft'].includes(rawStatus)) {
    return rawStatus;
  }

  const now = new Date();
  const startDate = promotion.startDate ? new Date(promotion.startDate) : null;
  const endDate = promotion.endDate ? new Date(promotion.endDate) : null;

  if (endDate && !Number.isNaN(endDate.getTime()) && endDate < now) return 'expired';
  if (startDate && !Number.isNaN(startDate.getTime()) && startDate > now) return 'scheduled';
  return 'active';
}

function buildPromotionQaFlags(promotion) {
  const flags = [];
  const title = normalizeValue(promotion.title);
  const discount = normalizeValue(promotion.discount);
  const effectiveStatus = promotion.effectiveStatus || getEffectivePromotionStatus(promotion);
  const merchantStatus = promotion.merchantState || promotion.merchant?.status || 'unknown';
  const startDate = promotion.startDate ? new Date(promotion.startDate) : null;
  const endDate = promotion.endDate ? new Date(promotion.endDate) : null;
  const hasValidWindow =
    startDate &&
    endDate &&
    !Number.isNaN(startDate.getTime()) &&
    !Number.isNaN(endDate.getTime()) &&
    startDate <= endDate;

  if (!promotion.image) flags.push('missing_image');
  if (!promotion.url) flags.push('missing_url');
  if (!hasValidWindow) flags.push('invalid_dates');
  if (promotion.featured && effectiveStatus === 'expired') flags.push('expired_featured');
  if (effectiveStatus === 'active' && !hasValidWindow) flags.push('active_invalid_window');
  if (['suspended', 'rejected'].includes(merchantStatus) && ['active', 'scheduled'].includes(effectiveStatus)) {
    flags.push('merchant_inactive_visibility');
  }

  if (discount && !/%|\boff\b|\bsave\b|\bdeal\b|\bfree\b|\b\d+\b/.test(discount)) {
    flags.push('discount_unclear');
  }
  if (!title || title.length < 4) {
    flags.push('weak_title');
  }

  return flags;
}

function sortPromotions(promotions, sortBy, sortOrder) {
  const direction = sortOrder === 'asc' ? 1 : -1;
  const valueForSort = (promotion) => {
    switch (sortBy) {
      case 'title':
        return normalizeValue(promotion.title);
      case 'merchant':
        return normalizeValue(promotion.merchant?.name);
      case 'status':
        return normalizeValue(promotion.effectiveStatus);
      case 'category':
        return normalizeValue(promotion.category);
      case 'featured':
        return promotion.featured ? 1 : 0;
      case 'viewCount':
      case 'clickCount':
      case 'favoriteCount':
      case 'commentCount':
      case 'ratingsCount':
      case 'averageRating':
      case 'ctr':
      case 'ageDays':
      case 'daysRemaining':
      case 'qaCount':
        return promotion[sortBy] ?? 0;
      case 'startDate':
      case 'endDate':
      case 'createdAt':
        return promotion[sortBy] ? new Date(promotion[sortBy]).getTime() : 0;
      default:
        return promotion.createdAt ? new Date(promotion.createdAt).getTime() : 0;
    }
  };

  return [...promotions].sort((a, b) => {
    const left = valueForSort(a);
    const right = valueForSort(b);
    if (left < right) return -1 * direction;
    if (left > right) return 1 * direction;
    return 0;
  });
}

async function buildPromotionAnalyticsMap(promotionIds) {
  if (!promotionIds.length) {
    return {
      clickMap: new Map(),
      viewMap: new Map(),
      favoriteMap: new Map(),
    };
  }

  const ids = promotionIds.map((id) => new mongoose.Types.ObjectId(id));

  const [clickCounts, favoriteCounts] = await Promise.all([
    PromotionClick.aggregate([
      { $match: { promotion: { $in: ids } } },
      {
        $group: {
          _id: '$promotion',
          clickCount: {
            $sum: {
              $cond: [{ $eq: ['$type', 'view'] }, 0, 1],
            },
          },
          viewCount: {
            $sum: {
              $cond: [{ $eq: ['$type', 'view'] }, 1, 0],
            },
          },
        },
      },
    ]),
    User.aggregate([
      { $match: { favorites: { $in: ids } } },
      { $unwind: '$favorites' },
      { $match: { favorites: { $in: ids } } },
      { $group: { _id: '$favorites', favoriteCount: { $sum: 1 } } },
    ]),
  ]);

  return {
    clickMap: new Map(clickCounts.map((entry) => [String(entry._id), { clickCount: entry.clickCount || 0, viewCount: entry.viewCount || 0 }])),
    favoriteMap: new Map(favoriteCounts.map((entry) => [String(entry._id), entry.favoriteCount || 0])),
  };
}

router.get('/promotions', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const {
      q = '',
      status = 'all',
      merchantId,
      merchantState = 'all',
      category = 'all',
      featured = 'all',
      dateFrom,
      dateTo,
      createdFrom,
      createdTo,
      sortBy = 'createdAt',
      sortOrder = 'desc',
      page = 1,
      limit = 20,
    } = req.query;

    const mongoFilter = {};
    const featuredValue = parseBoolean(featured);

    if (merchantId && mongoose.Types.ObjectId.isValid(merchantId)) {
      mongoFilter.merchant = merchantId;
    }
    if (category && category !== 'all') {
      mongoFilter.category = category;
    }
    if (featuredValue !== undefined) {
      mongoFilter.featured = featuredValue;
    }

    const startDateFrom = parseDateValue(dateFrom);
    const endDateTo = parseDateValue(dateTo, true);
    if (startDateFrom || endDateTo) {
      mongoFilter.endDate = {};
      if (startDateFrom) mongoFilter.endDate.$gte = startDateFrom;
      if (endDateTo) mongoFilter.startDate = { $lte: endDateTo };
    }

    const createdAtFrom = parseDateValue(createdFrom);
    const createdAtTo = parseDateValue(createdTo, true);
    if (createdAtFrom || createdAtTo) {
      mongoFilter.createdAt = {};
      if (createdAtFrom) mongoFilter.createdAt.$gte = createdAtFrom;
      if (createdAtTo) mongoFilter.createdAt.$lte = createdAtTo;
    }

    const rawPromotions = await Promotion.find(mongoFilter)
      .populate('merchant', 'name status logo contactInfo category')
      .lean();

    const promotionIds = rawPromotions.map((promotion) => String(promotion._id));
    const { clickMap, favoriteMap } = await buildPromotionAnalyticsMap(promotionIds);

    const enriched = rawPromotions.map((promotion) => {
      const promotionId = String(promotion._id);
      const ratings = Array.isArray(promotion.ratings) ? promotion.ratings : [];
      const comments = Array.isArray(promotion.comments) ? promotion.comments : [];
      const clickStats = clickMap.get(promotionId) || { clickCount: 0, viewCount: 0 };
      const favoriteCount = favoriteMap.get(promotionId) || 0;
      const averageRating = ratings.length
        ? Number((ratings.reduce((sum, rating) => sum + (rating.value || 0), 0) / ratings.length).toFixed(1))
        : 0;
      const effectiveStatus = getEffectivePromotionStatus(promotion);
      const now = Date.now();
      const createdAt = promotion.createdAt ? new Date(promotion.createdAt).getTime() : now;
      const endDate = promotion.endDate ? new Date(promotion.endDate).getTime() : now;
      const ageDays = Math.max(0, Math.floor((now - createdAt) / 86400000));
      const rawDaysRemaining = Math.ceil((endDate - now) / 86400000);
      const daysRemaining = Number.isFinite(rawDaysRemaining) ? rawDaysRemaining : 0;
      const ctr = clickStats.viewCount > 0 ? Number(((clickStats.clickCount / clickStats.viewCount) * 100).toFixed(1)) : 0;

      const enrichedPromotion = {
        ...promotion,
        effectiveStatus,
        merchantState: promotion.merchant?.status || 'unknown',
        commentCount: comments.length,
        ratingsCount: ratings.length,
        averageRating,
        favoriteCount,
        clickCount: clickStats.clickCount,
        viewCount: clickStats.viewCount,
        ctr,
        ageDays,
        daysRemaining,
      };

      const qaFlags = buildPromotionQaFlags(enrichedPromotion);
      return {
        ...enrichedPromotion,
        qaFlags,
        qaCount: qaFlags.length,
      };
    });

    const normalizedQuery = normalizeValue(q);
    let filtered = enriched.filter((promotion) => {
      if (status !== 'all' && promotion.effectiveStatus !== status) return false;
      if (merchantState !== 'all' && promotion.merchantState !== merchantState) return false;

      if (normalizedQuery) {
        const haystack = [
          promotion.title,
          promotion.discount,
          promotion.category,
          promotion.merchant?.name,
        ]
          .map(normalizeValue)
          .join(' ');
        if (!haystack.includes(normalizedQuery)) return false;
      }

      return true;
    });

    filtered = sortPromotions(filtered, sortBy, sortOrder);

    const pageNumber = Math.max(1, toNumber(page, 1));
    const limitNumber = Math.min(100, Math.max(1, toNumber(limit, 20)));
    const totalCount = filtered.length;
    const totalPages = Math.max(1, Math.ceil(totalCount / limitNumber));
    const safePage = Math.min(pageNumber, totalPages);
    const startIndex = (safePage - 1) * limitNumber;
    const data = filtered.slice(startIndex, startIndex + limitNumber);

    res.status(200).json({
      data,
      totalCount,
      totalPages,
      currentPage: safePage,
      pageSize: limitNumber,
      filters: {
        q,
        status,
        merchantId: merchantId || null,
        merchantState,
        category,
        featured,
        dateFrom: dateFrom || null,
        dateTo: dateTo || null,
        createdFrom: createdFrom || null,
        createdTo: createdTo || null,
        sortBy,
        sortOrder,
      },
    });
  } catch (error) {
    console.error('Error in GET /api/admin/promotions:', error);
    res.status(500).json(safeError(error));
  }
});

router.get('/promotions/filters', authenticateJWT, authorizeAdmin, async (_req, res) => {
  try {
    const [categories, merchants] = await Promise.all([
      Promotion.distinct('category'),
      Merchant.find().select('name status').sort({ name: 1 }).lean(),
    ]);

    res.status(200).json({
      categories: categories.filter(Boolean).sort(),
      merchants,
      merchantStates: ['active', 'pending_approval', 'approved', 'rejected', 'suspended', 'needs_review'],
    });
  } catch (error) {
    console.error('Error fetching promotion filters:', error);
    res.status(500).json(safeError(error));
  }
});

router.post('/promotions/bulk', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const { ids, action, value } = req.body || {};
    const validIds = Array.isArray(ids)
      ? ids.filter((id) => mongoose.Types.ObjectId.isValid(id))
      : [];

    if (!validIds.length) {
      return res.status(400).json({ message: 'At least one valid promotion ID is required.' });
    }

    const update = {};
    if (action === 'approve') update.status = 'approved';
    if (action === 'reject') update.status = 'rejected';
    if (action === 'pause') update.status = 'admin_paused';
    if (action === 'resume') update.status = 'active';
    if (action === 'feature') update.featured = true;
    if (action === 'unfeature') update.featured = false;
    if (action === 'set_category') update.category = value;

    if (!Object.keys(update).length) {
      return res.status(400).json({ message: 'Unsupported bulk action.' });
    }

    const result = await Promotion.updateMany(
      { _id: { $in: validIds } },
      { $set: update }
    );

    res.status(200).json({
      message: 'Bulk action completed.',
      matchedCount: result.matchedCount || 0,
      modifiedCount: result.modifiedCount || 0,
    });
  } catch (error) {
    console.error('Error in POST /api/admin/promotions/bulk:', error);
    res.status(500).json(safeError(error));
  }
});

module.exports = router;
