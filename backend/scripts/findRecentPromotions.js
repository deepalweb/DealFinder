require('dotenv').config();
const mongoose = require('mongoose');
const Promotion = require('../models/Promotion');
const Merchant = require('../models/Merchant');

async function findRecentPromotions() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connected to MongoDB\n');

    // Find promotions created in last 24 hours
    const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const recent = await Promotion.find({ createdAt: { $gte: yesterday } })
      .populate('merchant', 'name')
      .sort({ createdAt: -1 })
      .lean();

    console.log(`=== Promotions Created in Last 24 Hours (${recent.length}) ===\n`);

    if (recent.length === 0) {
      console.log('❌ No promotions created in the last 24 hours');
      console.log('\nThis means the web app promotion creation failed.');
      console.log('Check the web app console for errors.\n');
    } else {
      recent.forEach((promo, index) => {
        console.log(`${index + 1}. ${promo.title}`);
        console.log(`   Created: ${new Date(promo.createdAt).toLocaleString()}`);
        console.log(`   Status: ${promo.status}`);
        console.log(`   Start: ${new Date(promo.startDate).toISOString().split('T')[0]}`);
        console.log(`   End: ${new Date(promo.endDate).toISOString().split('T')[0]}`);
        console.log(`   Image: ${promo.image ? (promo.image.startsWith('https://dealfinderimages') ? '✅ Azure URL' : promo.image.substring(0, 50) + '...') : 'None'}`);
        console.log('');
      });
    }

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
  }
}

findRecentPromotions();
