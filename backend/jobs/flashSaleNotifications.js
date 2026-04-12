const Promotion = require('../models/Promotion');
const NotificationPreference = require('../models/NotificationPreference');
const NotificationService = require('../services/NotificationService');

/**
 * Detect flash sales (deals with very short duration) and notify users
 * A flash sale is defined as a deal that expires in less than 6 hours
 */
async function notifyFlashSale(promotionId) {
  try {
    console.log('[Flash Sale Job] Checking promotion:', promotionId);

    const promotion = await Promotion.findById(promotionId).populate('merchant');
    if (!promotion || !promotion.endDate) {
      return 0;
    }

    const now = new Date();
    const timeLeft = promotion.endDate.getTime() - now.getTime();
    const hoursLeft = timeLeft / (60 * 60 * 1000);

    // Only consider it a flash sale if it expires in less than 6 hours
    // and was just created (within last 30 minutes)
    const thirtyMinutesAgo = new Date(now.getTime() - 30 * 60 * 1000);
    const isNewDeal = promotion.createdAt >= thirtyMinutesAgo;

    if (hoursLeft > 6 || !isNewDeal) {
      return 0;
    }

    console.log(`[Flash Sale Job] Flash sale detected! ${hoursLeft.toFixed(1)} hours left`);

    // Get all users with flash sale notifications enabled
    const preferences = await NotificationPreference.find({
      'preferences.flashSales.enabled': true,
      $or: [
        { 'channels.push.enabled': true },
        { 'channels.web.enabled': true }
      ]
    });

    if (preferences.length === 0) {
      console.log('[Flash Sale Job] No users with flash sale notifications enabled');
      return 0;
    }

    // Filter by category if user has category preferences
    const merchantName = typeof promotion.merchant === 'object' 
      ? promotion.merchant.name 
      : 'a store';

    let notificationsSent = 0;

    for (const pref of preferences) {
      // Check if user is interested in this category
      const userCategories = pref.preferences.categories || [];
      if (userCategories.length > 0 && promotion.category) {
        if (!userCategories.includes(promotion.category)) {
          continue;
        }
      }

      await NotificationService.sendNotification(
        pref.userId,
        'flash_sale',
        { 
          dealId: promotion._id.toString(),
          merchantId: typeof promotion.merchant === 'object' ? promotion.merchant._id.toString() : promotion.merchant,
          hoursLeft: Math.floor(hoursLeft)
        },
        {
          title: '⚡ Flash Sale Alert!',
          body: `${promotion.title} at ${merchantName} - ${promotion.discount || 'Limited time only'}! Ends in ${Math.floor(hoursLeft)} hours!`,
          channels: ['push', 'web'],
          priority: 'urgent'
        }
      );

      notificationsSent++;
    }

    console.log(`[Flash Sale Job] Sent ${notificationsSent} notifications`);
    return notificationsSent;
  } catch (error) {
    console.error('[Flash Sale Job] Error:', error.message);
    return 0;
  }
}

/**
 * Check for ongoing flash sales that are about to expire
 * Run this every hour
 */
async function checkExpiringFlashSales() {
  try {
    console.log('[Expiring Flash Sales Job] Starting...');

    const now = new Date();
    const in1Hour = new Date(now.getTime() + 60 * 60 * 1000);
    const in2Hours = new Date(now.getTime() + 2 * 60 * 60 * 1000);

    // Find deals expiring in the next 1-2 hours (to avoid duplicate notifications)
    const expiringDeals = await Promotion.find({
      status: { $in: ['active', 'approved'] },
      endDate: { 
        $gte: in1Hour,
        $lte: in2Hours
      }
    }).populate('merchant');

    if (expiringDeals.length === 0) {
      console.log('[Expiring Flash Sales Job] No flash sales expiring soon');
      return;
    }

    console.log(`[Expiring Flash Sales Job] Found ${expiringDeals.length} deals expiring soon`);

    // Get all users with flash sale notifications enabled
    const preferences = await NotificationPreference.find({
      'preferences.flashSales.enabled': true
    });

    let notificationsSent = 0;

    for (const deal of expiringDeals) {
      const timeLeft = deal.endDate.getTime() - now.getTime();
      const hoursLeft = Math.floor(timeLeft / (60 * 60 * 1000));
      const minutesLeft = Math.floor((timeLeft % (60 * 60 * 1000)) / (60 * 1000));

      const merchantName = typeof deal.merchant === 'object' 
        ? deal.merchant.name 
        : 'a store';

      for (const pref of preferences) {
        // Check category preference
        const userCategories = pref.preferences.categories || [];
        if (userCategories.length > 0 && deal.category) {
          if (!userCategories.includes(deal.category)) {
            continue;
          }
        }

        await NotificationService.sendNotification(
          pref.userId,
          'flash_sale',
          { 
            dealId: deal._id.toString(),
            merchantId: typeof deal.merchant === 'object' ? deal.merchant._id.toString() : deal.merchant,
            hoursLeft,
            minutesLeft
          },
          {
            title: '⏰ Flash Sale Ending Soon!',
            body: `Last chance! "${deal.title}" at ${merchantName} ends in ${hoursLeft}h ${minutesLeft}m!`,
            channels: ['push', 'web'],
            priority: 'urgent'
          }
        );

        notificationsSent++;
      }
    }

    console.log(`[Expiring Flash Sales Job] Sent ${notificationsSent} notifications`);
  } catch (error) {
    console.error('[Expiring Flash Sales Job] Error:', error.message);
  }
}

module.exports = {
  notifyFlashSale,
  checkExpiringFlashSales
};
