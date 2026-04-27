const mongoose = require('mongoose');

const sectionAssignmentSchema = new mongoose.Schema(
  {
    sectionKey: {
      type: String,
      required: true,
      enum: ['banner', 'hot_deals', 'new_this_week', 'nearby'],
    },
    promotion: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Promotion',
      required: true,
    },
    enabled: { type: Boolean, default: true },
    mode: {
      type: String,
      enum: ['manual', 'auto', 'forced', 'hidden', 'boosted', 'excluded'],
      default: 'manual',
    },
    priority: { type: Number, default: 0 },
    startAt: { type: Date },
    endAt: { type: Date },
    bannerImageUrl: { type: String },
    radiusKm: { type: Number },
    minDistanceKm: { type: Number },
    maxDistanceKm: { type: Number },
    excludeFromAuto: { type: Boolean, default: false },
    metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
    updatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  },
  {
    timestamps: true,
  }
);

sectionAssignmentSchema.index({ sectionKey: 1, promotion: 1 }, { unique: true });
sectionAssignmentSchema.index({ sectionKey: 1, enabled: 1, priority: -1, startAt: 1, endAt: 1 });

module.exports = mongoose.model('SectionAssignment', sectionAssignmentSchema);
