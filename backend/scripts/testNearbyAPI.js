require('dotenv').config();
const mongoose = require('mongoose');
const Merchant = require('../models/Merchant');
const Promotion = require('../models/Promotion');

async function testNearbyAPI() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected to MongoDB\n');

    const latitude = 6.8786028;
    const longitude = 79.8707617;
    const searchRadiusKm = 50;
    const radiusInMeters = searchRadiusKm * 1000;

    console.log('🧪 Testing nearby API logic...');
    console.log(`   Location: [${longitude}, ${latitude}]`);
    console.log(`   Radius: ${searchRadiusKm}km\n`);

    // Step 1: Find nearby merchants
    console.log('Step 1: Finding nearby merchants...');
    let merchantsWithDistance = [];
    try {
      merchantsWithDistance = await Merchant.aggregate([
        {
          $geoNear: {
            near: { type: 'Point', coordinates: [longitude, latitude] },
            distanceField: 'distance',
            maxDistance: radiusInMeters,
            spherical: true,
            query: { 'location.type': 'Point' }
          }
        },
        { $limit: 100 },
        {
          $project: { _id: 1, name: 1, location: 1, distance: 1 }
        }
      ]);
      
      console.log(`✅ Found ${merchantsWithDistance.length} merchants:`);
      merchantsWithDistance.forEach(m => {
        console.log(`   - ${m.name}: ${(m.distance / 1000).toFixed(2)}km`);
      });
    } catch (geoErr) {
      console.error('❌ $geoNear error:', geoErr.message);
      return;
    }

    if (merchantsWithDistance.length === 0) {
      console.log('\n❌ No merchants found nearby. Stopping.');
      await mongoose.disconnect();
      return;
    }

    const merchantIds = merchantsWithDistance.map(m => m._id);
    console.log(`\n   Merchant IDs: ${merchantIds.map(id => id.toString()).join(', ')}\n`);

    // Step 2: Find promotions for these merchants
    console.log('Step 2: Finding promotions for these merchants...');
    const now = new Date();
    console.log(`   Current time: ${now.toISOString()}\n`);

    const query = {
      merchant: { $in: merchantIds },
      status: { $in: ['active', 'approved'] },
      startDate: { $lte: now },
      endDate: { $gte: now },
    };

    console.log('   Query:', JSON.stringify(query, null, 2));

    let promotions = await Promotion.find(query)
      .select('-comments -ratings')
      .populate({ path: 'merchant', select: 'name logo location address contactInfo currency' })
      .limit(50)
      .lean();

    console.log(`\n✅ Found ${promotions.length} promotions\n`);

    if (promotions.length > 0) {
      promotions.forEach(promo => {
        const merchantInfo = merchantsWithDistance.find(m => m._id.equals(promo.merchant._id));
        console.log(`   - ${promo.title}`);
        console.log(`     Merchant: ${promo.merchant.name}`);
        console.log(`     Status: ${promo.status}`);
        console.log(`     Dates: ${promo.startDate?.toISOString().split('T')[0]} to ${promo.endDate?.toISOString().split('T')[0]}`);
        console.log(`     Distance: ${merchantInfo ? (merchantInfo.distance / 1000).toFixed(2) + 'km' : 'N/A'}\n`);
      });
    } else {
      console.log('❌ No promotions found. Checking why...\n');
      
      // Check promotions without date filter
      const allMerchantPromos = await Promotion.find({
        merchant: { $in: merchantIds }
      }).select('title status startDate endDate');
      
      console.log(`   Total promotions for these merchants: ${allMerchantPromos.length}`);
      allMerchantPromos.forEach(p => {
        console.log(`   - ${p.title}`);
        console.log(`     Status: ${p.status} (need: active or approved)`);
        console.log(`     Start: ${p.startDate?.toISOString()}`);
        console.log(`     End: ${p.endDate?.toISOString()}`);
        console.log(`     Start <= now: ${p.startDate <= now}`);
        console.log(`     End >= now: ${p.endDate >= now}\n`);
      });
    }

    await mongoose.disconnect();
    console.log('✅ Done!');
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

testNearbyAPI();
