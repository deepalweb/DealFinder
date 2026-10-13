# Google Stitch reference: Discover

The user supplied a Discover mockup as a reference after the Milestone 1 implementation. This document captures the reference and the subsequent Flutter implementation. The initial reference collection did not change screens; the implementation status is recorded below.

## Layout to carry forward

1. Compact header: selected area, notifications, and an Account shortcut.
2. Clear Discover title and prominent search for offers, stores, and categories.
3. Horizontal category chips **before** the featured offer.
4. Featured card: large photo, merchant, offer title, key eligibility/expiry conditions, and an independently tappable save control.
5. Near You: horizontally browsable cards with a See all entry leading to Nearby. Show distance, price, fulfillment, and expiry together when known.
6. Bank spotlight: a small bank-offer preview that links into Bank Offers with the selected bank filter.
7. Ending Soon: compact offer rows with a relevant condition and a clearly named action.
8. Persistent five-destination navigation.

The reference's restrained surfaces, readable offer title, consistent rounded cards, and photo-first layout fit the existing redesign. Its category-before-feature order and compact header would bring browsing controls closer to the top than the current large greeting/hero. Keep Browse stores reachable; the screenshot does not replace that accepted requirement.

## Adaptations for DealFinder

| Reference element | DealFinder treatment |
| --- | --- |
| Emerald actions, selected chips, and tabs | Use the accepted sapphire identity and existing semantic theme tokens. |
| Bank Perks / Bookmarks tab names | Retain Discover, Nearby, Bank Offers, Saved, Account. |
| Global Verified label beside Discover | Omit unless its scope can be clearly explained. Verification belongs to the individual merchant/offer with real supporting status. |
| Linked Card Eligibility | Use bank/card preferences or Browse bank offers wording until an actual linking/eligibility capability exists. Do not imply that choosing a bank confirms eligibility. |
| Claim Now | Match the actual supported action: View offer, Show code, Get QR, or Visit website. Reserve Claim for a working claim operation. |
| Tiny bookmark/microphone controls | Use labelled semantics, visible feedback, and at least 48 logical pixel hit regions on Android / 44 pt on iOS. Show a microphone only with a functioning voice-search flow. |
| Fixed compact card dimensions | Let conditions and titles wrap and cards grow for large text and Sinhala/Tamil. Keep the next card partially visible as a browsing cue without clipping the active card's essential information. |
| Carousel dots | Use manual paging and accessible page indicators. Additional rotation needs user control and reduced-motion handling. |

## Data and workflow requirements

- Existing mobile promotion fields include bank name, card types, minimum spend, start/end dates, trust status, delivery capability, and coordinates/distance. These can support selected condition labels when present, subject to actual API values and their meaning.
- Existing fulfillment fields include fulfillment type, visit, delivery, and pickup availability. Map these to their documented meaning before displaying badges; do not infer dine-in from visit availability or takeaway from delivery being unavailable. Explicit dine-in support may require a more specific API field.
- Valid Fri–Sun needs explicit supported day restrictions. Do not invent a weekday badge from an arbitrary date range or an ambiguous description.
- All (42), See all (18), bank venue counts, discount amounts, and “Updated 10m ago” must be calculated from the relevant real result set and fetch timestamp. Hide unsupported counts/freshness labels.
- Near You must reflect GPS or the selected area. When no area is available, offer Choose area rather than presenting unrelated results as nearby. Consumer area selection remains Milestone 2 work.
- Saved state must be consistent between featured cards, nearby cards, details, and Saved. Guest save uses the existing sign-in return flow. Failed requests must not be reported as accepted saves.
- The previously inspected local public bank-offers endpoint had no published offers. Present a useful empty state until real data exists; example banks and discounts in this reference are visual examples, not application content.
- Ending Soon needs real expiry data and correct timezone handling. “Expires midnight tonight” and urgency labels should appear only when justified by the offer's actual expiry precision.

## Review basis

Apple `layout.md > Visual hierarchy` says “Order content by relative importance.” This supports putting search and category refinement ahead of secondary sections; the exact section order remains a product choice. Apple `accessibility.md > Vision` says “Support larger text sizes.” Apple `buttons.md > Best practices` specifies a hit region of at least 44×44 pt. Apply these principles through Flutter while respecting Android conventions.

UI UX Pro Max's initial eligibility/hierarchy search did not identify a specific mobile offer-card pattern. Its narrower Font Size Scale result applies across platforms and supports consistent type hierarchy. The offer-card composition and bank spotlight recommendations above are product judgments based on the supplied reference, not claims that a skill mandates them.

This reference informs the next Discover visual pass and Milestone 3 offer clarity. It does not establish completed eligibility, card linking, voice search, redemption, or release validation.


## Implemented Discover screen

- Compact area header with notifications and an Account shortcut; Discover title and search lead the page.
- Real category chips precede the featured card; Browse stores remains reachable.
- Photo cards use readable theme surfaces, actual merchant verification, price, distance, supported fulfillment, bank/card conditions, minimum spend, and Colombo-date expiry labels.
- Featured offers page manually with previous/next and accessible page controls. No automatic rotation is used. Curated banner management remains respected.
- Nearby shows location-derived in-store offers within 5 km rather than unrelated fallback promotions. With no location, it explains the requirement and offers the existing area entry or explicit Use my location.
- Bank spotlight uses returned bank names/discounts and opens a filtered route in Bank Offers. With no data, it shows an honest empty state.
- Ending Soon uses upcoming expiry dates in Colombo and compact photo rows with View offer actions.
- General Popular recommendations remain available below these sections; personalized wording requires a supported user-specific reason.
- Save controls use the existing guest sign-in return. Normal promotion writes update local snapshots after API acceptance; failures keep state unchanged. Cards and details observe membership changes. Platform bank offers remain device-local snapshots because the current server favorites API accepts merchant promotions; that limitation is communicated after saving.
- New interface copy is included in English, Sinhala, and Tamil. Cards grow with their text rather than relying on fixed content heights. Existing category-name translations still need the full language audit.

The existing five-tab navigation, sapphire branding, merchant editor, and backend schema remain. Consumer area selection, bank-card preference management, voice search, explicit weekday restrictions, and card linking are still separate work. No sample bank eligibility/count/freshness content was invented.


### Validation

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub`: all 16 tests pass. New checks cover rejected saves/removals preserving state, accepted writes persisting snapshots, and a featured card retaining distance/conditions at 375 px with double text size in dark mode.
- ARM64 Android debug APK builds successfully. Samsung inspection covered the category-first header, featured photo/conditions, nearby rails, bank empty state, Ending Soon rows, and light/dark appearance. Temporary device appearance changes were restored.
- Previews: `mobile_app/design-preview/stitch-discover-light.png`, `stitch-discover-nearby.png`, `stitch-discover-sections.png`, and `stitch-discover-dark.png`.
- iPhone/release checks, screen-reader audits, live guest registration/sign-in and redemption remain unverified. Published bank data is needed to exercise real bank preview/filter journeys.
