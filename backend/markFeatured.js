require('dotenv').config();
const mongoose = require('mongoose');
const Promotion = require('./models/Promotion');

async function markFeatured() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected to MongoDB\n');

    // Mark the first 3 deals as featured
    const result = await Promotion.updateMany(
      { featured: false },
      { $set: { featured: true } },
      { limit: 3 }
    );

    console.log(`✅ Marked ${result.modifiedCount} deals as featured\n`);

    // Show updated deals
    const featured = await Promotion.find({ featured: true }).sort({ createdAt: -1 });
    console.log(`📍 Featured deals (${featured.length}):`);
    featured.forEach((p, i) => {
      console.log(`${i + 1}. ${p.title}`);
      console.log(`   Status: ${p.status} | Featured: ${p.featured}`);
    });

    await mongoose.disconnect();
    console.log('\n✅ Done! Refresh your local webapp to see the featured deals');
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

markFeatured();
