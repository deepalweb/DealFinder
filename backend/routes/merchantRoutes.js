const express = require('express');
const router = express.Router();
const Merchant = require('../models/Merchant');
const User = require('../models/User');

// Get all merchants
router.get('/', async (req, res) => {
  try {
    const merchants = await Merchant.find().populate('promotions');
    res.status(200).json(merchants);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching merchants', error });
  }
});

// Get a merchant by ID
router.get('/:id', async (req, res) => {
  try {
    const merchant = await Merchant.findById(req.params.id).populate('promotions');
    if (!merchant) return res.status(404).json({ message: 'Merchant not found' });
    res.status(200).json(merchant);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching merchant', error });
  }
});

// Create a new merchant
router.post('/', async (req, res) => {
  try {
    const { name, profile, contactInfo, userId } = req.body;
    
    // Create the merchant
    const merchant = new Merchant({
      name,
      profile,
      contactInfo,
      promotions: []
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
    res.status(500).json({ message: 'Error creating merchant', error });
  }
});

// Update a merchant
router.put('/:id', async (req, res) => {
  try {
    const { name, profile, contactInfo } = req.body;
    
    const updatedMerchant = await Merchant.findByIdAndUpdate(
      req.params.id,
      { name, profile, contactInfo },
      { new: true }
    );
    
    if (!updatedMerchant) {
      return res.status(404).json({ message: 'Merchant not found' });
    }
    
    res.status(200).json(updatedMerchant);
  } catch (error) {
    res.status(500).json({ message: 'Error updating merchant', error });
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
    res.status(500).json({ message: 'Error deleting merchant', error });
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
    res.status(500).json({ message: 'Error fetching dashboard data', error });
  }
});

module.exports = router;