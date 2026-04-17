require('dotenv').config();
const mongoose = require('mongoose');
const Promotion = require('../models/Promotion');
const Merchant = require('../models/Merchant'); // Need to load this for populate

async function listAllPromotions() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connected to MongoDB\n');

    const promotions = await Promotion.find()
      .populate('merchant', 'name')
      .sort({ createdAt: -1 })
      .lean();

    console.log(`=== All Promotions (${promotions.length} total) ===\n`);

    promotions.forEach((promo, index) => {
      const now = new Date();
      const start = new Date(promo.startDate);
      const end = new Date(promo.endDate);
      const isActive = start <= now && end >= now;
      const status = promo.status || 'unknown';

      console.log(`${index + 1}. ${promo.title}`);
      console.log(`   ID: ${promo._id}`);
      console.log(`   Merchant: ${promo.merchant?.name || 'Unknown'}`);
      console.log(`   Status: ${status}`);
      console.log(`   Start: ${start.toISOString().split('T')[0]}`);
      console.log(`   End: ${end.toISOString().split('T')[0]}`);
      console.log(`   Active: ${isActive ? '✅ YES' : '❌ NO'}`);
      console.log(`   Created: ${new Date(promo.createdAt).toLocaleString()}`);
      console.log(`   Image: ${promo.image ? promo.image.substring(0, 60) + '...' : 'None'}`);
      console.log('');
    });

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
  }
}

listAllPromotions();
