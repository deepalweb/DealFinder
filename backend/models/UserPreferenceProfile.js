const mongoose = require('mongoose');

const userPreferenceProfileSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true,
    index: true,
  },
  categoryAffinity: {
    type: Map,
    of: Number,
    default: {},
  },
  merchantAffinity: {
    type: Map,
    of: Number,
    default: {},
  },
  topCategories: [{ type: String }],
  topMerchantIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Merchant' }],
  topQueryTerms: [{ type: String }],
  preferredRadiusKm: { type: Number, default: 10 },
  lastKnownLocation: {
    latitude: { type: Number },
    longitude: { type: Number },
    updatedAt: { type: Date },
  },
  segment: {
    name: { type: String, default: 'cold_start' },
    confidence: { type: Number, default: 0.2 },
  },
  stats: {
    searchCount: { type: Number, default: 0 },
    viewCount: { type: Number, default: 0 },
    clickCount: { type: Number, default: 0 },
    favoriteCount: { type: Number, default: 0 },
    nearbySearchCount: { type: Number, default: 0 },
  },
  lastActiveAt: { type: Date, default: Date.now },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

userPreferenceProfileSchema.pre('save', function onSave(next) {
  this.updatedAt = new Date();
  next();
});

module.exports = mongoose.model('UserPreferenceProfile', userPreferenceProfileSchema);
