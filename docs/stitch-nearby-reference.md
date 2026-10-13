# Google Stitch reference: Nearby

The supplied reference combines an area header, radius/category/open-now controls, an interactive map, and a draggable results sheet. This is a useful progression from the previous separate list/map modes. The implementation uses the existing sapphire visual system and five-tab shell.

## Review decisions

| Reference element | DealFinder treatment |
| --- | --- |
| Green header, pins, and actions | Sapphire theme tokens; selected pins and cards have distinct outlines and semantic selection state. |
| Within 3 km | Real selectable 1/3/5/10 km queries centered on the selected area. Radius is persisted. |
| Search this area | Panning changes a draft center; pressing the button fetches using that center. Panning alone does not send repeated API requests. |
| Open Now | Derived from published merchant schedules in Colombo time. Unknown/malformed schedules are excluded, and the interface explains that this is based on store hours rather than a live availability guarantee. |
| Approximate location / Enable Exact | Display an approximation/recent-location notice only when the location result supports it. Use my location requests permission explicitly; settings provide a route to OS precision/service controls. No fake precision toggle is shown. |
| Layer icon | Replaced with Show results, which has a supported action. No unsupported satellite/map style switch is presented. |
| Offer pins | Real discounts or actual prices, with overlapping offers grouped into count markers that zoom in. |
| Draggable sheet | Nonmodal sheet with expand/collapse buttons, allowing people to use it without a drag gesture. |
| Dine-in, Brunch, Claim, Book | No invented fulfillment or redemption capabilities. Existing in-store/delivery/pickup fields are shown; View offer leads to the working detail actions. |
| Bank eligibility | Real bank name, card type, minimum spend, and expiry when present. These conditions do not claim to confirm an individual customer's eligibility. |

## Implemented journeys

- Guest browsing starts with a named Colombo area when no saved area exists. It does not require GPS or request location permission on initialization.
- Choose area searches the available local presets and stored merchant areas. People can also navigate the map and choose Search this area, without entering raw coordinates.
- The selected area is persisted and shared with Discover. Manual/map areas take precedence over automatic location checks in Discover.
- Map and list use one filtered, distance-sorted collection. Selecting a pin reveals its corresponding selected card at the top of the sheet; selecting a card focuses and highlights its map marker or group. Details open within the preserved Nearby tab stack.
- Search radius, category, open-now, and text filters affect both map and list. Counts reflect the displayed result set. New requests supersede previous requests so late responses cannot overwrite the current area.
- Distances are approximate straight-line distances from the search area, rather than travel distances or a claim that the device is at the selected point.
- Matching cached offers can support offline browsing. A cache from another area is rejected for the current area's results and explained with a retry action. Failed map tiles do not block list browsing.
- Offer saves use the shared guest sign-in return and API-acceptance behavior from Discover. Notifications and Account remain reachable from the header.
- New Nearby copy is provided in English, Sinhala, and Tamil. Existing stored area names and category-name localization still need the full language audit.

## Guidance and service boundaries

Apple `maps.md > Best practices` says “Clearly identify elements that people select.” The shared selected offer drives marker and row treatment. Its advice to cluster overlapping points informs count markers. Apple `sheets.md > Best practices` recommends a nonmodal view for supplementary controls that affect the main task; the map remains usable behind the results sheet. UI UX Pro Max's Dragging Movements guidance supports the expand/collapse button alternatives.

The existing OpenStreetMap tile provider is retained with visible attribution. No new public Nominatim search service was introduced: its [usage policy](https://operations.osmfoundation.org/policies/nominatim/) limits aggregate application traffic and prohibits autocomplete. Place search here filters available local area records; global geocoding/provider selection remains separate work.

Approximate/denied permission flows still require device-specific validation, as do iPhone and release performance checks. Normal store hours do not account for exceptional holiday closures unless the API supplies them. Card eligibility and live claims/bookings remain dependent on their actual API capabilities.


## Validation evidence

- The full Flutter test suite passed 24 tests. The eight Nearby-specific tests also pass after the final refinements, including actual map widget interactions with injected local tiles and a simulated API.
- Flutter analysis is clean and the ARM64 Android debug APK builds successfully.
- Samsung SM A065F inspection loaded the existing local API with both coarse and fine location permissions denied. No location prompt appeared; the named default area returned offers. Manual selection of Colombo 04 requested that area's coordinates and displayed distances relative to its center.
- The results button expanded the sheet without dragging. Selecting the Fashion map pin highlighted its marker and brought the matching Fashion row to the top. Light/dark appearance was inspected. Original location permissions and device appearance settings were restored.
- Initial sheet height was increased after phone inspection so the first offer's price is visible, and save controls moved into the merchant row to reduce unused space. Attribution uses a theme surface so it remains legible over map tiles in both appearances.
- Captures are under `mobile_app/design-preview/`: `stitch-nearby-light.png`, `stitch-nearby-selected.png`, `stitch-nearby-list.png`, `stitch-nearby-dark.png`, `stitch-nearby-area-picker.png`, and `stitch-nearby-no-gps.png`.

The denied-permission check is a real Android check; reduced-accuracy GPS, live store-hour coverage, TalkBack/VoiceOver, iPhone, and release-mode performance remain unverified. Automated cache tests verify the area-mismatch rule; a full airplane-mode journey has not been run. Public browsing uses the unauthenticated nearby endpoint, but live guest sign-in/registration/redemption remains separate validation.


## Google Maps migration

The current implementation uses Google Maps rather than the original OpenStreetMap tiles. The map provider setup and validation status are maintained in [google-maps-setup.md](google-maps-setup.md). Historical screenshots below/above may still show the former map provider.
