# Push Notifications Setup Guide

This guide explains how to set up push notifications for nearby deals in the DealFinder mobile app.

## Features Added

1. **Firebase Cloud Messaging (FCM)** - Push notification infrastructure
2. **Local Notifications** - In-app notification display
3. **Background Location Checking** - Periodic nearby deal checks
4. **Notification Settings** - User preferences for notifications
5. **Automatic Nearby Deal Alerts** - Smart location-based notifications

## Setup Instructions

### 1. Firebase Project Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing one
3. Add Android app:
   - Package name: `com.example.deal_finder_mobile`
   - Download `google-services.json`
   - Place in `android/app/` directory

4. Add iOS app:
   - Bundle ID: `com.example.dealFinderMobile`
   - Download `GoogleService-Info.plist`
   - Place in `ios/Runner/` directory

### 2. Android Configuration

Add to `android/app/build.gradle`:
```gradle
dependencies {
    implementation 'com.google.firebase:firebase-messaging:23.0.0'
}

apply plugin: 'com.google.gms.google-services'
```

Add to `android/build.gradle`:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```

### 3. iOS Configuration

Add to `ios/Runner/Info.plist`:
```xml
<key>FirebaseMessagingAutoInitEnabled</key>
<true/>
```

### 4. Dependencies Added

```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.10
  flutter_local_notifications: ^16.3.2
```

## How It Works

### Notification Types

1. **Nearby Deals** - When user enters area with active deals
2. **Favorite Stores** - New deals from followed merchants
3. **Expiring Deals** - Deals about to expire
4. **Recommendations** - Personalized deal suggestions

### Background Processing

- **Location Checks**: Every 30 minutes when app is active
- **Smart Filtering**: Only notify for new deals within 5km
- **Rate Limiting**: Maximum 1 notification per 30 minutes
- **Battery Optimization**: Minimal background processing

### User Controls

Users can control notifications in Profile → Notifications tab:
- ✅ **Nearby Deals** - Location-based alerts
- ✅ **Favorite Stores** - Updates from followed merchants
- ✅ **Expiring Deals** - Time-sensitive alerts
- ✅ **Recommendations** - Personalized suggestions

## Implementation Details

### Services Created

1. **PushNotificationService** - FCM integration and local notifications
2. **BackgroundLocationService** - Periodic location-based checks
3. **NotificationSettingsWidget** - User preference controls

### Key Features

- **Automatic Permission Requests** - Handles location and notification permissions
- **Foreground Notifications** - Shows notifications when app is open
- **Background Notifications** - Works when app is closed
- **Customizable Settings** - User can enable/disable specific types

### Notification Flow

1. **User Location** → Check every 30 minutes
2. **API Query** → Find deals within 5km radius
3. **Smart Filter** → Only new deals since last check
4. **User Preferences** → Respect notification settings
5. **Display** → Show local notification with deal details

## Testing

### Test Nearby Notifications

1. Enable location permissions
2. Go to Profile → Notifications
3. Enable "Nearby Deals"
4. Move to area with active deals
5. Wait up to 30 minutes for notification

### Manual Testing

```dart
// Trigger test notification
await PushNotificationService.checkNearbyDealsAndNotify();
```

## Troubleshooting

### Common Issues

1. **No notifications** - Check permissions in device settings
2. **Location not working** - Verify GPS and app location permissions
3. **Firebase errors** - Ensure google-services files are correctly placed
4. **iOS notifications** - Check APNs certificate in Firebase console

### Debug Steps

1. Check Firebase project configuration
2. Verify FCM token generation
3. Test location permissions
4. Check notification settings in app
5. Monitor device logs for errors

## Production Considerations

### Performance

- **Battery Usage**: Minimal impact with 30-minute intervals
- **Data Usage**: Small API calls for location queries
- **Storage**: Minimal local storage for preferences

### Privacy

- **Location Data**: Only used for nearby deal detection
- **No Tracking**: Location not stored or transmitted
- **User Control**: Full control over notification preferences

### Scalability

- **Server Load**: Distributed across user base
- **Rate Limiting**: Built-in to prevent spam
- **Graceful Degradation**: Works without location if needed

## Future Enhancements

1. **Geofencing** - More precise location triggers
2. **Smart Timing** - Learn user patterns for optimal timing
3. **Rich Notifications** - Images and action buttons
4. **Push Campaigns** - Admin-triggered promotional notifications
5. **Analytics** - Track notification effectiveness

## Security

- **Token Management** - Secure FCM token handling
- **Permission Checks** - Proper permission validation
- **Data Encryption** - Secure API communication
- **User Privacy** - Minimal data collection