# Discover: supplied Stitch screen implementation

The attached brief and screen supersede earlier sapphire Discover and uniform-card proposals. Emerald is scoped to Discover and its selected navigation bar; Account, merchant tools, detail routes and other tabs retain their existing theme and workflows. Production records are untouched.

## Approved addition: Nearby deals

The subsequent request adds one compact horizontal Nearby deals section between Featured offers and Bank Perks. Existing banner, expiry, featured, bank and full-width collections retain their composition and inventory. The new preview shows up to six closest public, matching, coordinate-backed physical offers within 3 km of the selected area. Online, unknown-location and out-of-radius offers are excluded. It uses approximately 173px-wide cards on a 390px phone and full-width flowing cards at enlarged text sizes. Save and detail actions use the existing flows; View all opens Nearby. Empty previews explain the loaded-results limitation and provide manual area selection, without automatic GPS permission.

Nearby is an independent geographic projection, so the same offer may also remain in Featured, Bank Perks or the main feed. This deliberate repetition preserves those existing collections; IDs remain unique within each collection, and the original collections remain mutually deduplicated.

The updated actual-screen renders passed the same six light/dark/narrow/enlarged/localized configurations. The full-page fixture is now 390 × 2829 logical pixels because of the added section. Targeted location checks confirm nearest-first ordering, area changes, online/unknown/out-of-radius exclusion and the View all callback.

Nearby addition verification: **26 targeted tests passed** (`.codex-logs/discover-nearby-tests-final.log`), the actual-screen renderer passed (`discover-nearby-render.log`), targeted static analysis found no issues (`discover-nearby-analyze.log`), and the Android debug APK built successfully (`discover-nearby-build.log`).

## Visual checklist and evidence

Reference: 287 × 1600 pixels. Comparison viewport: 390 × 844 logical pixels, full-page capture at 390 logical pixels. Sampled pale background is approximately `#FDF8FC`; banner greens cluster around `#067856`–`#077F5B`. Flutter uses a solid emerald banner, neutral rounded surfaces, white information panels, inset feed photographs, compact type and subtle borders. Existing platform typography is retained.

- Compact two-line location identity, notification action and aligned right shortcut.
- Three evenly divided fulfillment segments; compact search and supported icon chips.
- Emerald curated banner with thumbnail, minimum-spend information and right-aligned light action.
- One genuine expiring offer, timestamp-derived remaining time and horizontal thumbnail card.
- Horizontal featured rail showing the next card, rather than a grid or full-width hero.
- Two-column bank grid with bottom image benefits, circular saves and actual card restrictions.
- Continuous full-width cards with inset images, merchant identity, real ratings, compact metadata, divider and right-aligned mint action.
- One five-tab navigation bar, preserved independent stacks and scroll/filter state.

Open [the side-by-side comparison](stitch-discover-match/index.html). It includes first viewports, full-page captures, dark mode, a 320px phone and enlarged English/Sinhala/Tamil layouts. Renders use labelled, deterministic fixtures with a fixed reference clock; they do not represent database inventory.

## Changes after rendered comparison

First render: four preview cards consumed inventory intended for the full-width feed; the banner action was left-aligned; initially decoded images were absent from the first capture. Corrected to two rail cards, a reserved four-card bank grid, three remaining full-width fixture cards, right-aligned actions and explicit image precaching.

Second render: rail images and compact-bank descriptions made the page too tall relative to the reference. Corrected rail width to approximately 66% of the phone, rail image ratio to 2:1, bank image ratio to 1.8:1, suppressed repeated benefit descriptions in compact previews, and moved bank benefit badges to the image's lower edge. Unique descriptive titles remain visible in every variant; full-width cards retain their title summary. Material bank/card, minimum-spend and maximum-discount fields still wrap without truncation. The final capture uses smaller visible CTA surfaces inside 44px touch targets and the sampled `#077F5B` banner green.

Remaining differences: existing food photos repeat where exact reference subjects are unavailable; platform typography differs from the prototype's Inter; accessible touch regions and visible restrictions can increase height; mockup-only business claims are replaced or omitted. The bottom directory/store/all-offers links preserve existing routes. No 100% match is claimed.

## Supported substitutions

| Reference element | Implemented behavior |
| --- | --- |
| Delivering to / estimated minutes | Actual selected area, “Offers around”, manual choice and explicit GPS flow |
| Cart with quantity | Same compact right-side footprint opens Browse stores; no fake count |
| Delivery / Dine-In / Pickup | All offers / In-store / Online; supported Delivery/Pickup remain in Filters |
| Top Rated / Free Delivery / BOGO | All offers / Ending soon / Categories / Bank Offers, backed by existing fields |
| Flash privilege / Claim Code | Actual curated banner and View offer; existing detail screen determines the supported code, directions, website or QR action |
| Claimed counts / capacity progress | Omitted; no capacity model is available |
| Today's Top Deals | Featured offers; no invented ranking |
| Registered-card eligibility / Banks Active | Actual bank names, card types, conditions and distinct-bank count in the displayed collection |
| Near You / delivery times | Approximate selected-area distance only when coordinates support it; online offers omit physical distance |
| Personalized More Deals | More deals to explore, with loaded-result limitations |

## Connections and state

The existing promotions and bank-offer services remain separate. Curated banner/hot/expiry inventory uses `fetchCuratedHomeSections` and its established cache. Discover applies selected category, fulfillment, bank and expiry constraints to collections. Resource-aware IDs deduplicate the original collections; the added Nearby projection may repeat their eligible offers as explained above. Expired/future/nonpublic offers are excluded. No missing inventory is fabricated.

Promotion/bank continuation offsets, Load more on zero loaded matches, retry, stale-response guards, area changes, guest sign-in return and API-confirmed save feedback remain. Curated and bank request failures show distinct retry messages. Category selection is available through Filters across the actual supported taxonomy, including categories absent from the loaded sample; the full directory remains linked below the feed.

## Main files

- `mobile_app/lib/src/widgets/stitch_discover_components.dart`: screen-specific theme, header, segments, search, chips, banner, expiry strip and three card variants.
- `mobile_app/lib/src/screens/home_screen.dart`: collections, curated loading, filtering, pagination and routing.
- `mobile_app/lib/src/screens/main_navigation_screen.dart`: Discover-only bottom-bar styling; independent navigators retained.
- `mobile_app/lib/src/widgets/offer_save_button.dart`: optional compact circular bookmark/heart appearance; existing save/sign-in/error flow retained.
- `mobile_app/lib/src/widgets/discover_search_hint.dart`: configurable text size/line count for the compact search bar.
- `mobile_app/tool/stitch_discover_preview_test.dart`: deterministic actual-screen renderer.
- `mobile_app/test/stitch_discover_test.dart`: collection ordering/deduplication and failure states; existing regression tests updated for the new controls.

## Validation

- Full Flutter regression suite: **78 tests passed** (`.codex-logs/stitch-match-regression-verified.log`).
- Static analysis across `lib`, `test` and the actual-screen renderer: **no issues** (`stitch-match-analysis-verified.log`).
- Actual-screen renderer and collection/error checks: **passed**, with twelve PNG captures across six light/dark/narrow/large/localized configurations (`stitch-match-render-verified.log`). The reference-match baseline before Nearby was 390 × 2514 logical pixels; the supplied reference normalized to 390px is approximately 2174px tall. The additional Nearby render is described above. The remaining height difference comes from supported conditions, fixture summaries, touch targets and retained directory links; it is not described as a pixel-perfect match.
- Main measured light-mode text contrasts: white/banner **5.00:1**, supporting gray/white **5.75:1**, primary green/pale background **5.03:1**. These do not certify every UI color pairing.
- Android **debug APK built** at `mobile_app/build/app/outputs/flutter-apk/app-debug.apk`; embedded Dart sources were checked against final workspace sources. No app deployment, merge or production record change was performed.
- The local comparison's image links all resolve. Reference and actual full-page images are displayed at equal widths for comparison.

iOS hardware/simulator, TalkBack/VoiceOver and authenticated real-service save/redemption checks require separate verification; fixture and Android debug results do not certify those journeys.


## Compact-card sizing follow-up

Discover retains separate horizontal-preview, small Nearby, bank-grid and large feed variants. Compact variants now reserve consistent line slots for title, store, genuine rating (or Not rated), approximate distance and price/saving. Optional bank conditions, expiry and previous-price lines no longer change compact-card height; full conditions remain in offer details. Large feed cards and section order are unchanged. At enlarged text the compact geometry scales with system text size and the existing one-column layout remains.

Size regression coverage compares short and long records with different optional fields in all three compact variants at normal and double text scale. The actual Flutter gallery was refreshed across light/dark, narrow and localized enlarged-text configurations. Earlier APK verification above predates this follow-up; no new device build or installation is claimed here.
