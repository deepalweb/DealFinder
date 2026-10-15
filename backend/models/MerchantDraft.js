const mongoose = require("mongoose");
const schema = new mongoose.Schema(
  {
    owner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    merchant: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Merchant",
      required: true,
    },
    clientKey: { type: String, required: true, maxlength: 80 },
    data: { type: mongoose.Schema.Types.Mixed, default: {} },
    promotionId: {
      type: mongoose.Schema.Types.ObjectId,
      default: () => new mongoose.Types.ObjectId(),
    },
    submittedAt: { type: Date },
  },
  { timestamps: true },
);
schema.index({ owner: 1, merchant: 1, clientKey: 1 }, { unique: true });
module.exports = mongoose.model("MerchantDraft", schema);
