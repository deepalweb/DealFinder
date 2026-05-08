# Mobile Search and Filtering Improvement Plan

## Goal

Make search and filtering in the mobile app easy to discover, consistent across screens, fast enough to feel responsive, and reliable enough that users trust the results.

## Current Status

### What exists today

1. Deal search entry from Home
   - `HomeScreen` opens `SearchScreen`, which then opens `SearchResultsScreen`.
   - Files:
     - `mobile_app/lib/src/screens/home_screen.dart`
     - `mobile_app/lib/src/screens/search_screen.dart`

2. Deal browsing and filtering in Explore
   - `AllDealsScreen` has category, price, discount, and sort controls.
   - It does not support keyword search.
   - File:
     - `mobile_app/lib/src/screens/all_deals_screen.dart`

3. Store search and filtering
   - `StoresScreen` has keyword search, category chips, and sorting.
   - This is currently the cleanest of the search/filter flows.
   - File:
     - `mobile_app/lib/src/screens/stores_screen.dart`

4. Advanced deal search
   - `AdvancedSearchScreen` supports suggestions, history, price range, category, merchant, discount-only, expiry, and sort.
   - It appears to be effectively hidden because it is only opened from `QuickSearchWidget`, and `QuickSearchWidget` is not used anywhere in the app.
   - Files:
     - `mobile_app/lib/src/screens/advanced_search_screen.dart`
     - `mobile_app/lib/src/widgets/quick_search_widget.dart`

5. Shared local search logic
   - `SearchService` and `SearchMatcher` provide suggestions, matching, sorting, and advanced filtering.
   - Files:
     - `mobile_app/lib/src/services/search_service.dart`
     - `mobile_app/lib/src/services/search_matcher.dart`

### What is working

- Sinhala-aware keyword matching exists in the local matcher.
- Category normalization already exists and is reused in multiple places.
- Store search has a better visual presentation than the deal search flow.
- Explore already has a decent set of non-text filters.

### Main problems

1. The experience is fragmented
   - Search, advanced search, Explore filters, and store filters all behave differently.
   - Users have to guess whether to use Home search, Explore, or Stores.

2. Advanced search is not part of the main user journey
   - The most capable deal search screen is behind an unused widget.

3. Search results are based on full local fetches
   - `SearchService.getSuggestions()` and `performAdvancedSearch()` both fetch all promotions, then filter on-device.
   - This will get slower and less accurate as data grows.

4. Filter capabilities are inconsistent
   - `SearchResultsScreen` only supports category and a small sort menu.
   - `AllDealsScreen` supports filters but no keyword search.
   - `DealsListScreen` still shows a placeholder snack bar for filtering.

5. Error handling is too quiet
   - `SearchService` returns empty lists on failure, which makes backend or network issues look like “no results”.

6. Suggestions are expensive
   - Suggestions currently come from scanning all promotions after each query change.
   - There is no debounce or stale-request protection.

7. Some filters are incomplete
   - Location filtering in `SearchService` is marked as simplified and currently does nothing meaningful.
   - Price range is static in advanced search and may not fit real deal data.

### Architecture observation

The backend already has stronger search capabilities than the mobile app is using:

- basic endpoints in `ApiService` for keyword/category search
- an AI search route at `POST /api/ai/search`
- a backend suggestions route at `GET /api/ai/search/suggestions`

Today, the mobile app mostly ignores those and relies on client-side filtering instead.

## Improvement Plan

### Phase 1: Consolidate the user experience

Goal: one obvious way to search deals, one consistent way to filter deals.

1. Make one primary deal search screen
   - Replace the current split between `SearchScreen`, `SearchResultsScreen`, and hidden `AdvancedSearchScreen`.
   - Keep one `DealsSearchScreen` with:
     - search bar
     - inline suggestions
     - results list
     - filter bottom sheet
     - visible active filter chips

2. Connect Explore to the same search/filter model
   - Add keyword search to `AllDealsScreen`.
   - Reuse the same filter model and same sorting options as the dedicated deal search screen.

3. Keep Stores separate, but align the interaction model
   - Preserve the good UI direction in `StoresScreen`.
   - Match the same patterns for:
     - search field behavior
     - clear-all behavior
     - active filter summary
     - empty states

### Phase 2: Introduce a shared search state model

Goal: stop spreading query/filter logic across multiple widgets.

Create a shared search state object for deals, for example:

- `query`
- `category`
- `merchant`
- `minPrice`
- `maxPrice`
- `minDiscount`
- `expiresBefore` or `endingSoon`
- `latitude`
- `longitude`
- `radiusKm`
- `sortBy`

Then move filtering orchestration into a single controller/service so UI screens only read and update state.

Recommended output:

- `DealSearchFilters` model
- `DealSearchController` or equivalent notifier/state class
- shared helpers for:
  - serializing filters
  - counting active filters
  - building UI chips
  - resetting filters

### Phase 3: Move deal search to backend-first

Goal: improve relevance, performance, and future scalability.

1. Use backend suggestions first
   - Prefer `GET /api/ai/search/suggestions?q=...`
   - Keep local suggestion fallback only for offline or failure cases

2. Use backend search first
   - Prefer `POST /api/ai/search` for deal search
   - Pass structured filters instead of fetching all promotions locally

3. Keep client-side fallback
   - If AI search is unavailable, use the current matcher logic as fallback
   - This keeps the feature resilient while we transition

4. Standardize category normalization with backend taxonomy
   - Reconcile mobile category aliases with backend AI taxonomy so results stay consistent

### Phase 4: Fix usability gaps in filters

Goal: make filters understandable and fast to use.

1. Replace hidden/secondary filters with a clear filter sheet
   - show current values
   - allow reset
   - show active filter count

2. Show active filters above results
   - examples:
     - `Electronics`
     - `Under Rs. 5,000`
     - `Discount 20%+`
     - `Ending Soon`

3. Add “Clear all” everywhere
   - deal search
   - Explore
   - Stores

4. Improve filter semantics
   - use real discount percentage parsing
   - use dynamic price bounds from returned data if possible
   - replace vague expiry filter labels with user-friendly options
     - `Any time`
     - `Ending in 24h`
     - `Ending this week`

5. Implement actual location filtering
   - either through backend distance-aware search
   - or through client distance calculations only if backend cannot support it

### Phase 5: Make interactions feel responsive

Goal: remove lag and uncertainty.

1. Debounce text input
   - suggestions: 250 to 350 ms
   - result refresh: slightly delayed for typed changes if using live search

2. Prevent stale results
   - ignore out-of-order responses
   - cancel or supersede older requests

3. Surface loading and failure states clearly
   - loading spinner or skeleton for result refresh
   - “couldn’t load results” state instead of silent empty lists

4. Persist useful user behavior
   - recent searches
   - recent filters
   - saved searches only if there is a real entry point for them

### Phase 6: Add measurement and test coverage

Goal: keep improvements from regressing.

1. Unit tests
   - category normalization
   - text matching
   - discount parsing
   - filter serialization

2. Widget tests
   - search submit
   - filter apply / clear
   - empty state rendering
   - suggestion tap flow

3. Telemetry
   - send search/filter events to `/api/ai/events`
   - track:
     - search submitted
     - filter used
     - result clicked
     - zero-result searches
     - clear-filters usage

## Recommended Implementation Order

### Sprint 1

- Build shared `DealSearchFilters` model
- Merge `SearchScreen` and `AdvancedSearchScreen` into one primary deal search flow
- Add filter chips and clear-all
- Hook up backend suggestions
- Stop silent failure returns in search UI

### Sprint 2

- Add keyword search to Explore
- Reuse the same deal filter sheet in Explore
- Hook deal search results to backend AI search
- Implement proper empty/error/loading states

### Sprint 3

- Clean up `DealsListScreen` placeholder filter behavior
- Reconcile mobile/backend taxonomy
- Add telemetry and tests
- Tune ranking, sorting, and location-aware search

## Immediate Code Targets

- `mobile_app/lib/src/screens/search_screen.dart`
- `mobile_app/lib/src/screens/advanced_search_screen.dart`
- `mobile_app/lib/src/screens/all_deals_screen.dart`
- `mobile_app/lib/src/screens/deals_list_screen.dart`
- `mobile_app/lib/src/services/search_service.dart`
- `mobile_app/lib/src/services/search_matcher.dart`
- `mobile_app/lib/src/services/api_service.dart`
- `mobile_app/lib/src/screens/stores_screen.dart`

## Definition of Done

Search and filtering are in a good place when:

- users have one obvious deal search flow
- Explore and search use the same filter language
- store filtering feels consistent with deal filtering
- suggestions and results are fast
- errors are visible
- filters are easy to apply and easy to clear
- search logic is shared instead of duplicated
- backend-first search is the default path
