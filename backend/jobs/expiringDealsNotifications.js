const Promotion = require('../models/Promotion');
const User = require('../models/User');
const DealAlert = require('../models/DealAlert');
const NotificationPreference = require('../models/NotificationPreference');
const NotificationService = require('../services/NotificationService');
const { hasRecentNotification } = require('./jobNotificationUtils');

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

    // Collect all favorite IDs across all users, then query once
    const allFavoriteIds = [...new Set(preferences.flatMap(p => {
      const user = p.userId;
      return (user && user.favorites) ? user.favorites.map(id => id.toString()) : [];
    }))];

    if (allFavoriteIds.length === 0) {
      console.log('[Expiring Deals Job] No favorites found');
      return;
    }

    // Single query for all expiring deals across all users
    const maxExpiryHours = Math.max(...preferences.map(p => p.preferences.expiringDeals.hours || 24));
    const maxThreshold = new Date(now.getTime() + maxExpiryHours * 60 * 60 * 1000);

    const allExpiringDeals = await Promotion.find({
      _id: { $in: allFavoriteIds },
      status: { $in: ['active', 'approved', 'pending_approval', 'scheduled'] },
      endDate: { $gte: now, $lte: maxThreshold }
    }).populate('merchant').lean();

    const expiringDealsMap = new Map(allExpiringDeals.map(d => [d._id.toString(), d]));

    let notificationsSent = 0;
    const recentWindowStart = new Date(Date.now() - 24 * 60 * 60 * 1000);

    for (const pref of preferences) {
      const user = pref.userId;
      if (!user || !user.favorites || user.favorites.length === 0) continue;

      const expiryHours = pref.preferences.expiringDeals.hours || 24;
      const expiryThreshold = new Date(now.getTime() + expiryHours * 60 * 60 * 1000);

      const expiringDeals = user.favorites
        .map(id => expiringDealsMap.get(id.toString()))
        .filter(d => d && new Date(d.endDate) <= expiryThreshold);

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

        const alreadySent = await hasRecentNotification({
          userId: user._id,
          type: 'expiring_deal',
          dealId: deal._id,
          merchantId: typeof deal.merchant === 'object' ? deal.merchant._id : deal.merchant,
          since: recentWindowStart,
        });

        if (alreadySent) {
          continue;
        }

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
        const summaryKey = `summary:${expiringToday.map(({ deal }) => deal._id.toString()).sort().join(',')}`;
        const alreadySent = await hasRecentNotification({
          userId: user._id,
          type: 'expiring_deal',
          summaryKey,
          since: recentWindowStart,
        });

        if (alreadySent) {
          continue;
        }

        await NotificationService.sendNotification(
          user._id,
          'expiring_deal',
          { 
            summaryKey,
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

    const alertRows = await DealAlert.find({
      active: true,
      alertTypes: 'expiry',
    })
      .populate('userId')
      .populate({
        path: 'promotion',
        match: {
          status: { $in: ['active', 'approved', 'pending_approval', 'scheduled'] },
          endDate: { $gte: now, $lte: in48Hours },
        },
        populate: { path: 'merchant' },
      });

    for (const alert of alertRows) {
      const user = alert.userId;
      const deal = alert.promotion;
      if (!user || !deal) continue;

      const pref = preferences.find((item) => String(item.userId?._id) === String(user._id));
      if (!pref) continue;

      const expiryHours = pref.preferences.expiringDeals.hours || 24;
      const expiryThreshold = new Date(now.getTime() + expiryHours * 60 * 60 * 1000);
      if (deal.endDate > expiryThreshold) continue;

      const hoursLeft = Math.max(0, Math.floor((deal.endDate.getTime() - now.getTime()) / (60 * 60 * 1000)));
      const merchantName = typeof deal.merchant === 'object' ? deal.merchant.name : 'a store';
      const merchantId = typeof deal.merchant === 'object' ? deal.merchant._id : deal.merchant;
      const alreadySent = await hasRecentNotification({
        userId: user._id,
        type: 'expiring_deal',
        dealId: deal._id,
        merchantId,
        since: recentWindowStart,
      });

      if (alreadySent) continue;

      const notification = await NotificationService.sendNotification(
        user._id,
        'expiring_deal',
        {
          dealId: deal._id.toString(),
          merchantId: merchantId?.toString(),
          hoursLeft,
          source: 'deal_alert',
        },
        {
          title: '⏰ Deal Alert: Expiring Soon',
          body: `"${deal.title}" at ${merchantName} expires in ${hoursLeft} hour${hoursLeft !== 1 ? 's' : ''}.`,
          channels: ['push', 'web', 'email'],
          priority: hoursLeft <= 6 ? 'urgent' : 'high',
        }
      );

      if (notification) {
        alert.lastExpiryNotifiedAt = new Date();
        await alert.save();
        notificationsSent++;
      }
    }

    console.log(`[Expiring Deals Job] Sent ${notificationsSent} notifications`);
  } catch (error) {
    console.error('[Expiring Deals Job] Error:', error.message);
  }
}

module.exports = checkExpiringDealsForUsers;
