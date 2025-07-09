const express = require('express');
const router = express.Router();
const Promotion = require('../../models/Promotion');
const { authenticateJWT, authorizeAdmin } = require('../../middleware/auth');

// Add safeError helper
function safeError(error) {
  if (process.env.NODE_ENV === 'production') {
    return { message: 'An error occurred' };
  }
  return { message: error.message, stack: error.stack };
}

// Get all promotions for Admin (with potential filters)
router.get('/promotions', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const { status, merchantId, category, featured, sortBy = 'createdAt', sortOrder = 'desc' } = req.query;
    const filter = {};

    if (status) filter.status = status;
    if (merchantId) filter.merchant = merchantId;
    if (category) filter.category = category;
    if (featured !== undefined) filter.featured = featured === 'true';

    const sortOptions = {};
    if (['createdAt', 'startDate', 'endDate', 'title'].includes(sortBy)) {
      sortOptions[sortBy] = sortOrder === 'asc' ? 1 : -1;
    } else {
      sortOptions['createdAt'] = -1; // Default sort
    }

    // TODO: Add pagination
    // const page = parseInt(req.query.page) || 1;
    // const limit = parseInt(req.query.limit) || 20;
    // const skip = (page - 1) * limit;

    const promotions = await Promotion.find(filter)
      .populate('merchant', 'name') // Populate merchant name
      .sort(sortOptions);
      // .skip(skip)
      // .limit(limit);

    // const totalPromotions = await Promotion.countDocuments(filter);

    res.status(200).json({
      data: promotions,
      // currentPage: page,
      // totalPages: Math.ceil(totalPromotions / limit),
      // totalCount: totalPromotions
    });
  } catch (error) {
    console.error('Error in GET /api/admin/promotions:', error);
    res.status(500).json(safeError(error));
  }
});

module.exports = router;
