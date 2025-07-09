const mongoose = require('mongoose');

const merchantSchema = new mongoose.Schema({
  name: { type: String, required: true, unique: true },
  profile: { type: String },
  contactInfo: { type: String },
  promotions: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Promotion' }],
  logo: { type: String }, // Add logo field for profile image
  createdAt: { type: Date, default: Date.now },
  address: { type: String },
  contactNumber: { type: String },
  socialMedia: {
    facebook: { type: String },
    instagram: { type: String },
    twitter: { type: String },
    tiktok: { type: String }
  },
  status: {
    type: String,
    enum: ['active', 'pending_approval', 'approved', 'rejected', 'suspended', 'needs_review'],
    default: 'active' // Default for admin-created merchants
  },
  // Field to store who created the merchant, if needed for workflows
  // createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
});

module.exports = mongoose.model('Merchant', merchantSchema);