const NotificationLog = require('../models/NotificationLog');
const NotificationPreference = require('../models/NotificationPreference');
const User = require('../models/User');
const webpush = require('web-push');
const admin = require('firebase-admin');
const mailer = require('../mailer');

class NotificationService {
  constructor() {
    // Configure web-push VAPID keys
    if (process.env.VAPID_PUBLIC_KEY && process.env.VAPID_PRIVATE_KEY) {
      webpush.setVapidDetails(
        'mailto:' + (process.env.M365_EMAIL || 'noreply@dealfinder.com'),
        process.env.VAPID_PUBLIC_KEY,
        process.env.VAPID_PRIVATE_KEY
      );
    }
  }

  /**
   * Send notification to a user across specified channels
   */
  async sendNotification(userId, type, data, options = {}) {
    try {
      const { title, body, channels = ['push', 'email', 'web'], priority = 'normal' } = options;

      // Get user preferences
      const prefs = await NotificationPreference.findOne({ userId });
      if (!prefs) {
        console.log(`No preferences found for user ${userId}`);
        return null;
      }

      // Check if notification type is enabled
      if (!this._isNotificationEnabled(prefs, type)) {
        console.log(`Notification type ${type} disabled for user ${userId}`);
        return null;
      }

      // Check quiet hours
      if (this._isQuietHours(prefs)) {
        console.log(`Quiet hours active for user ${userId}`);
        return null;
      }

      // Create notification log
      const notificationLog = new NotificationLog({
        userId,
        type,
        title,
        body,
        data,
        channels,
        priority,
        sentAt: new Date()
      });

      // Send through each channel
      const results = await Promise.allSettled([
        channels.includes('push') && prefs.channels.push.enabled 
          ? this._sendPushNotification(prefs, title, body, data, notificationLog)
          : Promise.resolve(),
        channels.includes('email') && prefs.channels.email.enabled 
          ? this._sendEmailNotification(userId, title, body, data, notificationLog)
          : Promise.resolve(),
        channels.includes('web') && prefs.channels.web.enabled 
          ? this._sendWebPushNotification(prefs, title, body, data, notificationLog)
          : Promise.resolve()
      ]);

      await notificationLog.save();
      return notificationLog;
    } catch (error) {
      console.error('Error sending notification:', error);
      return null;
    }
  }

  /**
   * Send notification to multiple users
   */
  async batchNotify(userIds, type, data, options) {
    const results = await Promise.allSettled(
      userIds.map(userId => this.sendNotification(userId, type, data, options))
    );
    return results.filter(r => r.status === 'fulfilled').map(r => r.value);
  }

  /**
   * Schedule notification for later
   */
  async scheduleNotification(userId, type, data, sendAt, options) {
    // TODO: Implement with job queue (Bull/Agenda)
    console.log(`Scheduled notification for ${userId} at ${sendAt}`);
    return { scheduled: true, sendAt };
  }

  /**
   * Send push notification via FCM
   */
  async _sendPushNotification(prefs, title, body, data, log) {
    try {
      if (!prefs.channels.push.token) {
        throw new Error('No FCM token');
      }

      const normalizedData = Object.entries(data || {}).reduce((acc, [key, value]) => {
        if (value === undefined || value === null) {
          return acc;
        }

        acc[key] = typeof value === 'string' ? value : JSON.stringify(value);
        return acc;
      }, {});

      const message = {
        notification: { title, body },
        data: normalizedData,
        token: prefs.channels.push.token
      };

      if (admin.apps.length > 0) {
        await admin.messaging().send(message);
        log.status.push.sent = true;
        log.status.push.delivered = true;
      } else {
        throw new Error('Firebase not initialized');
      }
    } catch (error) {
      log.status.push.error = error.message;
      console.error('Push notification error:', error);
    }
  }

  /**
   * Send web push notification
   */
  async _sendWebPushNotification(prefs, title, body, data, log) {
    try {
      if (!prefs.channels.web.subscription) {
        throw new Error('No web push subscription');
      }

      const payload = JSON.stringify({
        title,
        body,
        icon: '/favicon.ico',
        badge: '/favicon.ico',
        data: data || {}
      });

      await webpush.sendNotification(prefs.channels.web.subscription, payload);
      log.status.web.sent = true;
    } catch (error) {
      log.status.web.error = error.message;
      console.error('Web push error:', error);
    }
  }

  /**
   * Send email notification
   */
  async _sendEmailNotification(userId, title, body, data, log, userEmail = null) {
    try {
      let email = userEmail;
      if (!email) {
        const user = await User.findById(userId).select('email').lean();
        email = user?.email;
      }
      if (!email) throw new Error('User email not found');

      const emailHtml = this._generateEmailTemplate(title, body, data);

      await mailer.sendMail({
        from: `DealFinder <${process.env.M365_EMAIL}>`,
        to: email,
        subject: title,
        html: emailHtml
      });

      log.status.email.sent = true;
    } catch (error) {
      log.status.email.error = error.message;
      console.error('Email notification error:', error);
    }
  }

  /**
   * Check if notification type is enabled
   */
  _isNotificationEnabled(prefs, type) {
    const typeMap = {
      'nearby_deal': prefs.preferences.nearbyDeals.enabled,
      'favorite_store': prefs.preferences.favoriteStores.enabled,
      'expiring_deal': prefs.preferences.expiringDeals.enabled,
      'price_drop': prefs.preferences.priceDrops.enabled,
      'flash_sale': prefs.preferences.flashSales.enabled,
      'weekly_digest': prefs.preferences.weeklyDigest.enabled,
      'category_deal': true,
      'deal_redeemed': true,
      'merchant_expiry': true,
      'account_activity': true
    };
    return typeMap[type] !== false;
  }

  /**
   * Check if current time is within quiet hours
   */
  _isQuietHours(prefs) {
    if (!prefs.quietHours.enabled) return false;

    const now = new Date();
    const currentTime = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
    const { start, end } = prefs.quietHours;

    if (start < end) {
      return currentTime >= start && currentTime < end;
    } else {
      return currentTime >= start || currentTime < end;
    }
  }

  /**
   * Generate email template
   */
  _generateEmailTemplate(title, body, data) {
    const dealLink = data.dealId 
      ? `${process.env.APP_URL || 'https://dealfinderlk.com'}/deal/${data.dealId}`
      : process.env.APP_URL || 'https://dealfinderlk.com';

    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
      </head>
      <body style="margin:0;padding:0;font-family:Inter,Arial,sans-serif;background:#f8fafc">
        <div style="max-width:600px;margin:0 auto;padding:20px">
          <div style="background:#fff;border-radius:12px;padding:32px;box-shadow:0 2px 8px rgba(0,0,0,0.05)">
            <div style="text-align:center;margin-bottom:24px">
              <h1 style="color:#6366f1;margin:0;font-size:24px">DealFinder</h1>
            </div>
            <h2 style="color:#1e293b;font-size:20px;margin:0 0 16px">${title}</h2>
            <p style="color:#475569;font-size:16px;line-height:1.6;margin:0 0 24px">${body}</p>
            ${data.dealId ? `
              <a href="${dealLink}" style="display:inline-block;background:linear-gradient(135deg,#6366f1,#8b5cf6);color:#fff;padding:12px 32px;border-radius:8px;text-decoration:none;font-weight:600">
                View Deal →
              </a>
            ` : ''}
            <div style="margin-top:32px;padding-top:24px;border-top:1px solid #e2e8f0">
              <p style="color:#94a3b8;font-size:14px;margin:0">
                You're receiving this because you enabled notifications in your DealFinder account.
                <a href="${process.env.APP_URL || 'https://dealfinderlk.com'}/profile" style="color:#6366f1">Manage preferences</a>
              </p>
            </div>
          </div>
        </div>
      </body>
      </html>
    `;
  }

  /**
   * Get user notifications
   */
  async getUserNotifications(userId, options = {}) {
    const { limit = 20, skip = 0, unreadOnly = false } = options;
    const query = { userId };
    if (unreadOnly) query.read = false;

    return await NotificationLog.find(query)
      .sort({ createdAt: -1 })
      .limit(limit)
      .skip(skip);
  }

  /**
   * Mark notification as read
   */
  async markAsRead(notificationId, userId) {
    return await NotificationLog.findOneAndUpdate(
      { _id: notificationId, userId },
      { read: true, readAt: new Date() },
      { new: true }
    );
  }

  /**
   * Get unread count
   */
  async getUnreadCount(userId) {
    return await NotificationLog.countDocuments({ userId, read: false });
  }
}

module.exports = new NotificationService();
