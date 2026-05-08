# Play Store Release Checklist

Use this after Android signing and Firebase configuration are complete.

## App package

- `flutter analyze` passes
- `flutter test` passes
- `flutter build appbundle` succeeds
- Release bundle is built from the production backend configuration
- Version in `pubspec.yaml` is updated for this release

## Android signing

- Upload keystore created and backed up
- `mobile_app/android/key.properties` created locally
- Play App Signing enabled in Google Play Console
- Team has stored keystore passwords securely

## Firebase and Google config

- `mobile_app/android/app/google-services.json` matches `com.dealfinder.mobile`
- Android SHA-1 and SHA-256 for the upload key are added in Firebase
- `mobile_app/ios/Runner/GoogleService-Info.plist` is present for iOS builds
- `GOOGLE_WEB_CLIENT_ID` is set in `mobile_app/.env`
- `GOOGLE_MAPS_API_KEY` is configured for Android and iOS

## Runtime verification

- Email/password login works against production
- Google Sign-In works on a signed Android build
- Push notifications can be granted and received
- Nearby deals and location permission flows work
- Share links open the correct production domain
- Merchant flows work if merchant accounts are part of launch scope

## Play Console content

- App name finalized
- Short description and full description added
- Privacy policy URL added
- Contact email, website, and phone set if needed
- App icon, screenshots, and feature graphic uploaded
- Content rating completed
- Data safety form completed
- Ads declaration completed
- Target audience and app content questions completed

## Launch controls

- Internal testing uploaded first
- Closed testing or open testing completed if required by Play
- Crash and login smoke tests run on a physical Android device
- Rollout percentage chosen for production release

## Final artifact

- Upload `mobile_app/build/app/outputs/bundle/release/app-release.aab`
- Tag the release in source control if your team uses release tags
- Record the released version code and date
