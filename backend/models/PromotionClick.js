// PromotionClick model for tracking promotion click analytics
const mongoose = require('mongoose');

const promotionClickSchema = new mongoose.Schema({
  promotion: { type: mongoose.Schema.Types.ObjectId, ref: 'Promotion', required: true },
  merchant: { type: mongoose.Schema.Types.ObjectId, ref: 'Merchant', required: true },
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, // optional
  timestamp: { type: Date, default: Date.now },
  type: { type: String, default: 'click' }
});

module.exports = mongoose.model('PromotionClick', promotionClickSchema);
