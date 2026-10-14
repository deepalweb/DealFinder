# Stitch Account prototype review

Source: user-supplied HTML attachment reviewed on 14 October 2026. This was a
source review, not a browser render or interaction test. The accompanying
user review is substantially consistent with the HTML.

## Adopt

Retain grouped settings, rounded surfaces, clear identity and editing controls,
and the existing Discover/Nearby/Bank Offers/Saved/Account navigation. Keep
DealFinder's sapphire identity. Saved content remains primarily in Saved;
Account may offer compact shortcuts. Merchant workspace access is role-specific.

## Fix before reusing the HTML

- Header contains 44 px of simulated status-bar content plus 56 px of navigation,
  while main reserves 56 px. The discrepancy is 44 px plus the header safe-area
  inset. Remove simulated device chrome and size offsets from the real header.
- Allow browser zoom; remove forced 884 px minimum height and hidden scrollbars.
- Replace placeholder links and decorative settings rows with semantic,
  keyboard-accessible controls and real actions. Increase compact hit areas.
- Remove hardcoded membership tiers, saver rankings, savings, voucher counts,
  verification, card numbers, and storage/security claims.
- Footer version uses #BDC9C1 on #FCF8FB: computed contrast is approximately
  1.62:1, below the 4.5:1 normal-text target. Use a readable semantic text color.
- Consolidate duplicated icon imports and height rules; permit long labels to
  wrap. Preserve visible focus indicators and appropriate image alternatives.

## Distinguish existing capability from proposed features

- Mobile already supports semantic light/dark themes and follows
  `ThemeMode.system`. An in-app appearance override is optional product scope.
- Bank/card offer filtering exists; persistent personal bank/card preferences
  are not implemented. Proposed preferences should store selection metadata,
  without implying bank linking or guaranteed eligibility.
- Redemption creation/redeeming and merchant QR scanning exist. A consolidated
  personal redemption/review history and trustworthy account savings totals
  still need their own data and workflow verification.
- User deletion exists as an admin-only endpoint; it is not self-service account
  deletion. Provide a real user-facing deletion workflow before advertising it.
- Location/radius browsing exists, but the prototype's “5 km auto-alert” must not
  equate browsing radius with notification subscription settings.
- Current mobile source version is 1.0.2+3; the prototype's 2.4.1 (Build 198) is
  placeholder content. Display installed build metadata when adding this footer.

## Design guidance

Apple `settings.md` → Best practices advises minimizing settings and respecting
systemwide preferences; Task-specific options supports keeping area/radius
controls in Nearby. `managing-accounts.md` → Deleting accounts supports an
accessible, working deletion path. Account's current Flutter redesign provides
the base layout; the HTML should inform refinement rather than introduce
unsupported loyalty, payment, analytics, or security features.

## Acceptance recheck

The existing Flutter screen follows the sapphire theme, system dark mode, and
grouped settings direction. The HTML's fixed-header defect is not present in
the Flutter Scaffold/AppBar structure. Unsupported loyalty/payment/activity
claims and consumer deletion controls are not exposed in the Flutter screen.

A new integration check found that system Back from Account editing did not
restore the overview inside the five-tab shell. The shell now calls `maybePop`
instead of `pop`, respecting the Account page's PopScope. All nine targeted
profile/navigation/discovery tests passed after the correction. A permanent
regression test is in `mobile_app/test/account_navigation_test.dart`.

The acceptance criteria are not yet fully met:

- Favorite removal catches API errors but still removes the local record and
  displays success. Unfollow has no local error recovery around its asynchronous
  operation, while dismissal happens before the request completes.
- Favorite and following load failures can display zero counts as though they
  were verified. Favorite loading also creates its own ApiService rather than
  using the screen's injected service, limiting the existing test coverage.
- Profile/photo update code retains local-only success fallbacks when session
  credentials are absent. The main Account gate normally prevents that entry,
  but these paths should not imply an accepted server update.
- Dynamic installed-version metadata is not displayed yet.
- Several security validation/unfollow messages remain English-only.
- The original HTML attachment has been reviewed, not corrected or integrated;
  its header, zoom, contrast, and placeholder-action findings still apply.

Passing widget tests do not establish live upload/submission behavior or native
screen-reader behavior. This recheck did not rebuild/reinstall the APK after
the Back correction.
