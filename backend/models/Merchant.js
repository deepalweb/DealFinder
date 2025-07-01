const mongoose = require('mongoose');

const merchantSchema = new mongoose.Schema({
  name: { type: String, required: true, unique: true },
  profile: { type: String },
  contactInfo: { type: String },
  promotions: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Promotion' }],
  logo: { type: String }, // Add logo field for profile image
  createdAt: { type: Date, default: Date.now },
  address: { type: String },
  latitude: { type: Number },
  longitude: { type: Number },
  contactNumber: { type: String },
  socialMedia: {
    facebook: { type: String },
    instagram: { type: String },
    twitter: { type: String },
    tiktok: { type: String }
  },
  website: { type: String },
  bannerImage: { type: String }, // For cover photo
});

module.exports = mongoose.model('Merchant', merchantSchema);