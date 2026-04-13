const mongoose = require('mongoose');

const promotionSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String, required: true },
  discount: { type: String, required: true },
  code: { type: String, required: true },
  category: { type: String, required: true },
  merchant: { type: mongoose.Schema.Types.ObjectId, ref: 'Merchant', required: true },
  startDate: { type: Date, required: true },
  endDate: { type: Date, required: true },
  images: [{ type: String }],
  image: { type: String },
  url: { type: String },
  featured: { type: Boolean, default: false },
  originalPrice: { type: Number },
  discountedPrice: { type: Number },
  status: {
    type: String,
    enum: [
      'pending_approval',
      'approved',
      'active',
      'scheduled',
      'expired',
      'rejected',
      'admin_paused',
      'draft'
    ],
    default: 'pending_approval'
  },
  createdAt: { type: Date, default: Date.now },
  comments: [{
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    text: { type: String, required: true },
    createdAt: { type: Date, default: Date.now }
  }],
  ratings: [{
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    value: { type: Number, min: 1, max: 5, required: true },
    createdAt: { type: Date, default: Date.now }
  }]
});

// Indexes for the main query: status + date range filter
promotionSchema.index({ status: 1, endDate: 1, startDate: 1 });
promotionSchema.index({ merchant: 1, status: 1 });
promotionSchema.index({ featured: 1, status: 1 });

module.exports = mongoose.model('Promotion', promotionSchema);
