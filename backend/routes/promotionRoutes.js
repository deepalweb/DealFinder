const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const { body, validationResult } = require('express-validator');
const Promotion = require('../models/Promotion');
const Merchant = require('../models/Merchant');
const PromotionClick = require('../models/PromotionClick');
const User = require('../models/User');
const { authenticateJWT, authorizeAdmin, authorizePromotionOwnerOrAdmin, gentleAuthenticateJWT } = require('../middleware/auth');
const { notifyFavoriteStoreFollowers } = require('../jobs/favoriteStoreNotifications');
const { notifyFlashSale } = require('../jobs/flashSaleNotifications');
const { notifyPriceDrop } = require('../jobs/priceDropNotifications');
const {
  invalidateSectionCaches,
  resolveSection,
  resolveHomepageSections,
} = require('../services/sectionService');

// Add safeError helper
function safeError(error) {
  if (process.env.NODE_ENV === 'production') {
    return { message: 'An error occurred' };
  }
  return { message: error.message, stack: error.stack };
}

function stripBase64Media(value) {
  return typeof value === 'string' && value.startsWith('data:image') ? null : value;
}

const COLOMBO_TIME_ZONE = 'Asia/Colombo';
const COLOMBO_OFFSET = '+05:30';
const DATE_ONLY_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

function getColomboDateKey(value = new Date()) {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: COLOMBO_TIME_ZONE,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(value);

  const year = parts.find((part) => part.type === 'year')?.value;
  const month = parts.find((part) => part.type === 'month')?.value;
  const day = parts.find((part) => part.type === 'day')?.value;

  return `${year}-${month}-${day}`;
}

function getColomboDayRange(value = new Date()) {
  const dateKey = getColomboDateKey(value);
  const start = new Date(`${dateKey}T00:00:00.000${COLOMBO_OFFSET}`);
  const endExclusive = new Date(start.getTime() + 24 * 60 * 60 * 1000);
  return { start, endExclusive };
}

function normalizePromotionDateInput(value, boundary = 'start') {
  if (!value) return value;
  if (value instanceof Date) return value;

  if (typeof value === 'string' && DATE_ONLY_PATTERN.test(value)) {
    const time = boundary === 'end' ? '23:59:59.999' : '00:00:00.000';
    return new Date(`${value}T${time}${COLOMBO_OFFSET}`);
  }

  return new Date(value);
}

function buildActivePromotionQuery(value = new Date()) {
  const { start, endExclusive } = getColomboDayRange(value);

  return {
    status: { $in: ['active', 'approved'] },
    startDate: { $lt: endExclusive },
    endDate: { $gte: start },
  };
}

function resolveLifecycleStatus(startDate, endDate, value = new Date()) {
  const { start, endExclusive } = getColomboDayRange(value);

  if (endDate < start) return 'expired';
  if (startDate >= endExclusive) return 'scheduled';
  return 'active';
}

function sanitizePromotionPayload(promotion) {
  if (!promotion || typeof promotion !== 'object') return promotion;

  const sanitized = { ...promotion };
  if (sanitized.merchant && typeof sanitized.merchant === 'object') {
    sanitized.merchant = {
      ...sanitized.merchant,
      logo: stripBase64Media(sanitized.merchant.logo),
    };
  }

  return sanitized;
}

// --- Move analytics routes to the top to avoid /:id conflicts ---
// Get analytics for a merchant (Protected: merchant self or admin)
// This requires a different auth logic: authorizeMerchantSelfOrAdmin, but applied to merchantId in params
// Or a new middleware: authorizeMerchantAnalyticsAccess
// For now, let's make it admin only or merchant if their merchantId matches
async function authorizeMerchantAnalytics(req, res, next) {
  if (!req.user) return res.status(401).json({ message: "Authentication required." });
  if (req.user.role === 'admin' || (req.user.role === 'merchant' && req.user.merchantId === req.params.merchantId)) {
    return next();
  }
  return res.status(403).json({ message: "Forbidden: You cannot access this merchant's analytics."});
}
router.get('/analytics/merchant/:merchantId', authenticateJWT, authorizeMerchantAnalytics, async (req, res) => {
  try {
    const clicks = await PromotionClick.find({ merchant: req.params.merchantId }).populate('promotion user');
    res.status(200).json(clicks);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Get analytics for a promotion (Protected: promotion owner or admin)
router.get('/:id/analytics', authenticateJWT, authorizePromotionOwnerOrAdmin, async (req, res) => {
  try {
    const clicks = await PromotionClick.find({ promotion: req.params.id }).populate('user');
    res.status(200).json(clicks);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Server-side cache for homepage (5 minute TTL)
let homepageCache = null;
let homepageCacheTs = 0;
const HOMEPAGE_CACHE_TTL = 5 * 60 * 1000; // Increased from 2 minutes

// Invalidate homepage cache (call after promotion create/update/delete)
function invalidateHomepageCache() { homepageCache = null; homepageCacheTs = 0; }

// Get homepage data (optimized endpoint)
router.get('/homepage', async (req, res) => {
  try {
    if (homepageCache && Date.now() - homepageCacheTs < HOMEPAGE_CACHE_TTL) {
      return res.status(200).json(homepageCache);
    }

    const query = buildActivePromotionQuery();

    const [sections, latest] = await Promise.all([
      resolveHomepageSections(),
      Promotion.find(query)
        .select('-comments -ratings')
        .populate('merchant', 'name logo currency')
        .sort({ createdAt: -1 })
        .limit(20)
        .lean()
    ]);

    homepageCache = {
      featured: sections.banner,
      latest: latest.map(sanitizePromotionPayload),
      banner: sections.banner,
      hotDeals: sections.hotDeals,
      newThisWeek: sections.newThisWeek,
      flashSales: sections.flashSales,
      sections: sections.sections,
    };
    homepageCacheTs = Date.now();

    res.status(200).json(homepageCache);
  } catch (error) {
    console.error('Error in GET /api/promotions/homepage:', error);
    res.status(500).json(safeError(error));
  }
});

// Server-side cache for nearby deals (2 minute TTL)
let nearbyCache = new Map();
const NEARBY_CACHE_TTL = 2 * 60 * 1000;

function getNearbyCache(lat, lon, radius) {
  const key = `${lat.toFixed(3)}_${lon.toFixed(3)}_${radius}`;
  const cached = nearbyCache.get(key);
  if (cached && Date.now() - cached.timestamp < NEARBY_CACHE_TTL) {
    return cached.data;
  }
  return null;
}

function setNearbyCache(lat, lon, radius, data) {
  const key = `${lat.toFixed(3)}_${lon.toFixed(3)}_${radius}`;
  nearbyCache.set(key, { data, timestamp: Date.now() });
  // Limit cache size
  if (nearbyCache.size > 100) {
    const firstKey = nearbyCache.keys().next().value;
    nearbyCache.delete(firstKey);
  }
}

// Get nearby promotions - Optimized with single aggregation pipeline
router.get('/nearby', async (req, res) => {
  try {
    const { latitude, longitude, radius } = req.query;

    if (!latitude || !longitude) {
      return res.status(400).json({ message: 'Latitude and longitude are required query parameters.' });
    }

    const lat = parseFloat(latitude);
    const lon = parseFloat(longitude);

    if (isNaN(lat) || isNaN(lon)) {
      return res.status(400).json({ message: 'Latitude and longitude must be valid numbers.' });
    }

    const searchRadiusKm = parseFloat(radius) || 10;
    
    // Check cache first
    const cached = getNearbyCache(lat, lon, searchRadiusKm);
    if (cached) {
      console.log('[Nearby API] Returning cached results');
      return res.status(200).json(cached);
    }

    const radiusInMeters = searchRadiusKm * 1000;
    const merchantLimit = parseInt(req.query.limit) || 30; // Reduced for faster geo query
    const promotionLimit = parseInt(req.query.promotionLimit) || 100;

    const { start, endExclusive } = getColomboDayRange();

    try {
      // Single optimized aggregation pipeline
      const promotions = await Merchant.aggregate([
        {
          $geoNear: {
            near: { type: 'Point', coordinates: [lon, lat] },
            distanceField: 'distance',
            maxDistance: radiusInMeters,
            spherical: true,
            query: { 'location.type': 'Point' }
          }
        },
        { $limit: merchantLimit }, // Limit merchants first for faster geo query
        {
          $lookup: {
            from: 'promotions',
            let: { merchantId: '$_id' },
            pipeline: [
              {
                $match: {
                  $expr: { $eq: ['$merchant', '$$merchantId'] },
                  status: { $in: ['active', 'approved'] },
                  startDate: { $lt: endExclusive },
                  endDate: { $gte: start }
                }
              },
              { $sort: { createdAt: -1, _id: -1 } },
              { $limit: 10 }, // Keep only the newest promotions per merchant
              {
                $project: {
                  title: 1,
                  description: 1,
                  discount: 1,
                  code: 1,
                  category: 1,
                  merchant: 1,
                  startDate: 1,
                  endDate: 1,
                  images: 1,
                  image: 1,
                  url: 1,
                  featured: 1,
                  originalPrice: 1,
                  discountedPrice: 1,
                  status: 1,
                  createdAt: 1
                }
              }
            ],
            as: 'promotions'
          }
        },
        {
          $unwind: {
            path: '$promotions',
            preserveNullAndEmptyArrays: false // Don't include merchants with no promotions
          }
        },
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
                    distance: '$distance'
                  }
                }
              ]
            }
          }
        },
        {
          $sort: { createdAt: -1, _id: -1 }
        },
        { $limit: promotionLimit }
      ]);

      // Cache the result
      setNearbyCache(lat, lon, searchRadiusKm, promotions);

      res.status(200).json(promotions);

    } catch (geoErr) {
      console.error('[Nearby API] Aggregation error:', geoErr.message);
      return res.status(500).json({ 
        message: 'Query failed',
        error: process.env.NODE_ENV === 'production' ? undefined : geoErr.message,
        hint: 'Check if geospatial index exists on Merchant.location field'
      });
    }

  } catch (error) {
    console.error('[Nearby API] Error:', error);
    res.status(500).json(safeError(error));
  }
});

// Manual cache clear endpoint (for admin/testing - clears all in-memory caches)
router.post('/admin/clear-cache', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    invalidateHomepageCache();
    nearbyCache.clear();
    invalidateSectionCaches();
    
    console.log('[Cache Clear] All caches cleared by admin');
    res.status(200).json({ 
      message: 'All caches cleared successfully',
      cleared: ['homepage', 'nearby', 'sections'],
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('[Cache Clear] Error:', error);
    res.status(500).json(safeError(error));
  }
});

// Get all promotions
router.get('/', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 0; // 0 means no limit
    const skip = parseInt(req.query.skip) || 0;

    const query = buildActivePromotionQuery();
    
    let promotionsQuery = Promotion.find(query)
      .select('-comments -ratings')
      .populate('merchant', 'name logo address contactInfo currency location')
      .sort({ createdAt: -1 })
      .lean();
    
    if (limit > 0) {
      promotionsQuery = promotionsQuery.limit(limit).skip(skip);
    }
    
    const promotions = (await promotionsQuery).map(sanitizePromotionPayload);
    res.status(200).json(promotions);
  } catch (error) {
    console.error('Error in GET /api/promotions:', error);
    res.status(500).json(safeError(error));
  }
});

router.get('/sections', async (_req, res) => {
  try {
    const sections = await resolveHomepageSections();
    res.status(200).json(sections);
  } catch (error) {
    console.error('Error in GET /api/promotions/sections:', error);
    res.status(500).json(safeError(error));
  }
});

router.get('/sections/:sectionKey', async (req, res) => {
  try {
    const { sectionKey } = req.params;
    if (!['banner', 'hot_deals', 'new_this_week', 'flash_sales', 'nearby'].includes(sectionKey)) {
      return res.status(400).json({ message: 'Invalid section key.' });
    }

    const section = await resolveSection(sectionKey, {
      latitude: req.query.latitude,
      longitude: req.query.longitude,
      radiusKm: req.query.radius,
    });
    res.status(200).json(section);
  } catch (error) {
    console.error(`Error in GET /api/promotions/sections/${req.params.sectionKey}:`, error);
    res.status(500).json(safeError(error));
  }
});

// Get public stats for a promotion
router.get('/:id/stats', async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ message: 'Invalid promotion ID.' });
    }

    const promotion = await Promotion.findById(req.params.id)
      .select('ratings comments')
      .lean();

    if (!promotion) {
      return res.status(404).json({ message: 'Promotion not found' });
    }

    const ratings = Array.isArray(promotion.ratings) ? promotion.ratings : [];
    const comments = Array.isArray(promotion.comments) ? promotion.comments : [];

    const [favoriteCount, totalClickCount, viewCount, directionCount] =
        await Promise.all([
          User.countDocuments({ favorites: promotion._id }),
          PromotionClick.countDocuments({ promotion: promotion._id }),
          PromotionClick.countDocuments({ promotion: promotion._id, type: 'view' }),
          PromotionClick.countDocuments({ promotion: promotion._id, type: 'direction' }),
        ]);

    const averageRating = ratings.length
      ? ratings.reduce((sum, rating) => sum + (rating.value || 0), 0) / ratings.length
      : 0;

    res.status(200).json({
      commentCount: comments.length,
      ratingsCount: ratings.length,
      averageRating,
      favoriteCount,
      clickCount: totalClickCount,
      viewCount,
      directionCount,
    });
  } catch (error) {
    console.error(`Error fetching promotion stats ${req.params.id}:`, error);
    res.status(500).json(safeError(error));
  }
});

// Get a promotion by ID
router.get('/:id', async (req, res) => {
  try {
    const promotion = await Promotion.findById(req.params.id).populate('merchant');
    if (!promotion) return res.status(404).json({ message: 'Promotion not found' });
    res.status(200).json(promotion);
  } catch (error) {
    console.error(`Error fetching promotion ${req.params.id}:`, error);
    res.status(500).json(safeError(error));
  }
});

// Get promotions by merchant ID
router.get('/merchant/:merchantId', async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.merchantId)) {
      return res.status(400).json({ message: 'Valid merchant ID is required' });
    }
    const promotions = await Promotion.find({ merchant: req.params.merchantId })
      .select('-comments -ratings')
      .sort({ createdAt: -1 })
      .lean();
    res.status(200).json(promotions);
  } catch (error) {
    console.error(`Error fetching promotions for merchant ${req.params.merchantId}:`, error);
    res.status(500).json(safeError(error));
  }
});

// Create a new promotion (Authenticated: Admin, or Merchant for themselves)
router.post('/', authenticateJWT, [
  body('title').trim().notEmpty().withMessage('Title is required'),
  body('description').trim().notEmpty().withMessage('Description is required'),
  body('discount').trim().notEmpty().withMessage('Discount is required'),
  body('code').trim().notEmpty().withMessage('Promotion code is required'),
  body('category').trim().notEmpty().withMessage('Category is required'),
  body('startDate').isISO8601().withMessage('Start date must be a valid date'),
  body('endDate').isISO8601().withMessage('End date must be a valid date'),
  body('image').optional().isString(),
  body('images').optional().isArray().withMessage('Images must be an array'),
  body('url').optional().isString(),
  body('merchantId').trim().notEmpty().withMessage('Merchant ID is required'),
  body('featured').optional().isBoolean(),
  body('originalPrice').optional().isNumeric().withMessage('Original price must be a number.'),
  body('discountedPrice').optional().isNumeric().withMessage('Discounted price must be a number.')
    .custom((value, { req }) => {
      if (value && req.body.originalPrice && parseFloat(value) >= parseFloat(req.body.originalPrice)) {
        throw new Error('Discounted price must be less than original price.');
      }
      return true;
    }),
  body('status').optional().isIn(['pending_approval', 'approved', 'rejected', 'admin_paused', 'draft', 'active', 'scheduled', 'expired'])
    .withMessage('Invalid status value provided for creation.'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ message: 'Validation failed', errors: errors.array() });
  }
  try {
    let { title, description, discount, code, category, startDate, endDate, image, images, url, merchantId, featured, originalPrice, discountedPrice } = req.body;
    const normalizedStartDate = normalizePromotionDateInput(startDate, 'start');
    const normalizedEndDate = normalizePromotionDateInput(endDate, 'end');

    // Authorization: Admin can create for any merchantId. Merchant can only create for their own merchantId.
    if (req.user.role === 'merchant') {
      if (!req.user.merchantId) {
        return res.status(403).json({ message: 'Forbidden: You are a merchant but not linked to a merchant profile.' });
      }
      if (merchantId !== req.user.merchantId.toString()) {
        // If merchant tries to specify a different merchantId, either deny or override.
        // Overriding is safer to prevent accidental/malicious mis-assignment.
        console.warn(`Merchant ${req.user.id} attempted to create promotion for ${merchantId} but is being reassigned to their own merchantId ${req.user.merchantId}.`);
        merchantId = req.user.merchantId.toString();
      }
    } else if (req.user.role !== 'admin') {
      // Neither merchant nor admin, should not be able to create promotions
      return res.status(403).json({ message: 'Forbidden: You do not have permission to create promotions.' });
    }
    // If admin, they can specify any merchantId, so no changes needed to merchantId from req.body

    if (!mongoose.Types.ObjectId.isValid(merchantId)) {
      return res.status(400).json({ message: 'Invalid merchant ID.' });
    }

    // Validate merchant exists
    const merchant = await Merchant.findById(merchantId);
    if (!merchant) {
      return res.status(404).json({ message: `Merchant not found with ID: ${merchantId}` });
    }

    let initialStatus = resolveLifecycleStatus(normalizedStartDate, normalizedEndDate);
    if (req.user.role === 'admin' && ['pending_approval', 'rejected', 'admin_paused', 'draft'].includes(req.body.status)) {
      initialStatus = req.body.status;
    }
    
    const promotionData = {
      title,
      description,
      discount,
      code,
      category,
      startDate: normalizedStartDate,
      endDate: normalizedEndDate,
      image,
      images: images || [],
      url,
      merchant: merchantId,
      featured: featured === true || featured === 'true',
      originalPrice: originalPrice ? parseFloat(originalPrice) : undefined,
      discountedPrice: discountedPrice ? parseFloat(discountedPrice) : undefined,
      status: initialStatus
    };

    const promotion = new Promotion(promotionData);
    const savedPromotion = await promotion.save();
    
    // Link promotion to merchant without re-saving the whole merchant document.
    // This avoids unrelated legacy merchant field validation failures from blocking promotion creation.
    await Merchant.findByIdAndUpdate(
      merchantId,
      { $addToSet: { promotions: savedPromotion._id } },
      { runValidators: false }
    );
    
    // Trigger notifications asynchronously
    setImmediate(async () => {
      try {
        // Notify favorite store followers
        await notifyFavoriteStoreFollowers(savedPromotion._id);
        
        // Check if it's a flash sale
        await notifyFlashSale(savedPromotion._id);
      } catch (err) {
        console.error('Error sending notifications for new promotion:', err);
      }
    });
    
    // Invalidate caches
    homepageCache = null;
    nearbyCache.clear(); // Clear nearby deals cache on create
    invalidateSectionCaches();
    
    console.log('[Promotion Create] Caches invalidated');
    res.status(201).json(savedPromotion);
  } catch (error) {
    console.error('Error creating promotion:', error);
    res.status(500).json(safeError(error));
  }
});

// Update a promotion (Protected: Admin or Promotion Owner)
router.put('/:id', authenticateJWT, authorizePromotionOwnerOrAdmin, [
  body('title').optional().trim().notEmpty().withMessage('Title cannot be empty'),
  body('description').optional().isString(),
  body('discount').optional().trim().notEmpty().withMessage('Discount cannot be empty'),
  body('code').optional().isString(),
  body('category').optional().trim().notEmpty().withMessage('Category cannot be empty'),
  body('startDate').optional().isISO8601().withMessage('Start date must be a valid date'),
  body('endDate').optional().isISO8601().withMessage('End date must be a valid date'),
  body('image').optional().isString(),
  body('images').optional().isArray().withMessage('Images must be an array'),
  body('url').optional().isString(),
  body('featured').optional().isBoolean(),
  body('originalPrice').optional().isNumeric().withMessage('Original price must be a number.'),
  body('discountedPrice').optional().isNumeric().withMessage('Discounted price must be a number.')
    .custom((value, { req }) => {
      // Ensure originalPrice is considered if it's not being updated but exists on the promotion
      // This validation might be better handled by fetching the promotion first if not all price fields are sent
      if (value && req.body.originalPrice && parseFloat(value) >= parseFloat(req.body.originalPrice)) {
        throw new Error('Discounted price must be less than original price.');
      }
      // If only discountedPrice is sent, and originalPrice exists on doc, this check might be insufficient without fetching doc.
      // For now, assuming if prices are sent, they are sent together or this check is sufficient.
      return true;
    }),
  body('status').optional().isIn(['pending_approval', 'approved', 'rejected', 'admin_paused', 'draft', 'active', 'scheduled', 'expired'])
    .withMessage('Invalid status value provided for update.'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  try {
    const { title, description, discount, code, category, startDate, endDate, image, images, url, featured, originalPrice, discountedPrice } = req.body;
    const normalizedStartDate = startDate !== undefined ? normalizePromotionDateInput(startDate, 'start') : undefined;
    const normalizedEndDate = endDate !== undefined ? normalizePromotionDateInput(endDate, 'end') : undefined;

    const updateData = {
      title, description, discount, code, category, image, url,
      featured: featured === true || featured === 'true'
    };
    if (normalizedStartDate !== undefined) updateData.startDate = normalizedStartDate;
    if (normalizedEndDate !== undefined) updateData.endDate = normalizedEndDate;
    if (images !== undefined) updateData.images = images;

    // Properly calculate status based on dates
    if (startDate || endDate) {
      const existingPromotion = await Promotion.findById(req.params.id).select('startDate endDate');
      if (!existingPromotion) {
        return res.status(404).json({ message: 'Promotion not found' });
      }

      const sDate = normalizedStartDate || existingPromotion.startDate;
      const eDate = normalizedEndDate || existingPromotion.endDate;
      updateData.status = resolveLifecycleStatus(sDate, eDate);
    }


    if (originalPrice !== undefined) updateData.originalPrice = parseFloat(originalPrice);
    if (discountedPrice !== undefined) updateData.discountedPrice = parseFloat(discountedPrice);

    // Additional validation if both prices are present in the update
    if (updateData.originalPrice !== undefined && updateData.discountedPrice !== undefined && updateData.discountedPrice >= updateData.originalPrice) {
        return res.status(400).json({ errors: [{ msg: 'Discounted price must be less than original price.' }] });
    }
    // If only one price is updated, ensure it's still valid with the existing other price
    if (updateData.originalPrice === undefined && updateData.discountedPrice !== undefined) {
        const existingPromo = await Promotion.findById(req.params.id);
        if (existingPromo && existingPromo.originalPrice !== undefined && updateData.discountedPrice >= existingPromo.originalPrice) {
            return res.status(400).json({ errors: [{ msg: 'Discounted price must be less than the existing original price.' }] });
        }
    }
    if (updateData.discountedPrice === undefined && updateData.originalPrice !== undefined) {
        const existingPromo = await Promotion.findById(req.params.id);
        if (existingPromo && existingPromo.discountedPrice !== undefined && existingPromo.discountedPrice >= updateData.originalPrice) {
            return res.status(400).json({ errors: [{ msg: 'The new original price makes the existing discounted price invalid.' }] });
        }
    }

    // Handle status update by admin
    if (req.body.status && req.user.role === 'admin') {
        const allowedAdminStatuses = ['pending_approval', 'approved', 'rejected', 'admin_paused', 'draft', 'active', 'scheduled', 'expired'];
        if (allowedAdminStatuses.includes(req.body.status)) {
            updateData.status = req.body.status;

            // Re-evaluate live lifecycle when admin wants the promotion publicly visible.
            if (['approved', 'active', 'scheduled', 'expired'].includes(updateData.status)) {
                const existingPromotion = await Promotion.findById(req.params.id).select('startDate endDate');
                if (!existingPromotion) {
                    return res.status(404).json({ message: 'Promotion not found' });
                }

                const sDate = updateData.startDate || existingPromotion.startDate;
                const eDate = updateData.endDate || existingPromotion.endDate;
                updateData.status = resolveLifecycleStatus(sDate, eDate);
            }
        } else {
            return res.status(400).json({ message: 'Invalid status value for admin update.' });
        }
    } else if (req.body.status && req.user.role !== 'admin') {
        // Merchants cannot directly change status through this general update endpoint after creation.
        // They might have specific actions like "submit for approval" or "withdraw" later.
        return res.status(403).json({ message: 'Forbidden: Merchants cannot directly change promotion status.' });
    }


    // Get the old promotion data before update
    const oldPromotion = await Promotion.findById(req.params.id);
    
    const updatedPromotion = await Promotion.findByIdAndUpdate(
      req.params.id,
      { $set: updateData }, // Use $set to only update provided fields
      { new: true }
    );
    
    if (!updatedPromotion) {
      return res.status(404).json({ message: 'Promotion not found' });
    }
    
    const oldDiscountedPrice =
      typeof oldPromotion?.discountedPrice === 'number' ? oldPromotion.discountedPrice : null;
    const newDiscountedPrice =
      typeof updatedPromotion.discountedPrice === 'number' ? updatedPromotion.discountedPrice : null;
    const discountChanged =
      oldPromotion && updatedPromotion.discount !== oldPromotion.discount;
    const discountedPriceDropped =
      oldDiscountedPrice !== null &&
      newDiscountedPrice !== null &&
      newDiscountedPrice < oldDiscountedPrice;

    // Check for price drop notification (discount label changed or discounted price decreased)
    if (oldPromotion && (discountChanged || discountedPriceDropped)) {
      setImmediate(async () => {
        try {
          console.log(
            `[Price Drop] Triggering notification check. Discount: "${oldPromotion.discount}" -> "${updatedPromotion.discount}", discountedPrice: ${oldDiscountedPrice} -> ${newDiscountedPrice}`
          );
          await notifyPriceDrop(req.params.id, {
            oldDiscount: oldPromotion.discount,
            newDiscount: updatedPromotion.discount,
            oldDiscountedPrice,
            newDiscountedPrice,
            oldOriginalPrice:
              typeof oldPromotion.originalPrice === 'number' ? oldPromotion.originalPrice : null,
            newOriginalPrice:
              typeof updatedPromotion.originalPrice === 'number'
                ? updatedPromotion.originalPrice
                : null,
          });
        } catch (err) {
          console.error('Error sending price drop notification:', err);
        }
      });
    }
    
    // Invalidate caches
    homepageCache = null;
    nearbyCache.clear(); // Clear nearby deals cache on update
    invalidateSectionCaches();
    
    console.log('[Promotion Update] Caches invalidated');
    res.status(200).json(updatedPromotion);
  } catch (error) {
    console.error(`Error updating promotion ${req.params.id}:`, error);
    res.status(500).json(safeError(error));
  }
});

// Delete a promotion (Protected: Admin or Promotion Owner)
router.delete('/:id', authenticateJWT, authorizePromotionOwnerOrAdmin, async (req, res) => {
  try {
    // The authorizePromotionOwnerOrAdmin middleware already fetches the promotion if the user is not an admin.
    // However, if the user is an admin, it doesn't. So we might need to fetch it here anyway for the merchant update.
    // Or, the middleware could attach the promotion to req if found.
    // For simplicity now, let's assume it's fine, or refetch if needed.
    const promotion = await Promotion.findById(req.params.id); // This might be redundant if middleware is enhanced
    if (!promotion) {
      return res.status(404).json({ message: 'Promotion not found' });
    }
    
    // Remove promotion from merchant's promotions array
    await Merchant.updateOne(
      { _id: promotion.merchant },
      { $pull: { promotions: promotion._id } }
    );
    
    await Promotion.findByIdAndDelete(req.params.id);
    
    // Invalidate caches
    homepageCache = null;
    nearbyCache.clear(); // Clear nearby deals cache on delete
    invalidateSectionCaches();
    
    console.log('[Promotion Delete] Caches invalidated');
    res.status(200).json({ message: 'Promotion deleted successfully' });
  } catch (error) {
    console.error(`Error deleting promotion ${req.params.id}:`, error);
    res.status(500).json(safeError(error));
  }
});

// Record a promotion click (Optionally authenticated)
// Uses gentleAuthenticateJWT imported from ../middleware/auth
router.post('/:id/click', gentleAuthenticateJWT, async (req, res) => {
  try {
    const promotion = await Promotion.findById(req.params.id);
    if (!promotion) return res.status(404).json({ message: 'Promotion not found' });

    const clickData = {
      promotion: promotion._id,
      merchant: promotion.merchant,
      type: req.body.type || 'click',
      user: req.user ? req.user.id : (req.body.userId || null) // Prefer authenticated user
    };

    // If req.user exists, we use req.user.id.
    // If not, we fallback to req.body.userId (which could be for anonymous tracking if desired, or just null).
    // For better security, if strict user association is needed, always rely on req.user.id and make gentleAuthenticateJWT mandatory authenticateJWT.
    // Current setup allows anonymous clicks if no token, or if token but body has different userId, still uses token's user.

    const click = new PromotionClick(clickData);
    await click.save();
    res.status(201).json({ message: 'Click recorded' });
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// --- Comments & Ratings ---
// Add a comment to a promotion (Authenticated users only)
router.post('/:id/comments', authenticateJWT, async (req, res) => {
  try {
    const { text } = req.body; // userId will come from req.user.id
    if (!text) return res.status(400).json({ message: 'Text is required.' });

    const promotion = await Promotion.findById(req.params.id);
    if (!promotion) return res.status(404).json({ message: 'Promotion not found' });

    promotion.comments.push({ user: req.user.id, text });
    await promotion.save();
    // Populate user details for the new comment before sending back
    const newComment = promotion.comments[promotion.comments.length - 1];
    await Promotion.populate(newComment, { path: 'user', select: 'name email profilePicture' });

    res.status(201).json(newComment);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Get comments for a promotion
router.get('/:id/comments', async (req, res) => {
  try {
    const promotion = await Promotion.findById(req.params.id).populate(
      'comments.user',
      'name email profilePicture',
    );
    if (!promotion) return res.status(404).json({ message: 'Promotion not found' });
    res.status(200).json(promotion.comments);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Add or update a rating for a promotion (Authenticated users only)
router.post('/:id/ratings', authenticateJWT, async (req, res) => {
  try {
    const { value } = req.body; // userId will come from req.user.id
    if (typeof value !== 'number' || value < 1 || value > 5) {
      return res.status(400).json({ message: 'Valid rating value (1-5) is required.' });
    }
    const promotion = await Promotion.findById(req.params.id);
    if (!promotion) return res.status(404).json({ message: 'Promotion not found' });

    // Remove previous rating by this user to prevent multiple ratings
    promotion.ratings = promotion.ratings.filter(r => r.user.toString() !== req.user.id);
    promotion.ratings.push({ user: req.user.id, value });

    await promotion.save();

    // Populate user details for the ratings before sending back
    await Promotion.populate(promotion, { path: 'ratings.user', select: 'name email profilePicture' });

    res.status(201).json(promotion.ratings);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Get ratings for a promotion
router.get('/:id/ratings', async (req, res) => {
  try {
    const promotion = await Promotion.findById(req.params.id).populate(
      'ratings.user',
      'name email profilePicture',
    );
    if (!promotion) return res.status(404).json({ message: 'Promotion not found' });
    res.status(200).json(promotion.ratings);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

module.exports = router;
