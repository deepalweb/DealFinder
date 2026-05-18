const mongoose = require('mongoose');

const bankOfferSchema = new mongoose.Schema({
  title: { type: String, required: true, trim: true },
  description: { type: String, required: true, trim: true },
  discount: { type: String, required: true, trim: true },
  code: { type: String, required: true, trim: true },
  category: { type: String, default: 'bank_cards', immutable: true },
  bankName: { type: String, required: true, trim: true, index: true },
  cardTypes: [{
    type: String,
    enum: ['credit', 'debit', 'prepaid'],
    required: true,
  }],
  offerType: {
    type: String,
    required: true,
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
    index: true,
  },
  applicableCategories: [{ type: String, trim: true }],
  applicableMerchants: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Merchant' }],
  minimumSpend: { type: Number, min: 0 },
  maximumBenefit: { type: Number, min: 0 },
  termsAndConditions: { type: String, trim: true },
  image: { type: String },
  images: [{ type: String }],
  url: { type: String },
  featured: { type: Boolean, default: false },
  isSponsored: { type: Boolean, default: true },
  priority: { type: Number, default: 0 },
  status: {
    type: String,
    enum: ['active', 'scheduled', 'expired', 'rejected', 'admin_paused', 'draft'],
    default: 'draft',
    index: true,
  },
  startDate: { type: Date, required: true },
  endDate: { type: Date, required: true },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  updatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
}, {
  timestamps: true,
});

bankOfferSchema.index({ status: 1, endDate: 1, startDate: 1, priority: -1, _id: -1 });
bankOfferSchema.index({ category: 1, status: 1, _id: -1 });
bankOfferSchema.index({ featured: 1, status: 1, _id: -1 });

module.exports = mongoose.model('BankOffer', bankOfferSchema);
