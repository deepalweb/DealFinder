# Notification System - Phase 2 Implementation

## ✅ Completed Features

### Backend Jobs (5 new files)
1. **nearbyDealsNotifications.js** - Checks for new deals near users every 30 minutes
2. **expiringDealsNotifications.js** - Notifies users about expiring favorite deals daily at 9 AM
3. **favoriteStoreNotifications.js** - Notifies when favorite stores post new deals
4. **priceDropNotifications.js** - Detects price drops and notifies users every 2 hours
5. **flashSaleNotifications.js** - Detects flash sales (< 6 hours) and sends urgent notifications
6. **notificationScheduler.js** - Cron-based job scheduler for all notification jobs

### Backend Integration
- Updated `server.js` to initialize notification jobs on startup
- Updated `promotionRoutes.js` to trigger notifications when:
  - New promotion is created → Notify favorite store followers + Check for flash sale
  - Promotion is updated → Check for price drop
- Added `node-cron` dependency for job scheduling

### Mobile App (2 new files)
1. **notification_settings_screen.dart** - Comprehensive settings UI with:
   - Channel toggles (Push, Email)
   - Notification type preferences
   - Nearby radius slider
   - Expiring hours slider
   - Category selection chips
   - Quiet hours time pickers
   - Test notification button

2. **Updated api_service.dart** - Added notification API methods:
   - getNotificationPreferences()
   - updateNotificationPreferences()
   - subscribeToNotifications()
   - unsubscribeFromNotifications()
   - sendTestNotification()

## 📋 Job Schedule

| Job | Frequency | Description |
|-----|-----------|-------------|
| **Nearby Deals** | Every 30 minutes | Checks for new deals within user's radius |
| **Expiring Deals** | Daily at 9 AM | Notifies about favorite deals expiring soon |
| **Favorite Stores** | Every 2 hours | Batch check for new deals from followed stores |
| **Price Drops** | Every 2 hours | Detects discount increases on favorite deals |
| **Flash Sales** | Every hour | Checks for deals expiring in 1-2 hours |
| **Merchant Expiry** | Daily at 10 AM | Notifies merchants about expiring deals (existing) |

## 🎯 Notification Triggers

### Automatic Triggers

1. **New Promotion Created**
   - ✅ Notifies users who favorited any deal from that merchant
   - ✅ Checks if it's a flash sale (< 6 hours duration)
   - ✅ Sends urgent notifications for flash sales

2. **Promotion Updated**
   - ✅ Checks if discount increased by 10%+
   - ✅ Notifies users who favorited that deal

3. **Scheduled Jobs**
   - ✅ Nearby deals check (every 30 min)
   - ✅ Expiring deals check (daily 9 AM)
   - ✅ Price drops check (every 2 hours)
   - ✅ Flash sales check (every hour)

## 🔧 Setup Instructions

### 1. Install Dependencies

```bash
cd backend
npm install node-cron
```

### 2. Restart Backend Server

The notification jobs will automatically initialize on server startup:

```bash
cd backend
npm start
```

You should see:
```
[Job Scheduler] Initializing notification jobs...
[Job Scheduler] All notification jobs initialized
[Job Scheduler] Schedule:
  - Nearby deals: Every 30 minutes
  - Expiring deals (users): Daily at 9 AM
  - Favorite stores: Every 2 hours
  - Price drops: Every 2 hours
  - Flash sales: Every hour
  - Merchant expiry: Daily at 10 AM
```

### 3. Test Notification Triggers

#### Test New Promotion Notification
```bash
# Create a new promotion via API or admin panel
# Users who favorited deals from that merchant will be notified
```

#### Test Flash Sale
```bash
# Create a promotion with endDate < 6 hours from now
# All users with flash sale notifications enabled will be notified
```

#### Test Price Drop
```bash
# Update a promotion's discount from "50%" to "70%"
# Users who favorited that deal will be notified
```

### 4. Run Jobs Manually (Testing)

Create a test script `backend/scripts/testJobs.js`:

```javascript
require('dotenv').config();
const mongoose = require('mongoose');
const { runAllJobsNow } = require('../jobs/notificationScheduler');

async function test() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Running all jobs...');
  await runAllJobsNow();
  console.log('Done!');
  process.exit(0);
}

test();
```

Run it:
```bash
node backend/scripts/testJobs.js
```

## 📱 Mobile App Integration

### 1. Add Notification Settings to Navigation

Update your main navigation to include the notification settings screen:

```dart
// In your navigation/routing
import 'package:your_app/src/screens/notification_settings_screen.dart';

// Add route
'/notification-settings': (context) => const NotificationSettingsScreen(),

// Add menu item in user profile
ListTile(
  leading: const Icon(Icons.notifications),
  title: const Text('Notification Settings'),
  onTap: () => Navigator.pushNamed(context, '/notification-settings'),
),
```

### 2. Initialize FCM Token on Login

```dart
// After successful login
final fcmToken = await PushNotificationService.getToken();
if (fcmToken != null) {
  await ApiService().subscribeToNotifications(fcmToken, 'push');
}
```

### 3. Test Mobile Notifications

1. Open the app and login
2. Go to Notification Settings
3. Enable Push Notifications
4. Tap "Send Test Notification"
5. You should receive a notification

## 🎨 Notification Types & Icons

| Type | Icon | Priority | Channels |
|------|------|----------|----------|
| Nearby Deal | 🎯 | High | Push, Web |
| Favorite Store | 💝 | High | Push, Web, Email |
| Expiring Deal | ⏰ | Urgent | Push, Web, Email |
| Price Drop | 💰 | High | Push, Web |
| Flash Sale | ⚡ | Urgent | Push, Web |
| Category Deal | 📦 | Normal | Push, Web |
| Deal Redeemed | ✅ | Normal | Push, Email |
| Weekly Digest | 📧 | Low | Email |

## 📊 Monitoring & Logs

### Check Job Execution

Jobs log to console with prefixes:
```
[Nearby Deals Job] Starting...
[Nearby Deals Job] Found 5 new deals
[Nearby Deals Job] Sent 12 notifications

[Expiring Deals Job] Starting...
[Expiring Deals Job] Sent 8 notifications

[Flash Sale Job] Flash sale detected! 3.5 hours left
[Flash Sale Job] Sent 45 notifications
```

### Monitor Notification Delivery

Check the `notificationlogs` collection in MongoDB:
```javascript
db.notificationlogs.find({
  createdAt: { $gte: new Date(Date.now() - 24*60*60*1000) }
}).sort({ createdAt: -1 })
```

### Check Notification Preferences

```javascript
db.notificationpreferences.find({
  'preferences.nearbyDeals.enabled': true
}).count()
```

## 🐛 Troubleshooting

### Jobs Not Running

**Check server logs:**
```bash
# Should see job scheduler initialization
[Job Scheduler] Initializing notification jobs...
```

**Verify cron syntax:**
```javascript
// Test cron expression
const cron = require('node-cron');
console.log(cron.validate('*/30 * * * *')); // Should be true
```

### No Notifications Sent

**Check user preferences:**
```javascript
// Verify users have notifications enabled
db.notificationpreferences.find({
  'preferences.nearbyDeals.enabled': true,
  'channels.push.enabled': true
})
```

**Check quiet hours:**
```javascript
// Verify not in quiet hours
// Quiet hours are checked before sending
```

**Check notification logs:**
```javascript
// Look for errors in status
db.notificationlogs.find({
  'status.push.error': { $exists: true }
})
```

### Flash Sales Not Detected

**Verify deal duration:**
```javascript
// Flash sales must:
// 1. Be created within last 30 minutes
// 2. Expire in less than 6 hours

const deal = await Promotion.findById('dealId');
const now = new Date();
const hoursLeft = (deal.endDate - now) / (60*60*1000);
console.log('Hours left:', hoursLeft); // Should be < 6
```

### Price Drops Not Working

**Check discount format:**
```javascript
// Discount must contain percentage
// Good: "50%", "70% off", "80% discount"
// Bad: "Half price", "Buy 1 Get 1"
```

## 🚀 Performance Optimization

### Batch Processing

Jobs process users in batches to avoid memory issues:

```javascript
// Process 100 users at a time
const batchSize = 100;
for (let i = 0; i < users.length; i += batchSize) {
  const batch = users.slice(i, i + batchSize);
  await Promise.all(batch.map(user => sendNotification(user)));
}
```

### Rate Limiting

Prevent notification spam:
- Max 3 notifications per user per day (configurable)
- Quiet hours respected
- Duplicate prevention (same deal, same user, within 24h)

### Database Indexes

Ensure these indexes exist:
```javascript
// NotificationLog
db.notificationlogs.createIndex({ userId: 1, createdAt: -1 })
db.notificationlogs.createIndex({ type: 1, createdAt: -1 })

// NotificationPreference
db.notificationpreferences.createIndex({ userId: 1 }, { unique: true })

// Promotion
db.promotions.createIndex({ createdAt: -1 })
db.promotions.createIndex({ endDate: 1 })
```

## 📈 Next Steps (Phase 3)

1. **Advanced Features:**
   - Category-based notifications
   - Weekly digest emails
   - Smart notification timing (ML-based)
   - Notification fatigue prevention

2. **Analytics:**
   - Delivery rate tracking
   - Open rate analytics
   - Conversion tracking
   - A/B testing

3. **Optimization:**
   - Queue system (Bull/Redis)
   - Retry logic for failed deliveries
   - Notification grouping
   - Smart batching

## 📝 API Endpoints Added

No new endpoints in Phase 2 - all functionality uses existing Phase 1 endpoints.

## 🎉 Success Metrics

Track these metrics to measure success:
- Notification delivery rate (target: > 95%)
- Open rate (target: > 20%)
- Click-through rate (target: > 10%)
- User opt-out rate (target: < 5%)
- Average notifications per user per day (target: 1-3)

## 📚 Additional Resources

- [node-cron documentation](https://www.npmjs.com/package/node-cron)
- [Cron expression generator](https://crontab.guru/)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Web Push Protocol](https://developers.google.com/web/fundamentals/push-notifications)
