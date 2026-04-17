require('dotenv').config();
const mongoose = require('mongoose');
const Promotion = require('../models/Promotion');
const Merchant = require('../models/Merchant');

async function testPromotionCreation() {
  try {
    console.log('Testing promotion creation...\n');

    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connected to MongoDB\n');

    // Get first merchant
    const merchant = await Merchant.findOne();
    if (!merchant) {
      console.error('❌ No merchants found in database');
      console.log('Please create a merchant first');
      return;
    }

    console.log(`✅ Found merchant: ${merchant.name} (${merchant._id})\n`);

    // Test promotion data (similar to what mobile app sends)
    const testPromotion = {
      title: 'Test Promotion',
      description: 'This is a test promotion',
      discount: '20%',
      code: 'TEST20',
      category: 'Electronics',
      startDate: new Date(),
      endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days from now
      merchant: merchant._id,
      featured: false,
      status: 'active',
      // Test with Azure URL (not base64)
      image: 'https://dealfinderimages.blob.core.windows.net/deals/test/test-image.jpg',
      images: ['https://dealfinderimages.blob.core.windows.net/deals/test/test-image.jpg']
    };

    console.log('Creating test promotion...');
    const promotion = new Promotion(testPromotion);
    const saved = await promotion.save();

    console.log('✅ Promotion created successfully!');
    console.log(`ID: ${saved._id}`);
    console.log(`Title: ${saved.title}`);
    console.log(`Status: ${saved.status}\n`);

    // Clean up - delete test promotion
    await Promotion.findByIdAndDelete(saved._id);
    console.log('✅ Test promotion deleted (cleanup)\n');

    console.log('🎉 Promotion creation is working correctly!');

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('\nFull error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

testPromotionCreation();
