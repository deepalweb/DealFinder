const mongoose = require('mongoose');

const notificationPreferenceSchema = new mongoose.Schema({
  userId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true,
    unique: true 
  },
  channels: {
    push: { 
      enabled: { type: Boolean, default: false },
      token: { type: String }
    },
    email: { 
      enabled: { type: Boolean, default: true }
    },
    web: { 
      enabled: { type: Boolean, default: false },
      subscription: { type: Object }
    }
  },
  preferences: {
    nearbyDeals: { 
      enabled: { type: Boolean, default: true },
      radius: { type: Number, default: 5 }
    },
    favoriteStores: { 
      enabled: { type: Boolean, default: true }
    },
    expiringDeals: { 
      enabled: { type: Boolean, default: true },
      hours: { type: Number, default: 24 }
    },
    priceDrops: { 
      enabled: { type: Boolean, default: true }
    },
    categories: [{ type: String }],
    flashSales: { 
      enabled: { type: Boolean, default: true }
    },
    weeklyDigest: { 
      enabled: { type: Boolean, default: true },
      day: { type: String, default: 'sunday' }
    }
  },
  quietHours: {
    enabled: { type: Boolean, default: false },
    start: { type: String, default: '22:00' },
    end: { type: String, default: '08:00' }
  },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

notificationPreferenceSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

notificationPreferenceSchema.index({ 'preferences.nearbyDeals.enabled': 1 });
notificationPreferenceSchema.index({ 'preferences.favoriteStores.enabled': 1 });
notificationPreferenceSchema.index({ 'preferences.expiringDeals.enabled': 1 });
notificationPreferenceSchema.index({ 'preferences.categories': 1 });

module.exports = mongoose.model('NotificationPreference', notificationPreferenceSchema);
