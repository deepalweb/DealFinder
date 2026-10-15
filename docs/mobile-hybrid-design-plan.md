# DealFinder mobile: Uber Eats + Groupon design plan

Superseded for Discover: the subsequent supplied Stitch screenshot and implementation brief now govern this screen, including its emerald palette and mixed banner/expiry/rail/bank-grid/full-width composition. See [the screenshot implementation and comparison](stitch-discover-match.md). Other screens keep their prior scope and theme.

Nearby has subsequently received its own scoped refinement: [current Nearby implementation and previews](nearby-refinement.md). Its header, map/result balance, cards and shared-area synchronization follow that report; Discover's accepted layout is preserved.

Update, 15 October 2026: the user's density correction supersedes the full-width Discover feed below. Discover now uses compact horizontal offer rows and a two-column continuing feed at normal text size; enlarged text keeps full-width cards. The subsequent section review replaces the illustrated Discover category rail with compact text chips (All, supported categories, More). Header and search/filter geometry remain approved; search includes localized example hints. See [implementation notes](mobile-hybrid-implementation.md). The remaining data, eligibility and navigation requirements still apply.

Status: visual checkpoint approved by the user; Flutter integration completed, with device acceptance still pending. This plan records the approved direction. See [implementation and current verification](mobile-hybrid-implementation.md) for what is now built.

## Direction

**Make exploring offers feel as easy as browsing Uber Eats, with the savings and conditions as clear as the current Groupon-inspired cards.**

Keep sapphire DealFinder branding and the current Flutter architecture. Use Uber Eats as the reference for browsing rhythm, visual category shortcuts and a compact location/search header. Use Groupon as the reference for readable offers, tangible savings and detail structure. These are product-design choices, not Apple-mandated layouts.

## What changes from the current version

| Current implementation | Proposed next iteration | Purpose |
| --- | --- | --- |
| Categories mainly behind a header icon | A compact illustrated category rail on Discover, plus the existing full directory | Show the app covers everyday spending beyond restaurants |
| Introductory slogan and a separate distance explanation above cards | Short location header and one concise section subtitle | Put the first real offer higher on screen |
| Nearly every offer field has its own line | Group related metadata; retain material restrictions visibly | Improve scanning without concealing eligibility |
| Three large offers before the bank preview | Two wide offers, then one short bank collection when inventory exists | Add variety earlier without filling the page with sections |
| Large detail summary, copy-link block and strong “Why visit?” panel | A compact summary, quieter highlights and share/copy in the toolbar | Give conditions and the actual next action more prominence |
| Mostly identical card treatment across contexts | One shared card with full-width feed and compact horizontal-preview variants | Match density to the browsing task |

## Discover: recommended composition

1. **Location and notifications.** `Colombo 03 ⌄` with a small `Explore offers` context label. The area opens manual selection and an explicit Use my location action. Notifications remain on the right. Account stays in its tab.
2. **Search and filters.** `Search deals, stores, or bank offers`, with a 48px filter target and an applied-filter count. On scroll, pin only the search/filter row; the location, categories and other controls scroll away. At enlarged text, allow a taller header or a simple search toolbar action rather than squeezing content.
3. **One visual category rail.** Food & Dining, Daily Essentials, Shopping, Electronics, Beauty & Salon and Wellness; All categories remains reachable. Use existing original vector artwork where suitable. Do not add food subcategories or unsupported category IDs. Tapping a category filters Discover in place and exposes a clear reset; All categories opens the existing directory with area context preserved.
4. **First offer follows categories.** Put Sort, Ending soon, In-store and Online inside Filters initially; include Delivery/Pickup there only where supported. Show the applied-filter count and a clear reset. Add frequent-use shortcuts only if usability evidence supports them. Nearby and Bank Offers remain bottom tabs.
5. **Two wide offers.** These establish the product before a promotion banner. Use a local section title only when the offers actually meet the selected area's radius; otherwise use Explore offers. Keep pagination available when the loaded sample has no matching nearby offers.
6. **One short bank collection, if populated and relevant.** At most three compact preview cards, with part of the next card visible. Each shows bank, card type, benefit and material spend/cap conditions. See all opens Bank Offers. Omit an empty collection; a failed request gets a retry message. No “your cards” wording without persistent preferences. The bank preview must respect the active category, fulfillment and applicable eligibility filters. If those constraints cannot be evaluated reliably from the bank API, show an Explore bank offers entry instead of unrelated preview cards. Under Online, suppress physical distance everywhere, including the bank preview.

   With sparse inventory, show the available one or two offers without empty slots or duplicated cards. Empty bank inventory does not block the continuing feed.

7. **More offers.** A continuous, lazy, full-width feed. Deduplicate resource-aware IDs across the first offers, bank preview and remaining feed. A genuinely featured offer can occupy one normal feed position. Do not add another large hero, auto-rotating carousel or several overlapping collections.
8. **Browse stores.** A clear text entry after the bank collection, also reachable from merchant search results.

Suggested reading order, not a fixed-height screenshot:

```text
Colombo 03 ⌄                              Notifications
[ Search deals, stores, or bank offers       Filters ]
[ Food ] [ Essentials ] [ Shopping ] [ More categories → ]

Matching offers loaded so far
[ Landscape photo                              Save ]
Merchant · Area
25% off your food bill
Minimum spend LKR 3,000 · Maximum discount LKR 1,000
Selected credit cards · Dine-in
Approx. distance from selected area · Expiry

[ Second full-width offer ]
Explore bank offers                              See all
[ Compact bank offer ] [ Next offer peeking → ]
Browse stores →
More offers
[ Full-width offer ] …

Discover | Nearby | Bank Offers | Saved | Account
```

The bill-level discount example has no calculated item price: 25% applies to an eligible food bill, subject to the minimum spend and maximum discount. Fixed-price packages use separate fixtures and their own applicable conditions; never imply that a displayed item price automatically qualifies for a bill-level offer.

All example prices, merchants and conditions in concept work must be labelled fixtures. They are not promised inventory.

## Card system

**Main feed:** landscape photograph, 16px radius, solid neutral information surface, 16px content padding and 16–20px gaps between cards. Start with a roughly 1.8:1 image crop; verify the crop against actual merchant media. Retain the existing 680px maximum width on wider screens.

Give one saving the strongest emphasis: a known current price with a valid higher previous price, or the offer's actual percentage/currency benefit when no sale price exists. Do not show the same saving as an image ribbon, large headline and extra badge simultaneously.

Then show merchant, offer title, eligibility, fulfillment, area/distance and expiry in a consistent order. Group related facts with wrapping rather than shrinking type. A bank restriction, minimum spend or maximum benefit must not disappear merely to hit a card-height target. Long titles and translated conditions grow the card. If space is tight, lower-priority rating information can move to details; do not invent ratings or truncate material restrictions.

**Horizontal preview:** aim for 78–84% of the available phone width, leaving the next card visible. Use only for the bank collection. Cards have the same data rules and save semantics as the main feed. At large text sizes, convert the preview into vertically flowing cards instead of clipping conditions inside a fixed-height rail.

**Controls:** tapping the listing opens details; bookmark remains a separate action with explicit failure handling. Do not add a repeated Claim button to every card. Standalone bank saving remains unavailable until its API supports it.

## Other screens

| Screen | Hybrid treatment | Behaviour to preserve |
| --- | --- | --- |
| Categories | Roomy illustrated tiles in the separate directory; smaller rail on Discover | Actual taxonomy; large-text column reduction; filters and manual area |
| Search/results | Uber Eats-style recent searches and clear refinements; Groupon-style wide results | Existing suggestions/history, real query results, back/scroll restoration, loaded-result honesty |
| Nearby | Map-first browsing with compact selected-offer card and expandable list | Google Maps, manual area, explicit GPS, Search this area, synchronized selection, accessible expand/list controls |
| Bank Offers | Bank/card filters above consistent wide offer cards | Separate resource IDs, real restrictions, independent pagination, empty/error states |
| Offer details | Gallery → compact merchant/offer/saving summary → important eligibility and conditions → highlights → remaining conditions → merchant information/reviews | Existing real links, codes, directions, QR, reporting and authenticated actions |
| Merchant profile | Photo/logo identity, area, supported fulfillment, follow, then offers | Actual merchant details and reviews, active/expired visibility, authorized workspace access |
| Saved | Familiar wide cards with Active/Expired/All and compact Following/Compare entries | API-confirmed saves, cached-copy indication, five-offer comparison and tab state |
| Account | Keep the recently simplified identity and grouped settings | Real build metadata, system appearance, profile editing, QR and authorized merchant tools |

On details, move share/copy-link to toolbar actions, make the highlights panel quieter, and put important conditions immediately after the summary, before highlights. Keep material eligibility before the primary action. The primary label describes the actual destination: Get directions, Open merchant website, Copy code or supported redemption. Ordering remains an external merchant action where that is what the API provides. A sticky action must never cover content or bypass eligibility/sign-in requirements.

## Visual and motion rules

- **Palette:** existing sapphire `#2457E8`; neutral light and dark surfaces from the current semantic theme. Sapphire identifies primary actions/selection, with a consistent saving treatment. Amber/red communicate substantiated urgency only. No emerald rebrand.
- **Type:** existing platform typography. Starting sizes: section headings 20–22, offer titles 17–18, main saving 22–24 and supporting conditions 14–16 logical pixels. Validate with actual scripts and nonlinear TextScaler; these are starting values, not fixed accessibility limits.
- **Assets:** merchant media for offers; existing original category vectors for navigation. Neutral missing-media placeholders; unrelated restaurant photos do not stand in for electronics or retail. No Uber/Groupon imagery enters the app asset bundle.
- **Motion:** short pressed feedback, standard route transitions and a restrained selected-card transition on Nearby. Prefer existing AppMotion tokens; Reduce Motion removes extra scaling/movement. No autoplay banners or continual countdown animation.
- **Navigation:** retain Discover, Nearby, Bank Offers, Saved and Account. Preserve independent stacks, selected filters and scroll position. Use iOS back/sheet conventions and Android back/Material conventions in the shared Flutter implementation.

## Data boundaries

The present Discover implementation filters/sorts a loaded sample. A header choice does not establish comprehensive nearby inventory. Until geographic filtering, sorting and pagination are coordinated server-side, label the sample **Matching offers loaded so far**, including after category changes. Keep Load more accessible even when the loaded sample contains no matches, and preserve filters during every additional-page request. Server-side geographic filtering/sorting/pagination is a separate explicit engineering milestone. Do not call far-away or coordinate-less inventory nearby. Online offers have no physical distance.

Distinguish these states rather than using one empty screen:

- **No matches in loaded results:** explain the current category/filters, offer Clear filters, and retain Load more when another page exists.
- **No offers returned by the service:** show a genuine inventory-empty state and Refresh; no fictional replacement offers.
- **Request failure:** show Retry, retain existing results when available, and identify a saved/cached copy honestly.
- **Pagination failure:** retain cards and filters, show retry at the continuation point, and retry the same offset.

Apply only supported sorts/filters. “Open now” needs reliable business hours/time zones; “Top rated” needs adequate genuine ratings; “Free delivery” needs delivery fee data. Delivery times, checkout, memberships and guaranteed bank eligibility are not part of this design iteration.

The prior local check returned zero standalone bank offers. Design and test empty bank states; fixture screenshots do not prove live inventory. Preserve valid-price checks, Sri Lanka expiry semantics, guest browsing, API-confirmed save feedback and promotion/bank endpoint separation.

## Implementation order and acceptance

| Stage | Work | Gate |
| --- | --- | --- |
| 1. Visual direction | Produce 390px light/dark Discover and detail concepts, plus a 320px enlarged-text layout, from labelled fixtures | Normal 390px fixture viewport shows location, search, category choices and at least one saving. This is not a universal constraint: narrow screens, languages and accessibility settings may require scrolling. Never shrink text or hide conditions to fit a screenshot |
| 2. Discover | Reuse category artwork; compact header; shared card variants; optional bank collection; stable scroll behaviour | Category/filter changes produce correct loaded matches; no duplicate offers; empty matches can load more; no silent filter reset |
| 3. Behaviour verification | Combined filters, category-aware bank previews, pagination, guest saves, failures and navigation restoration | Correct matching and state preservation; honest empty/failure handling; no incompatible IDs or false save success |
| 4. Screen alignment | Search, Nearby, Bank Offers, details and merchant profile use approved components and spacing | Find an offer, understand eligibility, take its supported action, and return with context intact; Account remains unchanged |
| 5. Validation | Re-run current regression suite and targeted layout/state tests; render all changed screens; Android build | 320/390/430px and tablet, English/Sinhala/Tamil, large text, both themes, slow/offline/error states and failed saves pass |
| 6. Device acceptance | Real Android and iOS/simulator checks where available | TalkBack/VoiceOver, safe areas/back gestures, release/profile scrolling and map transitions verified, with unavailable checks reported |

Proposed usability check: ask participants to find one relevant offer near a manually chosen area, explain its bank/spend restrictions, and choose the correct next action without coaching. Record completion, wrong turns and whether restrictions were misunderstood; compare with the present design before claiming improvement.

## Guidance and evidence

This is a proposed synthesis based on the current rendered Flutter screen, source inspection, the earlier locally saved Uber Eats promotional screenshot and Groupon reference review. It is not a hands-on audit of current signed-in Uber Eats or Groupon apps.

Public context checked: [Uber Eats category browsing](https://www.ubereats.com/near-me/grocery), [Uber grocery product direction](https://www.uber.com/us/en/newsroom/grocery-product/), [Groupon app listing](https://apps.apple.com/us/app/groupon-local-deals-near-me/id352683833). These support product context, not claims that either app currently uses this exact composition.

Apple references read locally: `layout.md › Visual hierarchy` (“Order content by relative importance”), `accessibility.md › Vision`, `typography.md › Conveying hierarchy`, `color.md › Best practices`, `collections.md`, `search-fields.md`, `tab-bars.md`, `motion.md`, `designing-for-ios.md`, and `cross-platform.md`. Apple supplies platform/accessibility principles; the hybrid composition and tab names are DealFinder product decisions.

UI UX Pro Max Flutter search supports TextScaler, Semantics and screen-reader validation. Its broad marketplace design-system output suggested a green marketing/showcase treatment; that conflicts with the established sapphire mobile direction and is not adopted. Web-only navigation search results do not govern the mobile plan.

The existing implementation and its 69-test result remain the baseline documented in [mobile-groupon-redesign.md](mobile-groupon-redesign.md); no tests or app changes are claimed for this plan-only task.

## Visual checkpoint and approval boundary

Render Discover and Details at 390px in light/dark mode and at 320px with enlarged text, using clearly labelled fixtures. Include scrolled Details so the summary-to-conditions order can be reviewed. Present the renders for user approval **before production-screen integration**. This approval boundary comes from the user's latest request, not a skill requirement.

Prototype components live under `mobile_app/tool/hybrid_checkpoint/`. After approval, promote those exact components and spacing into the app, adapting data inputs and callbacks without independently redrawing the layouts. Prototype filtering/navigation only exercises fixtures; production behaviour requires Stage 3 verification. Account is outside the implementation scope of this iteration.

See [visual checkpoint](mobile-hybrid-checkpoint/index.html) for renders and the review checklist. New preview checks are separate from the previously reported 69-test production baseline.

### Checkpoint verification

The isolated Flutter preview rendered Discover and Details at 390px in light/dark, at 320px with 2× text in light/dark, plus scrolled views and extended Discover composition. Two checkpoint tests passed (render/layout checks and combined fixture category/Online filtering with distance suppressed). Targeted Dart analysis of the prototype and renderer reports no issues. These are English fixture checks; production API, localization, devices and the earlier production regression suite were not rerun for this visual-only checkpoint.

## Approval and integration

The user approved the rendered checkpoint. The approval boundary above has been satisfied; implementation proceeded using the promoted layout components. [Review the integrated production-widget renders](mobile-hybrid-live/index.html). The earlier 69-test baseline and prototype checks above are historical; current results are in the implementation report.


## Navigation update: Stores tab

The main mobile navigation now uses **Discover, Nearby, Stores, Saved, Account**, replacing the former Bank Offers destination with the existing merchant directory. This supersedes the five-tab labels proposed earlier in this plan. Bank offers remain reachable through Discover's bank shortcuts; bank results open in Discover's independent route stack, preserving the selected bank and return context. Both phone navigation and the wide-screen rail use the localized Stores label and storefront icon.
