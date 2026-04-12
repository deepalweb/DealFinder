# Notification System - Phase 1 Implementation

## ✅ Completed Features

### Backend
1. **Enhanced Notification Models**
   - `NotificationPreference` - User notification settings and channel configurations
   - `NotificationLog` - Tracks all sent notifications and delivery status

2. **Notification Service Layer**
   - Centralized notification service (`services/NotificationService.js`)
   - Multi-channel support (Push, Email, Web Push)
   - Quiet hours functionality
   - Batch notifications
   - Notification type filtering

3. **Updated API Routes**
   - `GET /api/notifications` - Get user notifications
   - `GET /api/notifications/unread-count` - Get unread count
   - `PATCH /api/notifications/:id/read` - Mark as read
   - `DELETE /api/notifications/:id` - Delete notification
   - `GET /api/notifications/preferences` - Get preferences
   - `PUT /api/notifications/preferences` - Update preferences
   - `POST /api/notifications/preferences/reset` - Reset to defaults
   - `POST /api/notifications/subscribe` - Subscribe to push
   - `POST /api/notifications/unsubscribe` - Unsubscribe
   - `POST /api/notifications/test` - Send test notification
   - `POST /api/notifications/broadcast` - Admin broadcast (Admin only)

### Frontend (Web)
1. **Service Worker**
   - Web push notification handler (`public/sw.js`)
   - Notification click handling with deep linking
   - Background sync support

2. **Web Push Utilities**
   - `lib/webPush.ts` - Helper functions for web push
   - Permission management
   - Subscription handling

3. **Notification API Client**
   - Added `NotificationAPI` to `lib/api/index.ts`
   - All notification endpoints integrated

4. **UI Components**
   - `NotificationBell` - Header notification bell with dropdown
   - Real-time unread count badge
   - Recent notifications preview

5. **Notifications Page**
   - Full notification list view (`app/notifications/page.tsx`)
   - Filter by all/unread
   - Mark as read functionality
   - Delete notifications
   - Deep linking to deals

## 🔧 Setup Instructions

### 1. Generate VAPID Keys for Web Push

```bash
cd backend
npx web-push generate-vapid-keys
```

Add the generated keys to your `.env` file:
```
VAPID_PUBLIC_KEY=your_generated_public_key
VAPID_PRIVATE_KEY=your_generated_private_key
```

### 2. Update Environment Variables

Add these to `backend/.env`:
```
# Web Push VAPID Keys
VAPID_PUBLIC_KEY=your_vapid_public_key
VAPID_PRIVATE_KEY=your_vapid_private_key

# Firebase (if not already configured)
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_CLIENT_EMAIL=your_firebase_client_email
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_KEY\n-----END PRIVATE KEY-----\n"

# App URL for email links
APP_URL=https://dealfinderlk.com
```

### 3. Install Dependencies

Backend (if needed):
```bash
cd backend
npm install web-push firebase-admin
```

### 4. Initialize Notification Preferences for Existing Users

Run this script once to create default preferences for existing users:

```javascript
// backend/scripts/initNotificationPrefs.js
const mongoose = require('mongoose');
const User = require('../models/User');
const NotificationPreference = require('../models/NotificationPreference');

async function initPreferences() {
  await mongoose.connect(process.env.MONGO_URI);
  
  const users = await User.find({});
  
  for (const user of users) {
    const exists = await NotificationPreference.findOne({ userId: user._id });
    if (!exists) {
      await new NotificationPreference({ userId: user._id }).save();
      console.log(`Created preferences for ${user.email}`);
    }
  }
  
  console.log('Done!');
  process.exit(0);
}

initPreferences();
```

Run it:
```bash
node backend/scripts/initNotificationPrefs.js
```

## 📱 Testing

### Test Web Push Notifications

1. **Enable notifications in browser**
   - Visit your app
   - Click "Allow" when prompted for notifications

2. **Send test notification**
   ```bash
   curl -X POST http://localhost:8080/api/notifications/test \
     -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     -H "Content-Type: application/json"
   ```

3. **Check notification center**
   - Click the bell icon in header
   - Visit `/notifications` page

### Test Email Notifications

Ensure `M365_EMAIL` is configured in `.env`, then:
```bash
curl -X POST http://localhost:8080/api/notifications/test-email \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "test@example.com",
    "subject": "Test Notification",
    "text": "This is a test"
  }'
```

## 🎯 Usage Examples

### Send Notification from Backend

```javascript
const NotificationService = require('./services/NotificationService');

// Send to single user
await NotificationService.sendNotification(
  userId,
  'nearby_deal',
  { dealId: '123', merchantId: '456' },
  {
    title: '🎯 New Deal Nearby!',
    body: '50% off at Pizza Hut - Only 2km away!',
    channels: ['push', 'web'],
    priority: 'high'
  }
);

// Send to multiple users
await NotificationService.batchNotify(
  [userId1, userId2, userId3],
  'flash_sale',
  { dealId: '789' },
  {
    title: '⚡ Flash Sale Alert!',
    body: 'Limited time offer - 70% off electronics!',
    channels: ['push', 'web', 'email']
  }
);
```

### Update User Preferences from Frontend

```typescript
import { NotificationAPI } from '@/lib/api';

// Get preferences
const prefs = await NotificationAPI.getPreferences();

// Update preferences
await NotificationAPI.updatePreferences({
  preferences: {
    nearbyDeals: { enabled: true, radius: 10 },
    expiringDeals: { enabled: true, hours: 48 },
    quietHours: { enabled: true, start: '22:00', end: '08:00' }
  }
});

// Subscribe to web push
const subscription = await subscribeToPushNotifications(VAPID_PUBLIC_KEY);
await NotificationAPI.subscribe(subscription, 'web');
```

## 🔍 Database Indexes

The following indexes are automatically created:
- `NotificationLog`: `{ userId: 1, createdAt: -1 }`
- `NotificationLog`: `{ type: 1, createdAt: -1 }`
- `NotificationLog`: `{ read: 1, userId: 1 }`
- `NotificationPreference`: `{ userId: 1 }` (unique)

## 🚀 Next Steps (Phase 2)

1. Implement background jobs for:
   - Nearby deal detection
   - Expiring deal alerts
   - Price drop monitoring
   
2. Add notification triggers:
   - New deal from favorite store
   - Category-based notifications
   - Flash sale alerts

3. Mobile app integration:
   - Enhanced FCM handling
   - Local notification scheduling
   - Notification settings screen

## 📝 Notes

- Service worker must be served over HTTPS in production
- Web push requires user permission
- Quiet hours are checked before sending notifications
- Notification preferences are created automatically on first user registration
- All notification types respect user preferences

## 🐛 Troubleshooting

**Web push not working:**
- Check VAPID keys are correctly set
- Ensure service worker is registered
- Verify HTTPS in production
- Check browser console for errors

**Notifications not appearing:**
- Verify user has notification preferences created
- Check notification type is enabled in preferences
- Ensure not in quiet hours
- Check backend logs for errors

**Email notifications failing:**
- Verify M365_EMAIL is configured
- Check mailer configuration
- Test with `/api/notifications/test-email` endpoint
