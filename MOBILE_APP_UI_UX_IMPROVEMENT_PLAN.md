# Mobile App UI/UX Improvement Tracker

## Purpose

Use this file as the working implementation tracker for mobile app UI/UX improvements.

How to use it:

- mark completed items with `[x]`
- keep in-progress items as `[ ]` until fully verified
- add file references or notes under each section as work lands
- treat `Before Launch` items as highest priority

## Success Criteria

- [ ] Home is easy to scan on a small phone
- [ ] Search and Explore feel like one system
- [ ] Stores and merchants feel trustworthy and interactive
- [ ] Urgency and expiry behavior are consistent everywhere
- [ ] Empty and failure states always offer a next step
- [ ] The app feels visually cohesive across screens
- [ ] Accessibility basics are covered

---

## Before Launch

### P0: Core UX Stability

- [ ] Unify deal search and Explore interaction language
- [ ] Remove dead-end empty states across core discovery flows
- [ ] Standardize expiry and countdown behavior across all deal surfaces
- [ ] Improve readability of home callouts and section support UI on small screens
- [ ] Strengthen merchant trust and store discovery feedback
- [ ] Complete a mobile accessibility basics pass

### P0: Must-Verify User Journeys

- [ ] Home to deal discovery feels clear and intentional
- [ ] Search entry to results flow feels obvious and responsive
- [ ] Explore browsing supports meaningful filtering and reset behavior
- [ ] Stores browsing has visible active filters and clean recovery paths
- [ ] Merchant profiles feel complete enough to trust
- [ ] Deal expiry messaging matches actual deal logic

---

## Sri Lanka Optimization

Use this section to guide decisions that make the app feel truly useful for Sri Lankan users.

### Winning Formula

Good deals + accurate distance + strong trust cues + clear urgency + simple UX

### Highest-Value Local Principles

1. Trust comes before polish
   - users will forgive simple visuals faster than fake, stale, or unclear deals

2. Location must feel practical
   - “near me” is more useful when expressed as distance, not only maps

3. Urgency must be explicit
   - `Ending today` is clearer than a generic timer for many users

4. Social proof only works if it is real
   - fake activity numbers will damage trust quickly

### Sri Lanka Priority Ideas

#### 1. `Ending today` highlight

Priority: `P0`

- [x] Add an explicit `Ending today` badge for deals that expire before local midnight
- [x] Keep `Ends in Xh Ym` for tighter urgency windows where needed
- [x] Avoid vague urgency wording when a clearer label is available

Recommended placement:

- home `Ending Soon`
- deal cards
- deal detail header
- merchant active deals list

Why this matters:

- easy to understand at a glance
- aligns with how many users browse offers quickly
- reinforces trust when the label matches actual logic

#### 2. `Verified deal` badge

Priority: `P0`

- [ ] Define what “verified” means before showing the badge
- [ ] Only show the badge when a deal has actually passed that rule
- [ ] Add supporting micro-copy where useful
  - `Verified today`
  - `Confirmed by merchant`
  - `Recently checked`

Recommended placement:

- deal card top badge area
- deal detail near title / merchant info
- merchant profile active deals

Why this matters:

- trust is a major adoption factor in Sri Lanka
- reduces fear of fake or stale offers

Implementation warning:

- never show this badge without a real backend or business rule
- if every deal is “verified,” the label loses all value

#### 3. Distance label like `500m away`

Priority: `P1`

- [ ] Show a clear distance label when the location signal is reliable
- [ ] Prefer:
  - `350m away`
  - `1.2km away`
- [ ] Hide distance when the app cannot calculate it reliably

Recommended placement:

- nearby deal cards
- home `Near You`
- search results for location-aware browsing
- deal detail header or merchant section when available

Why this matters:

- nearby relevance is important for real-world usage
- easier to evaluate than map-first UI

Implementation warning:

- inaccurate distance hurts trust more than missing distance

#### 4. Social proof like `Used by 20 people today`

Priority: `P2 unless real tracking exists`

- [ ] Only implement if the number comes from real event data
- [ ] Prefer measurable wording such as:
  - `20 people viewed this today`
  - `12 people saved this today`
  - `8 shoppers opened directions today`
- [ ] Avoid vague or inflated usage claims

Recommended placement:

- deal detail page
- optionally merchant profile highlights

Why this matters:

- social proof can improve confidence
- but fake numbers will create distrust quickly

Implementation warning:

- do not ship this until event data is dependable

### Recommended Implementation Order

- [x] 1. Ship `Ending today` highlight
- [ ] 2. Introduce a real `Verified deal` model and badge
- [ ] 3. Improve distance labels where location quality is strong
- [ ] 4. Add social proof only after telemetry is reliable

### Suggested Product Rules

- [ ] Never show trust badges without real rules
- [ ] Never show distance when the location signal is weak
- [ ] Never show social proof numbers unless they are real and recent
- [ ] Prefer simple, explicit wording over clever wording

### Screen Targets

- `mobile_app/lib/src/screens/home_screen.dart`
- `mobile_app/lib/src/screens/deal_detail_screen.dart`
- `mobile_app/lib/src/screens/merchant_profile_screen.dart`
- `mobile_app/lib/src/widgets/modern_deal_card.dart`
- `mobile_app/lib/src/widgets/deal_card.dart`
- `mobile_app/lib/src/screens/nearby_deals_screen.dart`
- backend/event sources as needed for verification and usage counts

---

## Quick Wins

### Home Readability

- [x] Clean up compressed section callouts on narrow screens
- [x] Standardize title, badge, icon, and description alignment in home callouts
- [x] Reduce repeated urgency noise where a section-level message works better
- [ ] Make each home section visually distinct enough to scan quickly

Files:

- `mobile_app/lib/src/screens/home_screen.dart`
- `mobile_app/lib/src/widgets/section_header.dart`
- `mobile_app/lib/src/widgets/modern_deal_card.dart`
- `mobile_app/lib/src/widgets/flash_sale_card.dart`

### Empty / Error / Loading States

- [ ] Standardize empty-state structure: icon, title, message, next actions
- [ ] Standardize error-state structure: explanation, retry, fallback action
- [ ] Ensure all key discovery screens have explicit retry or clear actions
- [ ] Replace any silent failure-to-empty behavior with visible feedback

Files:

- `mobile_app/lib/src/screens/home_screen.dart`
- `mobile_app/lib/src/screens/search_screen.dart`
- `mobile_app/lib/src/screens/stores_screen.dart`
- `mobile_app/lib/src/screens/merchant_profile_screen.dart`
- `mobile_app/lib/src/screens/all_deals_screen.dart`

### Copy and Action Clarity

- [x] Make follow/unfollow copy more human and specific
- [ ] Improve no-results and retry copy tone
- [ ] Align sort and filter labels across search and explore
- [ ] Replace vague expiry wording with clearer user-facing labels

Files:

- `mobile_app/lib/src/screens/home_screen.dart`
- `mobile_app/lib/src/screens/search_screen.dart`
- `mobile_app/lib/src/screens/stores_screen.dart`
- `mobile_app/lib/src/screens/all_deals_screen.dart`

### Accessibility Basics

- [ ] Audit major buttons for touch target size
- [ ] Improve contrast on urgency badges and chips
- [ ] Add semantics labels for follow, share, directions, and key actions
- [ ] Review readability of small supporting text on mobile widths

Files:

- `mobile_app/lib/src/screens/home_screen.dart`
- `mobile_app/lib/src/screens/stores_screen.dart`
- `mobile_app/lib/src/screens/merchant_profile_screen.dart`
- `mobile_app/lib/src/screens/deal_detail_screen.dart`

---

## Medium Redesign Tasks

### 1. Search and Explore Unification

Goal: one obvious deal search path, one consistent filtering model.

- [ ] Replace the current split between search entry, results, and hidden advanced search with one primary flow
- [ ] Add keyword search to `AllDealsScreen`
- [ ] Reuse the same filter language, sort labels, and clear-all behavior in search and Explore
- [ ] Surface active filter chips above results in all deal-browsing screens
- [ ] Remove placeholder or incomplete filter experiences

Files:

- `mobile_app/lib/src/screens/search_screen.dart`
- `mobile_app/lib/src/screens/advanced_search_screen.dart`
- `mobile_app/lib/src/screens/all_deals_screen.dart`
- `mobile_app/lib/src/screens/deals_list_screen.dart`

### 2. Shared Search / Filter State

Goal: stop duplicating filter logic across screens.

- [ ] Create a shared `DealSearchFilters` model
- [ ] Create a shared controller/notifier for deal search state
- [ ] Centralize filter serialization, active filter count, chip building, and reset logic
- [ ] Make screens consume shared state instead of reimplementing logic

Files:

- `mobile_app/lib/src/services/search_service.dart`
- `mobile_app/lib/src/services/search_matcher.dart`
- new shared state files as needed

### 3. Backend-First Search

Goal: improve performance, relevance, and scalability.

- [ ] Use backend suggestions first
- [ ] Use backend deal search first
- [ ] Keep local fallback for offline or degraded modes
- [ ] Reconcile category normalization with backend taxonomy
- [ ] Make failures visible instead of silently returning empty lists

Files:

- `mobile_app/lib/src/services/api_service.dart`
- `mobile_app/lib/src/services/search_service.dart`
- `mobile_app/lib/src/services/search_matcher.dart`

### 4. Home Discovery System

Goal: make home a stronger discovery surface.

- [ ] Ensure each section has a distinct role and supporting presentation
- [ ] Improve section callouts for readability and consistency
- [ ] Strengthen contextual `See All` flows with context memory
- [ ] Keep urgency concentrated in the most useful place
- [ ] Audit section density on small screens

Files:

- `mobile_app/lib/src/screens/home_screen.dart`
- `mobile_app/lib/src/screens/all_deals_screen.dart`
- `mobile_app/lib/src/screens/nearby_deals_screen.dart`

### 5. Stores Discovery Improvements

Goal: make store browsing feel easy to control and rewarding to use.

- [ ] Keep active filters visible when set
- [ ] Provide one-tap filter removal and clear-all
- [ ] Improve follow-state persistence and feedback
- [ ] Improve empty/error recovery actions
- [ ] Keep content hierarchy simple and consistent

Files:

- `mobile_app/lib/src/screens/stores_screen.dart`
- `mobile_app/lib/src/widgets/merchant_card.dart`
- `mobile_app/lib/src/services/merchant_following_manager.dart`

### 6. Merchant Trust and Profile UX

Goal: make merchants feel credible and complete.

- [ ] Add stronger merchant trust cues where data exists
- [ ] Keep active/expired tabs and counts clear
- [ ] Improve merchant action hierarchy
- [ ] Align expiry messaging with deal surfaces
- [ ] Improve tab-level empty states

Files:

- `mobile_app/lib/src/screens/merchant_profile_screen.dart`
- `mobile_app/lib/src/screens/deal_detail_screen.dart`

---

## Urgency and Expiry System

Goal: make time-sensitive deals feel consistent and trustworthy.

- [x] Define explicit urgency tiers
- [x] Standardize timezone and parsing behavior
- [x] Standardize end-of-day semantics for date-only expiry selection
- [x] Align `Ending Soon` labels with actual logic
- [ ] Standardize countdown wording across home, cards, detail, and merchant screens
- [ ] Decide where section-level timers are better than card-level timers

Files:

- `mobile_app/lib/src/models/promotion.dart`
- `mobile_app/lib/src/screens/home_screen.dart`
- `mobile_app/lib/src/screens/deal_detail_screen.dart`
- `mobile_app/lib/src/widgets/modern_deal_card.dart`
- `mobile_app/lib/src/widgets/deal_card.dart`
- `mobile_app/lib/src/screens/merchant_profile_screen.dart`
- `mobile_app/lib/src/screens/create_promotion_screen.dart`

---

## Design System Pass

Goal: make the app feel like one product instead of several separate screens.

### Layout and Spacing

- [ ] Standardize section spacing
- [ ] Standardize chip and badge spacing
- [ ] Standardize card padding and internal rhythm
- [ ] Standardize title/subtitle spacing patterns

### Reusable Patterns

- [ ] Create a repeatable pattern for section callouts
- [ ] Create a repeatable pattern for active filter summaries
- [ ] Create a repeatable pattern for urgency badges
- [ ] Create a repeatable pattern for empty/error states
- [ ] Create a repeatable pattern for stat pills and action rows

### Copy and Visual Consistency

- [ ] Standardize action label tone
- [ ] Standardize recovery-state tone
- [ ] Standardize chip and badge severity colors
- [ ] Standardize supporting text sizing rules

Files:

- `mobile_app/lib/src/screens/home_screen.dart`
- `mobile_app/lib/src/screens/search_screen.dart`
- `mobile_app/lib/src/screens/stores_screen.dart`
- `mobile_app/lib/src/screens/merchant_profile_screen.dart`
- shared widgets as created

---

## Motion and Feedback

Goal: make the app feel polished without adding noise.

- [ ] Add consistent screen-to-detail motion for deals
- [ ] Add consistent screen-to-profile motion for merchants
- [ ] Add consistent feedback for follow, filter, and tab switching
- [ ] Reduce sudden layout shifts during loading and refresh
- [ ] Use subtle transitions for success states instead of relying only on snackbars

Files:

- `mobile_app/lib/src/screens/home_screen.dart`
- `mobile_app/lib/src/screens/stores_screen.dart`
- `mobile_app/lib/src/screens/merchant_profile_screen.dart`
- `mobile_app/lib/src/screens/deal_detail_screen.dart`

---

## Suggested Sprint Order

### Sprint 1: Launch-Critical UX

- [ ] Stabilize expiry and countdown behavior
- [ ] Finish empty/error/loading improvements
- [ ] Improve home readability and section clarity
- [ ] Align store discovery feedback

### Sprint 1 Execution Checklist

Use this as the concrete file-by-file action list for the current sprint.

#### A. Expiry and Countdown Consistency

- [x] Normalize promotion date parsing to local time
  File: `mobile_app/lib/src/models/promotion.dart`
- [x] Save date-only expiry selections as end-of-day values
  File: `mobile_app/lib/src/screens/create_promotion_screen.dart`
- [x] Align home `Ending Soon` membership with actual date logic
  File: `mobile_app/lib/src/screens/home_screen.dart`
- [x] Move `Ending Soon` urgency from per-card noise to section-level emphasis
  File: `mobile_app/lib/src/screens/home_screen.dart`
- [x] Standardize countdown wording between detail, merchant, and card surfaces
  Files:
  `mobile_app/lib/src/screens/deal_detail_screen.dart`
  `mobile_app/lib/src/screens/merchant_profile_screen.dart`
  `mobile_app/lib/src/widgets/deal_card.dart`
  `mobile_app/lib/src/widgets/modern_deal_card.dart`
- [x] Define and document final urgency tiers in shared helper logic
  Files:
  `mobile_app/lib/src/screens/home_screen.dart`
  `mobile_app/lib/src/screens/deal_detail_screen.dart`

#### B. Empty / Error / Loading State Cleanup

- [x] Improve home empty state with clear next actions
  File: `mobile_app/lib/src/screens/home_screen.dart`
- [x] Improve stores empty and error recovery actions
  File: `mobile_app/lib/src/screens/stores_screen.dart`
- [x] Improve search results empty and failure states
  File: `mobile_app/lib/src/screens/search_screen.dart`
- [x] Verify retry / clear / browse actions use consistent language
  Files:
  `mobile_app/lib/src/screens/home_screen.dart`
  `mobile_app/lib/src/screens/search_screen.dart`
  `mobile_app/lib/src/screens/stores_screen.dart`
  `mobile_app/lib/src/screens/all_deals_screen.dart`
- [x] Improve `AllDealsScreen` zero-results recovery state
  File: `mobile_app/lib/src/screens/all_deals_screen.dart`

#### C. Home Readability and Section Clarity

- [x] Improve section callout readability on small screens
  File: `mobile_app/lib/src/screens/home_screen.dart`
- [x] Make `Ending Soon` heading area more intentional
  File: `mobile_app/lib/src/screens/home_screen.dart`
- [x] Audit `Flash Sales`, `New This Week`, and `Near You` for final visual balance
  File: `mobile_app/lib/src/screens/home_screen.dart`
- [x] Review title and badge wrapping behavior on narrow Android devices
  File: `mobile_app/lib/src/screens/home_screen.dart`

#### D. Store Discovery Feedback

- [x] Keep active store filters visible with one-tap removal
  File: `mobile_app/lib/src/screens/stores_screen.dart`
- [x] Strengthen follow-state micro feedback
  Files:
  `mobile_app/lib/src/screens/stores_screen.dart`
  `mobile_app/lib/src/widgets/merchant_card.dart`
- [x] Review follow copy and failure feedback for consistency with merchant profile
  Files:
  `mobile_app/lib/src/screens/stores_screen.dart`
  `mobile_app/lib/src/screens/merchant_profile_screen.dart`

#### E. Sprint 1 Accessibility Sweep

- [x] Add semantics labels to follow, share, directions, and search actions
  Files:
  `mobile_app/lib/src/widgets/merchant_card.dart`
  `mobile_app/lib/src/screens/deal_detail_screen.dart`
  `mobile_app/lib/src/screens/home_screen.dart`
  `mobile_app/lib/src/screens/search_screen.dart`
- [ ] Review urgency badge contrast and small supporting text contrast
  Files:
  `mobile_app/lib/src/screens/home_screen.dart`
  `mobile_app/lib/src/widgets/deal_card.dart`
  `mobile_app/lib/src/screens/deal_detail_screen.dart`

#### Sprint 1 Acceptance

- [ ] A deal edited to expire today appears in `Ending Soon` when expected
- [ ] Home, stores, and search all offer a recovery action on empty/failure states
- [ ] `Ending Soon` is readable on small screens without repeated timer noise
- [ ] Stores filtering and follow behavior feel responsive and understandable
- [ ] Core discovery actions have baseline accessibility labels

### Sprint 2: Discovery Unification

- [ ] Unify deal search and Explore interaction model
- [ ] Add shared filter chips, summaries, and clear-all behavior
- [ ] Connect backend-first suggestions and search
- [ ] Remove incomplete or hidden search/filter flows

### Sprint 3: Merchant Trust and Design System

- [ ] Strengthen merchant trust presentation
- [ ] Align action hierarchy and urgency display
- [ ] Standardize spacing, chips, badges, and callouts

### Sprint 4: Accessibility, Motion, and QA

- [ ] Complete accessibility sweep
- [ ] Complete motion consistency pass
- [ ] Add widget tests for major flows
- [ ] Run regression pass across home, search, stores, and merchant views

---

## Notes / Progress Log

Use this section to record completed work and follow-up decisions.

- [x] Sprint 1 tracker created with concrete file-by-file execution tasks
- [x] Home callout readability pass landed, including cleaner stacked callout layout
- [x] `Ending Soon` moved from repeated per-card countdowns to section-level urgency
- [x] Shared expiry formatter introduced for detail, merchant, and classic deal-card surfaces
- [x] Recovery wording aligned around `Retry` / `Clear filters` / browse actions across core discovery screens
- [x] `AllDealsScreen` now has a proper zero-results recovery state instead of a bare text fallback
- [x] Baseline semantics labels added for home search and store follow/share icon actions
- [x] Deal detail actions now have semantics labels for favorite, share, directions, call, WhatsApp, deal link, and website
- [x] Shared urgency tiers are now documented in `deal_expiry_helper.dart`
- [x] Home section support panels were rebalanced for better narrow-screen readability, including a cleaner `Near You` layout
- [x] Verification pass completed on the current Sprint 1 changed set:
  - `dart analyze` on the changed files completed with only non-blocking `prefer_const_*` infos in `home_screen.dart`
  - `flutter test` passed
- [x] Sri Lanka `Ending today` highlight is now implemented across cards, deal detail, and merchant active-deal surfaces
- [x] Follow/unfollow copy and failure feedback are now aligned between stores and merchant profile flows
- [x] Urgency badge colors were tightened on deal card, modern deal card, detail, and merchant surfaces for better contrast consistency
- [x] Verification pass completed for this follow/urgency polish set:
  - targeted `flutter analyze` passed with no issues
  - `flutter test` passed
- [ ] Run a full analyzer/test pass after the current Sprint 1 batch is complete
- [ ] Add links to PRs, screenshots, or test notes here
