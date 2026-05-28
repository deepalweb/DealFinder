const Promotion = require('../models/Promotion');
const NotificationLog = require('../models/NotificationLog');
const NotificationPreference = require('../models/NotificationPreference');
const UserPreferenceProfile = require('../models/UserPreferenceProfile');
const NotificationService = require('../services/NotificationService');

function toMerchantCoords(merchant) {
  const coordinates = merchant?.location?.coordinates;
  if (!Array.isArray(coordinates) || coordinates.length < 2) {
    return null;
  }

  const [longitude, latitude] = coordinates;
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    return null;
  }

  return { latitude, longitude };
}

function haversineKm(lat1, lon1, lat2, lon2) {
  const toRadians = (degrees) => (degrees * Math.PI) / 180;
  const earthRadiusKm = 6371;
  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(dLon / 2) ** 2;

  return earthRadiusKm * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

async function wasRecentlySent(userId, dealId) {
  const thirtyMinutesAgo = new Date(Date.now() - 30 * 60 * 1000);
  const existing = await NotificationLog.findOne({
    userId,
    type: 'nearby_deal',
    'data.dealId': String(dealId),
    createdAt: { $gte: thirtyMinutesAgo },
  })
    .select('_id')
    .lean();

  return Boolean(existing);
}

/**
 * Check for new deals near users and send notifications
 * Run this job every 30 minutes
 */
async function checkNearbyDeals() {
  try {
    console.log('[Nearby Deals Job] Starting...');

    const preferences = await NotificationPreference.find({
      'preferences.nearbyDeals.enabled': true,
      $or: [
        { 'channels.push.enabled': true },
        { 'channels.web.enabled': true },
        { 'channels.email.enabled': true },
      ],
    }).lean();

    if (preferences.length === 0) {
      console.log('[Nearby Deals Job] No users with nearby notifications enabled');
      return 0;
    }

    const profileMap = new Map(
      (
        await UserPreferenceProfile.find({
          userId: { $in: preferences.map((pref) => pref.userId) },
          'lastKnownLocation.latitude': { $ne: null },
          'lastKnownLocation.longitude': { $ne: null },
        })
          .select('userId lastKnownLocation preferredRadiusKm')
          .lean()
      ).map((profile) => [String(profile.userId), profile])
    );

    const thirtyMinutesAgo = new Date(Date.now() - 30 * 60 * 1000);
    const newDeals = await Promotion.find({
      status: { $in: ['active', 'approved', 'pending_approval', 'scheduled'] },
      createdAt: { $gte: thirtyMinutesAgo },
    })
      .populate('merchant', 'name location')
      .lean();

    const geocodedDeals = newDeals
      .map((deal) => {
        const coords = toMerchantCoords(deal.merchant);
        return coords ? { ...deal, merchantCoords: coords } : null;
      })
      .filter(Boolean);

    if (geocodedDeals.length === 0) {
      console.log('[Nearby Deals Job] No new geocoded deals in the last 30 minutes');
      return 0;
    }

    let notificationsSent = 0;

    for (const pref of preferences) {
      const profile = profileMap.get(String(pref.userId));
      const userLocation = profile?.lastKnownLocation;

      if (
        !userLocation ||
        !Number.isFinite(userLocation.latitude) ||
        !Number.isFinite(userLocation.longitude)
      ) {
        continue;
      }

      const radiusKm = Math.max(
        1,
        Number(pref.preferences?.nearbyDeals?.radius) ||
          Number(profile?.preferredRadiusKm) ||
          5
      );

      for (const deal of geocodedDeals) {
        const distanceKm = haversineKm(
          userLocation.latitude,
          userLocation.longitude,
          deal.merchantCoords.latitude,
          deal.merchantCoords.longitude
        );

        if (distanceKm > radiusKm) {
          continue;
        }

        if (await wasRecentlySent(pref.userId, deal._id)) {
          continue;
        }

        const merchantName = deal.merchant?.name || 'a store';

        await NotificationService.sendNotification(
          pref.userId,
          'nearby_deal',
          {
            dealId: deal._id.toString(),
            merchantId: deal.merchant?._id?.toString?.() || deal.merchant?._id || '',
            distanceKm: Number(distanceKm.toFixed(1)),
            radiusKm,
          },
          {
            title: 'Nearby deal for you',
            body: `${deal.title} at ${merchantName} is about ${distanceKm.toFixed(1)} km away.`,
            channels: ['push', 'web'],
            priority: 'high',
          }
        );

        notificationsSent += 1;
      }
    }

    console.log(`[Nearby Deals Job] Sent ${notificationsSent} notifications`);
    return notificationsSent;
  } catch (error) {
    console.error('[Nearby Deals Job] Error:', error.message);
    return 0;
  }
}

module.exports = checkNearbyDeals;
