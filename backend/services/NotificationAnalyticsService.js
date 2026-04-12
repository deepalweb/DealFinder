const NotificationLog = require('../models/NotificationLog');
const NotificationPreference = require('../models/NotificationPreference');

class NotificationAnalyticsService {
  /**
   * Get delivery statistics for a date range
   */
  async getDeliveryStats(startDate, endDate) {
    const stats = await NotificationLog.aggregate([
      {
        $match: {
          createdAt: { $gte: startDate, $lte: endDate }
        }
      },
      {
        $group: {
          _id: null,
          total: { $sum: 1 },
          pushSent: { $sum: { $cond: ['$status.push.sent', 1, 0] } },
          pushDelivered: { $sum: { $cond: ['$status.push.delivered', 1, 0] } },
          pushOpened: { $sum: { $cond: ['$status.push.opened', 1, 0] } },
          emailSent: { $sum: { $cond: ['$status.email.sent', 1, 0] } },
          emailOpened: { $sum: { $cond: ['$status.email.opened', 1, 0] } },
          webSent: { $sum: { $cond: ['$status.web.sent', 1, 0] } },
          webClicked: { $sum: { $cond: ['$status.web.clicked', 1, 0] } },
          read: { $sum: { $cond: ['$read', 1, 0] } }
        }
      }
    ]);

    if (stats.length === 0) {
      return {
        total: 0,
        deliveryRate: 0,
        openRate: 0,
        clickRate: 0,
        readRate: 0
      };
    }

    const data = stats[0];
    return {
      total: data.total,
      push: {
        sent: data.pushSent,
        delivered: data.pushDelivered,
        opened: data.pushOpened,
        deliveryRate: data.pushSent > 0 ? (data.pushDelivered / data.pushSent * 100).toFixed(2) : 0,
        openRate: data.pushDelivered > 0 ? (data.pushOpened / data.pushDelivered * 100).toFixed(2) : 0
      },
      email: {
        sent: data.emailSent,
        opened: data.emailOpened,
        openRate: data.emailSent > 0 ? (data.emailOpened / data.emailSent * 100).toFixed(2) : 0
      },
      web: {
        sent: data.webSent,
        clicked: data.webClicked,
        clickRate: data.webSent > 0 ? (data.webClicked / data.webSent * 100).toFixed(2) : 0
      },
      readRate: data.total > 0 ? (data.read / data.total * 100).toFixed(2) : 0
    };
  }

  /**
   * Get notification stats by type
   */
  async getStatsByType(startDate, endDate) {
    const stats = await NotificationLog.aggregate([
      {
        $match: {
          createdAt: { $gte: startDate, $lte: endDate }
        }
      },
      {
        $group: {
          _id: '$type',
          count: { $sum: 1 },
          read: { $sum: { $cond: ['$read', 1, 0] } },
          delivered: { $sum: { $cond: ['$status.push.delivered', 1, 0] } }
        }
      },
      {
        $sort: { count: -1 }
      }
    ]);

    return stats.map(s => ({
      type: s._id,
      count: s.count,
      read: s.read,
      delivered: s.delivered,
      readRate: s.count > 0 ? (s.read / s.count * 100).toFixed(2) : 0
    }));
  }

  /**
   * Get user engagement metrics
   */
  async getUserEngagement(startDate, endDate) {
    const totalUsers = await NotificationPreference.countDocuments();
    
    const activeUsers = await NotificationLog.distinct('userId', {
      createdAt: { $gte: startDate, $lte: endDate }
    });

    const engagedUsers = await NotificationLog.distinct('userId', {
      createdAt: { $gte: startDate, $lte: endDate },
      read: true
    });

    const optedInPush = await NotificationPreference.countDocuments({
      'channels.push.enabled': true
    });

    const optedInEmail = await NotificationPreference.countDocuments({
      'channels.email.enabled': true
    });

    return {
      totalUsers,
      activeUsers: activeUsers.length,
      engagedUsers: engagedUsers.length,
      engagementRate: activeUsers.length > 0 ? (engagedUsers.length / activeUsers.length * 100).toFixed(2) : 0,
      optInRates: {
        push: totalUsers > 0 ? (optedInPush / totalUsers * 100).toFixed(2) : 0,
        email: totalUsers > 0 ? (optedInEmail / totalUsers * 100).toFixed(2) : 0
      }
    };
  }

  /**
   * Get hourly distribution of notifications
   */
  async getHourlyDistribution(startDate, endDate) {
    const distribution = await NotificationLog.aggregate([
      {
        $match: {
          createdAt: { $gte: startDate, $lte: endDate }
        }
      },
      {
        $group: {
          _id: { $hour: '$createdAt' },
          count: { $sum: 1 },
          opened: { $sum: { $cond: ['$status.push.opened', 1, 0] } }
        }
      },
      {
        $sort: { _id: 1 }
      }
    ]);

    return distribution.map(d => ({
      hour: d._id,
      count: d.count,
      opened: d.opened,
      openRate: d.count > 0 ? (d.opened / d.count * 100).toFixed(2) : 0
    }));
  }

  /**
   * Get top performing notifications
   */
  async getTopPerforming(limit = 10) {
    const topNotifications = await NotificationLog.aggregate([
      {
        $match: {
          createdAt: { $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) } // Last 30 days
        }
      },
      {
        $group: {
          _id: { type: '$type', title: '$title' },
          count: { $sum: 1 },
          opened: { $sum: { $cond: ['$status.push.opened', 1, 0] } },
          clicked: { $sum: { $cond: ['$status.web.clicked', 1, 0] } }
        }
      },
      {
        $project: {
          type: '$_id.type',
          title: '$_id.title',
          count: 1,
          opened: 1,
          clicked: 1,
          openRate: {
            $cond: [
              { $gt: ['$count', 0] },
              { $multiply: [{ $divide: ['$opened', '$count'] }, 100] },
              0
            ]
          }
        }
      },
      {
        $sort: { openRate: -1 }
      },
      {
        $limit: limit
      }
    ]);

    return topNotifications;
  }

  /**
   * Get notification failures
   */
  async getFailures(startDate, endDate) {
    const failures = await NotificationLog.find({
      createdAt: { $gte: startDate, $lte: endDate },
      $or: [
        { 'status.push.error': { $exists: true } },
        { 'status.email.error': { $exists: true } },
        { 'status.web.error': { $exists: true } }
      ]
    })
    .select('type title status createdAt')
    .sort({ createdAt: -1 })
    .limit(100);

    return failures;
  }

  /**
   * Get daily notification volume
   */
  async getDailyVolume(days = 30) {
    const startDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
    
    const volume = await NotificationLog.aggregate([
      {
        $match: {
          createdAt: { $gte: startDate }
        }
      },
      {
        $group: {
          _id: {
            year: { $year: '$createdAt' },
            month: { $month: '$createdAt' },
            day: { $dayOfMonth: '$createdAt' }
          },
          count: { $sum: 1 },
          types: { $push: '$type' }
        }
      },
      {
        $sort: { '_id.year': 1, '_id.month': 1, '_id.day': 1 }
      }
    ]);

    return volume.map(v => ({
      date: `${v._id.year}-${String(v._id.month).padStart(2, '0')}-${String(v._id.day).padStart(2, '0')}`,
      count: v.count,
      typeBreakdown: v.types.reduce((acc, type) => {
        acc[type] = (acc[type] || 0) + 1;
        return acc;
      }, {})
    }));
  }

  /**
   * Get comprehensive dashboard stats
   */
  async getDashboardStats() {
    const now = new Date();
    const last24h = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    const last7d = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const last30d = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    const [
      stats24h,
      stats7d,
      stats30d,
      typeStats,
      userEngagement,
      topPerforming,
      recentFailures
    ] = await Promise.all([
      this.getDeliveryStats(last24h, now),
      this.getDeliveryStats(last7d, now),
      this.getDeliveryStats(last30d, now),
      this.getStatsByType(last7d, now),
      this.getUserEngagement(last7d, now),
      this.getTopPerforming(5),
      this.getFailures(last24h, now)
    ]);

    return {
      last24Hours: stats24h,
      last7Days: stats7d,
      last30Days: stats30d,
      byType: typeStats,
      userEngagement,
      topPerforming,
      recentFailures: recentFailures.length
    };
  }
}

module.exports = new NotificationAnalyticsService();
