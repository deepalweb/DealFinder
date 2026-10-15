# Stores and store details refinement

## Review and changes

The directory previously placed a large introduction, activity summary and several overlapping store collections ahead of its main list. It now leads with a short introduction, search, category chips, sorting and the directory. Search clear now clears both the controller and query. Store cards use consistent summary slots, an 88px directory image, genuine ratings/counts when supplied and independent View store, Follow and Share actions. Compact photo cards retain a distinct variant. Large text stacks the layout. Opening hours now use the shared Colombo schedule logic, including overnight hours and exclusive closing boundaries, rather than the device-local calculation.

Store details retains its banner/logo identity, supported fulfillment, Follow, directions, external merchant website, Offers/About/Reviews and active/expired views. The banner and summary grouping are tighter; offer cards match the current main feed. Both store pages use locally scoped marketplace tokens for chips, buttons, cards and toolbar contrast, and constrain content to 680px on wide screens. Store offer navigation retains the injected API client. Following state refreshes when returning to the directory.

Public active offers use the shared consumer visibility rule. Expired inventory also excludes private/draft states. This fixes a previously unguarded expired filter. No database records were changed.

Apple principles applied: `layout.md › Visual hierarchy`, “Use progressive disclosure to make layouts cleaner and easier to interact with”; `typography.md › Supporting Dynamic Type`, “Consider adjusting your layout at large font sizes”; `collections.md › Best practices`, “Use the standard row or grid layout whenever possible.” Flutter conventions come from `cross-platform.md`. UI UX Pro Max's Flutter TextScaler and LayoutBuilder guidance informed adaptive layouts. The exact directory composition is a DealFinder product choice.

## Verification and limits

[Actual Flutter preview gallery](stores-refinement/index.html). Five configurations render directory, profile offers, About and Reviews: light/dark 390px, dark 320px double text, enlarged Sinhala and Tamil. Fixtures are explicitly labelled; they do not establish live inventory. The map is a fixture, not Google tiles.

Targeted coverage exercises search reset, opening a store, active/expired inventory, private-draft exclusion, section changes and narrow enlarged text. Existing compact-card navigation and localized-label checks remain in the regression suite.

Native Google Maps, sharing, phone/web destinations, authenticated following/reviews and screen-reader/device checks require separate validation. No build, deployment or production data mutation is claimed for this iteration. Structural widget changes require a hot restart of an already-running app.

Validation results: the full regression run passed 87 tests and flagged two obsolete assertions for the replaced offer-card class. After updating those assertions, all five profile tests passed. The three focused store tests passed, as did the five-configuration renderer producing 20 images. All gallery image references resolve.

Final Dart analysis of the changed screens, shared widgets, tests and renderer: **no issues found**.

## Loading failure follow-up

Store identity and offers now load independently: an offers failure retains the store header and About/Reviews, shows an inline retry, and avoids displaying failed inventory as an empty list. Store requests have a 30-second timeout and typed HTTP status errors; a 404 has a distinct unavailable-store message. Ten targeted store/profile tests passed and analysis found no issues. Read-only checks returned HTTP 200 from both local endpoints for all 14 stores; this does not establish connectivity from a phone/emulator. The configured mobile base currently uses localhost, so device-specific connectivity remains a separate diagnostic.
