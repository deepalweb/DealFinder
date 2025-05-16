const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const Promotion = require('../models/Promotion');
const Merchant = require('../models/Merchant');
const PromotionClick = require('../models/PromotionClick');

// Add safeError helper
function safeError(error) {
  if (process.env.NODE_ENV === 'production') {
    return { message: 'An error occurred' };
  }
  return { message: error.message, stack: error.stack };
}

// --- Move analytics routes to the top to avoid /:id conflicts ---
// Get analytics for a merchant
router.get('/analytics/merchant/:merchantId', async (req, res) => {
  try {
    const clicks = await PromotionClick.find({ merchant: req.params.merchantId }).populate('promotion user');
    res.status(200).json(clicks);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Get analytics for a promotion
router.get('/:id/analytics', async (req, res) => {
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

// Create a new promotion
router.post('/', [
  body('title').trim().notEmpty().withMessage('Title is required'),
  body('description').optional().isString(),
  body('discount').trim().notEmpty().withMessage('Discount is required'),
  body('code').optional().isString(),
  body('category').trim().notEmpty().withMessage('Category is required'),
  body('startDate').isISO8601().withMessage('Start date must be a valid date'),
  body('endDate').isISO8601().withMessage('End date must be a valid date'),
  body('image').optional().isString(),
  body('url').optional().isString(),
  body('merchantId').trim().notEmpty().withMessage('Merchant ID is required'),
  body('featured').optional().isBoolean(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  try {
    const { title, description, discount, code, category, startDate, endDate, image, url, merchantId, featured } = req.body;
    
    // Validate merchant exists
    const merchant = await Merchant.findById(merchantId);
    if (!merchant) {
      return res.status(404).json({ message: 'Merchant not found' });
    }
    
    const promotion = new Promotion({
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
      featured: featured === true || featured === 'true', // ensure boolean
      status: new Date(endDate) > new Date() ? 'active' : 'expired'
    });
    
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

// Update a promotion
router.put('/:id', [
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
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  try {
    const { title, description, discount, code, category, startDate, endDate, image, url, featured } = req.body;
    
    // Calculate status based on end date
    const status = new Date(endDate) > new Date() ? 'active' : 'expired';
    const updatedPromotion = await Promotion.findByIdAndUpdate(
      req.params.id,
      {
        title,
        description,
        discount,
        code,
        category,
        startDate,
        endDate,
        image,
        url,
        featured: featured === true || featured === 'true', // ensure boolean
        status
      },
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

// Delete a promotion
router.delete('/:id', async (req, res) => {
  try {
    const promotion = await Promotion.findById(req.params.id);
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

// Record a promotion click
router.post('/:id/click', async (req, res) => {
  try {
    const promotion = await Promotion.findById(req.params.id);
    if (!promotion) return res.status(404).json({ message: 'Promotion not found' });
    const merchantId = promotion.merchant;
    const userId = req.body.userId || null;
    const type = req.body.type || 'click';
    const click = new PromotionClick({
      promotion: promotion._id,
      merchant: merchantId,
      user: userId,
      type
    });
    await click.save();
    res.status(201).json({ message: 'Click recorded' });
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

module.exports = router;