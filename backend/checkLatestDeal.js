require('dotenv').config({ path: require('path').resolve(__dirname, '.env') });
const mongoose = require('mongoose');
const Promotion = require('./models/Promotion');
const Merchant = require('./models/Merchant');

async function checkLatestDeal() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    const now = new Date();
    
    // Get the most recently created deal
    const latest = await Promotion.findOne()
      .sort({ createdAt: -1 })
      .populate('merchant', 'name location');
    
    if (!latest) {
      console.log('❌ No deals found in database');
      await mongoose.disconnect();
      return;
    }
    
    console.log('📌 Most Recently Created Deal:');
    console.log('Title:', latest.title);
    console.log('Status:', latest.status);
    console.log('Featured:', latest.featured);
    console.log('Created:', latest.createdAt);
    console.log('Start Date:', latest.startDate);
    console.log('End Date:', latest.endDate);
    console.log('\n📍 Merchant Info:');
    console.log('Name:', latest.merchant?.name);
    console.log('Has Location:', !!latest.merchant?.location);
    if (latest.merchant?.location) {
      console.log('Location Type:', latest.merchant.location.type);
      console.log('Coordinates:', latest.merchant.location.coordinates);
    }
    
    console.log('\n✅ Status Check:');
    const isActive = latest.status === 'active' || latest.status === 'approved';
    const isInDate = latest.startDate <= now && latest.endDate >= now;
    console.log('Is Active/Approved:', isActive);
    console.log('Is In Date Range:', isInDate);
    console.log('Ready for Nearby:', isActive && isInDate ? '✅ YES' : '❌ NO');
    
    await mongoose.disconnect();
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

checkLatestDeal();
