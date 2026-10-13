# Google Maps integration

OpenStreetMap/Leaflet has been replaced in mobile Nearby, merchant editing,
merchant profiles, the web Nearby map, and the web merchant location picker.
Mobile address labels use native Android/iOS reverse geocoding, with the existing
24-hour cache and graceful fallback. They no longer call Nominatim.

## Local configuration

Run from the repository root:

```powershell
node scripts/configure-google-maps.js
```

The script reads only Google Maps keys from `backend/.env` and writes these
ignored files, preserving other Android properties and web environment values:

- `mobile_app/android/secrets.properties`: `GOOGLE_MAPS_API_KEY`
- `mobile_app/ios/Flutter/MapsConfig.xcconfig`: `GOOGLE_MAPS_API_KEY`
- `frontend-next/.env.local`: `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY`

Restart Next.js after changing its key. Rebuild the mobile app after changing a
native key. Android also accepts the `GOOGLE_MAPS_ANDROID_API_KEY` build environment
variable. The script accepts platform-specific environment variables or entries
in `backend/.env`: `GOOGLE_MAPS_ANDROID_API_KEY`, `GOOGLE_MAPS_IOS_API_KEY`, and
`GOOGLE_MAPS_WEB_API_KEY`. Each falls back to the supplied `GOOGLE_MAPS_API_KEY`.
The full backend environment is never copied into the clients.

Client map keys are necessarily included in the installed app or browser bundle.
For release, use separate restricted keys for each platform and keep a separate
server key. Android needs the package `com.dealfinder.mobile` and the signing
certificate SHA-1; iOS needs its actual bundle ID; web needs the deployed and
local website referrers. Restrict each key to its required Maps API.

Enable Maps SDK for Android, Maps SDK for iOS, and Maps JavaScript API on the
corresponding Google Cloud project, with billing enabled. A key restricted only
to backend/server APIs will not authorize these SDKs.
See [Google's API key guidance](https://developers.google.com/maps/api-security-best-practices)
and the [Flutter plugin setup](https://pub.dev/packages/google_maps_flutter).

## Behavior and compatibility

Nearby retains manual areas, explicit location permission, radius/category/open
filters, clustered discount badges, selection synchronization, explicit
“Search this area,” and the draggable results sheet. Google attribution moves
above the sheet. Dark mode uses a dark Google map style. Offer rows remain usable
without GPS; network access is required for fresh map content.

Merchant editing supports tapping the map and dragging the merchant marker.
The web picker also follows changes from its coordinate inputs. Web offer popups
use DOM text nodes rather than interpolated HTML and link to `/deal/:id`.

Minimum targets are Android API 24 and iOS 15. Android Gradle Plugin is upgraded
to 8.9.2 to satisfy the native geocoding dependency; the existing Gradle 8.12
wrapper remains compatible. The Android Maps implementation is pinned to 2.18.6
to retain compatibility with the project's Kotlin 2.1 compiler (newer
implementations pull in Kotlin 2.3 metadata). The checked-in iOS key loading is
configured through Xcode's Debug/Release xcconfigs and the Runner Info.plist.
An iOS build and native map authorization must still be checked on macOS/iPhone.
The mobile Flutter web target is not configured by this migration; the web
application is `frontend-next`.

## Validation

- Flutter analysis: clean.
- Flutter tests: 24 passed, including explicit camera search and selected rows.
- Web TypeScript check: passed.
- Web map component lint: passed.
- Android debug APK: built successfully after native dependency compatibility fixes.
- Android device: Google map tiles, custom offer badges, radius overlay, Google attribution, marker/list selection, and explicit map-area search verified on the connected Samsung phone. Supplied key successfully authorized Maps SDK for Android.
- Nearby tests re-run after the Android implementation pin: all 8 passed.
- Next.js production build: passed (31 routes).

Web browser map authorization remains unverified: the browser automation surface
was unavailable in this session. The production build and static checks passed.

Device checks confirmed that explicit map-area search changes the displayed
distances (the selected demo offer changed from 0 m to 1.2 km after panning).
The original Colombo 04 browsing area was restored after verification.

The final APK, including the corrected area separator and consumed offer marker
taps (to keep native popups away from map controls), was built and installed.
Those last presentation fixes were compiled; the prior device checks establish
map authorization and core map interactions.
