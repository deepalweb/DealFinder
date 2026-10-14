# Mobile development deals

Run `npm run seed:mobile-demo` from `backend` to refresh the development fixtures.
The script connects to MongoDB using the ignored backend environment and refuses
to seed any database other than `test`. It updates only the named `[DEMO]` stores
and `DFDEV-` offer codes in its fixture list, without deleting existing records.

The fixture set contains 34 offers across 12 fictional merchants:

- 32 active offers, one scheduled offer, and one expired offer.
- Six bank/card examples with bank names, card types, minimum spend, and maximum
  benefit fields. These are fictional eligibility examples, not actual bank deals.
- Dining, bakery, groceries, electronics, fashion, books, home essentials,
  spa/salon, and fitness/wellness examples.
- In-store, delivery, and pickup examples, including offers ending today or
  tomorrow, geolocated stores, sample opening hours, and images.

On 14 October 2026, the expanded seed added 24 offers and refreshed the ten
existing fixtures. All 34 records were read back with linked LKR merchants, and
the non-fixture promotion count was unchanged.

All fixture titles are marked `[DEMO]` and descriptions identify them as
development-only offers. They are not real redeemable discounts. Images are
remote sample photos; availability depends on the image host and network.
