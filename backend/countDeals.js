require('dotenv').config({ path: require('path').resolve(__dirname, '.env') });
const mongoose = require('mongoose');
const Promotion = require('./models/Promotion');

async function count() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    const total = await Promotion.countDocuments();
    const active = await Promotion.countDocuments({ status: { $in: ['active', 'approved'] } });
    const now = new Date();
    const inDateRange = await Promotion.countDocuments({
      status: { $in: ['active', 'approved'] },
      startDate: { $lte: now },
      endDate: { $gte: now }
    });
    
    console.log('📊 Deal Statistics:');
    console.log('Total deals:', total);
    console.log('Active/Approved deals:', active);
    console.log('Active + In Date Range:', inDateRange);
    
    await mongoose.disconnect();
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}
count();
