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
    const now = new Date();
    const in7Days = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

    const totalUsers = await User.countDocuments();
    const totalMerchants = await Merchant.countDocuments();
    const pendingMerchants = await Merchant.countDocuments({ status: 'pending_approval' });
    const activeMerchants = await Merchant.countDocuments({ status: 'active' });

    const totalPromotions = await Promotion.countDocuments();

    const [pending, active, scheduled, expired, rejected, paused, draft, activePromotions] = await Promise.all([
      Promotion.countDocuments({ status: 'pending_approval' }),
      Promotion.countDocuments({ status: 'active' }),
      Promotion.countDocuments({ status: 'scheduled' }),
      Promotion.countDocuments({ status: 'expired' }),
      Promotion.countDocuments({ status: 'rejected' }),
      Promotion.countDocuments({ status: 'admin_paused' }),
      Promotion.countDocuments({ status: 'draft' }),
      Promotion.countDocuments({
        status: { $in: ['active', 'approved'] },
        startDate: { $lte: now },
        endDate: { $gte: now },
      }),
    ]);

    const expiringSoon = await Promotion.find({
      status: { $in: ['active', 'approved'] },
      startDate: { $lte: now },
      endDate: { $gte: now, $lte: in7Days },
    }).populate('merchant', 'name').sort({ endDate: 1 }).limit(10).lean();

    // Recent activity — last 10 events across users, merchants, promotions
    const [recentUsers, recentMerchants, recentPromotions] = await Promise.all([
      User.find().sort({ createdAt: -1 }).limit(5).select('name email role createdAt').lean(),
      Merchant.find().sort({ createdAt: -1 }).limit(5).select('name status createdAt').lean(),
      Promotion.find().sort({ createdAt: -1 }).limit(5).select('title status createdAt merchant').populate('merchant', 'name').lean(),
    ]);

    const activity = [
      ...recentUsers.map(u => ({ type: 'user', label: `${u.name} registered`, sub: u.role, time: u.createdAt })),
      ...recentMerchants.map(m => ({ type: 'merchant', label: `${m.name} joined`, sub: m.status, time: m.createdAt })),
      ...recentPromotions.map(p => ({ type: 'promotion', label: p.title, sub: `${p.status} · ${typeof p.merchant === 'object' ? p.merchant?.name : ''}`, time: p.createdAt })),
    ].sort((a, b) => new Date(b.time).getTime() - new Date(a.time).getTime()).slice(0, 10);

    res.status(200).json({
      totalUsers,
      totalMerchants,
      merchantsByStatus: { pending_approval: pendingMerchants, active: activeMerchants },
      totalPromotions,
      activePromotions,
      promotionsByStatus: {
        active,
        scheduled,
        pending_approval: pending,
        expired,
        rejected,
        admin_paused: paused,
        draft,
      },
      expiringSoon,
      activity,
    });

  } catch (error) {
    console.error('Error fetching admin dashboard stats:', error);
    res.status(500).json(safeError(error));
  }
});

module.exports = router;
