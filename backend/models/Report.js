const mongoose = require('mongoose');

const reportSchema = new mongoose.Schema({
  targetType: {
    type: String,
    enum: ['promotion', 'merchant'],
    required: true,
    index: true,
  },
  promotion: { type: mongoose.Schema.Types.ObjectId, ref: 'Promotion', index: true },
  merchant: { type: mongoose.Schema.Types.ObjectId, ref: 'Merchant', index: true },
  reporter: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
  reason: {
    type: String,
    enum: [
      'fake_or_misleading',
      'expired_or_invalid',
      'wrong_information',
      'inappropriate',
      'spam',
      'other',
    ],
    required: true,
  },
  description: { type: String, trim: true, maxlength: 1000 },
  status: {
    type: String,
    enum: ['open', 'reviewing', 'resolved', 'dismissed'],
    default: 'open',
    index: true,
  },
  resolutionNote: { type: String, trim: true, maxlength: 1000 },
  resolvedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  resolvedAt: { type: Date },
}, {
  timestamps: true,
});

reportSchema.index({ status: 1, createdAt: -1 });
reportSchema.index({ targetType: 1, status: 1, createdAt: -1 });

module.exports = mongoose.model('Report', reportSchema);
