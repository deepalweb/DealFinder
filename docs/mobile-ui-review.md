# Mobile UI Review — 2026-10-16

**Scope:** the Flutter app (iOS and Android): Discover, Nearby, Stores (directory and store page), offer details and Account.

**Basis:** Apple's Human Interface Guidelines (the `apple-design` skill), with Material conventions where they differ.

**Evidence:**
- Screenshots regenerated from the current code (`mobile_app/tool/*_preview_test.dart`) in light, dark, large-text, 320 px, Sinhala and Tamil versions.
- Contrast calculated from the theme's hex values.
- The Account screen was reviewed from code; it has no preview script.

**Overall:** Critical issues (C1). The screens themselves rate Good. The design's strength is honesty: conditions, minimum spend and approximate distance are shown up front. Its main weakness is two competing color identities.

## Findings and status

| ID | Sev | Finding | Fix | Status |
|---|---|---|---|---|
| C1 | Critical | No in-app account deletion. Required by `managing-accounts.md › Deleting accounts` and App Store guideline 5.1.1(v). | `DELETE /api/users/me` + Account screen button with confirmation + web profile button | **Done** (`feat/account-deletion`) |
| H1 | High | Two brand themes. Blue `#2457E8` (`AppTheme`) vs green `#007B59` (`stitchDiscoverTheme` on Discover, Nearby and offer details). The selected tab and surfaces change color between tabs. | One theme in `AppTheme` (green); delete `stitchDiscoverTheme` | Next |
| H2 | High | Discover has three control rows (segmented control, search with filter button, chip row), with "All offers" in two of them | Search, plus one chip row (In store/Online as chips); everything else in the filter sheet | Open |
| H3 | High | Header buttons duplicate tabs: the store button on Discover, the account button on Nearby | Remove both; keep only the bell | Open |
| M1 | Medium | The tab bar's height, background and indicator differ between tabs | One `NavigationBarTheme` (comes with H1) | Next |
| M2 | Medium | Save is a heart in one place and a bookmark elsewhere | Always the bookmark, to match the Saved tab | Open |
| M3 | Medium | The store page switches views with checkmark chips | `SegmentedButton` / `TabBar` for Offers/About/Reviews | Open |
| M4 | Medium | "Ends in 26395d 0h" | Countdown under 48 h, otherwise the date | Open |
| M5 | Medium | Mixed Title Case and sentence case | Sentence case everywhere | Open |
| M6 | Medium | System-speak: "Matching offers loaded so far", "2 visible • 0 following • 2 total stores", "Not rated" on every row, "1 Offers", "Deal details" vs "offer" | Remove or rewrite; use ICU plurals; "Offer details" | Open |
| L1 | Low | Store cards have three actions | Remove "View store" (the card opens the store) | Open |
| L2 | Low | Offer cards on a store page are titled with the store name | Use the offer title | Open |
| L3 | Low | The unused `textTertiary #737D90` token fails contrast (3.84:1) | Delete it | Open |

## Platform notes

- **iOS sign-in:** Google sign-in isn't configured for iOS (`Info.plist` has no Google URL scheme). App Store guideline 4.8 requires Sign in with Apple when an app offers third-party login.
- **Icons:** Cupertino and Material icons are mixed in the tab bar; use one set.
- **iOS swipe-back:** verify it works on a device.

## Keep

- Contrast passes everywhere:

  | Text | Contrast |
  |---|---|
  | Body | 5.3–5.7:1 |
  | Brand accents | 5.0–5.8:1 |
  | Dark mode | 8–17:1 |

- No clamping of system text size, and no text under 11 pt.
- Tap targets are 48×48 with labels.
- Large text and Sinhala/Tamil wrap without being cut off.
- The "Before you use this offer" box and approximate-distance labelling.
- Nearby's map with a draggable bottom sheet, and the fixed "Get directions" button on offer details.
- A `NavigationRail` replaces the bottom bar at ≥700 pt.
