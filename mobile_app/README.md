# DealFinder Mobile App

Flutter client for browsing promotions, saving favorites, reviewing deals, following merchants, and receiving notifications from the DealFinder backend.

## What the app includes

- Email/password, Google sign-in, and demo logins
- Home feed, explore view, merchant/store browsing, and favorites
- Deal detail pages with ratings, comments, sharing, and directions
- Merchant dashboard flows for creating and managing promotions
- Firebase Cloud Messaging support for push notifications

## Requirements

- Flutter 3.x
- A running DealFinder backend
- Firebase project files for Android/iOS if you want auth and push enabled
- A `.env` file in `mobile_app/` for local secrets and endpoints

## Environment setup

Create `mobile_app/.env` from `mobile_app/.env.example`.

Supported variables:

- `MOBILE_API_BASE_URL`: Full API base URL. Example: `http://10.0.2.2:8080/api/`
- `MOBILE_PUBLIC_BASE_URL`: Public web origin used for share links. Example: `https://example.com`
- `BACKEND_URL`: Optional fallback origin if you prefer defining only the backend host
- `GOOGLE_WEB_CLIENT_ID`: Google sign-in web client ID
- `GOOGLE_MAPS_API_KEY`: Needed for the static map preview on deal details

## Google Sign-In setup

Google Sign-In on mobile needs all three pieces below:

- `GOOGLE_WEB_CLIENT_ID` in `mobile_app/.env`
- `mobile_app/android/app/google-services.json`
- `mobile_app/ios/Runner/GoogleService-Info.plist`

The mobile app now tries Firebase-backed Google auth first, then falls back to the backend `/users/google-signin` exchange when Firebase sync is unavailable. You still need the Google mobile app registration to match the real app IDs and signing setup.

Important:

- Android must be registered in Firebase/Google Cloud with the exact application ID currently used by the app: `com.dealfinder.mobile`
- iOS must be registered with the exact bundle ID currently used by the app: `com.example.dealFinderMobile`
- If Android is failing with a configuration error, you usually need the correct SHA-1 and SHA-256 fingerprints added in Firebase before downloading a fresh `google-services.json`

## Embedded map setup

Nearby map view and merchant embedded maps need native Google Maps configuration in addition to `.env`.

- Android:
  Add `GOOGLE_MAPS_API_KEY=your-key` to `mobile_app/android/local.properties`, or provide it as a CI environment variable before building.
- iOS:
  Copy `mobile_app/ios/Flutter/MapsConfig.xcconfig.example` to `mobile_app/ios/Flutter/MapsConfig.xcconfig` and set `GOOGLE_MAPS_API_KEY=your-key`.

If those native values are missing, the app now falls back safely to list-based nearby browsing and external Google Maps links instead of crashing.

## Recommended secret flow

- Keep the backend Azure environment variable for backend-only Google APIs.
- Inject the same key separately into the mobile build for native map SDKs.
- Local Android builds: use `android/local.properties`.
- Local iOS builds: use `ios/Flutter/MapsConfig.xcconfig`.
- CI builds: set `GOOGLE_MAPS_API_KEY` as a pipeline secret and expose it during the platform build step.

## Build secret generator

This repo now includes a helper script that writes the mobile secret files from environment variables:

```bash
npm run mobile:secrets
```

It can generate:

- `mobile_app/.env`
- `mobile_app/android/app/google-services.json`
- `mobile_app/ios/Runner/GoogleService-Info.plist`
- `mobile_app/android/secrets.properties`
- `mobile_app/ios/Flutter/MapsConfig.xcconfig`

Recommended Azure/CI variables:

- `MOBILE_API_BASE_URL`
- `MOBILE_PUBLIC_BASE_URL`
- `BACKEND_URL`
- `GOOGLE_WEB_CLIENT_ID`
- `GOOGLE_MAPS_API_KEY`

Best option for Firebase mobile files:

- `GOOGLE_SERVICES_JSON_BASE64`
- `GOOGLE_SERVICE_INFO_PLIST_BASE64`

Fallback structured variables supported by the script:

- `FIREBASE_PROJECT_NUMBER`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_ANDROID_APP_ID`
- `FIREBASE_IOS_APP_ID`
- `FIREBASE_ANDROID_PACKAGE_NAME`
- `FIREBASE_IOS_BUNDLE_ID`
- `GOOGLE_ANDROID_API_KEY`
- `GOOGLE_IOS_API_KEY`
- `GOOGLE_IOS_CLIENT_ID`

Example PowerShell usage:

```powershell
$env:GOOGLE_SERVICES_JSON_BASE64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes((Get-Content .\google-services.json -Raw)))
$env:GOOGLE_SERVICE_INFO_PLIST_BASE64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes((Get-Content .\GoogleService-Info.plist -Raw)))
npm run mobile:secrets
```

## Run locally

```bash
flutter pub get
flutter run
```

## Quality checks

```bash
flutter analyze
flutter test
```

## Notes

- If Firebase is not configured, the app still starts, but Firebase-backed auth/notification features will be unavailable.
- Demo accounts are exposed in the login screen for local evaluation.
- The app currently defaults to production URLs unless overridden through `.env` or Dart defines.
