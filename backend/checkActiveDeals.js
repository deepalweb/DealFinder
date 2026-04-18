require('dotenv').config({ path: require('path').resolve(__dirname, '.env') });
const mongoose = require('mongoose');
const Promotion = require('./models/Promotion');

async function check() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    const now = new Date();
    
    // Check ALL active deals (regardless of featured status)
    const active = await Promotion.find({ 
      status: { $in: ['active', 'approved'] },
      startDate: { $lte: now },
      endDate: { $gte: now }
    });
    
    console.log('Total active deals:', active.length);
    console.log('Featured:', active.filter(p => p.featured).length);
    console.log('Non-featured:', active.filter(p => !p.featured).length);
    console.log('\nAll deals:');
    
    active.forEach(p => {
      const check = p.featured ? '✓' : ' ';
      console.log(` [${check}] ${p.title}`);
    });
    
    await mongoose.disconnect();
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

check();
