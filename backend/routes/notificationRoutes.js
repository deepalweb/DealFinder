const express = require('express');
const router = express.Router();
const NotificationLog = require('../models/NotificationLog');
const NotificationPreference = require('../models/NotificationPreference');
const NotificationService = require('../services/NotificationService');
const NotificationAnalyticsService = require('../services/NotificationAnalyticsService');
const transporter = require('../mailer');
const { authenticateJWT, authorizeAdmin } = require('../middleware/auth');

function safeError(error) {
  if (process.env.NODE_ENV === 'production') {
    return { message: 'An error occurred' };
  }
  return { message: error.message, stack: error.stack };
}

function buildChannelSummary(notification) {
  if (!notification) {
    return {
      push: { attempted: false, success: false, error: 'Notification was not created' },
      web: { attempted: false, success: false, error: 'Notification was not created' },
      email: { attempted: false, success: false, error: 'Notification was not created' },
    };
  }

  const attemptedChannels = new Set(notification.channels || []);
  const status = notification.status || {};

  return {
    push: {
      attempted: attemptedChannels.has('push'),
      success: status.push?.sent === true || status.push?.delivered === true,
      error: status.push?.error || null,
    },
    web: {
      attempted: attemptedChannels.has('web'),
      success: status.web?.sent === true,
      error: status.web?.error || null,
    },
    email: {
      attempted: attemptedChannels.has('email'),
      success: status.email?.sent === true,
      error: status.email?.error || null,
    },
  };
}

function buildSkippedSummary(reason) {
  return {
    push: { attempted: false, success: false, error: reason },
    web: { attempted: false, success: false, error: reason },
    email: { attempted: false, success: false, error: reason },
  };
}

function flattenForSet(input, prefix = '') {
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    return prefix ? { [prefix]: input } : {};
  }

  return Object.entries(input).reduce((acc, [key, value]) => {
    const nextPrefix = prefix ? `${prefix}.${key}` : key;

    if (value && typeof value === 'object' && !Array.isArray(value)) {
      Object.assign(acc, flattenForSet(value, nextPrefix));
    } else {
      acc[nextPrefix] = value;
    }

    return acc;
  }, {});
}

// Get user's notifications
router.get('/', authenticateJWT, async (req, res) => {
  try {
    const { limit = 20, skip = 0, unreadOnly = false } = req.query;
    const notifications = await NotificationService.getUserNotifications(
      req.user.id,
      { limit: parseInt(limit), skip: parseInt(skip), unreadOnly: unreadOnly === 'true' }
    );
    res.status(200).json(notifications);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Get unread count
router.get('/unread-count', authenticateJWT, async (req, res) => {
  try {
    const count = await NotificationService.getUnreadCount(req.user.id);
    res.status(200).json({ count });
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Mark notification as read
router.patch('/:id/read', authenticateJWT, async (req, res) => {
  try {
    const notification = await NotificationService.markAsRead(req.params.id, req.user.id);
    if (!notification) {
      return res.status(404).json({ message: 'Notification not found' });
    }
    res.status(200).json(notification);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Delete notification
router.delete('/:id', authenticateJWT, async (req, res) => {
  try {
    const result = await NotificationLog.findOneAndDelete({ _id: req.params.id, userId: req.user.id });
    if (!result) {
      return res.status(404).json({ message: 'Notification not found' });
    }
    res.status(200).json({ message: 'Notification deleted' });
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Get notification preferences
router.get('/preferences', authenticateJWT, async (req, res) => {
  try {
    let prefs = await NotificationPreference.findOne({ userId: req.user.id });
    if (!prefs) {
      // Create default preferences
      prefs = new NotificationPreference({ userId: req.user.id });
      await prefs.save();
    }
    res.status(200).json(prefs);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Update notification preferences
router.put('/preferences', authenticateJWT, async (req, res) => {
  try {
    const updates = flattenForSet(req.body);
    updates.updatedAt = new Date();

    const prefs = await NotificationPreference.findOneAndUpdate(
      { userId: req.user.id },
      { $set: updates },
      { new: true, upsert: true }
    );
    res.status(200).json(prefs);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Reset preferences to defaults
router.post('/preferences/reset', authenticateJWT, async (req, res) => {
  try {
    await NotificationPreference.findOneAndDelete({ userId: req.user.id });
    const prefs = new NotificationPreference({ userId: req.user.id });
    await prefs.save();
    res.status(200).json(prefs);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Subscribe to web push
router.post('/subscribe', authenticateJWT, async (req, res) => {
  try {
    const { subscription, type = 'web' } = req.body;
    const prefs = await NotificationPreference.findOneAndUpdate(
      { userId: req.user.id },
      { 
        $set: type === 'web' 
          ? { 'channels.web.subscription': subscription, 'channels.web.enabled': true }
          : { 'channels.push.token': subscription, 'channels.push.enabled': true }
      },
      { new: true, upsert: true }
    );
    res.status(200).json({ message: 'Subscribed successfully', prefs });
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Unsubscribe from notifications
router.post('/unsubscribe', authenticateJWT, async (req, res) => {
  try {
    const { type = 'web' } = req.body;
    const prefs = await NotificationPreference.findOneAndUpdate(
      { userId: req.user.id },
      { 
        $set: type === 'web' 
          ? { 'channels.web.enabled': false, 'channels.web.subscription': null }
          : { 'channels.push.enabled': false, 'channels.push.token': null }
      },
      { new: true }
    );
    res.status(200).json({ message: 'Unsubscribed successfully', prefs });
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Send test notification
router.post('/test', authenticateJWT, async (req, res) => {
  try {
    let prefs = await NotificationPreference.findOne({ userId: req.user.id });
    if (!prefs) {
      prefs = new NotificationPreference({ userId: req.user.id });
      await prefs.save();
    }

    const notification = await NotificationService.sendNotification(
      req.user.id,
      'account_activity',
      { test: true },
      {
        title: '🎉 Test Notification',
        body: 'This is a test notification from DealFinder!',
        channels: ['push', 'web', 'email'],
        ignoreQuietHours: true,
      }
    );

    const enabledChannels = {
      push: prefs.channels?.push?.enabled === true,
      web: prefs.channels?.web?.enabled === true,
      email: prefs.channels?.email?.enabled === true,
    };

    const noEnabledChannels = !enabledChannels.push && !enabledChannels.web && !enabledChannels.email;
    const summary = notification
      ? buildChannelSummary(notification)
      : buildSkippedSummary(
          noEnabledChannels
            ? 'No notification channels are enabled for this account'
            : 'Notification was skipped before delivery'
        );
    const pushWorked = summary.push.success;
    const webWorked = summary.web.success;
    const emailWorked = summary.email.success;

    res.status(200).json({
      message:
        pushWorked || webWorked || emailWorked
          ? 'Test notification processed'
          : 'Test notification did not reach any delivery channel',
      notification,
      summary,
      enabledChannels,
    });
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Admin: Broadcast notification
router.post('/broadcast', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const { title, body, type = 'account_activity', data = {} } = req.body;
    const User = require('../models/User');
    const users = await User.find({}, '_id');
    const userIds = users.map(u => u._id);
    
    const results = await NotificationService.batchNotify(
      userIds,
      type,
      data,
      { title, body, channels: ['push', 'web'] }
    );
    
    res.status(200).json({ message: `Broadcast sent to ${results.length} users`, results });
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Admin: Get notification analytics
router.get('/analytics/dashboard', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const stats = await NotificationAnalyticsService.getDashboardStats();
    res.status(200).json(stats);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

router.get('/analytics/delivery', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const start = startDate ? new Date(startDate) : new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const end = endDate ? new Date(endDate) : new Date();
    
    const stats = await NotificationAnalyticsService.getDeliveryStats(start, end);
    res.status(200).json(stats);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

router.get('/analytics/by-type', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const start = startDate ? new Date(startDate) : new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const end = endDate ? new Date(endDate) : new Date();
    
    const stats = await NotificationAnalyticsService.getStatsByType(start, end);
    res.status(200).json(stats);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

router.get('/analytics/engagement', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const start = startDate ? new Date(startDate) : new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const end = endDate ? new Date(endDate) : new Date();
    
    const stats = await NotificationAnalyticsService.getUserEngagement(start, end);
    res.status(200).json(stats);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

router.get('/analytics/hourly', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const start = startDate ? new Date(startDate) : new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const end = endDate ? new Date(endDate) : new Date();
    
    const distribution = await NotificationAnalyticsService.getHourlyDistribution(start, end);
    res.status(200).json(distribution);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

router.get('/analytics/top-performing', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    const top = await NotificationAnalyticsService.getTopPerforming(parseInt(limit));
    res.status(200).json(top);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

router.get('/analytics/volume', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const { days = 30 } = req.query;
    const volume = await NotificationAnalyticsService.getDailyVolume(parseInt(days));
    res.status(200).json(volume);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Legacy routes for backward compatibility
router.get('/admin/all', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const notifications = await NotificationLog.find().sort({ createdAt: -1 });
    res.status(200).json(notifications);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

router.post('/test-email', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const { to, subject, text } = req.body;
    if (!to || !subject || !text) {
      return res.status(400).json({ message: 'Missing required fields: to, subject, text' });
    }
    await transporter.sendMail({
      from: `DealFinder <${process.env.M365_EMAIL}>`,
      to,
      subject: subject || 'DealFinder Test Email',
      text: text || 'This is a test notification from DealFinder.',
      html: `<p>${text || 'This is a test notification from DealFinder.'}</p>`
    });
    res.status(200).json({ message: 'Test email sent successfully.' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to send test email.', error: err.message });
  }
});

module.exports = router;
