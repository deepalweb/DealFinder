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
  // Add comments and ratings for social features
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
  // Price fields
  price: { type: Number }, // Current price or general price if no sale
  originalPrice: { type: Number }, // Price before discount
  discountedPrice: { type: Number } // Price after discount, if applicable
});

module.exports = mongoose.model('Promotion', promotionSchema);