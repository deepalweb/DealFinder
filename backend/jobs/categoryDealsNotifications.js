const Promotion = require('../models/Promotion');
const NotificationPreference = require('../models/NotificationPreference');
const NotificationService = require('../services/NotificationService');

/**
 * Notify users about new deals in their preferred categories
 * Run this job every hour
 */
async function checkCategoryDeals() {
  try {
    console.log('[Category Deals Job] Starting...');

    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    
    // Get new deals from the last hour
    const newDeals = await Promotion.find({
      status: { $in: ['active', 'approved'] },
      createdAt: { $gte: oneHourAgo },
      category: { $exists: true, $ne: null }
    }).populate('merchant');

    if (newDeals.length === 0) {
      console.log('[Category Deals Job] No new deals in the last hour');
      return;
    }

    console.log(`[Category Deals Job] Found ${newDeals.length} new deals`);

    // Group deals by category
    const dealsByCategory = {};
    for (const deal of newDeals) {
      if (!deal.category) continue;
      if (!dealsByCategory[deal.category]) {
        dealsByCategory[deal.category] = [];
      }
      dealsByCategory[deal.category].push(deal);
    }

    let notificationsSent = 0;

    // Process each category
    for (const [category, deals] of Object.entries(dealsByCategory)) {
      // Find users interested in this category
      const preferences = await NotificationPreference.find({
        'preferences.categories': category,
        $or: [
          { 'channels.push.enabled': true },
          { 'channels.web.enabled': true },
          { 'channels.email.enabled': true }
        ]
      });

      if (preferences.length === 0) continue;

      console.log(`[Category Deals Job] ${preferences.length} users interested in ${category}`);

      // Send notification to each user
      for (const pref of preferences) {
        // If multiple deals in category, send summary
        if (deals.length > 1) {
          const dealTitles = deals.slice(0, 3).map(d => d.title).join(', ');
          const moreText = deals.length > 3 ? ` and ${deals.length - 3} more` : '';

          await NotificationService.sendNotification(
            pref.userId,
            'category_deal',
            { 
              category,
              dealIds: deals.map(d => d._id.toString()),
              count: deals.length
            },
            {
              title: `📦 ${deals.length} New ${category.charAt(0).toUpperCase() + category.slice(1)} Deals!`,
              body: `${dealTitles}${moreText}`,
              channels: ['push', 'web'],
              priority: 'normal'
            }
          );
        } else {
          // Single deal notification
          const deal = deals[0];
          const merchantName = typeof deal.merchant === 'object' 
            ? deal.merchant.name 
            : 'a store';

          await NotificationService.sendNotification(
            pref.userId,
            'category_deal',
            { 
              category,
              dealId: deal._id.toString(),
              merchantId: typeof deal.merchant === 'object' ? deal.merchant._id.toString() : deal.merchant
            },
            {
              title: `📦 New ${category.charAt(0).toUpperCase() + category.slice(1)} Deal!`,
              body: `${deal.title} at ${merchantName} - ${deal.discount || 'Check it out!'}`,
              channels: ['push', 'web'],
              priority: 'normal'
            }
          );
        }

        notificationsSent++;
      }
    }

    console.log(`[Category Deals Job] Sent ${notificationsSent} notifications`);
  } catch (error) {
    console.error('[Category Deals Job] Error:', error.message);
  }
}

module.exports = checkCategoryDeals;
