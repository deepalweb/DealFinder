# Firebase Configuration Setup

## Security Notice
Firebase configuration files contain sensitive API keys and should **never** be committed to version control.

## Setup Instructions

### Android

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Project Settings → General
4. Under "Your apps", find your Android app
5. Click "Download google-services.json"
6. Place the file at: `mobile_app/android/app/google-services.json`

### iOS

1. In Firebase Console, find your iOS app
2. Click "Download GoogleService-Info.plist"
3. Place the file at: `mobile_app/ios/Runner/GoogleService-Info.plist`

## Important Notes

- These files are listed in `.gitignore` and will not be committed
- Each developer must download their own copy
- For CI/CD, store these files as encrypted secrets
- Never share these files publicly or commit them to Git
- For Google Sign-In on Android release builds, add the upload key SHA-1 and SHA-256 fingerprints in Firebase before downloading the final `google-services.json`

## Release build reminder

If Android release signing changes, the Firebase Android app must include the SHA fingerprints from that signing key. See [ANDROID_RELEASE_SIGNING.md](./ANDROID_RELEASE_SIGNING.md).

## Template

A template file `google-services.json.example` is provided with placeholder values.
Replace the placeholders with your actual Firebase project values.
