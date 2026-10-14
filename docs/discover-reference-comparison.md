# Discover reference comparison and correction

The earlier build followed the section names but did not closely follow the
provided Stitch image's density, header hierarchy, or card proportions.
The supplied local `code.html` and `screen.png` are the visual baseline for
this correction.

| Area | Reference | Earlier build | Correction |
| --- | --- | --- | --- |
| Header | Compact fulfillment, location, search, filters | Added large logo/title row and a location card | Removed branding row and location card; compact controls pin while scrolling using intrinsic header sizing |
| Hero | Photo-led editorial panel | Large photo plus conditions/price footer | Dedicated photo-only editorial surface with overlaid offer text |
| Bank summary | Short banner | Large settings-style row | Compact banner with real card-condition guidance |
| Highlights | Short horizontal photo cards | Taller cards with expansive text and dividers | Smaller image, compact metadata, shorter padding |
| Bank grid | Two compact columns | Tall cards duplicating long offer text | Compact tiles; expand to one column with large text |
| Expiry | Short red banner with a small offer row | Large full offer card inside a pale container | Compact expiry surface in a red banner, showing actual expiry |
| More offers | Photo with compact detail body | Reused hero layout and many condition chips | Dedicated detail-preview surface with plain metadata and a working action |
| Map | Dark floating pill | Inline pale button | Floating dark map entry above the existing tab navigation |
| Footer | Five application tabs | Extra store carousel | Existing five tabs; store directory remains reachable via a compact link |

Sapphire remains the previously approved DealFinder identity. The reference's
linked-card claims, unverified delivery estimates, free delivery, countdown,
voucher inventory, and verified-deal total are not available API data and are
not copied. Actual ratings, requirements, dates, prices and map counts use
promotion data. Offer controls open supported detail actions.

`DiscoverOfferSurface` provides editorial, detail, and expiry variants;
`DiscoverOfferTile` and `DiscoverOfferGrid` provide the compact collections.
Imported photos remain bundled in `assets/discover/`.

The corrected full-page light/dark previews are rendered at the reference's
390px width using fixture data and the actual navigation shell. They are
design comparisons, not live database or physical-device screenshots.
Tests verify compact default proportions, expansion at double text size,
navigation, filtering, saving, and retry behaviour.
