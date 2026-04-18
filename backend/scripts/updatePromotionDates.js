require('dotenv').config();
const mongoose = require('mongoose');
const Merchant = require('../models/Merchant');
const Promotion = require('../models/Promotion');

async function updatePromotionDates() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected to MongoDB\n');

    const now = new Date();
    const thirtyDaysFromNow = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

    // Get all promotions without populate
    const promotions = await Promotion.find();
    
    console.log(`📊 Updating ${promotions.length} promotions...\n`);

    for (const promo of promotions) {
      const oldStart = promo.startDate;
      const oldEnd = promo.endDate;
      
      // Set to current date range
      promo.startDate = now;
      promo.endDate = thirtyDaysFromNow;
      
      // Ensure status is active or approved
      if (promo.status === 'expired') {
        promo.status = 'active';
      }
      
      await promo.save();
      
      console.log(`✅ Updated: ${promo.title}`);
      console.log(`   Status: ${promo.status}`);
      console.log(`   Old dates: ${oldStart?.toISOString().split('T')[0]} to ${oldEnd?.toISOString().split('T')[0]}`);
      console.log(`   New dates: ${promo.startDate.toISOString().split('T')[0]} to ${promo.endDate.toISOString().split('T')[0]}\n`);
    }

    // Verify
    console.log('🔍 Verifying updates...');
    const activePromotions = await Promotion.countDocuments({
      status: { $in: ['active', 'approved'] },
      startDate: { $lte: now },
      endDate: { $gte: now }
    });
    
    console.log(`✅ ${activePromotions} promotions are now active and valid\n`);

    await mongoose.disconnect();
    console.log('✅ Done! Try the nearby deals feature now.');
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

updatePromotionDates();
