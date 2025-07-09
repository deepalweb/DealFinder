const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const Promotion = require('../models/Promotion');
const Merchant = require('../models/Merchant');
const PromotionClick = require('../models/PromotionClick');
const { authenticateJWT, authorizeAdmin, authorizePromotionOwnerOrAdmin, gentleAuthenticateJWT } = require('../middleware/auth');

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

// Get all promotions
router.get('/', async (req, res) => {
  try {
    console.log('GET /api/promotions - Fetching active promotions');
    const now = new Date();
    console.log('Current date for promotion filtering:', now);
    
    // Find promotions that are currently active based on dates
    const promotions = await Promotion.find({
      startDate: { $lte: now }, // Start date is less than or equal to now
      endDate: { $gte: now }    // End date is greater than or equal to now
    }).populate('merchant');
    
    console.log(`Found ${promotions.length} active promotions`);
    res.status(200).json(promotions);
  } catch (error) {
    console.error('Error in GET /api/promotions:', error);
    // Log more details about the error
    if (error.name === 'MongoServerError') {
      console.error('MongoDB server error details:', error.code, error.codeName);
    }
    if (error.name === 'ValidationError') {
      console.error('Validation error details:', error.errors);
    }
    
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
    const promotions = await Promotion.find({ merchant: req.params.merchantId });
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
    return res.status(400).json({ errors: errors.array() });
  }
  try {
    let { title, description, discount, code, category, startDate, endDate, image, url, merchantId, featured, originalPrice, discountedPrice } = req.body;

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

    let initialStatus = 'pending_approval'; // Default for merchant submissions
    if (req.user.role === 'admin') {
      // Admin can specify a status, or it defaults to 'approved' if not 'pending_approval'
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
    const { title, description, discount, code, category, startDate, endDate, image, url, featured, originalPrice, discountedPrice } = req.body;
    
    const updateData = {
      title, description, discount, code, category, startDate, endDate, image, url,
      featured: featured === true || featured === 'true'
    };

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


    const updatedPromotion = await Promotion.findByIdAndUpdate(
      req.params.id,
      { $set: updateData }, // Use $set to only update provided fields
      { new: true }
    );
    
    if (!updatedPromotion) {
      return res.status(404).json({ message: 'Promotion not found' });
    }
    
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