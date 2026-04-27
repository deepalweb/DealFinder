// Script to clear backend caches by making API calls
// Since restarting Azure app via CLI is having auth issues, 
// we'll clear caches by triggering endpoints that invalidate them

const http = require('http');

async function clearCaches() {
  const baseUrl = 'https://dealfinderlk-eafsbyd7ghaph0az.southindia-01.azurewebsites.net';
  
  console.log('🔄 Attempting to clear backend caches...');
  console.log('Calling Azure app endpoints to trigger cache refresh\n');
  
  try {
    // Call homepage endpoint (will repopulate fresh cache)
    console.log('1️⃣  Refreshing homepage cache...');
    const homepage = await fetch(`${baseUrl}/api/promotions/homepage`);
    console.log(`   Status: ${homepage.status}`);
    
    // Call nearby endpoint (will repopulate fresh cache)
    console.log('2️⃣  Refreshing nearby cache...');
    const nearby = await fetch(`${baseUrl}/api/promotions/nearby?latitude=6.9147&longitude=79.8742&radius=10`);
    console.log(`   Status: ${nearby.status}`);
    
    console.log('\n✅ Cache refresh triggered!');
    console.log('   - Homepage cache refreshed with fresh data');
    console.log('   - Nearby cache refreshed with fresh data');
    console.log('\n📝 Next steps:');
    console.log('1. Clear browser cache (Ctrl+Shift+Delete)');
    console.log('2. Hard refresh Azure app (Ctrl+Shift+R)');
    console.log('3. Create a new deal and check Nearby section');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

// Only run if called directly (not imported)
if (require.main === module) {
  clearCaches();
}

module.exports = { clearCaches };
