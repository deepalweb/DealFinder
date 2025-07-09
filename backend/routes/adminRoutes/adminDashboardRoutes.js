const express = require('express');
const router = express.Router();
const User = require('../../models/User');
const Merchant = require('../../models/Merchant');
const Promotion = require('../../models/Promotion');
const { authenticateJWT, authorizeAdmin } = require('../../middleware/auth');

// Add safeError helper
function safeError(error) {
  if (process.env.NODE_ENV === 'production') {
    return { message: 'An error occurred' };
  }
  return { message: error.message, stack: error.stack };
}

// GET /api/admin/dashboard/stats - Fetch summary statistics for admin dashboard
router.get('/dashboard/stats', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const totalMerchants = await Merchant.countDocuments();
    const pendingMerchants = await Merchant.countDocuments({ status: 'pending_approval' });
    // Add other merchant statuses if needed, e.g., active, suspended
    // const activeMerchants = await Merchant.countDocuments({ status: 'active' });

    const totalPromotions = await Promotion.countDocuments();
    const pendingPromotions = await Promotion.countDocuments({ status: 'pending_approval' });
    // Add other promotion statuses if needed
    // const activePromotions = await Promotion.countDocuments({ status: 'active' });
    // Note: 'active' for promotions also depends on date, so a simple count on 'active' status might be misleading
    // if not also filtering by date. For a dashboard, 'approved' might be a better metric,
    // or specific counts for 'currently_live_approved_promotions'.
    // For simplicity, we'll stick to 'pending_approval' for now.

    res.status(200).json({
      totalUsers,
      totalMerchants,
      merchantsByStatus: {
        pending_approval: pendingMerchants,
        // active: activeMerchants, // Example
      },
      totalPromotions,
      promotionsByStatus: {
        pending_approval: pendingPromotions,
        // active: activePromotions, // Example
      }
    });

  } catch (error) {
    console.error('Error fetching admin dashboard stats:', error);
    res.status(500).json(safeError(error));
  }
});

module.exports = router;
