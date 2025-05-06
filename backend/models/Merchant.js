const mongoose = require('mongoose');

const merchantSchema = new mongoose.Schema({
  name: { type: String, required: true },
  profile: { type: String },
  contactInfo: { type: String },
  promotions: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Promotion' }],
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Merchant', merchantSchema);