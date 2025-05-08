const express = require('express');
const router = express.Router();
const Promotion = require('../models/Promotion');
const Merchant = require('../models/Merchant');

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
    
    res.status(500).json({ 
      message: 'Error fetching promotions', 
      errorName: error.name,
      errorMessage: error.message,
      errorCode: error.code
    });
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
    res.status(500).json({ message: 'Error fetching promotion', error: error.message });
  }
});

// Get promotions by merchant ID
router.get('/merchant/:merchantId', async (req, res) => {
  try {
    const promotions = await Promotion.find({ merchant: req.params.merchantId });
    res.status(200).json(promotions);
  } catch (error) {
    console.error(`Error fetching promotions for merchant ${req.params.merchantId}:`, error);
    res.status(500).json({ message: 'Error fetching merchant promotions', error: error.message });
  }
});

// Create a new promotion
router.post('/', async (req, res) => {
  try {
    const { title, description, discount, code, category, startDate, endDate, image, url, merchantId } = req.body;
    
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
      status: new Date(endDate) > new Date() ? 'active' : 'expired'
    });
    
    const savedPromotion = await promotion.save();
    
    // Add promotion to merchant's promotions array
    merchant.promotions.push(savedPromotion._id);
    await merchant.save();
    
    res.status(201).json(savedPromotion);
  } catch (error) {
    console.error('Error creating promotion:', error);
    res.status(500).json({ message: 'Error creating promotion', error: error.message });
  }
});

// Update a promotion
router.put('/:id', async (req, res) => {
  try {
    const { title, description, discount, code, category, startDate, endDate, image, url } = req.body;
    
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
    res.status(500).json({ message: 'Error updating promotion', error: error.message });
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
    res.status(500).json({ message: 'Error deleting promotion', error: error.message });
  }
});

module.exports = router;