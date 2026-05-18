const express = require('express');
const mongoose = require('mongoose');
const { body, validationResult } = require('express-validator');
const BankOffer = require('../models/BankOffer');
const { authenticateJWT, authorizeAdmin } = require('../middleware/auth');

const router = express.Router();

const COLOMBO_TIME_ZONE = 'Asia/Colombo';
const COLOMBO_OFFSET = '+05:30';
const DATE_ONLY_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

function safeError(error) {
  if (process.env.NODE_ENV === 'production') {
    return { message: 'An error occurred' };
  }
  return { message: error.message, stack: error.stack };
}

function getColomboDateKey(value = new Date()) {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: COLOMBO_TIME_ZONE,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(value);

  const year = parts.find((part) => part.type === 'year')?.value;
  const month = parts.find((part) => part.type === 'month')?.value;
  const day = parts.find((part) => part.type === 'day')?.value;

  return `${year}-${month}-${day}`;
}

function getColomboDayRange(value = new Date()) {
  const dateKey = getColomboDateKey(value);
  const start = new Date(`${dateKey}T00:00:00.000${COLOMBO_OFFSET}`);
  const endExclusive = new Date(start.getTime() + 24 * 60 * 60 * 1000);
  return { start, endExclusive };
}

function normalizeDateInput(value, boundary = 'start') {
  if (!value) return value;
  if (value instanceof Date) return value;
  if (typeof value === 'string' && DATE_ONLY_PATTERN.test(value)) {
    const time = boundary === 'end' ? '23:59:59.999' : '00:00:00.000';
    return new Date(`${value}T${time}${COLOMBO_OFFSET}`);
  }
  return new Date(value);
}

function resolveLifecycleStatus(startDate, endDate, value = new Date()) {
  const { start, endExclusive } = getColomboDayRange(value);
  if (endDate < start) return 'expired';
  if (startDate >= endExclusive) return 'scheduled';
  return 'active';
}

function buildActiveQuery(value = new Date()) {
  const { start, endExclusive } = getColomboDayRange(value);
  return {
    status: { $in: ['active', 'scheduled'] },
    startDate: { $lt: endExclusive },
    endDate: { $gte: start },
  };
}

function normalizeCardTypes(cardTypes) {
  if (!Array.isArray(cardTypes)) return [];
  return cardTypes
    .map((type) => String(type || '').trim().toLowerCase())
    .filter((type) => ['credit', 'debit', 'prepaid'].includes(type));
}

function normalizeBankOfferPayload(body = {}) {
  const applicableMerchants = Array.isArray(body.applicableMerchants)
    ? body.applicableMerchants
        .map((merchantId) => String(merchantId || '').trim())
        .filter((merchantId) => mongoose.Types.ObjectId.isValid(merchantId))
    : [];

  return {
    title: String(body.title || '').trim(),
    description: String(body.description || '').trim(),
    discount: String(body.discount || '').trim(),
    code: String(body.code || '').trim().toUpperCase(),
    bankName: String(body.bankName || '').trim(),
    cardTypes: normalizeCardTypes(body.cardTypes),
    offerType: String(body.offerType || '').trim().toLowerCase(),
    applicableCategories: Array.isArray(body.applicableCategories)
      ? body.applicableCategories.map((item) => String(item || '').trim()).filter(Boolean)
      : [],
    applicableMerchants,
    minimumSpend:
      body.minimumSpend === undefined || body.minimumSpend === null || body.minimumSpend === ''
        ? undefined
        : parseFloat(body.minimumSpend),
    maximumBenefit:
      body.maximumBenefit === undefined || body.maximumBenefit === null || body.maximumBenefit === ''
        ? undefined
        : parseFloat(body.maximumBenefit),
    termsAndConditions: String(body.termsAndConditions || '').trim(),
    image: typeof body.image === 'string' ? body.image : '',
    images: Array.isArray(body.images) ? body.images.filter((item) => typeof item === 'string' && item.trim()) : [],
    url: typeof body.url === 'string' ? body.url : '',
    featured: body.featured === true || body.featured === 'true',
    isSponsored: body.isSponsored === undefined ? true : body.isSponsored === true || body.isSponsored === 'true',
    priority:
      body.priority === undefined || body.priority === null || body.priority === ''
        ? 0
        : parseInt(body.priority, 10),
  };
}

function validateNormalizedBankOffer(data) {
  const errors = [];
  if (!data.title) errors.push({ msg: 'Title is required.', path: 'title' });
  if (!data.description) errors.push({ msg: 'Description is required.', path: 'description' });
  if (!data.discount) errors.push({ msg: 'Offer summary is required.', path: 'discount' });
  if (!data.code) errors.push({ msg: 'Promo code is required.', path: 'code' });
  if (!data.bankName) errors.push({ msg: 'Bank name is required.', path: 'bankName' });
  if (!data.cardTypes.length) errors.push({ msg: 'At least one card type is required.', path: 'cardTypes' });
  if (!data.offerType) errors.push({ msg: 'Offer type is required.', path: 'offerType' });
  if (data.minimumSpend !== undefined && Number.isNaN(data.minimumSpend)) {
    errors.push({ msg: 'Minimum spend must be a valid number.', path: 'minimumSpend' });
  }
  if (data.maximumBenefit !== undefined && Number.isNaN(data.maximumBenefit)) {
    errors.push({ msg: 'Maximum benefit must be a valid number.', path: 'maximumBenefit' });
  }
  if (Number.isNaN(data.priority)) {
    errors.push({ msg: 'Priority must be a valid integer.', path: 'priority' });
  }
  return errors;
}

router.get('/', async (req, res) => {
  try {
    const query = buildActiveQuery();
    const limit = Math.min(parseInt(req.query.limit, 10) || 100, 200);
    const offers = await BankOffer.find(query)
      .sort({ featured: -1, priority: -1, createdAt: -1, _id: -1 })
      .limit(limit)
      .lean();
    res.status(200).json(offers);
  } catch (error) {
    console.error('Error in GET /api/bank-offers:', error);
    res.status(500).json(safeError(error));
  }
});

router.get('/admin', authenticateJWT, authorizeAdmin, async (_req, res) => {
  try {
    const offers = await BankOffer.find({})
      .sort({ createdAt: -1, _id: -1 })
      .lean();
    res.status(200).json(offers);
  } catch (error) {
    console.error('Error in GET /api/bank-offers/admin:', error);
    res.status(500).json(safeError(error));
  }
});

router.get('/:id', async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ message: 'Invalid bank offer ID.' });
    }
    const offer = await BankOffer.findById(req.params.id).lean();
    if (!offer) {
      return res.status(404).json({ message: 'Bank offer not found.' });
    }
    res.status(200).json(offer);
  } catch (error) {
    console.error(`Error in GET /api/bank-offers/${req.params.id}:`, error);
    res.status(500).json(safeError(error));
  }
});

const writeValidators = [
  body('title').optional().isString(),
  body('description').optional().isString(),
  body('discount').optional().isString(),
  body('code').optional().isString(),
  body('bankName').optional().isString(),
  body('cardTypes').optional().isArray().withMessage('Card types must be an array.'),
  body('offerType').optional().isString(),
  body('applicableCategories').optional().isArray().withMessage('Applicable categories must be an array.'),
  body('applicableMerchants').optional().isArray().withMessage('Applicable merchants must be an array.'),
  body('minimumSpend').optional().isNumeric().withMessage('Minimum spend must be a number.'),
  body('maximumBenefit').optional().isNumeric().withMessage('Maximum benefit must be a number.'),
  body('termsAndConditions').optional().isString(),
  body('image').optional().isString(),
  body('images').optional().isArray().withMessage('Images must be an array.'),
  body('url').optional().isString(),
  body('featured').optional().isBoolean(),
  body('isSponsored').optional().isBoolean(),
  body('priority').optional().isInt().withMessage('Priority must be an integer.'),
  body('startDate').optional().isISO8601().withMessage('Start date must be a valid date.'),
  body('endDate').optional().isISO8601().withMessage('End date must be a valid date.'),
  body('status').optional().isIn(['active', 'scheduled', 'expired', 'rejected', 'admin_paused', 'draft'])
    .withMessage('Invalid status value provided.'),
];

router.post('/', authenticateJWT, authorizeAdmin, writeValidators, async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ message: 'Validation failed', errors: errors.array() });
  }

  try {
    const normalized = normalizeBankOfferPayload(req.body);
    const normalizedStartDate = normalizeDateInput(req.body.startDate, 'start');
    const normalizedEndDate = normalizeDateInput(req.body.endDate, 'end');
    const normalizedErrors = validateNormalizedBankOffer(normalized);
    if (!normalizedStartDate || Number.isNaN(normalizedStartDate.getTime())) {
      normalizedErrors.push({ msg: 'Start date is required.', path: 'startDate' });
    }
    if (!normalizedEndDate || Number.isNaN(normalizedEndDate.getTime())) {
      normalizedErrors.push({ msg: 'End date is required.', path: 'endDate' });
    }
    if (normalizedStartDate && normalizedEndDate && normalizedEndDate < normalizedStartDate) {
      normalizedErrors.push({ msg: 'End date must be the same day or later than start date.', path: 'endDate' });
    }
    if (normalizedErrors.length) {
      return res.status(400).json({ message: 'Validation failed', errors: normalizedErrors });
    }

    let status = resolveLifecycleStatus(normalizedStartDate, normalizedEndDate);
    if (['rejected', 'admin_paused', 'draft'].includes(req.body.status)) {
      status = req.body.status;
    }

    const payload = {
      ...normalized,
      category: 'bank_cards',
      image: normalized.image || undefined,
      images: normalized.images,
      url: normalized.url || undefined,
      termsAndConditions: normalized.termsAndConditions || undefined,
      startDate: normalizedStartDate,
      endDate: normalizedEndDate,
      status,
      createdBy: req.user.id,
      updatedBy: req.user.id,
    };

    const offer = new BankOffer(payload);
    const saved = await offer.save();
    res.status(201).json(saved);
  } catch (error) {
    console.error('Error creating bank offer:', error);
    res.status(500).json(safeError(error));
  }
});

router.put('/:id', authenticateJWT, authorizeAdmin, writeValidators, async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ message: 'Validation failed', errors: errors.array() });
  }

  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ message: 'Invalid bank offer ID.' });
    }

    const existing = await BankOffer.findById(req.params.id);
    if (!existing) {
      return res.status(404).json({ message: 'Bank offer not found.' });
    }

    const normalized = normalizeBankOfferPayload({ ...existing.toObject(), ...req.body });
    const normalizedStartDate = req.body.startDate !== undefined
      ? normalizeDateInput(req.body.startDate, 'start')
      : existing.startDate;
    const normalizedEndDate = req.body.endDate !== undefined
      ? normalizeDateInput(req.body.endDate, 'end')
      : existing.endDate;
    const normalizedErrors = validateNormalizedBankOffer(normalized);

    if (!normalizedStartDate || Number.isNaN(normalizedStartDate.getTime())) {
      normalizedErrors.push({ msg: 'Start date is required.', path: 'startDate' });
    }
    if (!normalizedEndDate || Number.isNaN(normalizedEndDate.getTime())) {
      normalizedErrors.push({ msg: 'End date is required.', path: 'endDate' });
    }
    if (normalizedStartDate && normalizedEndDate && normalizedEndDate < normalizedStartDate) {
      normalizedErrors.push({ msg: 'End date must be the same day or later than start date.', path: 'endDate' });
    }
    if (normalizedErrors.length) {
      return res.status(400).json({ message: 'Validation failed', errors: normalizedErrors });
    }

    let status = resolveLifecycleStatus(normalizedStartDate, normalizedEndDate);
    if (req.body.status && ['rejected', 'admin_paused', 'draft', 'active', 'scheduled', 'expired'].includes(req.body.status)) {
      if (['active', 'scheduled', 'expired'].includes(req.body.status)) {
        status = resolveLifecycleStatus(normalizedStartDate, normalizedEndDate);
      } else {
        status = req.body.status;
      }
    }

    const payload = {
      ...normalized,
      category: 'bank_cards',
      image: normalized.image || undefined,
      images: normalized.images,
      url: normalized.url || undefined,
      termsAndConditions: normalized.termsAndConditions || undefined,
      startDate: normalizedStartDate,
      endDate: normalizedEndDate,
      status,
      updatedBy: req.user.id,
    };

    const updated = await BankOffer.findByIdAndUpdate(
      req.params.id,
      payload,
      { new: true, runValidators: true }
    );
    res.status(200).json(updated);
  } catch (error) {
    console.error(`Error updating bank offer ${req.params.id}:`, error);
    res.status(500).json(safeError(error));
  }
});

router.delete('/:id', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ message: 'Invalid bank offer ID.' });
    }
    const deleted = await BankOffer.findByIdAndDelete(req.params.id);
    if (!deleted) {
      return res.status(404).json({ message: 'Bank offer not found.' });
    }
    res.status(200).json({ message: 'Bank offer deleted successfully.' });
  } catch (error) {
    console.error(`Error deleting bank offer ${req.params.id}:`, error);
    res.status(500).json(safeError(error));
  }
});

module.exports = router;
