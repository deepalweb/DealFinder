const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const Promotion = require('../models/Promotion');
const Merchant = require('../models/Merchant');
const PromotionClick = require('../models/PromotionClick');
const { authenticateJWT, authorizeAdmin, authorizePromotionOwnerOrAdmin, gentleAuthenticateJWT } = require('../middleware/auth');
const { notifyFavoriteStoreFollowers } = require('../jobs/favoriteStoreNotifications');
const { notifyFlashSale } = require('../jobs/flashSaleNotifications');
const { notifyPriceDrop } = require('../jobs/priceDropNotifications');

// Add safeError helper
function safeError(error) {
  if (process.env.NODE_ENV === 'production') {
    return { message: 'An error occurred' };
  }
  return { message: error.message, stack: error.stack };
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

    const now = new Date();
    const query = {
      status: { $in: ['active', 'approved'] },
      startDate: { $lte: now },
      endDate: { $gte: now }
    };

    const [featured, latest] = await Promise.all([
      Promotion.find({ ...query, featured: true })
        .select('-comments -ratings')
        .populate('merchant', 'name logo currency')
        .sort({ _id: -1 })
        .limit(8)
        .lean(),
      Promotion.find(query)
        .select('-comments -ratings')
        .populate('merchant', 'name logo currency')
        .sort({ _id: -1 })
        .limit(20)
        .lean()
    ]);

    homepageCache = { featured, latest };
    homepageCacheTs = Date.now();

    res.status(200).json(homepageCache);
  } catch (error) {
    console.error('Error in GET /api/promotions/homepage:', error);
    res.status(500).json(safeError(error));
  }
});

// Get nearby promotions
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
    const radiusInMeters = searchRadiusKm * 1000;

    let merchantsWithDistance = [];
    try {
      merchantsWithDistance = await Merchant.aggregate([
        {
          $geoNear: {
            near: { type: 'Point', coordinates: [lon, lat] },
            distanceField: 'distance',
            maxDistance: radiusInMeters,
            spherical: true,
            query: { 'location.type': 'Point' }
          }
        },
        {
          $project: { _id: 1, name: 1, location: 1, distance: 1 }
        }
      ]);
    } catch (geoErr) {
      console.error('$geoNear error:', geoErr.message);
      return res.status(200).json([]);
    }

    if (!merchantsWithDistance.length) {
      return res.status(200).json([]);
    }

    const merchantIds = merchantsWithDistance.map(m => m._id);

    const now = new Date();
    let promotions = await Promotion.find({
      merchant: { $in: merchantIds },
      status: { $in: ['active', 'approved'] },
      startDate: { $lte: now },
      endDate: { $gte: now },
    })
    .select('-comments -ratings')
    .populate({ path: 'merchant', select: 'name logo location address contactInfo currency' })
    .lean();

    promotions = promotions.map(promo => {
      const merchantInfo = merchantsWithDistance.find(m => m._id.equals(promo.merchant._id));
      if (merchantInfo && typeof promo.merchant === 'object' && promo.merchant !== null) {
        promo.merchant.distance = merchantInfo.distance;
      }
      return promo;
    });

    res.status(200).json(promotions);

  } catch (error) {
    console.error('Error fetching nearby promotions:', error);
    res.status(500).json(safeError(error));
  }
});


// Get all promotions
router.get('/', async (req, res) => {
  try {
    const now = new Date();
    const limit = parseInt(req.query.limit) || 0; // 0 means no limit
    const skip = parseInt(req.query.skip) || 0;
    
    const query = {
      status: { $in: ['active', 'approved'] },
      startDate: { $lte: now },
      endDate: { $gte: now }
    };
    
    let promotionsQuery = Promotion.find(query)
      .select('-comments -ratings')
      .populate('merchant', 'name logo address contactInfo currency location')
      .sort({ _id: -1 })
      .lean();
    
    if (limit > 0) {
      promotionsQuery = promotionsQuery.limit(limit).skip(skip);
    }
    
    const promotions = await promotionsQuery;
    res.status(200).json(promotions);
  } catch (error) {
    console.error('Error in GET /api/promotions:', error);
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
    const promotions = await Promotion.find({ merchant: req.params.merchantId })
      .select('-comments -ratings')
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

    // Validate merchant exists
    const merchant = await Merchant.findById(merchantId);
    if (!merchant) {
      return res.status(404).json({ message: `Merchant not found with ID: ${merchantId}` });
    }

    let initialStatus = 'active'; // Default for merchant submissions
    if (req.user.role === 'admin') {
      initialStatus = req.body.status && ['pending_approval', 'approved', 'rejected', 'admin_paused', 'draft'].includes(req.body.status) ? req.body.status : 'approved';
    }
    
    const promotionData = {
      title,
      description,
      discount,
      code,
      category,
      startDate,
      endDate,
      image,
      images: images || [],
      url,
      merchant: merchantId,
      featured: featured === true || featured === 'true',
      originalPrice: originalPrice ? parseFloat(originalPrice) : undefined,
      discountedPrice: discountedPrice ? parseFloat(discountedPrice) : undefined,
      status: initialStatus
    };

    // If status is 'approved', then determine if 'active', 'scheduled', or 'expired' based on dates
    if (promotionData.status === 'approved') {
      const now = new Date();
      const sDate = new Date(startDate);
      const eDate = new Date(endDate);
      if (eDate < now) {
        promotionData.status = 'expired';
      } else if (sDate > now) {
        promotionData.status = 'scheduled';
      } else {
        promotionData.status = 'active';
      }
    }
    
    const promotion = new Promotion(promotionData);
    const savedPromotion = await promotion.save();
    
    // Add promotion to merchant's promotions array
    merchant.promotions.push(savedPromotion._id);
    await merchant.save();
    
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
    
    homepageCache = null; // invalidate on create
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
    
    const updateData = {
      title, description, discount, code, category, startDate, endDate, image, url,
      featured: featured === true || featured === 'true'
    };
    if (images !== undefined) updateData.images = images;

    if (startDate && endDate) {
      updateData.status = new Date(endDate) > new Date() ? 'active' : 'expired';
    } else if (endDate) { // If only endDate is provided, we might need to fetch startDate from DB to determine status
        const existingPromo = await Promotion.findById(req.params.id);
        if (existingPromo) {
            updateData.status = new Date(endDate) > new Date(existingPromo.startDate) && new Date(endDate) > new Date() ? 'active' : 'expired';
        }
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

            // If admin sets to 'approved', re-evaluate active/scheduled/expired based on dates
            if (updateData.status === 'approved') {
                const sDate = new Date(updateData.startDate || (await Promotion.findById(req.params.id)).startDate);
                const eDate = new Date(updateData.endDate || (await Promotion.findById(req.params.id)).endDate);
                const now = new Date();
                if (eDate < now) updateData.status = 'expired';
                else if (sDate > now) updateData.status = 'scheduled';
                else updateData.status = 'active';
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
    
    // Check for price drop notification (discount field changed)
    if (discount && oldPromotion && discount !== oldPromotion.discount) {
      setImmediate(async () => {
        try {
          console.log(`[Price Drop] Discount changed from "${oldPromotion.discount}" to "${discount}"`);
          await notifyPriceDrop(req.params.id, oldPromotion.discount, discount);
        } catch (err) {
          console.error('Error sending price drop notification:', err);
        }
      });
    }
    
    homepageCache = null; // invalidate on update
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
    homepageCache = null; // invalidate on delete
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
    const promotion = await Promotion.findById(req.params.id).populate('comments.user', 'name email');
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
    const promotion = await Promotion.findById(req.params.id).populate('ratings.user', 'name email');
    if (!promotion) return res.status(404).json({ message: 'Promotion not found' });
    res.status(200).json(promotion.ratings);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

module.exports = router;