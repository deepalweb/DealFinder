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
  image: { type: String },
  url: { type: String },
  featured: { type: Boolean, default: false },
  status: { 
    type: String, 
    enum: ['active', 'expired'],
    default: 'active'
  },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Promotion', promotionSchema);