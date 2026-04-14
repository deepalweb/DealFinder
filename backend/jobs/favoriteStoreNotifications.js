const Promotion = require('../models/Promotion');
const User = require('../models/User');
const NotificationPreference = require('../models/NotificationPreference');
const NotificationService = require('../services/NotificationService');

/**
 * Notify users when their favorite stores post new deals
 * This should be called when a new promotion is created
 */
async function notifyFavoriteStoreFollowers(promotionId) {
  try {
    console.log('[Favorite Store Job] Starting for promotion:', promotionId);

    const promotion = await Promotion.findById(promotionId).populate('merchant');
    if (!promotion || !promotion.merchant) {
      console.log('[Favorite Store Job] Promotion or merchant not found');
      return;
    }

    const merchantId = typeof promotion.merchant === 'object' 
      ? promotion.merchant._id 
      : promotion.merchant;

    // Find promotions from this merchant that users have favorited
    const merchantPromotionIds = await Promotion.find({ merchant: merchantId }).distinct('_id');

    // Find users who have any of those promotions in their favorites
    const followingUsers = await User.find(
      { favorites: { $in: merchantPromotionIds } },
      { _id: 1 }
    ).lean();

    const merchantFollowers = new Set(followingUsers.map(u => u._id.toString()));

    if (merchantFollowers.size === 0) {
      console.log('[Favorite Store Job] No followers for this merchant');
      return;
    }

    console.log(`[Favorite Store Job] Found ${merchantFollowers.size} followers`);

    // Get preferences for these users
    const preferences = await NotificationPreference.find({
      userId: { $in: Array.from(merchantFollowers) },
      'preferences.favoriteStores.enabled': true
    });

    const merchantName = typeof promotion.merchant === 'object' 
      ? promotion.merchant.name 
      : 'your favorite store';

    let notificationsSent = 0;

    for (const pref of preferences) {
      await NotificationService.sendNotification(
        pref.userId,
        'favorite_store',
        { 
          dealId: promotion._id.toString(),
          merchantId: merchantId.toString()
        },
        {
          title: `💝 New Deal from ${merchantName}!`,
          body: `${promotion.title} - ${promotion.discount || 'Check it out now!'}`,
          channels: ['push', 'web', 'email'],
          priority: 'high'
        }
      );

      notificationsSent++;
    }

    console.log(`[Favorite Store Job] Sent ${notificationsSent} notifications`);
    return notificationsSent;
  } catch (error) {
    console.error('[Favorite Store Job] Error:', error.message);
    return 0;
  }
}

/**
 * Batch check for new deals from favorite stores
 * Run this every 2 hours to catch any missed notifications
 */
async function checkFavoriteStoresNewDeals() {
  try {
    console.log('[Favorite Store Batch Job] Starting...');

    const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000);
    
    const newDeals = await Promotion.find({
      status: { $in: ['active', 'approved'] },
      createdAt: { $gte: twoHoursAgo }
    });

    console.log(`[Favorite Store Batch Job] Found ${newDeals.length} new deals`);

    let totalNotifications = 0;

    for (const deal of newDeals) {
      const sent = await notifyFavoriteStoreFollowers(deal._id);
      totalNotifications += sent;
    }

    console.log(`[Favorite Store Batch Job] Total notifications sent: ${totalNotifications}`);
  } catch (error) {
    console.error('[Favorite Store Batch Job] Error:', error.message);
  }
}

module.exports = {
  notifyFavoriteStoreFollowers,
  checkFavoriteStoresNewDeals
};
