require('dotenv').config();
const mongoose = require('mongoose');
const Merchant = require('../models/Merchant');

// Sample locations in Colombo, Sri Lanka area
const sampleLocations = [
  {
    name: "Jane's Electronics",
    address: "123 Galle Road, Colombo 03, Sri Lanka",
    coordinates: [79.8612, 6.9271] // [longitude, latitude] - Colombo 03
  },
  {
    name: "Fashion Forward",
    address: "456 Duplication Road, Colombo 04, Sri Lanka",
    coordinates: [79.8653, 6.8935] // Colombo 04
  },
  {
    name: "Home Essentials",
    address: "789 Baseline Road, Colombo 09, Sri Lanka",
    coordinates: [79.8742, 6.9147] // Colombo 09
  }
];

async function addMerchantLocations() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected to MongoDB\n');

    for (const loc of sampleLocations) {
      const merchant = await Merchant.findOne({ name: loc.name });
      
      if (merchant) {
        merchant.address = loc.address;
        merchant.location = {
          type: 'Point',
          coordinates: loc.coordinates
        };
        
        await merchant.save();
        console.log(`✅ Updated ${loc.name}`);
        console.log(`   Address: ${loc.address}`);
        console.log(`   Coordinates: [${loc.coordinates[0]}, ${loc.coordinates[1]}]\n`);
      } else {
        console.log(`❌ Merchant not found: ${loc.name}\n`);
      }
    }

    // Verify the updates
    console.log('🔍 Verifying updates...');
    const merchantsWithLocation = await Merchant.countDocuments({
      'location.type': 'Point',
      'location.coordinates': { $exists: true, $ne: [] }
    });
    console.log(`✅ ${merchantsWithLocation} merchants now have location data\n`);

    // Test nearby query
    console.log('🧪 Testing nearby query from your location...');
    const testLat = 6.8786018;
    const testLng = 79.8707561;
    const testRadius = 50000; // 50km
    
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
      { $project: { name: 1, distance: 1, address: 1 } }
    ]);
    
    console.log(`✅ Found ${nearbyMerchants.length} merchants within 50km:`);
    nearbyMerchants.forEach(m => {
      console.log(`  - ${m.name}: ${(m.distance / 1000).toFixed(2)}km away`);
    });

    await mongoose.disconnect();
    console.log('\n✅ Done!');
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

addMerchantLocations();
