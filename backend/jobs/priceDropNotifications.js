const Promotion = require('../models/Promotion');
const User = require('../models/User');
const NotificationPreference = require('../models/NotificationPreference');
const NotificationService = require('../services/NotificationService');

/**
 * Track promotion price changes and notify users
 * Run this job every 2 hours
 */
async function checkPriceDrops() {
  try {
    console.log('[Price Drop Job] Starting...');

    // Get all users with price drop notifications enabled
    const preferences = await NotificationPreference.find({
      'preferences.priceDrops.enabled': true
    }).populate('userId');

    if (preferences.length === 0) {
      console.log('[Price Drop Job] No users with price drop notifications enabled');
      return;
    }

    let notificationsSent = 0;

    for (const pref of preferences) {
      const user = pref.userId;
      if (!user || !user.favorites || user.favorites.length === 0) continue;

      // Get user's favorite deals
      const favoriteDeals = await Promotion.find({
        _id: { $in: user.favorites },
        status: { $in: ['active', 'approved'] }
      }).populate('merchant');

      for (const deal of favoriteDeals) {
        // Check if deal has price information and was recently updated
        if (!deal.updatedAt) continue;

        const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000);
        if (deal.updatedAt < twoHoursAgo) continue;

        // Check if discount increased or price decreased
        // This is a simplified check - in production you'd track price history
        const hasSignificantChange = deal.discount && 
          (deal.discount.includes('70%') || 
           deal.discount.includes('80%') || 
           deal.discount.includes('90%'));

        if (hasSignificantChange) {
          const merchantName = typeof deal.merchant === 'object' 
            ? deal.merchant.name 
            : 'a store';

          await NotificationService.sendNotification(
            user._id,
            'price_drop',
            { 
              dealId: deal._id.toString(),
              merchantId: typeof deal.merchant === 'object' ? deal.merchant._id.toString() : deal.merchant,
              discount: deal.discount
            },
            {
              title: '💰 Price Drop Alert!',
              body: `"${deal.title}" at ${merchantName} - Now ${deal.discount}!`,
              channels: ['push', 'web', 'email'],
              priority: 'high'
            }
          );

          notificationsSent++;
        }
      }
    }

    console.log(`[Price Drop Job] Sent ${notificationsSent} notifications`);
  } catch (error) {
    console.error('[Price Drop Job] Error:', error.message);
  }
}

/**
 * Notify about a specific price drop (called when promotion is updated)
 */
async function notifyPriceDrop(promotionId, oldDiscount, newDiscount) {
  try {
    console.log('[Price Drop] Checking for promotion:', promotionId);

    // Parse discount percentages
    const oldPercent = parseInt(oldDiscount?.match(/\d+/)?.[0] || '0');
    const newPercent = parseInt(newDiscount?.match(/\d+/)?.[0] || '0');

    // Only notify if discount increased by at least 10%
    if (newPercent <= oldPercent || (newPercent - oldPercent) < 10) {
      return 0;
    }

    const promotion = await Promotion.findById(promotionId).populate('merchant');
    if (!promotion) return 0;

    // Find users who favorited this deal
    const users = await User.find({
      favorites: promotionId
    });

    if (users.length === 0) return 0;

    // Get preferences for these users
    const preferences = await NotificationPreference.find({
      userId: { $in: users.map(u => u._id) },
      'preferences.priceDrops.enabled': true
    });

    const merchantName = typeof promotion.merchant === 'object' 
      ? promotion.merchant.name 
      : 'a store';

    let notificationsSent = 0;

    for (const pref of preferences) {
      await NotificationService.sendNotification(
        pref.userId,
        'price_drop',
        { 
          dealId: promotion._id.toString(),
          merchantId: typeof promotion.merchant === 'object' ? promotion.merchant._id.toString() : promotion.merchant,
          oldDiscount,
          newDiscount
        },
        {
          title: '💰 Price Drop Alert!',
          body: `"${promotion.title}" at ${merchantName} - Discount increased from ${oldDiscount} to ${newDiscount}!`,
          channels: ['push', 'web'],
          priority: 'high'
        }
      );

      notificationsSent++;
    }

    console.log(`[Price Drop] Sent ${notificationsSent} notifications`);
    return notificationsSent;
  } catch (error) {
    console.error('[Price Drop] Error:', error.message);
    return 0;
  }
}

module.exports = {
  checkPriceDrops,
  notifyPriceDrop
};
