require('dotenv').config({ path: require('path').resolve(__dirname, '.env') });
const mongoose = require('mongoose');
const Promotion = require('./models/Promotion');
const Merchant = require('./models/Merchant');

async function checkAllDeals() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    const now = new Date();
    
    // Get ALL deals
    const allDeals = await Promotion.find()
      .populate('merchant', 'name location')
      .sort({ createdAt: -1 });
    
    console.log('📊 Total Deals:', allDeals.length);
    console.log('\n' + '='.repeat(80));
    
    allDeals.forEach((deal, i) => {
      const isActive = deal.status === 'active' || deal.status === 'approved';
      const inDateRange = deal.startDate <= now && deal.endDate >= now;
      const hasMerchant = !!deal.merchant;
      const hasLocation = deal.merchant?.location?.coordinates?.length === 2;
      
      const readyForNearby = isActive && inDateRange && hasMerchant && hasLocation;
      
      console.log(`\n${i + 1}. ${deal.title}`);
      console.log(`   Created: ${deal.createdAt.toLocaleDateString()} ${deal.createdAt.toLocaleTimeString()}`);
      console.log(`   Status: ${deal.status} ${isActive ? '✅' : '❌'}`);
      console.log(`   Dates: ${deal.startDate.toLocaleDateString()} - ${deal.endDate.toLocaleDateString()} ${inDateRange ? '✅' : '❌'}`);
      console.log(`   Merchant: ${deal.merchant?.name || 'MISSING'} ${hasMerchant ? '✅' : '❌'}`);
      console.log(`   Location: ${hasLocation ? `(${deal.merchant?.location?.coordinates})` : 'MISSING'} ${hasLocation ? '✅' : '❌'}`);
      console.log(`   Ready for Nearby: ${readyForNearby ? '✅ YES' : '❌ NO'}`);
    });
    
    console.log('\n' + '='.repeat(80));
    const readyForNearby = allDeals.filter(d => {
      const isActive = d.status === 'active' || d.status === 'approved';
      const inDateRange = d.startDate <= now && d.endDate >= now;
      const hasLocation = d.merchant?.location?.coordinates?.length === 2;
      return isActive && inDateRange && hasLocation;
    });
    
    console.log(`\n✅ Deals Ready for Nearby: ${readyForNearby.length}/${allDeals.length}`);
    
    await mongoose.disconnect();
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

checkAllDeals();
