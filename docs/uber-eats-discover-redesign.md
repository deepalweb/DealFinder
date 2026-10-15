# DealFinder photo-first Discover rebuild

This version supersedes the rejected category-grid marketplace layout.

## Concrete reference

Used the app screenshot in [Uber's April 3, 2024 newsroom article](https://www.uber.com/us/en/newsroom/uber-and-waymo-autonomous-deliveries-phoenix/). The source is historical public UI, not a verified current signed-in app. Reference-only files are in mobile_app/design-reference/uber-eats-public; they are not app assets.

## Changes

- A single location row with area selection, map navigation and notifications; no repeated Discover title or slogan.
- Large rounded search field; the filter button opens the existing draft/apply/cancel sheet.
- One horizontally scrollable category row, using original native vector illustrations for the six supported categories. Category selection updates actual offer filtering. All Categories opens the sheet; All quick filter clears the selection.
- Neutral quick-filter pills for All, Pickup, Bank Offers, Delivery and Ending Soon. Selected pills use inverse surface/ink colors; sapphire remains the brand accent.
- Borderless photo-led offers with a single discount ribbon, merchant name, save control, title, actual price/previous price, fulfillment, approximate distance, expiry and bank restrictions. There are no repeated View offer buttons in every card. Tap the listing to open the existing detail screen.
- Nearby offers within 3 km appear first, then a short bank preview and a continuous wide-card feed. Featured and ending-soon offers participate in these lists instead of adding separate repeated sections. Offer IDs are deduplicated across previews and the feed.
- Map navigation moved to the header; removed the floating map pill and the large reserved blank space.
- Flat five-tab bottom navigation replaces the floating rounded blurred capsule. Independent tab route stacks, guest access and account back handling are preserved. Discover uses a home symbol and Saved uses a bookmark to match its save control.
- Shared light control surfaces and typography ink are neutral; sapphire actions remain.

## Reusable pieces

- lib/src/widgets/discover_marketplace_card.dart
- lib/src/widgets/discover_category_strip.dart
- lib/src/widgets/discover_category_artwork.dart
- lib/src/widgets/discover_filter_sheet.dart

No database mutations, payment-card linkage, delivery-time calculations or shopping checkout were added. Existing merchant websites, directions and supported redemption actions remain in offer details. Bank requirements describe conditions rather than guaranteed eligibility.

## Validation

The full Flutter regression suite covers account back navigation, guest browsing, saved action gating, tab stacks, Nearby, merchant profiles, manual area selection, sorting, filter persistence and the new offer layout. New listing coverage checks supported conditions, opening details, dark mode and 2× text. Category/header coverage includes Sinhala/Tamil, small phones and landscape.

Manual preview command from mobile_app: `flutter test --no-pub tool/discover_preview_test.dart`. It produces long light/dark renders and normal 390×844 phone renders using clearly marked fixture data and bundled photos. These are not physical-device screenshots.

Final checks: all 49 Flutter tests passed; targeted static analysis reported no issues; Android debug APK built successfully. Physical-device testing was not performed in this pass.
