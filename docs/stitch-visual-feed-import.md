# Discover Visual Feed import

Imported Google Stitch project **DealFinder iOS Redesign**
(`11540197329145092969`), screen **Discover — Visual Feed**
(`3dc496ee83d04b87b55876ce9fc14a1b`). Original HTML, screenshot, and
the reference hero photograph are in
`mobile_app/design-reference/stitch-visual-feed/`.

The Flutter implementation adopts the reference's compact identity header,
separate browsing-area control, prominent search, category chips, single
editorial hero, stacked nearby offers, Ending Soon hero, image-led bank
offers, exploration feed, and store strip.

DealFinder's existing sapphire theme and semantic dark colors remain in use.
Content comes from the API and existing promotion cache. Prototype merchant
names, prices, account initials, notification dots, and Nugegoda location are
not copied into runtime data. Reference assets are for design review; runtime
offer images come from their promotion records.

Offer cards reuse persistent saving and supported offer-detail navigation.
Buttons say **View offer**, avoiding unsupported claims or redemptions.
Bank entries display actual active offer conditions. Category selection applies
to the bank feed and is carried into the All Offers and Ending Soon lists.
The existing Nearby and Bank Offers tab destinations remain available.
Store cards open the corresponding merchant profile.

The Explore section avoids repeating the offers already emphasized by the
hero, nearby preview, and Ending Soon. Personalized headings require supported
recommendation reasons; general fallback content is labeled Explore offers.
The header scrolls with the feed so controls do not obscure content on small
screens or with enlarged text. System status bars and bottom navigation are
provided by the existing application shell.

Validation covers category handoff, bank filtering, failed-load retry,
compact/editorial cards at double text size in dark mode, and existing saved
state and navigation regression tests. Light/dark previews use fixture data
and the imported reference photograph; they are not live API screenshots.
Device and iOS release validation are separate from these widget checks.
