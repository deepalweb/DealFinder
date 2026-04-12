const Promotion = require('../models/Promotion');
const User = require('../models/User');
const NotificationPreference = require('../models/NotificationPreference');
const NotificationService = require('../services/NotificationService');

/**
 * Check for new deals near users and send notifications
 * Run this job every 30 minutes
 */
async function checkNearbyDeals() {
  try {
    console.log('[Nearby Deals Job] Starting...');

    // Get all users with nearby deal notifications enabled
    const preferences = await NotificationPreference.find({
      'preferences.nearbyDeals.enabled': true,
      $or: [
        { 'channels.push.enabled': true },
        { 'channels.web.enabled': true },
        { 'channels.email.enabled': true }
      ]
    }).populate('userId');

    if (preferences.length === 0) {
      console.log('[Nearby Deals Job] No users with nearby notifications enabled');
      return;
    }

    // Get deals created in the last 30 minutes
    const thirtyMinutesAgo = new Date(Date.now() - 30 * 60 * 1000);
    const newDeals = await Promotion.find({
      status: { $in: ['active', 'approved'] },
      createdAt: { $gte: thirtyMinutesAgo },
      'location.coordinates': { $exists: true }
    }).populate('merchant');

    if (newDeals.length === 0) {
      console.log('[Nearby Deals Job] No new deals in the last 30 minutes');
      return;
    }

    console.log(`[Nearby Deals Job] Found ${newDeals.length} new deals`);

    let notificationsSent = 0;

    for (const pref of preferences) {
      const user = pref.userId;
      if (!user) continue;

      // Get user's last known location (you might want to store this)
      // For now, we'll skip users without location
      // In production, you'd track user locations or use their home address
      
      // Check each new deal
      for (const deal of newDeals) {
        if (!deal.location || !deal.location.coordinates) continue;

        // Calculate distance (simplified - in production use proper geospatial queries)
        const radius = pref.preferences.nearbyDeals.radius || 5;
        
        // Send notification
        const merchantName = typeof deal.merchant === 'object' 
          ? deal.merchant.name 
          : 'a store';

        await NotificationService.sendNotification(
          user._id,
          'nearby_deal',
          { 
            dealId: deal._id.toString(),
            merchantId: typeof deal.merchant === 'object' ? deal.merchant._id.toString() : deal.merchant,
            distance: radius
          },
          {
            title: '🎯 New Deal Nearby!',
            body: `${deal.title} at ${merchantName} - ${deal.discount || 'Special offer'}`,
            channels: ['push', 'web'],
            priority: 'high'
          }
        );

        notificationsSent++;
      }
    }

    console.log(`[Nearby Deals Job] Sent ${notificationsSent} notifications`);
  } catch (error) {
    console.error('[Nearby Deals Job] Error:', error.message);
  }
}

module.exports = checkNearbyDeals;
