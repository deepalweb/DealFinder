# DealFinder mobile marketplace redesign

Reviewed and implemented from `DealFinder_Mobile_Groupon_Codex_Prompt.md` (Downloads), 15 October 2026. The document is a design brief adopted by the user's request; its examples are not live inventory or permission to publish anything.

## Reference review and decisions

Reviewed the official [Groupon iOS listing](https://apps.apple.com/us/app/groupon-local-deals-near-me/id352683833), [Android listing](https://play.google.com/store/apps/details?id=com.groupon) and [mobile page](https://www.groupon.com/mobile). Downloaded and visually inspected all six public iPhone promotional screenshots, recorded under `mobile_app/design-reference/groupon-public/`. This is promotional-reference analysis, not a signed-in Groupon usability study.

Adopted landscape imagery above readable offer information, a separate category directory, a continuous single-column feed, a detail gallery and section navigation. Retained DealFinder sapphire, existing semantic themes, the five consumer tabs and real offer actions. Groupon branding, photography, device frames, purchase flows and promotional claims are not shipped as app assets.

Read Apple Design's accessibility, layout, typography, color, collection, search and tab guidance plus cross-platform guidance; used UI UX Pro Max's local Flutter accessibility search. Existing Flutter 3.41.7/Dart 3.11.5 supports the implementation. This does not claim native Liquid Glass rendering.

## Route and data audit

| Surface | Existing integration | Implementation |
| --- | --- | --- |
| Discover | `HomeScreen`, promotion cache/API, curated sections, BrowsingArea | Compact location/search controls, category entry, wide offer cards first, short bank preview, at most one separate featured offer, lazy continuation |
| Categories/results | Actual `predefinedCategories`, `AllDealsScreen` | Dedicated icon tiles; filtered full-width cards; loaded-result counts; pagination, retry and stale-response guards |
| Search | SearchService's search/history/suggestions and local fallback | Existing query flow retained; shared wide results; manual browsing area replaces automatic location access |
| Details | Promotion detail, merchant, comments/ratings/stats, redemption, outbound links | Gallery and zoom, Offer/Highlights/Conditions/Merchant links, expanded conditions, valid price comparisons, offer-specific order destination |
| Nearby | Existing Google Maps screen/controller and selected offer | Preserved explicit area search, manual location, synchronized selection and sheet; valid price or category markers; aligned result surfaces |
| Bank Offers | Separate bank resources plus bank-related merchant promotions | Shared cards, bank/card filters from loaded data, independent pagination for both sources; failed bank refresh is reported |
| Saved | Remote favorites with local snapshots, following, comparison | Active/expired/all filters, followed-store route, selection for up to five comparisons, API-confirmed removal, explicit cached-copy message |
| Account | Existing grouped settings, profile editor, auth and merchant workspace | Smaller identity row and editing entry; existing theme, QR, version metadata and supported settings retained |

Consumer tabs remain Discover, Nearby, Bank Offers, Saved and Account with existing independent route stacks. QR and merchant tools retain existing authorization. Unsupported consumer deletion, loyalty tiers, measured footfall, payment cards and guaranteed card eligibility were not added.

## Data correctness

- `OfferPresentation` distinguishes standalone bank IDs from promotion IDs and owns valid current/previous prices, savings, online distance suppression and public visibility.
- Missing, negative and non-finite amounts are not rendered as free offers. Previous price appears only when greater than a known current price. Currency savings are not interpreted as percentages.
- `Promotion.images` survives JSON and copy operations. Date-only starts/ends use Sri Lanka day boundaries; timestamps retain their instant. Unknown expiry remains unknown.
- Online-only offers do not expose physical visits or distance. Discover, search and details read the selected browsing area; GPS permission remains an explicit user action.
- Standalone bank details skip merchant-promotion analytics and review endpoints. Their save control is unavailable because the promotion-favorites API does not support them. Persistent bank/card preferences remain deferred.
- Promotion and bank result pages have independent offsets. Loaded-result counts describe the fetched sample, not the whole database. Nearby ordering is explicitly based on loaded offers; Discover does not claim a server-side geographic inventory query.
- Remote favorites are authoritative after a successful response; failed loading uses the saved copy visibly. Failed removal does not dismiss the offer. Comparison storage is scoped to the current account.

## Changed implementation files

New reusable files: `utils/offer_presentation.dart`, `widgets/discover_marketplace_card.dart`, `screens/categories_screen.dart`, `screens/followed_merchants_screen.dart` (under `mobile_app/lib/src/`).

Updated consumer screens: `home_screen.dart`, `all_deals_screen.dart`, `search_screen.dart`, `deal_detail_screen.dart`, `favorites_screen.dart`, `user_profile_screen.dart`, `deal_comparison_screen.dart`, `nearby_deals_screen.dart`.

Updated supporting files: `models/promotion.dart`, `services/api_service.dart`, `services/search_service.dart`, `services/deal_comparison_service.dart`, `widgets/offer_save_button.dart`, `widgets/profile_section.dart`, `widgets/nearby_offer_row.dart`.

A required additive API change also updates `backend/routes/bankOfferRoutes.js` and `backend/services/postgresBankOfferService.js`: bank-offer pages now accept a validated, bounded `skip`, and Postgres ordering includes a unique ID tie-breaker. This uses Sequelize query options, with no schema migration or database write. Applied the Supabase Postgres skill's pagination guidance; bounded offsets retain compatibility with the current client contract. Cursor pagination is preferable if inventory/page depth grows. The running backend must restart/deploy to load this route change; it was not restarted during this task.

Existing pending web, backend and mobile work was preserved. This report describes this mobile pass, not every difference on the working branch.

## Verification evidence

- Full normal Flutter suite: **69 tests passed**, including existing guest cancellation/resumption, independent tab stacks, failed favorite, Nearby area search/selection, profile error recovery and merchant visibility checks.
- Added model tests: valid/unknown amounts, currency versus percentages, resource identity, online visits/distance, date-only boundaries, gallery serialization and private pending offers.
- Added widget tests: pagination retry with unchanged offset, final page, ignored late response after disposal; category layouts in English/Sinhala/Tamil at 320/390/840 logical pixels with double text; detail gallery, expanded conditions and standalone-bank endpoint isolation.
- Large-text tests found a category overflow. The grid now measures actual localized labels and reduces columns at enlarged text sizes. Cards are bounded to 680 logical pixels on tablets.
- Analyzer: `flutter analyze --no-pub` — **No issues found** on the final source.
- Android: `flutter build apk --debug --no-pub` — **passed** on the final source. APK: `mobile_app/build/app/outputs/flutter-apk/app-debug.apk`. Current pubspec version: `1.0.2+3`. No iOS build attempted on Windows.
- Backend: `node --test backend/tests/bank-offer-pagination.test.js` passed (one test exercises advancing pages in both model adapters, unique ordering and invalid offsets). Models are mocked; no database was contacted by this test. Changed backend JavaScript also passes `node --check`.
- Read-only local API checks: `/api/promotions?limit=50` returned HTTP 200 and 29 rows; `/api/bank-offers?limit=50` returned HTTP 200 and zero standalone bank rows. These are endpoint sample observations, not a full database count or signed-in end-to-end validation. No data was inserted or modified.
- Screenshots are Flutter widget renders with **explicit demo fixtures**, bundled existing Stitch imagery and manually loaded SDK fonts. They are not production inventory or device screenshots. Renderer: `mobile_app/tool/groupon_preview_test.dart`.

## Previews

[Browse rendered screens](mobile-groupon-preview/index.html).

## Deferred or unverified

- Live signed-in save, QR redemption, bank eligibility and merchant submission journeys require authenticated end-to-end checks; existing mocked tests do not establish live success.
- No standalone bank inventory was returned by the local service, so bank filter behaviour uses fixture/source verification rather than live bank inventory.
- Discover filters and nearest ordering operate on the loaded sample. Comprehensive server-side location/category/search pagination remains a separate backend improvement. Existing search fallback/relevance behaviour was retained.
- Existing older copy outside the changed components still needs a full native-speaker localization review. Automated three-language layouts are not translation certification.
- iOS builds, safe-area/back-gesture checks, VoiceOver, Android TalkBack and release/profile scrolling/map transitions were not verified in this pass. Windows cannot build iOS. A connected Android handset was detected, but no claim of device testing is made.
- Persistent bank/card preferences, consumer-authorized deletion, booking, checkout, refunds and unsupported analytics remain out of scope.
- No GitHub push, deployment or platform regeneration was performed.
