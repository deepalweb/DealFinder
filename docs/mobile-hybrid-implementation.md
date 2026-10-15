# Approved hybrid mobile redesign — implementation

Discover's current visual implementation is documented in [Stitch screenshot match](stitch-discover-match.md). The later supplied screenshot supersedes this document's sapphire and category-row recommendations for Discover; the historical behavior notes and other-screen work below remain relevant.

The user approved the Discover and Details checkpoint before production integration. This pass applies that layout to Flutter and preserves the current five-tab architecture and Account layout.

## Implemented

Density revision validation: 77 Flutter regression tests passed; targeted static analysis found no issues; production-widget fixture renders passed in light/dark at 390px and at 320px with enlarged text. Android debug APK built and installed successfully on the connected Samsung device, preserving app data. These fixture renders do not certify live authenticated journeys or real-device accessibility.

- Discover: compact area/notification header; only search/Filters pins. Following the user's section review, the illustrated rail is replaced by a single horizontally scrolling text-chip row: All resets the category, the selected chip uses sapphire, and More opens the real category directory. Existing taxonomy and localized labels remain; the separate directory keeps its artwork. Chip widths and heights follow text scaling, with padded touch targets. Sort, ending-soon and fulfillment refinements remain in the draft/apply/cancel Filters sheet, including Online.
- Search-bar refinement: localized example hints (pizza, groceries, bank offers and general deal/store search) rotate every five seconds with a short fade. Header, search navigation and filter control remain unchanged. A stable screen-reader label describes the search scope; reduced-motion and accessible-navigation settings keep the hint stationary. Hidden tabs and covered routes do not advance it.
- Category-chip validation: 23 targeted Discover/filter/pagination/layout tests passed, including enlarged Sinhala/Tamil. At enlarged text, the bank collection heading and View all action now stack instead of competing for horizontal space.
- Feed (density revision, 15 October): compact horizontal rows replace the opening wide cards, with roughly two offers visible across a 390px phone. The continuing feed uses two columns with shorter image crops and 10–12px gaps. Bank previews use the same compact treatment. Sparse inventory does not create placeholder slots. Resource-aware IDs remain deduplicated. Enlarged text restores full-width, vertically flowing cards.
- `CompactDiscoverCardLayout` is Discover-only: 1.9:1 images, 12px corners, 10px content padding, 16px benefit, 14px descriptive title and 12px conditions. Descriptive titles can abbreviate to two lines; bank requirements, minimum spend and maximum discount wrap without truncation. Details and the other tabs retain their existing layouts.
- Shared layout: `HybridOfferCardLayout`, `HybridConditionsPanel` and `HybridSearchHeader` are used by the app and checkpoint fixtures. Photo ratio 1.8, radius 16, card padding 14, main benefit 22, title 16, conditions 14, metadata 13; all text scales. Details uses the approved compact summary and the same conditions panel.
- Cards emphasize one main benefit. Known price/previous-price comparisons are valid only when substantiated; spend-threshold offers with a stated discount use that benefit instead of suggesting that a calculated item price meets the bill threshold. No new pricing basis is invented.
- Details: gallery, compact merchant/benefit/title, important eligibility and full provided terms before optional highlights, then additional description, real actions, recommendations/reviews and merchant information. Share stays in the toolbar; More retains copy-link, Save, alerts and reporting. A single full-width sticky action describes its destination. Codes/QR and other supported actions remain in the action panel.
- Search, results, Bank Offers, Saved and merchant-profile offers share the wide card. Nearby keeps its compact selection/list controls and uses the same price-validity and online-distance rules. Account was not redesigned in this iteration.
- Navigation: the standard Flutter NavigationBar retains the same five destinations and independent stacks. It replaces the old custom label layout after the 320px/2× render exposed truncated tab names; offer content continues to scale with TextScaler.
- Manual area selection, explicit GPS and map access remain reachable. Failed location lookup invites manual selection. Chosen areas persist through BrowsingArea. Stale location lookups cannot overwrite a later area selection; unknown/old distance is cleared when it cannot be recomputed.

## Matching, pagination and states

Discover labels the sample **Matching offers loaded so far**. It does not claim comprehensive nearby coverage. Physical distances are computed from the selected browsing area; Online suppresses distance. A bank preview must match active category/fulfillment constraints; unrelated or unsupported bank metadata does not create a preview. The general Bank Offers entry remains reachable.

Bank eligibility is a facet: a merchant dining promotion can match Food & Dining and Bank Offers. Matching is consistent in Discover, search and complete results.

Promotion and bank continuation offsets remain separate. ApiService retains the original response's continuation hints before applying consumer visibility rules, so filtering the first response to zero visible matches does not prematurely remove Load more. Filters remain selected during page loading/failure/retry; a late page response after refresh is ignored.

States distinguish no matching loaded results, no consumer offers returned, request failure, retained/cached results and pagination failure. Retry uses the same continuation point. Server-side geographic filtering, sorting and pagination coordination remains explicitly separate backend work.

## Main files

- `mobile_app/lib/src/widgets/hybrid_offer_layout.dart`: promoted checkpoint layout components.
- `mobile_app/lib/src/widgets/discover_marketplace_card.dart`: live Promotion adapter.
- `mobile_app/lib/src/screens/home_screen.dart`: approved composition, location, filters and pagination.
- `mobile_app/lib/src/screens/deal_detail_screen.dart`: approved hierarchy and preserved real actions.
- `categories_screen.dart`, `discover_category_strip.dart`, `discover_filter_sheet.dart`: real routes, scalable categories and Online filter.
- `merchant_profile_screen.dart`, `nearby_offer_row.dart`, `nearby_deals_screen.dart`: related offer alignment.
- `all_deals_screen.dart`, `search_screen.dart`, `search_service.dart`, `bank_card_promotion_support.dart`: consistent category/fulfillment matching.
- `promotion.dart`, `offer_presentation.dart`, `api_service.dart`: explicit distance clearing, presentation rules and raw-page continuation hints.

## Validation

- Full Flutter regression suite after native-navigation integration: **75 tests passed**.
- A final targeted Discover/pagination run also passed **21 tests** after the stale-location guard.
- The integrated live-widget render test passed and produced 16 images: Discover/Details, light/dark, 390px normal and 320px at 2× text, initial/scrolled views.
- The promoted checkpoint render/filter checks also passed separately. Screenshot inspection caught the old custom tab-label truncation; the final native NavigationBar render shows readable labels at 320px/2×.
- Android debug build after final navigation integration: **passed**. APK: `mobile_app/build/app/outputs/flutter-apk/app-debug.apk` (version `1.0.2+3`).
- Static analysis of `lib`, `test`, the live renderer and promoted checkpoint components: **No issues found**. Coverage includes existing guest sign-in cancellation/resumption, failed favorite, independent tab stacks, manual-area/map selection, profiles, both themes, enlarged text, Sinhala/Tamil/English layouts and the offer gallery.

Added focused coverage checks zero loaded matches with category preserved through pagination failure/retry, ignored stale pages after refresh, combined category/Online matching without physical distance, continuation after consumer visibility filtering, spend-threshold price presentation, explicit distance clearing and bank-as-facet category matching.

[Integrated screen renders](mobile-hybrid-live/index.html) use actual production widgets with isolated, explicitly labelled fixtures. They are not API inventory or physical-device screenshots. The previous visual checkpoint remains a design reference; the live-widget gallery is the implementation evidence. No database writes, deployment or GitHub push occurred in this pass.

## Remaining verification

Authenticated live saves, QR redemption, external merchant destinations and notifications still require end-to-end checks with a real account. Automated tests preserve supported flows but do not prove live acceptance. Standalone bank favorites remain unsupported by the promotion-favorites API. The earlier bank-offset backend change requires the backend to load that source before pagination can work live.

English screenshot fixtures and automated localized layouts do not replace native-speaker review. iOS builds, VoiceOver/TalkBack and release/profile scrolling/map transitions were not verified on devices. The Android debug build is compilation evidence only. No claim of native Liquid Glass rendering or full Uber Eats/Groupon parity is made.
