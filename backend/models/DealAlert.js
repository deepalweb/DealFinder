const mongoose = require('mongoose');

const dealAlertSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  promotion: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Promotion',
    required: true,
    index: true,
  },
  alertTypes: [{
    type: String,
    enum: ['expiry', 'price_drop'],
  }],
  active: { type: Boolean, default: true, index: true },
  lastExpiryNotifiedAt: { type: Date },
  lastPriceDropNotifiedAt: { type: Date },
}, {
  timestamps: true,
});

dealAlertSchema.index({ userId: 1, promotion: 1 }, { unique: true });
dealAlertSchema.index({ promotion: 1, active: 1 });

module.exports = mongoose.model('DealAlert', dealAlertSchema);
