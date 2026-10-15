# Nearby page refinement

This iteration improves Nearby only and aligns its scoped emerald palette and navigation-bar treatment with the accepted Discover design. Discover's layout, Account and merchant tools are unchanged.

## Interface

- A compact location header replaces the logo and repeated large Nearby heading. Manual area selection, notifications and Account remain available.
- Radius uses an emerald chip; category and Open now controls use readable neutral chips. Existing supported radius choices and published-hours rules remain.
- The map fills the available canvas. The sheet initially occupies 46%, can collapse to 20%, and expands to 92% using its handle or labelled buttons. Google attribution is padded above the sheet. Expanded results hide floating map controls and remove unnecessary top map padding.
- Cards use 88px images, compact bookmarks, a clear saving, approximate distance/expiry metadata and a single neutral conditions panel. Bank/card, minimum-spend and maximum-discount text wraps. Large text switches the card to a vertical layout. Selecting a card synchronizes the map; View offer opens details through the existing API client.
- Result counts, area/radius context, approximate-location information, cached-area mismatch, loading, failure and empty-state handling remain explicit.

## Behavior corrections

Nearby now subscribes to shared browsing-area changes. Selecting an area on Discover updates an already-open Nearby tab without requesting GPS or issuing a duplicate request for its own area selection. Initialization and in-flight response guards prevent stale requests from replacing a newer area. The subscription is removed on disposal.

Nearby results now exclude nonpublic offers and coordinates outside valid geographic ranges, in addition to the existing radius/category/query/hours checks. Existing Search this area behavior, radius persistence, manual browsing, contextual Use my location action, offer selection and cache safeguards remain.

## Files

- `mobile_app/lib/src/screens/nearby_deals_screen.dart`
- `mobile_app/lib/src/widgets/nearby_offer_row.dart`
- `mobile_app/lib/src/services/nearby_discovery_controller.dart`
- `mobile_app/lib/src/screens/main_navigation_screen.dart` (Nearby-only selected bar styling)
- `mobile_app/test/nearby_discovery_test.dart`
- `mobile_app/tool/nearby_refinement_preview_test.dart`

## Preview and verification limits

[Open the actual Flutter UI previews](nearby-refinement/index.html). The header, filters, map controls, draggable sheet, result cards and navigation are actual app widgets. Offers are labelled fixtures. The background map is explicitly a geometric fixture, **not Google cartography**; widget tests cannot render the native Google Maps surface. Real Google Maps tiles, attribution placement, marker-camera transitions and GPS permission dialogs require separate device verification. No device/simulator accessibility certification is claimed.

Seventeen targeted Nearby/navigation tests passed, including area synchronization, stale-response handling, cache mismatch, map-search coordinates, selection without refetch, private/invalid offer exclusion, enlarged text and guest navigation.

Final verification: **81 regression tests passed**, full `lib`/`test`/renderer analysis found **no issues**, and the actual-controls renderer passed six configurations (light, dark, narrow, enlarged English, Sinhala and Tamil), each in map and expanded-list states. Preview image links resolve; diff whitespace checks passed. The Android debug APK built successfully at `mobile_app/build/app/outputs/flutter-apk/app-debug.apk`; it has not been installed on a device. No deployment or production data mutation is part of this task.


## Follow-up: uniform compact cards

Nearby cards now share identical image dimensions and reserved text slots at each text scale. Each summary shows two title lines, store name, rating (or Not rated), approximate distance and price/saving. Bank restrictions, expiry, previous prices and fulfillment details have been removed from this preview; the arrow opens the full offer details. Missing values are represented honestly. Large text uses a consistent stacked layout and grows all cards equally. Selection still updates the map and bookmarks remain independent actions.

This follow-up supersedes the earlier conditions-panel card design above. Updated map/list previews are available in the same gallery.
