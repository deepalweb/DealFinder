const mongoose = require('mongoose');

const redemptionSchema = new mongoose.Schema({
  promotion: { type: mongoose.Schema.Types.ObjectId, ref: 'Promotion', required: true, index: true },
  merchant: { type: mongoose.Schema.Types.ObjectId, ref: 'Merchant', required: true, index: true },
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  token: { type: String, required: true, unique: true, index: true },
  status: {
    type: String,
    enum: ['issued', 'redeemed', 'expired', 'cancelled'],
    default: 'issued',
    index: true,
  },
  expiresAt: { type: Date, required: true, index: true },
  redeemedAt: { type: Date },
  redeemedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
}, {
  timestamps: true,
});

redemptionSchema.index({ promotion: 1, user: 1, status: 1 });

module.exports = mongoose.model('Redemption', redemptionSchema);
