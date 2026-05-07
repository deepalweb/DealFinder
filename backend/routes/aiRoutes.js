const express = require('express');
const mongoose = require('mongoose');
const { body, query, validationResult } = require('express-validator');
const Merchant = require('../models/Merchant');
const Promotion = require('../models/Promotion');
const UserBehaviorEvent = require('../models/UserBehaviorEvent');
const { authenticateJWT, gentleAuthenticateJWT } = require('../middleware/auth');
const { getAiConfig, isAzureOpenAIConfigured } = require('../services/ai/config');
const { searchPromotions } = require('../services/ai/recommendationService');
const { understandSearchQuery } = require('../services/ai/queryUnderstandingService');
const { ensureUserPreferenceProfile, refreshUserPreferenceProfile } = require('../services/ai/userProfileService');
const { normalizeCategoryId } = require('../services/ai/searchTaxonomy');

const router = express.Router();

function safeError(error) {
  if (process.env.NODE_ENV === 'production') {
    return { message: 'An error occurred' };
  }
  return { message: error.message, stack: error.stack };
}

function handleValidationErrors(req, res) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    res.status(400).json({ errors: errors.array() });
    return true;
  }
  return false;
}

function sanitizeObjectId(value) {
  if (!value) return undefined;
  return mongoose.Types.ObjectId.isValid(value) ? value : undefined;
}

// Phase 0: event ingestion
router.post('/events', gentleAuthenticateJWT, [
  body('eventType').isString().trim().notEmpty().withMessage('eventType is required'),
  body('platform').optional().isIn(['web', 'mobile', 'backend', 'unknown']),
  body('query').optional().isString(),
  body('category').optional().isString(),
  body('sessionId').optional().isString(),
], async (req, res) => {
  if (handleValidationErrors(req, res)) return;

  try {
    const {
      eventType,
      platform,
      query: rawQuery,
      category,
      filters,
      sessionId,
      location,
      metadata,
      promotionId,
      merchantId,
    } = req.body;

    const event = await UserBehaviorEvent.create({
      userId: req.user?.id || undefined,
      sessionId: sessionId || undefined,
      platform: platform || 'unknown',
      eventType,
      query: rawQuery ? String(rawQuery).trim() : undefined,
      category: category ? normalizeCategoryId(category) : undefined,
      filters: filters && typeof filters === 'object' ? filters : undefined,
      location: location && typeof location === 'object' ? location : undefined,
      metadata: metadata && typeof metadata === 'object' ? metadata : undefined,
      promotionId: sanitizeObjectId(promotionId),
      merchantId: sanitizeObjectId(merchantId),
    });

    if (req.user?.id) {
      refreshUserPreferenceProfile(req.user.id).catch((error) => {
        console.warn('[AI Events] Profile refresh failed:', error.message);
      });
    }

    res.status(201).json({
      message: 'Event captured',
      eventId: event._id,
    });
  } catch (error) {
    console.error('Error in POST /api/ai/events:', error);
    res.status(500).json(safeError(error));
  }
});

// Phase 0: profile debugging endpoint
router.get('/profile/me', authenticateJWT, async (req, res) => {
  try {
    const profile = await ensureUserPreferenceProfile(req.user.id);
    res.status(200).json(profile || { message: 'No profile available yet.' });
  } catch (error) {
    console.error('Error in GET /api/ai/profile/me:', error);
    res.status(500).json(safeError(error));
  }
});

// Phase 1: AI search
router.post('/search', gentleAuthenticateJWT, [
  body('query').optional().isString(),
  body('filters').optional().isObject(),
  body('location').optional().isObject(),
  body('limit').optional().isInt({ min: 1, max: 50 }),
  body('sessionId').optional().isString(),
  body('model').optional().isString(),
], async (req, res) => {
  if (handleValidationErrors(req, res)) return;

  try {
    const {
      query: rawQuery = '',
      filters = {},
      location = null,
      limit = 20,
      sessionId,
      model,
    } = req.body;

    const interpretedQuery = await understandSearchQuery({
      query: rawQuery,
      location,
      model,
    });

    const response = await searchPromotions({
      userId: req.user?.id,
      sessionId,
      query: rawQuery,
      explicitFilters: filters,
      interpretedQuery,
      location,
      limit,
    });

    res.status(200).json(response);
  } catch (error) {
    console.error('Error in POST /api/ai/search:', error);
    res.status(500).json(safeError(error));
  }
});

router.get('/search/suggestions', gentleAuthenticateJWT, [
  query('q').isString().trim().isLength({ min: 1 }).withMessage('q is required'),
], async (req, res) => {
  if (handleValidationErrors(req, res)) return;

  try {
    const rawQuery = String(req.query.q || '').trim();
    const regex = new RegExp(rawQuery.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');

    const [promotions, merchants] = await Promise.all([
      Promotion.find({
        status: { $in: ['active', 'approved'] },
        $or: [
          { title: regex },
          { description: regex },
          { category: regex },
        ],
      }).select('title category').limit(12).lean(),
      Merchant.find({ name: regex }).select('name category').limit(8).lean(),
    ]);

    const suggestions = new Set();
    promotions.forEach((promotion) => {
      if (promotion.title) suggestions.add(promotion.title);
      if (promotion.category) suggestions.add(normalizeCategoryId(promotion.category));
    });
    merchants.forEach((merchant) => {
      if (merchant.name) suggestions.add(merchant.name);
      if (merchant.category) suggestions.add(normalizeCategoryId(merchant.category));
    });

    res.status(200).json({
      suggestions: [...suggestions].slice(0, 12),
    });
  } catch (error) {
    console.error('Error in GET /api/ai/search/suggestions:', error);
    res.status(500).json(safeError(error));
  }
});

router.get('/status', (_req, res) => {
  const config = getAiConfig();
  res.status(200).json({
    enabled: config.aiSearchEnabled,
    personalizationEnabled: config.personalizationEnabled,
    azureConfigured: isAzureOpenAIConfigured(),
    model: config.model,
    apiVersion: config.apiVersion,
  });
});

module.exports = router;
