const mongoose = require('mongoose');

const userBehaviorEventSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
  sessionId: { type: String, index: true },
  platform: {
    type: String,
    enum: ['web', 'mobile', 'backend', 'unknown'],
    default: 'unknown',
    index: true,
  },
  eventType: {
    type: String,
    enum: [
      'search_submitted',
      'search_result_clicked',
      'promotion_viewed',
      'promotion_clicked',
      'promotion_favorited',
      'promotion_unfavorited',
      'merchant_viewed',
      'nearby_search_used',
      'category_filter_used',
      'direction_requested',
    ],
    required: true,
    index: true,
  },
  promotionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Promotion', index: true },
  merchantId: { type: mongoose.Schema.Types.ObjectId, ref: 'Merchant', index: true },
  category: { type: String, index: true },
  query: { type: String },
  filters: { type: Object },
  location: {
    latitude: { type: Number },
    longitude: { type: Number },
    radiusKm: { type: Number },
    label: { type: String },
  },
  metadata: { type: Object },
  createdAt: { type: Date, default: Date.now, index: true },
});

userBehaviorEventSchema.index({ userId: 1, createdAt: -1 });
userBehaviorEventSchema.index({ eventType: 1, createdAt: -1 });

module.exports = mongoose.model('UserBehaviorEvent', userBehaviorEventSchema);
