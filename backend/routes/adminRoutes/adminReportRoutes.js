const express = require('express');
const router = express.Router();
const Report = require('../../models/Report');
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

module.exports = router;
