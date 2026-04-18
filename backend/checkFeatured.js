require('dotenv').config();
const mongoose = require('mongoose');
const Promotion = require('./models/Promotion');

async function check() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    const now = new Date();
    
    // Check featured deals
    const featured = await Promotion.find({ 
      featured: true,
      status: { $in: ['active', 'approved'] },
      startDate: { $lte: now },
      endDate: { $gte: now }
    });
    
    console.log('✅ Featured deals (active):', featured.length);
    featured.forEach(p => {
      console.log(' -', p.title, '| Status:', p.status, '| Featured:', p.featured);
    });
    
    // Check all active deals
    const all = await Promotion.find({ 
      status: { $in: ['active', 'approved'] },
      startDate: { $lte: now },
      endDate: { $gte: now }
    });
    
    console.log('\n📊 All active deals:', all.length);
    all.forEach(p => {
      console.log(' -', p.title, '| Featured:', p.featured);
    });
    
    await mongoose.disconnect();
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

check();
