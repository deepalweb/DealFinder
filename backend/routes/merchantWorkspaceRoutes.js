const express = require("express");
const mongoose = require("mongoose");
const router = express.Router();
const Draft = require("../models/MerchantDraft");
const Merchant = require("../models/Merchant");
const Promotion = require("../models/Promotion");
const User = require("../models/User");
const { authenticateJWT } = require("../middleware/auth");
const {
  pickDraft,
  validateOffer,
  promotionPayload,
} = require("../utils/merchantWorkflow");
router.use(authenticateJWT, async (req, res, next) => {
  try {
    if (req.user.role !== "merchant")
      return res.status(403).json({ message: "Merchant access required" });
    if (process.env.DATA_SOURCE === "postgres")
      return res.status(503).json({
        message:
          "Merchant draft workflow is currently available with MongoDB only.",
      });
    const account = await User.findById(req.user.id).select("merchantId role");
    if (account?.role !== "merchant" || !account.merchantId)
      return res.status(403).json({ message: "No merchant profile linked" });
    req.merchant = await Merchant.findById(account.merchantId);
    if (!req.merchant)
      return res.status(404).json({ message: "Store not found" });
    req.scope = { owner: req.user.id, merchant: account.merchantId };
    next();
  } catch {
    res.status(500).json({ message: "Unable to load merchant workspace" });
  }
});
router.get("/", async (req, res) => {
  try {
    const [drafts, promotions] = await Promise.all([
      Draft.find({ ...req.scope, submittedAt: { $exists: false } })
        .sort({ updatedAt: -1 })
        .lean(),
      Promotion.find({ merchant: req.scope.merchant })
        .sort({ createdAt: -1 })
        .lean(),
    ]);
    const { resolveLifecycleStatus } = require("../utils/promotionLifecycle");
    const normalized = promotions.map((p) => ({
      ...p,
      status: ["active", "scheduled", "expired"].includes(p.status)
        ? resolveLifecycleStatus(p.startDate, p.endDate)
        : p.status,
    }));
    res.json({ merchant: req.merchant, drafts, promotions: normalized });
  } catch {
    res.status(500).json({ message: "Unable to load workspace" });
  }
});
router.get("/drafts/:id", async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id))
      return res.status(404).json({ message: "Draft not found" });
    const draft = await Draft.findOne({ ...req.scope, _id: req.params.id });
    if (!draft) return res.status(404).json({ message: "Draft not found" });
    res.json(draft);
  } catch {
    res.status(500).json({ message: "Unable to load draft. Retry." });
  }
});
router.put("/drafts/:key", async (req, res) => {
  try {
    if (!/^[a-zA-Z0-9_-]{1,80}$/.test(req.params.key))
      return res.status(400).json({ message: "Invalid draft key" });
    const data = pickDraft(req.body.data || {});
    const draft = await Draft.findOneAndUpdate(
      {
        ...req.scope,
        clientKey: req.params.key,
        submittedAt: { $exists: false },
      },
      { $set: { data } },
      { new: true, upsert: true, runValidators: true },
    );
    res.json(draft);
  } catch (e) {
    res.status(e.code === 11000 ? 409 : 400).json({
      message:
        e.code === 11000
          ? "This draft was already submitted. Start a new draft."
          : e.message,
    });
  }
});
router.post("/drafts/:id/submit", async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id))
      return res.status(404).json({ message: "Draft not found" });
    const draft = await Draft.findOne({ ...req.scope, _id: req.params.id });
    if (!draft) return res.status(404).json({ message: "Draft not found" });
    if (draft.submittedAt)
      return res.json({
        promotionId: draft.promotionId,
        status: "pending_review",
      });
    const errors = validateOffer(draft.data, req.merchant);
    if (Object.keys(errors).length)
      return res
        .status(400)
        .json({ message: "Correct the offer before submitting", errors });
    if (["suspended", "rejected"].includes(req.merchant.status))
      return res
        .status(403)
        .json({ message: "Store is not eligible to submit promotions" });
    // Stable per-draft ID makes retries/concurrent submissions idempotent without a transaction requirement.
    const promotion = await Promotion.findOneAndUpdate(
      { _id: draft.promotionId },
      { $setOnInsert: promotionPayload(draft.data, req.merchant) },
      { upsert: true, new: true, runValidators: true },
    );
    await Merchant.updateOne(
      { _id: req.scope.merchant },
      { $addToSet: { promotions: promotion._id } },
    );
    draft.submittedAt = new Date();
    await draft.save();
    res.json({ promotionId: promotion._id, status: promotion.status });
  } catch {
    res.status(500).json({
      message: "Submission failed. Your saved draft is retained; retry safely.",
    });
  }
});
module.exports = router;
