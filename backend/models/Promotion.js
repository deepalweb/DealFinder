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
  originalPrice: { type: Number },
  discountedPrice: { type: Number },
  status: {
    type: String,
    enum: [
      'pending_approval', // Newly submitted by merchant, awaiting admin review
      'approved',         // Approved by admin, will become active based on dates
      'active',           // Approved and currently within startDate and endDate
      'scheduled',        // Approved but startDate is in the future
      'expired',          // Approved but endDate has passed
      'rejected',         // Rejected by admin
      'admin_paused',     // Paused by admin (overrides date-based active status)
      'draft'             // Saved by merchant but not yet submitted for approval
    ],
    default: 'pending_approval' // Default for new promotions, admin can override
  },
  // Note: 'active' and 'expired' can still be determined by dates for 'approved' promotions.
  // The 'status' field gives admins more direct control.
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
  }]
});

module.exports = mongoose.model('Promotion', promotionSchema);