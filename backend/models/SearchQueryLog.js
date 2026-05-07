const mongoose = require('mongoose');

const searchQueryLogSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
  sessionId: { type: String, index: true },
  query: { type: String, required: true },
  normalizedQuery: { type: String, index: true },
  explicitFilters: { type: Object },
  interpretedFilters: { type: Object },
  location: {
    latitude: { type: Number },
    longitude: { type: Number },
    radiusKm: { type: Number },
  },
  resultCount: { type: Number, default: 0 },
  aiUsed: { type: Boolean, default: false },
  fallbackUsed: { type: Boolean, default: false },
  latencyMs: { type: Number, default: 0 },
  topPromotionIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Promotion' }],
  createdAt: { type: Date, default: Date.now, index: true },
});

searchQueryLogSchema.index({ normalizedQuery: 1, createdAt: -1 });

module.exports = mongoose.model('SearchQueryLog', searchQueryLogSchema);
