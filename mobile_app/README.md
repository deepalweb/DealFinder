# DealFinder Mobile App

Flutter client for browsing promotions, saving favorites, reviewing deals, following merchants, and receiving notifications from the DealFinder backend.

## What the app includes

- Email/password and Google sign-in
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

Nearby map view, merchant embedded maps, and deal-location previews use OpenStreetMap tiles through `flutter_map`.

No Google Maps key is required for mobile map rendering.

## Build secret generator

This repo now includes a helper script that writes the mobile secret files from environment variables:

```bash
npm run mobile:secrets
```

It can generate:

- `mobile_app/.env`
- `mobile_app/android/app/google-services.json`
- `mobile_app/ios/Runner/GoogleService-Info.plist`

Recommended Azure/CI variables:

- `MOBILE_API_BASE_URL`
- `MOBILE_PUBLIC_BASE_URL`
- `BACKEND_URL`
- `GOOGLE_WEB_CLIENT_ID`

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

## Android release signing

Release bundles now require a real signing setup.

1. Create an upload keystore
2. Create `mobile_app/android/key.properties`
3. Add the keystore SHA-1 and SHA-256 to Firebase
4. Download a fresh `google-services.json`
5. Run `flutter build appbundle`

Detailed guide:

- [ANDROID_RELEASE_SIGNING.md](./ANDROID_RELEASE_SIGNING.md)
- [PLAY_STORE_RELEASE_CHECKLIST.md](./PLAY_STORE_RELEASE_CHECKLIST.md)

## Notes

- If Firebase is not configured, the app still starts, but Firebase-backed auth/notification features will be unavailable.
- The app currently defaults to production URLs unless overridden through `.env` or Dart defines.
- Android release builds require signing values in `mobile_app/android/key.properties` or equivalent environment variables.
