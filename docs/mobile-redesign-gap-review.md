# Review of the additional DealFinder proposal

The subsequent Google Stitch Discover reference is captured in [stitch-discover-reference.md](stitch-discover-reference.md), including layout choices, sapphire adaptations, and API-dependent labels. Its Flutter Discover implementation is now recorded in that document; remaining API and validation dependencies are still called out.

Compared the supplied design proposal with the Flutter redesign on 13 October 2026. The comparison now includes the accepted Milestone 1 implementation; its validation evidence and remaining acceptance work are recorded below.

## Assessment

The proposal gives DealFinder a stronger product focus: discover a usable nearby offer, understand eligibility, then take the appropriate action. Its visual principles largely match the implemented design system. Its navigation and workflow recommendations are a further product iteration, with several backend/data dependencies.

The current redesign establishes a visual foundation and improves selected interactions. It does not yet implement every journey or acceptance criterion in this proposal.

## Comparison

| Area | Current implementation | Additional work |
| --- | --- | --- |
| Visual direction | Neutral light/dark surfaces, system typography, blue actions, rounded cards, cached photos, restrained navigation translucency | Sapphire is the accepted identity; update launcher/store assets if adopting the new in-app mark. |
| Design tokens | Shared light/dark/high-contrast theme, spacing, type, button, input, sheet, and dialog styles | Continue auditing legacy colors and all enlarged/localized offer conditions. Existing contrast results cover selected token pairs, not the entire app. |
| Main navigation | Discover, Nearby, Bank Offers, Saved, Account; stores reachable from Discover and offer search | Validate the information architecture with consumers and keep merchant access easy to find. |
| Navigation state | Lazy nested navigators preserve per-tab routes and widget state; Saved no longer rebuilds on selection | Process-death restoration remains separate work. |
| Guest browsing | Signed-out startup opens Discover; protected actions open a sign-in gate and resume on accepted sign-in | Verify live email/Google sign-in, registration, cancellation, expired sessions, and offline authentication end to end. |
| Discover | Prominent search, featured offer, categories, nearby and other sections | Categories currently follow the featured card. Decide the desired order and reduce competing sections. General recommendation fallbacks now say Popular; personalized wording requires a supported API reason. |
| Deal cards | Shared photographed offer cards, merchant, price, discount, distance or near-term expiry | Add fulfillment/eligibility summaries, a save control, meaningful expiry beyond 48 hours, and a true compact variant. Current card shows expiry instead of distance when urgency is present. |
| Nearby | Shared map/results sheet, manual saved areas, Search this area, synchronized selection, radius/category/open-now controls, and straight-line distance notices | Validate approximate/denied permissions and release map performance; extend named-area coverage beyond local presets and stored merchants. |
| Location permission | Initial Discover/Nearby checks do not prompt; explicit Use my location controls request permission | Basic consumer area selection is implemented; validate declined/approximate access on real devices. |
| Search | Recent searches, suggestions, natural-language support, and quick filters exist | Show interpreted category/price/location as editable chips. Verify a single consistent filter sheet covers fulfillment, eligibility, availability, sorting, reset, and persistent selection. |
| Deal details | Image preview, actual verification badges, offer information, existing coupon/QR actions, bottom CTA, reviews and recommendations | Strengthen How to use instructions and key-condition hierarchy. Make external destination wording explicit. Verify QR/coupon states and all eligibility conditions against real data. |
| Bank Offers | Dedicated consumer destination uses the existing public bank/card data | Add bank/card filters and optional saved preferences. Structured offer-day/branch restrictions need API/schema review; do not imply eligibility data that is absent. |
| Saved and Account | Deals and following segments exist inside Profile; separate Favorites tab lists deals | Unify these under Saved, group active/expired favorites, and expose five-deal comparison through selection. Group account, support, history, language, and merchant entry points coherently. |
| Merchant workspace | Dashboard, profile editing, promotion creation, and QR scanner exist | Create a dedicated task-focused workspace; add draft recovery, upload progress/retry, and a consumer preview. The current creation screen has three tabs, not the four-step baseline claimed in the proposal. |
| Branches | Merchant has one location; inspected merchant/promotion schemas have no branch entity | Branch selection and branch-specific offers require data modeling/API changes, not only a location picker. |
| Administration and website | Existing web admin and consumer app were reviewed earlier | Desktop admin redesign and matching website presentation were outside the mobile implementation. Audit trails and moderation/backend fixes remain separate engineering work. |
| States and accessibility | Reduced-motion treatment, theme variants, loading/empty/error improvements, ten widget tests, Samsung inspection | Complete per-screen state coverage, freshness indicators, assistive-technology testing, full language/large-text audits, iPhone checks, and release-mode map/translucency performance testing. |

## Recommended sequence

1. **Discovery and navigation:** implement guest browsing, the proposed tab structure, nested tab navigation/state restoration, and safe return after sign-in. Keep merchants and stores reachable.
2. **Nearby:** manual area selection, map/list selection parity, draggable results, and Search this area. Use the selected map center for API requests rather than always the device location.
3. **Offer usability:** eligibility/fulfillment/expiry on cards, dedicated Bank Offers, clearer detail conditions, and appropriate directions/site/code/QR actions.
4. **Saved and merchant work:** active/expired saved sections, comparison entry, merchant workspace, draft recovery, and upload/preview states.
5. **Validation and integration:** cover all three languages, accessibility preferences, guest/auth transitions, offline/error states, and iOS/release performance. Address the previously identified backend issues alongside the affected flows.

Use the proposal's three acceptance tasks as the core scenario checks: find a nearby offer, confirm eligibility, and take the correct action. Successful UI messages must reflect actual API results. The existing successful build and widget tests are useful evidence, but do not establish that these broader tasks are complete.

## Decisions to retain

Keep solid readable content surfaces, limited navigation blur, truthful trust/analytics labels, system text scaling, appropriate native interaction patterns, and lightweight purposeful motion. Branch features should be shown only once the API can represent them. Card preferences should concern bank and card type, without collecting payment card numbers.

The shared skill guidance supports these foundations. The proposed tab names, green brand accent, four-stage creation wizard, and specific screen order are product choices rather than mandatory Apple rules.


## Milestone 1 implementation — 2026-10-13

The accepted product navigation is now **Discover, Nearby, Bank Offers, Saved, Account**. Sapphire remains the shared identity; the three-tab merchant promotion editor and current single-location API remain in place.

Implemented:

- Signed-out startup opens the discovery shell. Public offers, stores, search, and bank/card offers are browsable without signing in.
- Each destination has a lazily created nested Navigator in an IndexedStack. Switching tabs retains scroll/filter/widget state and open routes. Saved no longer recreates its screen on every selection; favorite membership changes trigger a data refresh without resetting its navigator.
- Discover exposes Browse stores. Offer search also links to the merchant directory using the same query, including when no offers match.
- Bank Offers has a permanent bank/card-only data constraint; changing its filters cannot turn the destination into a general promotion feed. It uses the existing public offers API. The inspected local bank-offers endpoint currently returns an empty list; no bank eligibility or branch data was invented.
- Saved and Account explain the benefits of signing in while guests can continue browsing. Offer save, deal alerts, redemption QR, report/feedback actions, store follows, and notifications use a sign-in gate.
- Sign-in is presented above the originating route. Successful email/Google sign-in returns a result; registration opened from that flow returns through sign-in to the same route. Cancel/back does not run the pending action. Private tab stacks reset on account changes; public tab stacks remain.
- Signing out returns Account/Saved to their guest gates and keeps the discovery shell available. Session removal proceeds even if remote notification/Firebase cleanup is unavailable; account caches are cleared while language preferences remain.
- Discover and Nearby perform only non-prompting location checks during initialization. Permission requests are limited to explicit Use my location controls. Nearby refresh reuses its selected position instead of resetting it to GPS. Its existing coordinate-based location dialog remains a development-era baseline for Milestone 2, not a completed consumer area picker.
- General recommendations display Popular. Personalized wording requires both a signed-in user and a supported API reason tied to viewed categories, liked/followed stores, or saved offers.
- New destination, store-entry, guest-gate, location-action, and popularity labels are available in English, Sinhala, and Tamil.

Validation includes widget tests for sign-in acceptance/cancellation with preserved original input, independent public route stacks, guest tab reachability, Discover/Saved state retention, narrow dark navigation with doubled text, and tablet navigation. Authentication return tests simulate the accepted session rather than calling live Firebase. The device/release scenarios remain a separate acceptance requirement: find a nearby offer, confirm eligibility, and take the correct action.

Remaining work follows Milestones 2–5: consumer area selection, draggable map results and Search this area; richer offer/eligibility actions and bank/card filters; active/expired Saved plus comparison and merchant draft/upload recovery; complete language, screen-reader, offline/error, iPhone, and Android release validation. Navigation state is preserved within the running app; process-death restoration has not been implemented. Existing favorite offline/remote reconciliation behavior has not been redesigned in this milestone.


Final checks for this iteration: `flutter analyze --no-pub` reports no issues; all 13 widget tests pass; `flutter build apk --debug --no-pub --target-platform android-arm64` succeeds. The APK was installed on Samsung SM A065F. Device inspection confirmed the five-tab layout, Browse stores entry, database-backed demo discovery, the bank-offer empty state, and returning to an open offer after switching to Nearby and back. Captures: `mobile_app/design-preview/discovery-milestone.png`, `bank-offers-milestone.png`, and `discovery-preserved-offer.png`. Live guest authentication/registration and redemption, iPhone checks, screen-reader audits, and release builds remain unverified.


## Stitch Discover implementation

The reference is now implemented in the discovery feed: compact header/search, category-before-feature order, manual feature paging, shared save controls, conditions and fulfillment on cards, nearby rails, bank spotlight/filter entry, and expiry rows. See [implementation details](stitch-discover-reference.md#implemented-discover-screen). The server favorites API is checked before changing normal promotion snapshots; rejected saves preserve existing state. This visual/interaction work does not complete the remaining consumer area-picker and release acceptance scenarios.


## Stitch Nearby implementation

The new [Nearby reference and implementation record](stitch-nearby-reference.md) covers the map-first screen, draggable results with button alternatives, shared selected area, real open-now schedule filtering, overlapping-marker groups, and explicit map-center search. Automated checks cover latest-request wins, selection/filter consistency, wrong-area cache rejection, manual-area persistence, overnight hours, large-text rows, explicit Search this area coordinates, and expanding results with reduced motion. Device/release evidence is recorded separately from these simulated API checks.
