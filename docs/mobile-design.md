# DealFinder mobile redesign

The design makes local savings easy to discover: clear search, real offer photography, readable prices, and a quiet interface around the content. Implemented in Flutter using the installed Apple Design and UI UX Pro Max skills.

The additional product proposal is assessed in [mobile-redesign-gap-review.md](mobile-redesign-gap-review.md), which separates the implemented visual foundation from remaining navigation and workflow changes.

## Visual system

- Sapphire blue (`#2457E8`) identifies actions. Discount badges use white text on blue; red identifies expiry or problems.
- Cool neutral canvas (`#F5F6FA`) and white cards in light mode. Charcoal canvas (`#10131B`) and elevated dark cards (`#1B202C`) in dark mode.
- System typography replaces the previous downloaded font pairing. Headlines use 28–34 logical pixels, body text 16–17, supporting labels 12–13. Text scaling remains enabled.
- Shared rounded cards, consistent gutters, restrained borders, and native button press feedback. Sheets, dialogs, inputs, tabs, switches, and loading indicators share the theme.
- A code-drawn ticket and discovery-star brand mark scales without raster blur. Existing merchant/deal photos are cached; missing images use themed placeholders. The launcher icon remains the existing asset.

Core measured color pairs:

| Pair | Contrast |
| --- | --- |
| Light primary text / white card | 16.27:1 |
| Light secondary text / canvas | 4.97:1 |
| White label / blue primary button | 5.83:1 |
| Dark primary text / card | 14.78:1 |
| Dark secondary text / card | 8.15:1 |
| Dark action / card | 8.40:1 |

These measurements cover the listed solid token pairs, not every image-overlay composition or every legacy state color.

## Layout and navigation

Home now leads with the brand/location, greeting, headline, and search, followed by the featured offer, horizontal categories, and deal sections. The featured offer opens its detail page. Shared cards prioritize the offer title and price; expiry is shown only for short remaining durations. Countdown refreshes run once per minute instead of repainting cards every second.

The five existing destinations stay available: Home, Deals, Stores, Favorites, Profile. The bottom bar uses one selected accent, labeled controls, semantics, subtle translucency, and opaque rendering when high contrast or accessible navigation is requested. Main content receives space for the bar rather than extending underneath its hit regions. At widths of 700 logical pixels and above, navigation becomes a rail. Existing IndexedStack tab state is preserved.

Explore and Stores use calm headings and direct search/filter controls. Store cards expose profile, follow, and share actions; unknown hours and nonexistent ratings are not presented as positive status. Profile groups account information, saved items, notification settings, and existing forms. Merchant dashboard uses the same surfaces and action hierarchy.

Deal details use a cached cover image and an explicit close control in the full-screen image viewer. The toolbar avoids repeating favorite/alert controls already in the bottom action bar. Action-panel buttons stack on narrower widths and can grow with text. Recommendations reuse the shared deal card. A deal is shown as verified only when its verification metadata supports that claim.

Favorites now open the selected deal. Comparison uses a horizontally scrollable table for every selected deal, rather than only the first two, with separate accessible view/remove actions. Notifications have distinct empty and failed-loading states with retry. Supporting search, reviews, settings, merchant profiles, and creation/edit forms use the shared theme and semantic colors.

## Motion and accessibility

- Brief selection/search transitions, platform-appropriate route transitions, and restrained selection haptics.
- Custom transitions and image fades respect reduced motion. Loading skeletons stop their shimmer when animations are disabled.
- Native icon/button themes provide at least 48 logical pixel targets; small custom action buttons were enlarged.
- Light/dark and high-contrast themes follow system settings. Images, labels, price blocks, and category/carousel sizes adapt to appearance and larger text.
- New authentication, notification, search, and store-action labels were added to English, Sinhala, and Tamil localization resources. Existing copy outside the changed labels retains its previous translations.

Flutter renders the translucent bar; this is a glass-inspired treatment rather than the native iOS Liquid Glass component. Apple navigation conventions are translated for Flutter, with Android behavior retained where appropriate.

## Guidance used

- Apple `accessibility.md > Vision`: “Support larger text sizes.” Applied through enabled text scaling, readable tokens, and adaptive card/category dimensions.
- Apple `layout.md > Visual hierarchy`: “Order content by relative importance.” Search and offer information precede secondary sections.
- Apple `typography.md > Conveying hierarchy`: “Minimize the number of typefaces you use”. The shared theme uses system typography.
- Apple `color.md > Best practices`: “Avoid using the same color to mean different things.” The action accent is separate from urgency.
- Apple `materials.md > Liquid Glass`: “Use Liquid Glass effects sparingly.” Translucency is concentrated in navigation.
- Apple `buttons.md > Best practices`: “Always include a press state for a custom button.” Cards and controls use Material/InkWell interaction feedback.
- Apple tab-bar, motion, dark-mode, and cross-platform references informed destination consistency, system preferences, and Flutter translation.
- UI UX Pro Max Flutter animation guidance supported implicit transitions and bounded repaint work. Its touch, contrast, safe-area, and token-driven-theme rules guided the component pass. The search result identifying a CRM product for “deal” was discarded as unrelated; DealFinder's visual direction is a product-specific design judgment.

Reference files are under `.design-rules/references/` and `.agents/skills/ui-ux-pro-max/`.

## Verification and previews

Flutter analysis reports no issues and the Android ARM64 debug APK builds successfully. The original visual pass had ten widget tests, including compact store actions, Sinhala labels, narrow dark navigation at double text size, tablet navigation, search clearing, large-text deal cards, authentication routing, and tab-state preservation. Android phone inspection covered Home, Deals, Stores, Profile, deal details, dark mode, scrolling, and 1.6× system text size. Phone appearance/font settings used during inspection were restored.

Captured previews are in `mobile_app/design-preview/`. The final ARM64 debug APK was installed and launched on the connected Samsung phone. Its logs confirmed eight discounts and eight merchants fetched from the existing local API, with nearby search returning HTTP 200. The APK is at `mobile_app/build/app/outputs/flutter-apk/app-debug.apk`. iOS build/device testing and a release-mode performance assessment remain unverified; no store release or cloud deployment was performed.


## Discovery journey update — 2026-10-13

The navigation and guest flows now build on this visual system: Discover, Nearby, Bank Offers, Saved, Account; persistent nested tab stacks; public browsing; a reachable store directory from discovery and search; and sign-in returning to the requested offer action. Location permission is requested by Use my location, and general recommendations are labelled Popular. See [the milestone implementation and remaining acceptance work](mobile-redesign-gap-review.md#milestone-1-implementation--2026-10-13).

Apple `managing-accounts.md > Best practices` says “Delay sign-in for as long as possible.” The public discovery shell and contextual sign-in gate apply this guidance. Apple `tab-bars.md > Best practices` supports preserving each section’s navigation state; the five destination names are DealFinder product choices. UI UX Pro Max’s Flutter state/navigation search informed shared session updates and destination state retention within the existing Navigator architecture.

Current iteration checks: Flutter analysis is clean, all 13 widget tests pass, and the ARM64 Android debug APK builds and is installed on the connected Samsung phone. New device previews show Discover, the empty Bank Offers destination, and an offer retained after switching tabs. Live authentication/registration, redemption, iPhone, and release acceptance checks remain outstanding.


## Stitch Discover visual pass

Discover now follows the supplied photo/card reference with sapphire actions: compact area/notification/account header, category chips before the feature, manual feature paging, nearby cards, a data-backed bank spotlight, and compact expiry rows. Shared card save controls and details update after accepted promotion API writes; failures preserve state. Card conditions grow with larger text, and appearance follows the existing semantic themes. See [the implementation record and screenshots](stitch-discover-reference.md#implemented-discover-screen). Current validation: clean analysis, 16 passing tests, successful ARM64 debug build, and Samsung light/dark inspection.


## Stitch Nearby pass

Nearby now shares a map and draggable results sheet, with persisted area selection, explicit map-center search, radius/category/store-hours filters, clustered markers, and synchronized selected cards. Sapphire controls and theme surfaces retain the existing visual identity. The results panel offers buttons as alternatives to dragging. Manual areas feed Discover's distance calculations as well. See [the Nearby review and evidence](stitch-nearby-reference.md). Validation includes 24 passing tests, successful Android builds, and Samsung browsing with GPS permission denied. iPhone, reduced-accuracy location, offline journeys, and release performance still need their full checks.
