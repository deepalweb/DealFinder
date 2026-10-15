# DealFinder consumer web marketplace

Review branch: `feat/web-discovery-marketplace`. This is a local, uncommitted patch; nothing was pushed, merged or deployed. Earlier mobile work and unrelated deleted workflow/Cloudflare files remain untouched.

The supplied `DealFinder_Web_Groupon_Codex_Prompt.md` guided this implementation. The [current public Groupon homepage](https://www.groupon.com/) was reviewed for its search/category/campaign/grid hierarchy. Its assets, logo, purchase workflows and promotional claims were not copied. Apple Design foundations and UI UX Pro Max's Next.js image/responsive guidance were used. A generated hero/testimonial recommendation was rejected because it conflicts with the requested offer marketplace.

## Source audit and scope

The checkout is Next.js 16.2.1, React 19.2.4, TypeScript and Tailwind 4 in frontend-next. Both required repository design skills are present. Only the root AGENTS.md applies to these source files.

The old homepage contained long marketing/comparison sections and requested GPS on mount. Cards placed all information over tall images, appended OFF indiscriminately, converted missing prices to zero and treated maximum bank benefit as price savings. Click counts were described as claims and verification was asserted unconditionally in details. Search/results mixed promotions with standalone bank records and requested GPS automatically.

The implemented scope covers the shared consumer header/category navigation/footer, marketplace homepage, shared card/loading states, category/search results and detail presentation. Merchant/admin dashboards and backend contracts were preserved. Shared sapphire theme tokens apply consistently; these dashboards were not redesigned.

## Resulting behaviour

- Compact searchable header, native keyboard-operable account menu, language/appearance controls, notifications where supported, manual area selector and secondary merchant/download navigation.
- Homepage: short value statement, one actual curated/featured offer when available, selected-area offers or an honestly named general collection, bank offers, up to three populated category collections, genuine expiry preview and a paginated More offers grid. Offer IDs are deduplicated across sections.
- Area choice persists in local browser storage. Google Maps uses the existing map component, with presets as a working fallback. GPS is requested only after Use my location. Distances are straight-line estimates from the selected centre; no routing/ETA promise is made.
- Landscape photographs above solid information panels. Typed mapping distinguishes bank records from card-related merchant promotions. Missing prices remain absent; maximum benefit is a cap, not a claimed saving. Failed images use a local SVG placeholder. Standalone bank records do not expose unsupported promotion-only saving.
- Results use desktop filters and a native mobile dialog. Category, bank, card type, fulfillment, active/ending availability and sorting affect results and persist in URL/state. Search requests debounce and discard stale responses. Counts are labelled loaded offers rather than platform totals. Standalone bank offers are not incorrectly excluded for lacking physical coordinates.
- Details provide a reserved gallery, actual merchant links, price/benefit/conditions, current lifecycle checks, supported directions/site/code actions, saved state, sharing, ratings and comments. Reviews follow the main offer/action layout on phones. No click count is described as a claim or sale; no hardcoded verification or fabricated countdown remains.
- Favorites update after API acceptance, reject duplicate local submissions, retain unsaved state after rejection and share status across cards/details. Guest intent survives sign-in through a validated internal return URL. Favorite-loading failures have an explicit retry state.
- English, Sinhala and Tamil copy uses the existing language context. Native focus styles, 44px controls, reduced-motion rules and semantic light/dark surfaces are maintained.

## Components and contracts

| Area | Files/contracts |
|---|---|
| Display/data mapping | lib/offer-display.ts; tests/offer-display.test.mjs |
| Shared browsing state | contexts/AreaContext.tsx, contexts/SavedOffersContext.tsx |
| Navigation | components/layout/Header.tsx, Footer.tsx, ConditionalLayout.tsx |
| Cards/media/sections | components/ui/PromotionCard.tsx; components/marketplace/OfferImage.tsx, DealSection.tsx, AreaSelector.tsx |
| Feed/pagination | components/marketplace/useOfferFeed.ts; PromotionAPI.getAll(limit, skip), getHomepage; BankOfferAPI.getAll |
| Results | app/categories/[categoryId]/CategoryPageClient.tsx; existing AiAPI.search contract |
| Details | app/deal/[dealId]/page.tsx, DealPageClient.tsx; correct promotion or bank endpoint |
| Login return | existing app/(auth)/login/page.tsx; safe internal next destination, without a session-storage/auth rewrite |

BankOfferAPI marks standalone records with `_offerKind: bank`. Their links use `/deal/id?kind=bank`; client and server choose the bank endpoint directly. Merchant promotions with bank conditions stay on promotion endpoints. Existing legacy bank detail links have a read fallback. Canonical deal/category URLs remain unchanged. Unsupported stock Product structured data was removed rather than carrying fabricated availability into SEO.

## Verification

- TypeScript `npx tsc --noEmit` and targeted ESLint pass.
- Production `npm run build` passes, including all existing merchant/admin routes.
- Seven Node regression tests pass: missing prices/caps, bank routing, Colombo lifecycle/date-only handling, percentage-only ranking, valid distances, safe return paths and explicit fulfillment restrictions overriding merchant capability.
- Headless Chrome rendered the actual local API's development offers. The initial feed showed 28 cards with zero page errors and zero GPS calls. No horizontal page overflow at 320, 360, 390, 768, 1024 or 1440px.
- Live read-path checks passed for manual area selection, sorting, detail/browser back, bank/card filtering, empty matches, clearing filters, mobile filter dismissal, language switching and dark appearance.
- Controlled tests passed for standalone bank endpoint selection, save rejection/no optimistic success, preserved guest intent, signed-in return navigation, search request/URL/refresh mapping, API failure with no fictional offers, image failure, GPS denial/manual recovery, dialog focus entry, Escape and focus restoration.
- Core palette contrast: action white-on-sapphire 5.83:1; light metadata 6.31:1; dark metadata 6.99:1; dark links 6.98:1. Legacy dashboards/auth styles outside this scope were not comprehensively audited.

[Rendered review gallery](web-marketplace-preview/index.html). The screenshots show local API DEMO inventory, not production verification. The existing dev server initially served stale gallery CSS; refreshing that project server resolved it. The local app remains available at http://localhost:3000.

## Limits

Real-account authentication, successful live favorites/comments/ratings writes, production hosting, live AI ranking and real standalone-bank inventory were not validated. Auth/bank/search/error cases used controlled responses where needed, avoiding real account/data mutations. Browser zoom was approximated with responsive viewport checks and root-font enlargement; a manual release accessibility/device pass remains appropriate.

The public listing API exposes active inventory, so the misleading Include Expired results control was removed. An expired record returned by the detail API shows expiry, with code copying disabled. No branch selectors, checkout, payments or payment-card collection were added. No existing consumer web QR/report UI was found in the original detail screen; backend/mobile capabilities were not replaced with pretend web controls. No Terms route exists in this checkout, so the footer links only to working About, Contact and Privacy routes plus the existing merchant registration/app-download destinations.

Auth/session storage and secrets were not changed. The narrow safe-return and truthful favorites fixes support the requested browsing journey.
