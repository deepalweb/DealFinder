const cron = require('node-cron');
const checkNearbyDeals = require('./nearbyDealsNotifications');
const checkExpiringDealsForUsers = require('./expiringDealsNotifications');
const { checkFavoriteStoresNewDeals } = require('./favoriteStoreNotifications');
const { checkPriceDrops } = require('./priceDropNotifications');
const { checkExpiringFlashSales } = require('./flashSaleNotifications');
const checkCategoryDeals = require('./categoryDealsNotifications');
const sendWeeklyDigest = require('./weeklyDigestNotifications');
const sendExpiryNotifications = require('./expiryNotifications'); // Existing merchant expiry job

/**
 * Initialize all notification background jobs
 */
function initializeNotificationJobs() {
  console.log('[Job Scheduler] Initializing notification jobs...');

  // Check for nearby deals every 30 minutes
  cron.schedule('*/30 * * * *', async () => {
    console.log('[Job Scheduler] Running nearby deals check...');
    await checkNearbyDeals();
  });

  // Check for expiring deals (user favorites) daily at 9 AM
  cron.schedule('0 9 * * *', async () => {
    console.log('[Job Scheduler] Running expiring deals check...');
    await checkExpiringDealsForUsers();
  });

  // Check for new deals from favorite stores every 2 hours
  cron.schedule('0 */2 * * *', async () => {
    console.log('[Job Scheduler] Running favorite stores check...');
    await checkFavoriteStoresNewDeals();
  });

  // Check for price drops every 2 hours
  cron.schedule('0 */2 * * *', async () => {
    console.log('[Job Scheduler] Running price drops check...');
    await checkPriceDrops();
  });

  // Check for expiring flash sales every hour
  cron.schedule('0 * * * *', async () => {
    console.log('[Job Scheduler] Running flash sales check...');
    await checkExpiringFlashSales();
  });

  // Check for category deals every hour
  cron.schedule('0 * * * *', async () => {
    console.log('[Job Scheduler] Running category deals check...');
    await checkCategoryDeals();
  });

  // Send weekly digest every Sunday at 8 AM
  cron.schedule('0 8 * * 0', async () => {
    console.log('[Job Scheduler] Sending weekly digest...');
    await sendWeeklyDigest();
  });

  // Merchant expiry notifications (existing) - daily at 10 AM
  cron.schedule('0 10 * * *', async () => {
    console.log('[Job Scheduler] Running merchant expiry notifications...');
    await sendExpiryNotifications();
  });

  console.log('[Job Scheduler] All notification jobs initialized');
  console.log('[Job Scheduler] Schedule:');
  console.log('  - Nearby deals: Every 30 minutes');
  console.log('  - Expiring deals (users): Daily at 9 AM');
  console.log('  - Favorite stores: Every 2 hours');
  console.log('  - Price drops: Every 2 hours');
  console.log('  - Flash sales: Every hour');
  console.log('  - Category deals: Every hour');
  console.log('  - Weekly digest: Sunday at 8 AM');
  console.log('  - Merchant expiry: Daily at 10 AM');
}

/**
 * Run all jobs immediately (for testing)
 */
async function runAllJobsNow() {
  console.log('[Job Scheduler] Running all jobs immediately...');
  
  try {
    await checkNearbyDeals();
    await checkExpiringDealsForUsers();
    await checkFavoriteStoresNewDeals();
    await checkPriceDrops();
    await checkExpiringFlashSales();
    await checkCategoryDeals();
    await sendWeeklyDigest();
    await sendExpiryNotifications();
    
    console.log('[Job Scheduler] All jobs completed');
  } catch (error) {
    console.error('[Job Scheduler] Error running jobs:', error);
  }
}

module.exports = {
  initializeNotificationJobs,
  runAllJobsNow
};
