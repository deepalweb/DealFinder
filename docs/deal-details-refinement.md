# Deal details refinement

## Review

The page already supported a real gallery, merchant links, eligibility, reviews and destination-specific actions. Source review found a summary led by price ahead of the offer title, rating information buried below, repeated primary destinations, a directions fallback on online offers, mismatched date formatting and hardcoded dark text in action headings. Render inspection also confirmed that the inherited white app-bar title was unreadable on the light surface. These were addressed.

This refinement uses the current accepted marketplace palette locally, preserving the global theme. It groups title, merchant, genuine rating, approximate distance and saving; adds a direct save toolbar control for supported promotions; retains full eligibility immediately after the summary; and leaves the primary destination in the safe-area footer. Alternative directions remain available for offers with both visiting and external ordering. Content is limited to 680px on wide screens. Action headings wrap and Full details has a 48px minimum tap area. Online offers do not show physical distance. Both validity displays use the Sri Lanka calendar and current locale.

Apple guidance: `layout.md › Visual hierarchy`, “Order content by relative importance”; `layout.md › Adaptability`, “Be prepared for text-size changes”; `buttons.md` and `toolbars.md` informed labelled actions and toolbar placement. Flutter translation comes from `cross-platform.md`; UI UX Pro Max's Flutter LayoutBuilder guidance informed adaptive layout checks. The exact DealFinder hierarchy and palette are product decisions.

## Preview and validation

[Actual Flutter previews](deal-details-refinement/index.html). Records and media are labelled fixtures, not live inventory. Five configurations cover light/dark 390px, dark 320px double text, enlarged Sinhala and Tamil; both summary and scrolled conditions are exported. Tests cover gallery navigation, visible restrictions, standalone bank resource separation, summary order, online distance suppression, footer action and narrow enlarged-text layout.

No live database writes, deployment or device installation were performed. Native share/directions, authenticated saves, merchant navigation with live data, QR/redemption and screen readers still require service/device verification. Historical APK results do not certify this change.

Final checks: **85 regression tests passed**, targeted source/test/renderer analysis found **no issues**, and the five-configuration renderer passed. No Android or iOS build was run for this refinement.
