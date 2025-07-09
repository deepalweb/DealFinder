const mongoose = require('mongoose');

const locationSchema = new mongoose.Schema({
  type: {
    type: String,
    enum: ['Point'],
    required: false // Set to false if location is optional
  },
  coordinates: {
    type: [Number], // [longitude, latitude]
    required: false // Set to false if location is optional
  }
});

const merchantSchema = new mongoose.Schema({
  name: { type: String, required: true, unique: true },
  profile: { type: String }, // Description of the merchant
  contactInfo: { type: String }, // General contact like email or phone
  promotions: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Promotion' }],
  logo: { type: String }, // URL or path to merchant's logo
  createdAt: { type: Date, default: Date.now },
  address: { type: String }, // Textual address
  contactNumber: { type: String }, // Specific contact phone number
  socialMedia: {
    facebook: { type: String },
    instagram: { type: String },
    twitter: { type: String },
    tiktok: { type: String }
  },
  status: {
    type: String,
    enum: ['active', 'pending_approval', 'approved', 'rejected', 'suspended', 'needs_review'],
    default: 'active'
  },
  location: { // GeoJSON Point for location
    type: locationSchema,
    index: '2dsphere' // Create a geospatial index for location queries
  }
  // Field to store who created the merchant, if needed for workflows
  // createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
});

// Ensure 'location' is not required by default if not always provided
merchantSchema.path('location.type').required(false);
merchantSchema.path('location.coordinates').required(false);


module.exports = mongoose.model('Merchant', merchantSchema);