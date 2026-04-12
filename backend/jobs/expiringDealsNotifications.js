const Promotion = require('../models/Promotion');
const User = require('../models/User');
const NotificationPreference = require('../models/NotificationPreference');
const NotificationService = require('../services/NotificationService');

/**
 * Check for deals expiring soon and notify users who favorited them
 * Run this job daily at 9 AM
 */
async function checkExpiringDealsForUsers() {
  try {
    console.log('[Expiring Deals Job] Starting...');

    const now = new Date();
    const in24Hours = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    const in48Hours = new Date(now.getTime() + 48 * 60 * 60 * 1000);

    // Get all users with expiring deal notifications enabled
    const preferences = await NotificationPreference.find({
      'preferences.expiringDeals.enabled': true
    }).populate('userId');

    if (preferences.length === 0) {
      console.log('[Expiring Deals Job] No users with expiring deal notifications enabled');
      return;
    }

    let notificationsSent = 0;

    for (const pref of preferences) {
      const user = pref.userId;
      if (!user || !user.favorites || user.favorites.length === 0) continue;

      const expiryHours = pref.preferences.expiringDeals.hours || 24;
      const expiryThreshold = new Date(now.getTime() + expiryHours * 60 * 60 * 1000);

      // Get user's favorite deals that are expiring soon
      const expiringDeals = await Promotion.find({
        _id: { $in: user.favorites },
        status: { $in: ['active', 'approved'] },
        endDate: { 
          $gte: now,
          $lte: expiryThreshold
        }
      }).populate('merchant');

      if (expiringDeals.length === 0) continue;

      // Group by time remaining
      const expiringSoon = [];
      const expiringToday = [];

      for (const deal of expiringDeals) {
        const timeLeft = deal.endDate.getTime() - now.getTime();
        const hoursLeft = Math.floor(timeLeft / (60 * 60 * 1000));

        if (hoursLeft <= 6) {
          expiringSoon.push({ deal, hoursLeft });
        } else if (hoursLeft <= 24) {
          expiringToday.push({ deal, hoursLeft });
        }
      }

      // Send notifications for deals expiring very soon (< 6 hours)
      for (const { deal, hoursLeft } of expiringSoon) {
        const merchantName = typeof deal.merchant === 'object' 
          ? deal.merchant.name 
          : 'a store';

        await NotificationService.sendNotification(
          user._id,
          'expiring_deal',
          { 
            dealId: deal._id.toString(),
            merchantId: typeof deal.merchant === 'object' ? deal.merchant._id.toString() : deal.merchant,
            hoursLeft
          },
          {
            title: '⏰ Deal Expiring Soon!',
            body: `"${deal.title}" at ${merchantName} expires in ${hoursLeft} hour${hoursLeft !== 1 ? 's' : ''}!`,
            channels: ['push', 'web', 'email'],
            priority: 'urgent'
          }
        );

        notificationsSent++;
      }

      // Send summary for deals expiring today
      if (expiringToday.length > 0) {
        const dealsList = expiringToday.slice(0, 3).map(({ deal }) => deal.title).join(', ');
        const moreText = expiringToday.length > 3 ? ` and ${expiringToday.length - 3} more` : '';

        await NotificationService.sendNotification(
          user._id,
          'expiring_deal',
          { 
            dealIds: expiringToday.map(({ deal }) => deal._id.toString()),
            count: expiringToday.length
          },
          {
            title: '📅 Deals Expiring Today',
            body: `${expiringToday.length} of your favorite deal${expiringToday.length !== 1 ? 's' : ''} expire${expiringToday.length === 1 ? 's' : ''} today: ${dealsList}${moreText}`,
            channels: ['push', 'web'],
            priority: 'high'
          }
        );

        notificationsSent++;
      }
    }

    console.log(`[Expiring Deals Job] Sent ${notificationsSent} notifications`);
  } catch (error) {
    console.error('[Expiring Deals Job] Error:', error.message);
  }
}

module.exports = checkExpiringDealsForUsers;
