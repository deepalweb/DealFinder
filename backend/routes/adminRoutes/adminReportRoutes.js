const express = require('express');
const router = express.Router();
const Report = require('../../models/Report');
const Promotion = require('../../models/Promotion');
const Merchant = require('../../models/Merchant');
const { authenticateJWT, authorizeAdmin } = require('../../middleware/auth');

function safeError(error) {
  if (process.env.NODE_ENV === 'production') {
    return { message: 'An error occurred' };
  }
  return { message: error.message, stack: error.stack };
}

router.get('/reports', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const { status = 'open', targetType = 'all', limit = 100 } = req.query;
    const query = {};
    if (status !== 'all') query.status = status;
    if (targetType !== 'all') query.targetType = targetType;

    const reports = await Report.find(query)
      .populate('promotion', 'title status category image')
      .populate('merchant', 'name status logo category')
      .populate('reporter', 'name email')
      .populate('resolvedBy', 'name email')
      .sort({ createdAt: -1 })
      .limit(Math.min(parseInt(limit, 10) || 100, 250))
      .lean();

    res.status(200).json(reports);
  } catch (error) {
    console.error('Error in GET /api/admin/reports:', error);
    res.status(500).json(safeError(error));
  }
});

router.patch('/reports/:id', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const { status, resolutionNote } = req.body;
    const validStatuses = ['open', 'reviewing', 'resolved', 'dismissed'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ message: 'Valid report status is required.' });
    }

    const update = {
      status,
      resolutionNote: typeof resolutionNote === 'string' ? resolutionNote.trim() : '',
    };
    const updateOperation = { $set: update };
    if (status === 'resolved' || status === 'dismissed') {
      update.resolvedBy = req.user.id;
      update.resolvedAt = new Date();
    } else {
      updateOperation.$unset = { resolvedBy: 1, resolvedAt: 1 };
    }

    const report = await Report.findByIdAndUpdate(
      req.params.id,
      updateOperation,
      { new: true, runValidators: true }
    )
      .populate('promotion', 'title status category image')
      .populate('merchant', 'name status logo category')
      .populate('reporter', 'name email')
      .populate('resolvedBy', 'name email');

    if (!report) return res.status(404).json({ message: 'Report not found' });
    res.status(200).json(report);
  } catch (error) {
    console.error(`Error in PATCH /api/admin/reports/${req.params.id}:`, error);
    res.status(500).json(safeError(error));
  }
});

router.post('/reports/:id/action', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const { action } = req.body || {};
    const report = await Report.findById(req.params.id);
    if (!report) return res.status(404).json({ message: 'Report not found' });

    if (action === 'pause_promotion') {
      if (!report.promotion) return res.status(400).json({ message: 'Report is not linked to a promotion.' });
      await Promotion.findByIdAndUpdate(report.promotion, { $set: { status: 'admin_paused' } });
      report.status = 'resolved';
      report.resolutionNote = 'Promotion paused from report queue.';
    } else if (action === 'verify_promotion') {
      if (!report.promotion) return res.status(400).json({ message: 'Report is not linked to a promotion.' });
      await Promotion.findByIdAndUpdate(report.promotion, {
        $set: {
          adminVerified: true,
          verifiedAt: new Date(),
          verifiedBy: req.user.id,
        },
      });
      report.status = 'resolved';
      report.resolutionNote = 'Promotion verified from report queue.';
    } else if (action === 'suspend_merchant') {
      if (!report.merchant) return res.status(400).json({ message: 'Report is not linked to a merchant.' });
      await Merchant.findByIdAndUpdate(report.merchant, { $set: { status: 'suspended' } });
      report.status = 'resolved';
      report.resolutionNote = 'Merchant suspended from report queue.';
    } else {
      return res.status(400).json({ message: 'Unsupported report action.' });
    }

    report.resolvedBy = req.user.id;
    report.resolvedAt = new Date();
    await report.save();

    const populated = await Report.findById(report._id)
      .populate('promotion', 'title status category image adminVerified verifiedAt')
      .populate('merchant', 'name status logo category')
      .populate('reporter', 'name email')
      .populate('resolvedBy', 'name email');

    res.status(200).json(populated);
  } catch (error) {
    console.error(`Error in POST /api/admin/reports/${req.params.id}/action:`, error);
    res.status(500).json(safeError(error));
  }
});

module.exports = router;
