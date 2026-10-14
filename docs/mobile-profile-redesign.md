# Account and merchant profile redesign

The mobile profiles now follow DealFinder's existing sapphire palette, semantic
light/dark colors, rounded surfaces, and platform typography.

## Account

The Account landing page presents the user's identity, saved/following counts,
and grouped links to saved content, notification settings, security, and language.
Profile editing is a focused page with a visible Back action. Merchant accounts
retain access to the merchant workspace. The parent five-tab navigation remains.

Profile and password saves disable repeated submissions and show a saving state.
A failed profile save retains the entered name and keeps the previously accepted
profile in storage. A background refresh avoids overwriting a name being edited.
Photo changes display after persistence succeeds. English, Sinhala, and Tamil
labels cover the new controls. Account transitions respect reduced motion.

## Merchant/store

The public store page leads with store identity, supported fulfillment modes,
published opening status, available offer counts, and Follow/Directions/Order
actions. Only applicable actions appear. It provides Offers, About, and Reviews
sections; the existing rating, review, follow, and report APIs remain connected.

Offers reuse the discovery cards, with save controls, eligibility conditions,
expiry information, and working offer-detail navigation. Active and expired
offers are separate; scheduled offers that have not started are excluded from
the active section. About contains contact links, today's hours, social links,
and the Google Maps location. Unknown hours do not claim that a store is closed.
Opening status uses the shared Colombo-time calculation, including overnight
schedules. Sharing links to the store page, rather than only its website.

## Design references

- Apple `layout.md` → Visual hierarchy: group related items and progressively
  disclose secondary content. Account editing and store reviews move out of the
  initial overview so the first view supports the main task.
- Apple `managing-accounts.md` → Best practices: public store browsing remains
  available; protected actions use the existing sign-in gate.
- Apple `accessibility.md` → Vision, and `cross-platform.md`: scalable text,
  semantic colors, labeled controls, and standard Back behavior.
- UI UX Pro Max Flutter search: settings/list accessibility; Semantics and
  linear layouts. Its native delivery checklist guided large-text and dark checks.

## Validation

- Flutter analysis: clean.
- Full Flutter suite: 29 tests passed, including five new profile tests.
- Tests cover rejected-save draft retention, merchant retry, active/expired
  selection, future-offer exclusion, unknown opening hours, and narrow dark
  screens at double text size, plus 375 px small-phone and 844 px landscape layouts.
- Android ARM64 debug APK: built successfully and installed on the connected phone.
- Light/dark previews use synthetic user/store records and SDK Roboto fonts.
  They are isolated widget renders, not screenshots of live user accounts.
- Live account editing, native camera/gallery uploads, rating/review submission,
  VoiceOver/TalkBack, iPhone, and release builds still need device verification.

Account deletion remains an existing product/API gap; this redesign does not add
a control without a supported deletion workflow.
