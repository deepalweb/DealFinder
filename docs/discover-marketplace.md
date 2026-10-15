# Discover location-first marketplace (superseded)

This iteration was rejected and replaced by [the photo-first rebuild](uber-eats-discover-redesign.md). The notes below describe the previous version.

Implemented in the Flutter mobile app using the existing sapphire theme and reusable offer surfaces.

## Page order

1. Compact tappable area header, everyday-savings message and notifications.
2. Search deals, stores or bank offers, with a working filter action.
3. Two-row visual category grid: Food & Dining, Daily Essentials, Shopping, Electronics, Beauty & Salon, Wellness; All and All Categories controls. Large text uses two columns.
4. Wide nearby cards, nearest first within 3 km of the selected area. Missing coordinates are never represented as nearby. Manual area changes update the results. No-match areas explain the result and retain other offers below.
5. Bank offer preview with actual bank/card/minimum-spend conditions and Bank Offers navigation.
6. One active compact featured banner when available; no automatic rotation. View offer opens existing details.
7. One ending-soon preview, when available and not already shown.
8. Continuous, lazily built full-width offer cards with filtering, actual prices, previous price when supported, fulfillment, approximate distance and expiry. Browse all offers and Browse stores remain reachable.

Sections exclude previously shown offer IDs. A featured offer is reserved from the nearby preview only when more than three nearby offers exist. Optional sections disappear when there is no distinct eligible offer.

## Data and interactions

The live development database contains 34 demo offers: Food & Dining 10, Shopping & Retail 6, Beauty & Salon 5, Daily Essentials 5, Health & Wellness 5, Electronics 3. Six overlap bank/card offers. Stored statuses are 32 active, one scheduled and one expired; display additionally checks dates. The layout is driven by API results rather than these hardcoded totals.

Filter-sheet edits are drafts until Apply. Dismissal cancels edits; Clear resets the draft. Controls cover category, bank offers, fulfillment and ending within 72 hours. Sorting offers default order, highest percentage discount, newest, expiry and distance when an area is available. Nearby previews intentionally retain nearest-first ordering. Filters carry into Browse all offers.

Save and detail actions reuse existing workflows, including sign-in gating. GPS permission is requested only from Use my location. No card linkage or guaranteed eligibility is implied. No database mutation is part of this UI change.

## Preview and validation

Run `flutter test --no-pub tool/discover_preview_test.dart` from mobile_app to generate `design-preview/discover-marketplace-light.png` and `discover-marketplace-dark.png`. These are fixture renders with bundled photos, not live-device or live-database screenshots.

Widget coverage includes area changes and honest nearby empty states, category navigation, filter apply/cancel/reset, percentage sorting, ending-soon availability, small/landscape layouts, enlarged text, localized Sinhala/Tamil layouts, dark mode, and existing save/detail workflows. Device release validation remains separate.

Latest validation: all 48 Flutter tests passed; targeted static analysis passed. Light and dark fixture renders were visually checked. Android debug APK built successfully; this pass was not installed or verified on a physical device.
