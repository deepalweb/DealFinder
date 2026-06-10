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
  description: { type: String }, // Merchant description
  category: { type: String, index: true }, // Add category field with index
  merchantType: {
    type: String,
    enum: ['offline', 'online', 'hybrid'],
    default: 'offline',
    index: true
  },
  website: { type: String }, // Merchant website URL
  orderLink: { type: String }, // External ordering link
  deliveryAvailable: { type: Boolean, default: false },
  pickupAvailable: { type: Boolean, default: false },
  openingHours: {
    monday: { open: { type: String }, close: { type: String }, closed: { type: Boolean, default: false } },
    tuesday: { open: { type: String }, close: { type: String }, closed: { type: Boolean, default: false } },
    wednesday: { open: { type: String }, close: { type: String }, closed: { type: Boolean, default: false } },
    thursday: { open: { type: String }, close: { type: String }, closed: { type: Boolean, default: false } },
    friday: { open: { type: String }, close: { type: String }, closed: { type: Boolean, default: false } },
    saturday: { open: { type: String }, close: { type: String }, closed: { type: Boolean, default: false } },
    sunday: { open: { type: String }, close: { type: String }, closed: { type: Boolean, default: false } }
  },
  contactInfo: { type: String }, // General contact like email or phone
  promotions: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Promotion' }],
  logo: { type: String }, // URL or path to merchant's logo
  banner: { type: String }, // URL or path to merchant's banner/cover photo
  createdAt: { type: Date, default: Date.now, index: true }, // Add index for sorting
  address: { type: String }, // Textual address
  contactNumber: { type: String }, // Specific contact phone number
  socialMedia: {
    facebook: { type: String },
    instagram: { type: String },
    twitter: { type: String },
    tiktok: { type: String }
  },
  ratings: [{
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    value: { type: Number, min: 1, max: 5, required: true },
    createdAt: { type: Date, default: Date.now }
  }],
  reviews: [{
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    text: { type: String, required: true },
    createdAt: { type: Date, default: Date.now }
  }],
  status: {
    type: String,
    enum: ['active', 'pending_approval', 'approved', 'rejected', 'suspended', 'needs_review'],
    default: 'active',
    index: true // Add index for filtering
  },
  currency: { type: String, default: 'USD' }, // e.g. USD, LKR, EUR, GBP, INR
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
