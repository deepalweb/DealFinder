require('dotenv').config();
const mongoose = require('mongoose');
const Promotion = require('../models/Promotion');
const Merchant = require('../models/Merchant');

async function checkImageData() {
  try {
    console.log('Checking image data in database...\n');

    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connected to MongoDB\n');

    // Check Promotions
    console.log('=== Promotions ===');
    const promotions = await Promotion.find().limit(5);
    console.log(`Total promotions: ${await Promotion.countDocuments()}\n`);
    
    promotions.forEach((promo, index) => {
      console.log(`Promotion ${index + 1}: ${promo.title}`);
      console.log(`  Main image: ${promo.image ? promo.image.substring(0, 100) + '...' : 'None'}`);
      console.log(`  Image type: ${promo.image ? (promo.image.startsWith('data:') ? 'BASE64' : promo.image.startsWith('http') ? 'URL' : 'UNKNOWN') : 'None'}`);
      console.log(`  Images array: ${promo.images ? promo.images.length : 0} images`);
      if (promo.images && promo.images.length > 0) {
        console.log(`  First image type: ${promo.images[0].startsWith('data:') ? 'BASE64' : promo.images[0].startsWith('http') ? 'URL' : 'UNKNOWN'}`);
      }
      console.log('');
    });

    // Check Merchants
    console.log('\n=== Merchants ===');
    const merchants = await Merchant.find().limit(5);
    console.log(`Total merchants: ${await Merchant.countDocuments()}\n`);
    
    merchants.forEach((merchant, index) => {
      console.log(`Merchant ${index + 1}: ${merchant.name}`);
      console.log(`  Logo: ${merchant.logo ? merchant.logo.substring(0, 100) + '...' : 'None'}`);
      console.log(`  Logo type: ${merchant.logo ? (merchant.logo.startsWith('data:') ? 'BASE64' : merchant.logo.startsWith('http') ? 'URL' : 'UNKNOWN') : 'None'}`);
      console.log(`  Banner: ${merchant.banner ? merchant.banner.substring(0, 100) + '...' : 'None'}`);
      console.log(`  Banner type: ${merchant.banner ? (merchant.banner.startsWith('data:') ? 'BASE64' : merchant.banner.startsWith('http') ? 'URL' : 'UNKNOWN') : 'None'}`);
      console.log('');
    });

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

checkImageData();
