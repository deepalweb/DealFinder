require('dotenv').config();
const mongoose = require('mongoose');
const Merchant = require('../models/Merchant');

async function checkMerchantLocations() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected to MongoDB');

    // Check total merchants
    const totalMerchants = await Merchant.countDocuments();
    console.log(`\n📊 Total merchants: ${totalMerchants}`);

    // Check merchants with location data
    const merchantsWithLocation = await Merchant.countDocuments({
      'location.type': 'Point',
      'location.coordinates': { $exists: true, $ne: [] }
    });
    console.log(`📍 Merchants with location: ${merchantsWithLocation}`);

    // Check merchants without location
    const merchantsWithoutLocation = totalMerchants - merchantsWithLocation;
    console.log(`❌ Merchants without location: ${merchantsWithoutLocation}`);

    // List merchants with location
    if (merchantsWithLocation > 0) {
      console.log('\n📍 Merchants with location data:');
      const merchants = await Merchant.find({
        'location.type': 'Point',
        'location.coordinates': { $exists: true, $ne: [] }
      }).select('name location address').limit(10);
      
      merchants.forEach(m => {
        console.log(`  - ${m.name}`);
        console.log(`    Address: ${m.address || 'N/A'}`);
        console.log(`    Coordinates: [${m.location.coordinates[0]}, ${m.location.coordinates[1]}]`);
      });
    }

    // List merchants without location
    if (merchantsWithoutLocation > 0) {
      console.log('\n❌ Merchants without location data:');
      const merchants = await Merchant.find({
        $or: [
          { 'location.type': { $ne: 'Point' } },
          { 'location.coordinates': { $exists: false } },
          { 'location.coordinates': [] }
        ]
      }).select('name address').limit(10);
      
      merchants.forEach(m => {
        console.log(`  - ${m.name} (Address: ${m.address || 'N/A'})`);
      });
    }

    // Check if geospatial index exists
    console.log('\n🔍 Checking indexes...');
    const indexes = await Merchant.collection.getIndexes();
    const hasGeoIndex = Object.keys(indexes).some(key => 
      indexes[key].some(idx => idx[0] === 'location' && idx[1] === '2dsphere')
    );
    
    if (hasGeoIndex) {
      console.log('✅ Geospatial index exists on location field');
    } else {
      console.log('❌ Geospatial index NOT found - creating it...');
      await Merchant.collection.createIndex({ location: '2dsphere' });
      console.log('✅ Geospatial index created');
    }

    // Test a nearby query
    console.log('\n🧪 Testing nearby query...');
    const testLat = 6.8786018;
    const testLng = 79.8707561;
    const testRadius = 50000; // 50km in meters
    
    try {
      const nearbyMerchants = await Merchant.aggregate([
        {
          $geoNear: {
            near: { type: 'Point', coordinates: [testLng, testLat] },
            distanceField: 'distance',
            maxDistance: testRadius,
            spherical: true,
            query: { 'location.type': 'Point' }
          }
        },
        { $limit: 5 },
        { $project: { name: 1, distance: 1, address: 1 } }
      ]);
      
      console.log(`✅ Found ${nearbyMerchants.length} merchants within 50km:`);
      nearbyMerchants.forEach(m => {
        console.log(`  - ${m.name}: ${(m.distance / 1000).toFixed(2)}km away`);
      });
    } catch (err) {
      console.error('❌ Nearby query failed:', err.message);
    }

    await mongoose.disconnect();
    console.log('\n✅ Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

checkMerchantLocations();
