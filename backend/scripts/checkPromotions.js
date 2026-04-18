require('dotenv').config();
const mongoose = require('mongoose');
const Merchant = require('../models/Merchant');
const Promotion = require('../models/Promotion');

async function checkPromotions() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected to MongoDB\n');

    // Get all merchants with location
    const merchants = await Merchant.find({
      'location.type': 'Point',
      'location.coordinates': { $exists: true, $ne: [] }
    }).select('_id name');

    console.log(`📍 Merchants with location: ${merchants.length}`);
    const merchantIds = merchants.map(m => m._id);

    // Check all promotions
    const totalPromotions = await Promotion.countDocuments();
    console.log(`📊 Total promotions: ${totalPromotions}\n`);

    // Check promotions for these merchants
    const merchantPromotions = await Promotion.find({
      merchant: { $in: merchantIds }
    }).populate('merchant', 'name');

    console.log(`🎯 Promotions for merchants with location: ${merchantPromotions.length}\n`);

    if (merchantPromotions.length > 0) {
      console.log('📋 Promotion details:');
      merchantPromotions.forEach(p => {
        const now = new Date();
        const isActive = p.startDate <= now && p.endDate >= now;
        const statusOk = ['active', 'approved'].includes(p.status);
        
        console.log(`\n  - ${p.title}`);
        console.log(`    Merchant: ${p.merchant?.name || 'Unknown'}`);
        console.log(`    Status: ${p.status} ${statusOk ? '✅' : '❌'}`);
        console.log(`    Start: ${p.startDate?.toISOString().split('T')[0]}`);
        console.log(`    End: ${p.endDate?.toISOString().split('T')[0]}`);
        console.log(`    Date valid: ${isActive ? '✅' : '❌ EXPIRED/FUTURE'}`);
        console.log(`    Will show in nearby: ${statusOk && isActive ? '✅ YES' : '❌ NO'}`);
      });
    }

    // Check what the API query would return
    console.log('\n\n🔍 Simulating API query...');
    const now = new Date();
    const apiQuery = {
      merchant: { $in: merchantIds },
      status: { $in: ['active', 'approved'] },
      startDate: { $lte: now },
      endDate: { $gte: now }
    };

    const apiResults = await Promotion.find(apiQuery).populate('merchant', 'name');
    console.log(`📡 API would return: ${apiResults.length} promotions`);

    if (apiResults.length === 0) {
      console.log('\n❌ No promotions match the criteria:');
      console.log('   - Must have status: active or approved');
      console.log('   - Must have startDate <= now');
      console.log('   - Must have endDate >= now');
      console.log('   - Must belong to a merchant with location data');
    }

    await mongoose.disconnect();
    console.log('\n✅ Done!');
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

checkPromotions();
