# Discover fine-tuning

This pass keeps the compact Stitch hierarchy and sapphire identity while
improving the supported discovery journey.

- The search surface's tune control opens a filter sheet. Bank, category,
  and fulfillment selections are drafts until Apply; closing discards edits.
- Empty filter combinations offer a working Clear filters action.
- Featured offers are excluded from the highlights. The bank grid prefers
  offers outside those highlights, falling back when the catalog is small.
- The initial More offers preview contains two offers and opens the full
  filtered catalog through View All.
- Tiles use a single descriptive line at normal text size, compact rating
  and distance metadata, and actual card requirements and expiry dates.
  Sub-kilometre distances use metres. Enlarged text remains expandable.

No linked-payment-card claims, unsupported delivery estimates, fabricated
urgency, or unverified eligibility were introduced.

Validation: 43 regression tests pass, including filter cancellation, filter
application and reset, card conditions, and dark mode with double text size.

## Reproduce visual previews

From `mobile_app`, run:

```sh
flutter test --no-pub tool/discover_preview_test.dart
```

The manual renderer uses clearly marked fixtures, bundled artwork, the project
theme, and the actual navigation shell. It writes
`design-preview/discover-finetuned-light.png` and
`design-preview/discover-finetuned-dark.png`. It locates SDK/package fonts from
the current environment rather than embedding a developer's home directory.
The renderer is outside the normal regression suite; these previews are not
live database or physical-device screenshots.
