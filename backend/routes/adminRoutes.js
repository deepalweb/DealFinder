const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Merchant = require('../models/Merchant');
const Promotion = require('../models/Promotion');
const PromotionClick = require('../models/PromotionClick');
const { authenticateJWT, authorizeAdmin } = require('../middleware/auth');
const bcrypt = require('bcryptjs');

// Middleware to ensure all routes in this file are admin-only
router.use(authenticateJWT, authorizeAdmin);

// Helper function to remove sensitive error details in production
function safeError(error) {
  if (process.env.NODE_ENV === 'production') {
    return { message: 'An error occurred' };
  }
  return { message: error.message, stack: error.stack };
}

// --- Analytics Endpoints ---
router.get('/analytics/summary', async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const totalMerchants = await Merchant.countDocuments();
    const totalPromotions = await Promotion.countDocuments();
    const totalPromotionClicks = await PromotionClick.countDocuments();
    // More analytics can be added here (e.g., active promotions, user roles distribution)
    res.status(200).json({
      totalUsers,
      totalMerchants,
      totalPromotions,
      totalPromotionClicks
    });
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// --- User Management ---
// Get all users
router.get('/users', async (req, res) => {
  try {
    const users = await User.find().select('-password');
    res.status(200).json(users);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Get a single user by ID
router.get('/users/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.status(200).json(user);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Create a new user (admin only)
router.post('/users', async (req, res) => {
  // Add validation if necessary
  try {
    const { name, email, password, role, businessName, profilePicture } = req.body;
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'User with this email already exists' });
    }
    const hashedPassword = await bcrypt.hash(password, 10); // Make sure to require bcrypt
    const user = new User({ name, email, password: hashedPassword, role: role || 'user', businessName, profilePicture });
    const savedUser = await user.save();
    // If role is merchant and businessName is provided, create a merchant profile
    if (role === 'merchant' && businessName) {
        const merchant = new Merchant({ name: businessName, contactInfo: email });
        const savedMerchant = await merchant.save();
        savedUser.merchantId = savedMerchant._id;
        await savedUser.save();
    }
    const userResponse = savedUser.toObject();
    delete userResponse.password;
    res.status(201).json(userResponse);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Update a user
router.put('/users/:id', async (req, res) => {
  // Add validation if necessary
  try {
    const { name, email, role, businessName, profilePicture } = req.body;
    // Ensure password is not updated here, or handle it separately if needed
    const updatedUser = await User.findByIdAndUpdate(
      req.params.id,
      { name, email, role, businessName, profilePicture },
      { new: true }
    ).select('-password');
    if (!updatedUser) return res.status(404).json({ message: 'User not found' });
    // Handle merchant profile linkage if role changes
    if (role === 'merchant' && businessName && !updatedUser.merchantId) {
        const merchant = new Merchant({ name: businessName, contactInfo: email, userId: updatedUser._id });
        const savedMerchant = await merchant.save();
        updatedUser.merchantId = savedMerchant._id;
        await updatedUser.save();
    } else if (role !== 'merchant' && updatedUser.merchantId) {
        // If role changed from merchant, consider how to handle the existing merchant profile
        // For now, we'll just unlink. Could also delete the merchant profile.
        await Merchant.findByIdAndDelete(updatedUser.merchantId);
        updatedUser.merchantId = undefined;
        await updatedUser.save();
    }
    res.status(200).json(updatedUser);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Delete a user
router.delete('/users/:id', async (req, res) => {
  try {
    const user = await User.findByIdAndDelete(req.params.id);
    if (!user) return res.status(404).json({ message: 'User not found' });
    // If user was a merchant, delete their merchant profile as well
    if (user.merchantId) {
      await Merchant.findByIdAndDelete(user.merchantId);
    }
    res.status(200).json({ message: 'User deleted successfully' });
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});


// --- Merchant Management ---
// Get all merchants
router.get('/merchants', async (req, res) => {
  try {
    const merchants = await Merchant.find().populate('promotions');
    res.status(200).json(merchants);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Get a single merchant by ID
router.get('/merchants/:id', async (req, res) => {
  try {
    const merchant = await Merchant.findById(req.params.id).populate('promotions');
    if (!merchant) return res.status(404).json({ message: 'Merchant not found' });
    res.status(200).json(merchant);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Create a new merchant
router.post('/merchants', async (req, res) => {
    // Add validation
    try {
        const { name, profile, contactInfo, userId, address, contactNumber, socialMedia, logo } = req.body;
        const merchant = new Merchant({ name, profile, contactInfo, address, contactNumber, socialMedia, logo });
        const savedMerchant = await merchant.save();
        if (userId) {
            await User.findByIdAndUpdate(userId, { merchantId: savedMerchant._id, role: 'merchant' });
        }
        res.status(201).json(savedMerchant);
    } catch (error) {
        res.status(500).json(safeError(error));
    }
});

// Update a merchant
router.put('/merchants/:id', async (req, res) => {
  // Add validation
  try {
    const updatedMerchant = await Merchant.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!updatedMerchant) return res.status(404).json({ message: 'Merchant not found' });
    res.status(200).json(updatedMerchant);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Delete a merchant
router.delete('/merchants/:id', async (req, res) => {
  try {
    const merchant = await Merchant.findByIdAndDelete(req.params.id);
    if (!merchant) return res.status(404).json({ message: 'Merchant not found' });
    // Remove merchantId from any associated users
    await User.updateMany({ merchantId: req.params.id }, { $unset: { merchantId: "" }, role: 'user' });
    // Delete all promotions associated with this merchant
    await Promotion.deleteMany({ merchant: req.params.id });
    res.status(200).json({ message: 'Merchant and associated promotions deleted successfully' });
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});


// --- Promotion Management ---
// Get all promotions
router.get('/promotions', async (req, res) => {
  try {
    const promotions = await Promotion.find().populate('merchant');
    res.status(200).json(promotions);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Get a single promotion by ID
router.get('/promotions/:id', async (req, res) => {
  try {
    const promotion = await Promotion.findById(req.params.id).populate('merchant');
    if (!promotion) return res.status(404).json({ message: 'Promotion not found' });
    res.status(200).json(promotion);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Create a new promotion
router.post('/promotions', async (req, res) => {
    // Add validation
    try {
        const { title, description, discount, code, category, merchantId, startDate, endDate, image, url, featured } = req.body;
        const merchant = await Merchant.findById(merchantId);
        if (!merchant) return res.status(404).json({ message: `Merchant not found with ID: ${merchantId}` });

        const promotion = new Promotion({
            title, description, discount, code, category, merchant: merchantId,
            startDate, endDate, image, url, featured,
            status: new Date(endDate) > new Date() ? 'active' : 'expired'
        });
        const savedPromotion = await promotion.save();
        merchant.promotions.push(savedPromotion._id);
        await merchant.save();
        res.status(201).json(savedPromotion);
    } catch (error) {
        res.status(500).json(safeError(error));
    }
});

// Update a promotion
router.put('/promotions/:id', async (req, res) => {
  // Add validation
  try {
    const { endDate } = req.body; // Get endDate to recalculate status
    const status = endDate && (new Date(endDate) > new Date()) ? 'active' : 'expired';
    const updatedPromotion = await Promotion.findByIdAndUpdate(
        req.params.id,
        { ...req.body, status }, // Include status in the update
        { new: true }
    ).populate('merchant');
    if (!updatedPromotion) return res.status(404).json({ message: 'Promotion not found' });
    res.status(200).json(updatedPromotion);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Delete a promotion
router.delete('/promotions/:id', async (req, res) => {
  try {
    const promotion = await Promotion.findByIdAndDelete(req.params.id);
    if (!promotion) return res.status(404).json({ message: 'Promotion not found' });
    // Remove promotion from merchant's promotions array
    await Merchant.updateOne({ _id: promotion.merchant }, { $pull: { promotions: promotion._id } });
    res.status(200).json({ message: 'Promotion deleted successfully' });
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

module.exports = router;
