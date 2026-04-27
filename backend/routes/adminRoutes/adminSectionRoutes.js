const express = require('express');
const mongoose = require('mongoose');
const { body, validationResult } = require('express-validator');
const { authenticateJWT, authorizeAdmin } = require('../../middleware/auth');
const SectionAssignment = require('../../models/SectionAssignment');
const Promotion = require('../../models/Promotion');
const {
  SECTION_KEYS,
  SECTION_CONFIG,
  getSectionManagerSnapshot,
  getConflicts,
  invalidateSectionCaches,
} = require('../../services/sectionService');

const router = express.Router();

function safeError(error) {
  if (process.env.NODE_ENV === 'production') {
    return { message: 'An error occurred' };
  }
  return { message: error.message, stack: error.stack };
}

function parseNullableNumber(value) {
  if (value === '' || value === null || value === undefined) return undefined;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : NaN;
}

router.get('/sections/config', authenticateJWT, authorizeAdmin, async (_req, res) => {
  res.status(200).json(SECTION_KEYS.map((key) => SECTION_CONFIG[key]));
});

router.get('/sections', authenticateJWT, authorizeAdmin, async (_req, res) => {
  try {
    const snapshot = await getSectionManagerSnapshot();
    res.status(200).json(snapshot);
  } catch (error) {
    console.error('Error in GET /api/admin/sections:', error);
    res.status(500).json(safeError(error));
  }
});

router.get('/sections/conflicts', authenticateJWT, authorizeAdmin, async (_req, res) => {
  try {
    res.status(200).json(await getConflicts());
  } catch (error) {
    console.error('Error in GET /api/admin/sections/conflicts:', error);
    res.status(500).json(safeError(error));
  }
});

router.post(
  '/sections/assignments',
  authenticateJWT,
  authorizeAdmin,
  [
    body('sectionKey').isIn(SECTION_KEYS),
    body('promotionId').optional().isString().notEmpty(),
    body('promotionIds').optional().isArray({ min: 1 }),
    body('promotionIds.*').optional().isString().notEmpty(),
    body('enabled').optional().isBoolean(),
    body('mode').optional().isIn(['manual', 'auto', 'forced', 'hidden', 'boosted', 'excluded']),
    body('priority').optional().isNumeric(),
    body('startAt').optional({ nullable: true }).isISO8601(),
    body('endAt').optional({ nullable: true }).isISO8601(),
    body('bannerImageUrl').optional({ nullable: true }).isString(),
    body('radiusKm').optional({ nullable: true }).isNumeric(),
    body('minDistanceKm').optional({ nullable: true }).isNumeric(),
    body('maxDistanceKm').optional({ nullable: true }).isNumeric(),
    body('excludeFromAuto').optional().isBoolean(),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ message: 'Validation failed', errors: errors.array() });
    }

    try {
      const {
        sectionKey,
        promotionId,
        promotionIds,
        enabled,
        mode,
        priority,
        startAt,
        endAt,
        bannerImageUrl,
        radiusKm,
        minDistanceKm,
        maxDistanceKm,
        excludeFromAuto,
        metadata,
      } = req.body;

      if (sectionKey === 'nearby') {
        return res.status(400).json({ message: 'Nearby deals are automatic and cannot be manually assigned.' });
      }

      const targetPromotionIds = Array.isArray(promotionIds) && promotionIds.length
        ? promotionIds
        : promotionId
          ? [promotionId]
          : [];

      if (!targetPromotionIds.length) {
        return res.status(400).json({ message: 'At least one promotion must be selected.' });
      }

      const invalidPromotionId = targetPromotionIds.find((id) => !mongoose.Types.ObjectId.isValid(id));
      if (invalidPromotionId) {
        return res.status(400).json({ message: 'One or more promotion IDs are invalid.' });
      }

      const promotions = await Promotion.find({ _id: { $in: targetPromotionIds } }).select('_id');
      if (promotions.length !== targetPromotionIds.length) {
        return res.status(404).json({ message: 'One or more selected promotions were not found.' });
      }

      const update = {
        enabled: enabled !== undefined ? enabled : true,
        mode: mode || 'manual',
        priority: priority !== undefined ? Number(priority) : 0,
        startAt: startAt || null,
        endAt: endAt || null,
        bannerImageUrl: bannerImageUrl || null,
        excludeFromAuto: excludeFromAuto === true,
        metadata: typeof metadata === 'object' && metadata ? metadata : {},
        updatedBy: req.user.id,
      };

      const parsedRadiusKm = parseNullableNumber(radiusKm);
      const parsedMinDistanceKm = parseNullableNumber(minDistanceKm);
      const parsedMaxDistanceKm = parseNullableNumber(maxDistanceKm);

      if (Number.isNaN(parsedRadiusKm) || Number.isNaN(parsedMinDistanceKm) || Number.isNaN(parsedMaxDistanceKm)) {
        return res.status(400).json({ message: 'Distance fields must be valid numbers.' });
      }

      if (parsedMinDistanceKm !== undefined && parsedMaxDistanceKm !== undefined && parsedMinDistanceKm > parsedMaxDistanceKm) {
        return res.status(400).json({ message: 'Minimum distance cannot exceed maximum distance.' });
      }

      update.radiusKm = parsedRadiusKm;
      update.minDistanceKm = parsedMinDistanceKm;
      update.maxDistanceKm = parsedMaxDistanceKm;

      const assignments = await Promise.all(
        targetPromotionIds.map((id) =>
          SectionAssignment.findOneAndUpdate(
            { sectionKey, promotion: id },
            { $set: update, $setOnInsert: { sectionKey, promotion: id } },
            { upsert: true, new: true }
          )
            .populate({
              path: 'promotion',
              populate: { path: 'merchant', select: 'name logo currency' },
            })
            .populate('updatedBy', 'name email')
        )
      );

      invalidateSectionCaches();
      res.status(200).json(assignments);
    } catch (error) {
      console.error('Error in POST /api/admin/sections/assignments:', error);
      res.status(500).json(safeError(error));
    }
  }
);

router.delete('/sections/assignments/:id', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const deleted = await SectionAssignment.findByIdAndDelete(req.params.id);
    if (!deleted) {
      return res.status(404).json({ message: 'Assignment not found.' });
    }

    invalidateSectionCaches();
    res.status(200).json({ message: 'Assignment removed.' });
  } catch (error) {
    console.error(`Error deleting section assignment ${req.params.id}:`, error);
    res.status(500).json(safeError(error));
  }
});

router.post('/sections/publish', authenticateJWT, authorizeAdmin, async (_req, res) => {
  try {
    invalidateSectionCaches();
    res.status(200).json({
      message: 'Section cache invalidated and latest curation is now live.',
      publishedAt: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Error in POST /api/admin/sections/publish:', error);
    res.status(500).json(safeError(error));
  }
});

module.exports = router;
