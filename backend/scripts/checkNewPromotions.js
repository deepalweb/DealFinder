require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const mongoose = require('mongoose');
const Promotion = require('../models/Promotion');
const Merchant = require('../models/Merchant'); // Need to load this model too

async function checkNewPromotions() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connected to MongoDB\n');

    // Get promotions created in last 7 days
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const recentPromotions = await Promotion.find({
      createdAt: { $gte: sevenDaysAgo }
    }).populate('merchant', 'name').sort({ createdAt: -1 });

    console.log(`\n=== Promotions Created in Last 7 Days (${recentPromotions.length}) ===\n`);

    if (recentPromotions.length === 0) {
      console.log('❌ No promotions created in the last 7 days\n');
      process.exit(0);
    }

    const now = new Date();
    recentPromotions.forEach((promo, index) => {
      const isActive = promo.startDate <= now && promo.endDate >= now;
      const willBeActive = promo.startDate > now;
      const hasExpired = promo.endDate < now;

      console.log(`${index + 1}. ${promo.title}`);
      console.log(`   ID: ${promo._id}`);
      console.log(`   Status: ${promo.status}`);
      console.log(`   Merchant: ${promo.merchant?.name || 'Unknown'}`);
      console.log(`   Start: ${promo.startDate.toISOString().split('T')[0]}`);
      console.log(`   End: ${promo.endDate.toISOString().split('T')[0]}`);
      console.log(`   Created: ${promo.createdAt.toLocaleString()}`);
      
      if (isActive) {
        console.log(`   ✅ ACTIVE NOW (should show in app)`);
      } else if (willBeActive) {
        console.log(`   ⏰ SCHEDULED (starts in future)`);
      } else if (hasExpired) {
        console.log(`   ❌ EXPIRED (ended in past)`);
      }
      
      console.log(`   Image: ${promo.image ? promo.image.substring(0, 50) + '...' : 'None'}`);
      console.log('');
    });

    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

checkNewPromotions();
