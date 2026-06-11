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
  fulfillmentType: {
    type: String,
    enum: ['visit', 'order', 'hybrid'],
    default: 'visit',
    index: true
  },
  orderLink: { type: String },
  visitAvailable: { type: Boolean, default: true },
  deliveryAvailable: { type: Boolean, default: false },
  pickupAvailable: { type: Boolean, default: false },
  featured: { type: Boolean, default: false },
  originalPrice: { type: Number },
  discountedPrice: { type: Number },
  bankName: { type: String, trim: true },
  cardTypes: [{
    type: String,
    enum: ['credit', 'debit', 'prepaid'],
  }],
  offerType: {
    type: String,
    enum: [
      'discount',
      'cashback',
      'installment',
      'dining',
      'grocery',
      'fuel',
      'travel',
      'electronics',
      'online',
      'other',
    ],
  },
  minimumSpend: { type: Number, min: 0 },
  maximumBenefit: { type: Number, min: 0 },
  status: {
    type: String,
    enum: [
      'active',
      'scheduled',
      'expired',
      'rejected',
      'admin_paused',
      'draft'
    ],
    default: 'draft'
  },
  adminVerified: { type: Boolean, default: false, index: true },
  verifiedAt: { type: Date },
  verifiedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  comments: [{
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    text: { type: String, required: true },
    createdAt: { type: Date, default: Date.now }
  }],
  ratings: [{
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    value: { type: Number, min: 1, max: 5, required: true },
    createdAt: { type: Date, default: Date.now }
  }],
  redemptionFeedback: [{
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    worked: { type: Boolean, required: true },
    createdAt: { type: Date, default: Date.now }
  }]
}, {
  timestamps: true,
});

// Indexes for the main query: status + date range filter
promotionSchema.index({ status: 1, endDate: 1, startDate: 1, _id: -1 });
promotionSchema.index({ merchant: 1, status: 1 });
promotionSchema.index({ featured: 1, status: 1, _id: -1 });
promotionSchema.index({ fulfillmentType: 1, status: 1, endDate: 1 });

module.exports = mongoose.model('Promotion', promotionSchema);
