# Discover deal feed

The supplied `stitch_dealfinder_ios_redesign/code.html` and `screen.png`
are implemented as native Flutter components on **Discover**. The reference's
Bank Offers active tab is not copied: Discover remains the selected destination
in the existing five-tab application shell.

## Components

- `DiscoverOfferSurface`: compact editorial, detail-preview, and expiry cards.
- `DiscoverOfferTile`: photo cards for horizontal highlights and bank offers.
- `DiscoverOfferGrid`: adaptive two-column grid, switching to one column for
  narrow layouts or enlarged text and three columns for wider layouts.
- `DiscoverOfferImage`: bundled demo artwork or the promotion's actual image.
- `DiscoverOfferRating`: valid API ratings with the app icon font and accessible labels.
- `DiscoverFilterSheet`: bank/category/fulfillment drafts with Apply and cancellation.

The screen composes these with delivery/in-store/pickup filters, area selection,
search, category/bank filters, a bank offer entry, nearby highlights, an expiry
section, exploration cards, map entry, and merchant shortcuts. Category and
fulfillment filters carry into Browse All. Fulfillment is matched against
promotion capabilities rather than estimated delivery time.

## Data and assets

All three imported photos are bundled under `mobile_app/assets/discover/`,
registered in `pubspec.yaml`. The reference HTML uses `/assets/discover/`
image URLs; Flutter uses bundle keys such as `assets/discover/stitch-1.jpg`.
The imported HTML, screenshot, and asset descriptions are in
`mobile_app/design-reference/stitch-discovery-deal-feed/`.

The bundled photos are used for clearly marked demo offers. Actual merchant
photographs remain sourced from API promotion records. The imported HTML and
its CDN scripts/styles are design references, not runtime dependencies.

DealFinder's sapphire and system-following dark theme remain in use. Ratings
appear only when backed by rating data. Bank/card requirements, minimum spend,
expiry, maximum benefit, and price come from offer records. The prototype's
linked cards, free delivery, delivery estimates, countdown, voucher inventory,
and verified-deal total are not available data and are not displayed as facts.
The map entry counts the actual matching offers within 5 km. Offer actions
open details; saving uses the existing authenticated workflow.

## Verification

Widget checks cover filtering, category/fulfillment handoff, API failure and
retry, adaptive grid/card layout with double text size, and working tile taps.
Light/dark renders use fixture records and bundled artwork; these are not
live database screenshots or device release validation.

Latest refinements and preview instructions: [Discover fine-tuning](discover-finetuning.md).

## Latest marketplace direction

The location-first brief now supersedes the original editorial section order. See [Discover marketplace](discover-marketplace.md) for implementation, filter behavior and validation scope. The original Stitch artifacts remain available as references.

## Current direction

The rejected marketplace iteration has been replaced by the [Uber Eats reference-based Discover rebuild](uber-eats-discover-redesign.md). The comparison HTML now shows the concrete Uber-published reference and normal phone-sized Flutter renders.
