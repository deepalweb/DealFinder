const express = require('express');
const router = express.Router();
const Merchant = require('../models/Merchant');
const User = require('../models/User');
const { body, validationResult } = require('express-validator');

// Remove sensitive error details from all API responses in production
function safeError(error) {
  if (process.env.NODE_ENV === 'production') {
    return { message: 'An error occurred' };
  }
  return { message: error.message, stack: error.stack };
}

// Helper to get followers count for a merchant
async function getFollowersCount(merchantId) {
  return await User.countDocuments({ merchantId });
}

// Get all merchants
router.get('/', async (req, res) => {
  try {
    const merchants = await Merchant.find().populate('promotions');
    // Add followers and activeDeals count to each merchant
    const merchantsWithCounts = await Promise.all(merchants.map(async (merchant) => {
      const followers = await getFollowersCount(merchant._id);
      const activeDeals = Array.isArray(merchant.promotions)
        ? merchant.promotions.filter(p => p.status === 'active' && new Date(p.endDate) >= new Date()).length
        : 0;
      return {
        ...merchant.toObject(),
        followers,
        activeDeals
      };
    }));
    res.status(200).json(merchantsWithCounts);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Get a merchant by ID
router.get('/:id', async (req, res) => {
  try {
    const merchant = await Merchant.findById(req.params.id).populate('promotions');
    if (!merchant) return res.status(404).json({ message: 'Merchant not found' });
    const followers = await getFollowersCount(merchant._id);
    const activeDeals = Array.isArray(merchant.promotions)
      ? merchant.promotions.filter(p => p.status === 'active' && new Date(p.endDate) >= new Date()).length
      : 0;
    res.status(200).json({
      ...merchant.toObject(),
      followers,
      activeDeals
    });
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Create a new merchant
router.post('/', [
  body('name').trim().notEmpty().withMessage('Name is required'),
  body('profile').optional().isString(),
  body('contactInfo').optional().isString(),
  body('userId').optional().isString(),
  body('address').optional().isString(),
  body('contactNumber').optional().isString(),
  body('socialMedia').optional().isObject(), // Accepts facebook, instagram, twitter, tiktok
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  try {
    const { name, profile, contactInfo, userId, address, contactNumber, socialMedia } = req.body;
    
    // Create the merchant
    const merchant = new Merchant({
      name,
      profile,
      contactInfo,
      promotions: [],
      address,
      contactNumber,
      socialMedia
    });
    
    const savedMerchant = await merchant.save();
    
    // If userId is provided, associate this merchant with a user
    if (userId) {
      await User.findByIdAndUpdate(userId, { 
        merchantId: savedMerchant._id,
        role: 'merchant'
      });
    }
    
    res.status(201).json(savedMerchant);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Update a merchant
router.put('/:id', [
  body('name').optional().trim().notEmpty().withMessage('Name cannot be empty'),
  body('profile').optional().isString(),
  body('contactInfo').optional().isString(),
  body('logo').optional().isString(),
  body('address').optional().isString(),
  body('contactNumber').optional().isString(),
  body('socialMedia').optional().isObject(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  try {
    const { name, profile, contactInfo, logo, address, contactNumber, socialMedia } = req.body;
    const updatedMerchant = await Merchant.findByIdAndUpdate(
      req.params.id,
      { name, profile, contactInfo, logo, address, contactNumber, socialMedia },
      { new: true }
    );
    if (!updatedMerchant) {
      return res.status(404).json({ message: 'Merchant not found' });
    }
    res.status(200).json(updatedMerchant);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Delete a merchant
router.delete('/:id', async (req, res) => {
  try {
    const merchant = await Merchant.findById(req.params.id);
    if (!merchant) {
      return res.status(404).json({ message: 'Merchant not found' });
    }
    
    // Update any users associated with this merchant
    await User.updateMany(
      { merchantId: merchant._id },
      { $unset: { merchantId: "" }, role: 'user' }
    );
    
    await Merchant.findByIdAndDelete(req.params.id);
    res.status(200).json({ message: 'Merchant deleted successfully' });
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Get merchant dashboard data
router.get('/:id/dashboard', async (req, res) => {
  try {
    const merchant = await Merchant.findById(req.params.id).populate('promotions');
    if (!merchant) {
      return res.status(404).json({ message: 'Merchant not found' });
    }
    
    // You could add more dashboard data here, like analytics
    const dashboardData = {
      merchant,
      promotionCount: merchant.promotions.length,
      activePromotions: merchant.promotions.filter(p => p.status === 'active').length,
      expiredPromotions: merchant.promotions.filter(p => p.status === 'expired').length
    };
    
    res.status(200).json(dashboardData);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

module.exports = router;