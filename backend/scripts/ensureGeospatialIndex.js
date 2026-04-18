require('dotenv').config();
const mongoose = require('mongoose');
const Merchant = require('../models/Merchant');

async function ensureGeospatialIndex() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected to MongoDB\n');

    // Drop all indexes and recreate
    console.log('🔄 Dropping existing indexes...');
    try {
      await Merchant.collection.dropIndexes();
      console.log('✅ Dropped all indexes\n');
    } catch (err) {
      console.log('⚠️  Could not drop indexes:', err.message, '\n');
    }

    // Create geospatial index
    console.log('🔨 Creating geospatial index...');
    await Merchant.collection.createIndex({ location: '2dsphere' });
    console.log('✅ Geospatial index created\n');

    // Verify index
    console.log('🔍 Verifying indexes...');
    const indexes = await Merchant.collection.getIndexes();
    console.log('Indexes:', JSON.stringify(indexes, null, 2), '\n');

    // Test query
    console.log('🧪 Testing geoNear query...');
    const testLat = 6.8786028;
    const testLng = 79.8707617;
    const testRadius = 50000;

    const result = await Merchant.aggregate([
      {
        $geoNear: {
          near: { type: 'Point', coordinates: [testLng, testLat] },
          distanceField: 'distance',
          maxDistance: testRadius,
          spherical: true,
          query: { 'location.type': 'Point' }
        }
      },
      { $limit: 5 }
    ]);

    console.log(`✅ geoNear returned ${result.length} merchants:`);
    result.forEach(m => {
      console.log(`  - ${m.name}: ${(m.distance / 1000).toFixed(2)}km`);
    });

    await mongoose.disconnect();
    console.log('\n✅ Done!');
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

ensureGeospatialIndex();
