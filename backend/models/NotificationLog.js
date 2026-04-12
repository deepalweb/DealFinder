const mongoose = require('mongoose');

const notificationLogSchema = new mongoose.Schema({
  userId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  type: { 
    type: String, 
    required: true,
    enum: [
      'nearby_deal',
      'favorite_store',
      'expiring_deal',
      'price_drop',
      'category_deal',
      'flash_sale',
      'deal_redeemed',
      'merchant_expiry',
      'weekly_digest',
      'account_activity'
    ]
  },
  title: { type: String, required: true },
  body: { type: String, required: true },
  data: { 
    type: Object,
    default: {}
  },
  channels: [{ 
    type: String, 
    enum: ['push', 'email', 'web'] 
  }],
  status: {
    push: {
      sent: { type: Boolean, default: false },
      delivered: { type: Boolean, default: false },
      opened: { type: Boolean, default: false },
      error: { type: String }
    },
    email: {
      sent: { type: Boolean, default: false },
      opened: { type: Boolean, default: false },
      error: { type: String }
    },
    web: {
      sent: { type: Boolean, default: false },
      clicked: { type: Boolean, default: false },
      error: { type: String }
    }
  },
  priority: { 
    type: String, 
    enum: ['low', 'normal', 'high', 'urgent'],
    default: 'normal'
  },
  read: { type: Boolean, default: false },
  readAt: { type: Date },
  sentAt: { type: Date },
  createdAt: { type: Date, default: Date.now }
});

notificationLogSchema.index({ userId: 1, createdAt: -1 });
notificationLogSchema.index({ type: 1, createdAt: -1 });
notificationLogSchema.index({ read: 1, userId: 1 });

module.exports = mongoose.model('NotificationLog', notificationLogSchema);
