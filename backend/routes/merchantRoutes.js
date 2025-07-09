const express = require('express');
const router = express.Router();
const Merchant = require('../models/Merchant');
const User = require('../models/User');
const { body, validationResult } = require('express-validator');
const { authenticateJWT, authorizeAdmin, authorizeMerchantSelfOrAdmin } = require('../middleware/auth');

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

// Create a new merchant (Admin Only)
router.post('/', authenticateJWT, authorizeAdmin, [
  body('name').trim().notEmpty().withMessage('Name is required'),
  body('profile').optional().isString(),
  body('contactInfo').optional().isString(),
  body('userId').optional().isString(), // For admin to link to existing user
  body('address').optional().isString(),
  body('contactNumber').optional().isString(),
  body('socialMedia').optional().isObject(),
  body('location').optional().isObject().withMessage('Location must be an object'),
  body('location.type').optional().isIn(['Point']).withMessage('Location type must be "Point"'),
  body('location.coordinates').optional().isArray({ min: 2, max: 2 }).withMessage('Coordinates must be an array of two numbers [longitude, latitude]'),
  body('location.coordinates.*').optional().isNumeric().withMessage('Coordinates must contain numbers')
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  try {
    const { name, profile, contactInfo, userId, address, contactNumber, socialMedia, location } = req.body;
    
    const merchantData = {
      name,
      profile,
      contactInfo,
      promotions: [],
      address,
      contactNumber,
      socialMedia
    };

    if (location && location.coordinates && location.coordinates.length === 2) {
      merchantData.location = {
        type: 'Point',
        coordinates: [parseFloat(location.coordinates[0]), parseFloat(location.coordinates[1])]
      };
    }
    
    const merchant = new Merchant(merchantData);
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

// Update a merchant (Merchant Self or Admin)
router.put('/:id', authenticateJWT, authorizeMerchantSelfOrAdmin, [
  body('name').optional().trim().notEmpty().withMessage('Name cannot be empty'),
  body('profile').optional().isString(),
  body('contactInfo').optional().isString(),
  body('logo').optional().isString(),
  body('address').optional().isString(),
  body('contactNumber').optional().isString(),
  body('socialMedia').optional().isObject(),
  body('status').optional().isIn(['active', 'pending_approval', 'approved', 'rejected', 'suspended', 'needs_review'])
    .withMessage('Invalid status value'),
  body('location').optional().isObject().withMessage('Location must be an object'),
  body('location.type').optional().isIn(['Point']).withMessage('Location type must be "Point"'),
  body('location.coordinates').optional().isArray({ min: 2, max: 2 }).withMessage('Coordinates must be an array of two numbers [longitude, latitude]'),
  body('location.coordinates.*').optional().isNumeric().withMessage('Coordinates must contain numbers')
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  try {
    const { name, profile, contactInfo, logo, address, contactNumber, socialMedia, status, location } = req.body;

    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (profile !== undefined) updateData.profile = profile;
    if (contactInfo !== undefined) updateData.contactInfo = contactInfo;
    if (logo !== undefined) updateData.logo = logo;
    if (address !== undefined) updateData.address = address;
    if (contactNumber !== undefined) updateData.contactNumber = contactNumber;
    if (socialMedia !== undefined) updateData.socialMedia = socialMedia;

    if (location === null) {
      // Frontend sends null to explicitly clear the location.
      // $set: { location: null } or $unset: { location: "" } might be needed depending on Mongoose behavior with 'undefined'.
      // Using 'undefined' with $set should lead to $unset if the schema path isn't explicitly set to allow null.
      // Let's be explicit with $unset for clarity if location is null.
      // However, findByIdAndUpdate with { $set: { location: undefined } } usually works as $unset.
      // For now, setting to undefined is fine, Mongoose should handle it. If not, use $unset.
      updateData.location = undefined;
    } else if (location && location.type === 'Point' &&
               Array.isArray(location.coordinates) && location.coordinates.length === 2 &&
               typeof location.coordinates[0] === 'number' &&
               typeof location.coordinates[1] === 'number' &&
               !isNaN(location.coordinates[0]) && // Ensure they are not NaN
               !isNaN(location.coordinates[1])) {
      // Location data is valid and complete
      updateData.location = {
        type: 'Point',
        coordinates: [location.coordinates[0], location.coordinates[1]] // Already numbers
      };
    }
    // If 'location' is present in req.body but doesn't match above (e.g., malformed),
    // the express-validator rules should have caught it and returned a 400.
    // If 'location' is not in req.body at all (undefined), it means no update to location was intended.

    // Only admins can change the status
    if (status !== undefined && req.user.role === 'admin') {
      updateData.status = status;
    } else if (status !== undefined && req.user.role !== 'admin') {
      // Merchants trying to change their own status - forbidden for now
      // Or, you might allow certain status changes by merchants, e.g., request deactivation
      return res.status(403).json({ message: 'Forbidden: Only admins can change merchant status.' });
    }

    const updateOperation = {};
    if (Object.keys(updateData).length > 0) {
      updateOperation.$set = updateData;
    }

    if (location === null) { // Frontend explicitly wants to clear location
      if (!updateOperation.$unset) {
        updateOperation.$unset = {};
      }
      updateOperation.$unset.location = 1; // Value '1' or '' typically used for $unset
      // Ensure location is not also in $set if it was processed before this check
      if (updateOperation.$set && updateOperation.$set.hasOwnProperty('location')) {
        delete updateOperation.$set.location;
      }
    }

    // Ensure there's something to update
    if (Object.keys(updateOperation).length === 0) {
      // No actual changes, just return the merchant found by ID or error if not found
      const merchant = await Merchant.findById(req.params.id);
      if (!merchant) return res.status(404).json({ message: 'Merchant not found (and no update data provided)' });
      return res.status(200).json(merchant); // Or a 304 Not Modified, but 200 with data is fine
    }

    const updatedMerchant = await Merchant.findByIdAndUpdate(
      req.params.id,
      updateOperation,
      { new: true, runValidators: true } // Added runValidators
    );
    if (!updatedMerchant) {
      return res.status(404).json({ message: 'Merchant not found' });
    }
    res.status(200).json(updatedMerchant);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Delete a merchant (Merchant Self or Admin)
// Note: authorizeMerchantSelfOrAdmin checks if req.user.merchantId matches req.params.id for merchants.
// For admins, it just lets them through.
router.delete('/:id', authenticateJWT, authorizeMerchantSelfOrAdmin, async (req, res) => {
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

// Get merchant dashboard data (Merchant Self or Admin)
router.get('/:id/dashboard', authenticateJWT, authorizeMerchantSelfOrAdmin, async (req, res) => {
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