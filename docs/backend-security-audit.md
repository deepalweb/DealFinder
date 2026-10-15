# DealFinder Backend Audit — 2026-10-15

**Scope:** the Express backend in `backend/` (MongoDB provider), plus the web (`frontend-next`) and Flutter (`mobile_app`) contracts that depend on it.

**Method:** each suspected defect was reproduced against a disposable loopback MongoDB (`mongodb-memory-server`, database `dealfinder_isolated_audit`), then fixed. Each fix has a focused regression test that failed before the fix and passes after it.

**Safety:**

- No production data was read or changed.
- No seed or migration script was run.
- The database provider was not changed.
- No secrets were printed.

## 1. Verification

| Suite | Command | Result |
|---|---|---|
| Backend: unit + isolated integration | `cd backend && npm test` | **48 / 48** pass. 9 of these are new in this round; all 9 failed before their fixes. |
| Web unit | `cd frontend-next && npm test` | 12 / 12 pass |
| Web types | `cd frontend-next && npx tsc --noEmit` | clean |
| Flutter | `cd mobile_app && flutter test` | 91 / 91 pass |

Regression tests are in `backend/tests/security-audit.integration.test.js`. Test names start with their severity, for example `P0 …`.

On first run the backend suite downloads a ~400 MB `mongod`. To reuse a local binary, set `MONGOMS_SYSTEM_BINARY` to its path; the one used for this audit is `.codex-logs/mongodb-bin/mongod.exe`.

**Client compatibility checked:**

- Web push sends `PushSubscription.toJSON()`.
- Mobile sends `{subscription: <FCM token>, type: 'push'}`.
- Both clients' preference payloads use only fields the new allowlist accepts.
- The analytics endpoints have no client callers.
- Web and mobile store rotated refresh tokens and call server-side logout.

## 2. Coverage by area

| Pri | Area | Status |
|---|---|---|
| P0 | Authentication | Verified and fixed in round 1 (§3.1). Registration, login, Google and Firebase identity, token validation, bcrypt hashing, and reset-token expiry and single use are covered by tests. |
| P0 | Authorization | Verified and fixed (§3.1, D2). Ownership is read from the current account on every protected route. No remaining cross-merchant path was found. |
| P0 | Data exposure | **Defects found and fixed: D2, D3.** Password, reset, refresh and Firebase fields are redacted (round 1). |
| P0 | Input security | Fixed: D5. Writable fields are allowlisted on every write route reviewed, with D1 the exception now fixed. No exploitable MongoDB operator injection was found: routes check value types, and Discover rejects non-scalar query values. Categories and search text are matched literally. Rich text is rendered as text; the only raw HTML is JSON-LD, which goes through a tested serializer. |
| P0 | Images | Fixed: D7 plus round 1. Content is fully decoded with `sharp` (25 MP cap), there is a 20 MB / 5-file limit, folders are per user, and deletion is restricted to owner or admin. Persistent storage is unverified (§6). |
| P1 | Sessions | Fixed in round 1. Sessions are durable and hashed, rotate on use, reject replays, survive restarts, are revoked on logout, and all are revoked on password change. |
| P1 | Database | MongoDB is the only provider; Postgres is no longer used. Readiness pings MongoDB with a 2 s timeout, MongoDB pooling is configured, and indexes exist on the main promotion and bank-offer queries. The leftover Postgres code is dead (§5). |
| P1 | Promotion lifecycle | Verified. The real states are `draft → pending_review → active/scheduled/expired`, plus `rejected` and `admin_paused`. Merchants cannot set status, and any merchant edit sends the offer back to `pending_review`. Visibility is derived from dates, so no expiry job is needed. |
| P1 | Pricing and eligibility | Verified, plus fix D6. Percentage values must be 0–100, the sale price must be below the original, end must be after start, and the bank/card pair must be supplied together. Clients show the benefit text as entered and compute a saving only from real prices. No "All payments" fallback exists. |
| P1 | Nearby discovery | Verified. Coordinates and radius (≤ 100 km) are validated, distance is in km, manual areas are supported, and online-only offers have no distance. Filtering runs before pagination. |
| P1 | Search and pagination | Verified. The limit is capped at 100, sorting is stable with an `_id` tiebreak, and `X-Total-Count` / `X-Has-More` are accurate. One risk: R3. |
| P1 | QR redemption | Verified in round 1. Consumption is atomic (8 concurrent attempts give 1 acceptance), active entitlements are unique, and there are expiry, ownership and audit records. |
| P1 | Merchant workflows | Verified. Drafts are scoped per owner with idempotent submission, admin approval is required, and pending stores are private. One risk: R4. |
| P1 | Bank offers | Verified. Bank offers use a separate model and endpoints, a bank-offer ID returns 404 from every promotion endpoint, writes are admin-only and validated, and unpublished offers are private. |
| P2 | Notifications | **Defects found and fixed: D1, D4, D8.** Jobs run on Colombo time. Missing functionality: §5. |
| P2 | AI features | Partly fixed: D3 covers AI search and suggestions. Verified: filters are sanitized, the client-chosen model is ignored, Azure calls time out after 10 s, results come from the database, and there is a heuristic fallback. Risk: R3. |
| P2 | Performance | Risks R2 and R5. |
| P2 | Operations | Verified: graceful shutdown and dependency-aware readiness. Missing: §5. |

## 3. Confirmed defects (all fixed)

### 3.1 Round 1: auth, ownership, images, Discover, redemption

Fixed before this round. All are covered by tests in the same file.

| Sev | Defect | Location | Fix |
|---|---|---|---|
| P0 | Firebase UID was usable as a password | `POST /api/users/firebase-auth` | Random password; any historical UID-derived hash is repaired on sign-in |
| P0 | An unverified provider email could link an existing account | `firebase-auth`, `google-signin` | `email_verified` is required |
| P0 | Ownership trusted the `merchantId` claim in the JWT | `middleware/auth.js` | Role and merchant link are read from the current account record |
| P0 | Store ownership could be claimed by matching a public contact email | `routes/userRoutes.js` (`ensureMerchantProfileForUser`) | Removed |
| P0 | Reset secrets appeared in the self-profile; reset tokens were logged, stored raw and consumed non-atomically | `routes/userRoutes.js`, `models/User.js` | Secrets redacted; tokens hashed, expiring and atomically consumed |
| P0 | Image content was checked only by file signature | `POST /api/images/upload*` | Full decode before storage |
| P0 | Unapproved promotions appeared in Discover and in sub-resources | `GET /api/promotions*` | Status gate plus `authorizePromotionRead` |
| P0 | Unpublished bank offers could be read by ID | `GET /api/bank-offers/:id` | Public reads return published offers only |
| P1 | Refresh tokens were held in memory, with no rotation or revocation | `services/sessionService.js` | Durable hashed sessions with reuse detection |
| P1 | Redemption was a read-then-save race | `POST /api/promotions/redemptions/redeem` | Conditional `findOneAndUpdate` |
| P1 | Anonymous clicks could be recorded as redemptions | `POST /api/promotions/:id/click` | `redeem` type rejected |
| P1 | Category input was treated as a regex; nearby results were truncated before filtering | `GET /api/promotions` | Escaped and anchored match; all filters run before pagination |
| P1 | Published offers could be edited without review | `PUT /api/promotions/:id` | Edits return the offer to `pending_review` and clear verification |
| P1 | Choosing Postgres silently fell back to MongoDB | multiple | Explicit 503 / 501 responses |

### 3.2 Round 2: confirmed in this audit

Each entry gives the evidence (the regression test, which failed before the fix), the impact and the fix.

**D1 — P0 Notification preferences: mass assignment and ownership hijack.**
- **Location:** `PUT /api/notifications/preferences` (`routes/notificationRoutes.js`).
- **Evidence:** the request body was flattened directly into `$set`. `{userId: <victim>}` moved the caller's preference document, including their push channel, to a victim who had no preferences yet. The same route accepted `channels.web.subscription`, an arbitrary push endpoint. Test: *P0 notification preferences cannot reassign ownership…*
- **Impact:** the victim's notifications go to the attacker's device. The injected push endpoint also enables D4.
- **Fix:** only keys matching `preferences.*`, `quietHours.*` and `channels.{push,email,web}.enabled` are accepted.

**D2 — P0 Merchant analytics expose customer accounts and are broken for owners.**
- **Location:** `GET /api/promotions/:id/analytics` and `GET /api/promotions/analytics/merchant/:merchantId`.
- **Evidence:** `populate('user')` returned the full user record (email, favorites, followed stores, preferences, `pushSubscription`) of every customer who clicked. Separately, the owner check compared an ObjectId to a string with `===`, so merchants always got 403. Test: *P0 merchant analytics never expose customer account fields…*
- **Impact:** customer PII leaked to merchants, and the merchant analytics feature didn't work.
- **Fix:** populate only `user.name` and `promotion.title,status`; compare IDs as strings.

**D3 — P0/P1 Private store contacts and hidden stores leaked on public discovery surfaces.**
- **Locations:** `services/sectionService.js` (`/promotions/homepage`, `/promotions/sections`, `/sections/:key`); `GET /promotions/recommended`; the homepage `latest` list; `POST /ai/search`; `GET /ai/search/suggestions`; `GET /users/:id/favorites`; `GET /users/:id/following-merchants`.
- **Evidence (contact):** the store's `contactInfo` is treated as private (stripped from `/merchants`), but sections selected it and their sanitizer kept it. Favorites and followed stores returned full store records.
- **Evidence (visibility):** only the main list, offer detail and redemption excluded stores that are suspended, rejected, pending approval or need review. Sections, recommendations, AI search and suggestions didn't. Suggestions also matched `pending_approval` offers and expired offers, and returned names of hidden stores.
- **Tests:** *P0 private store contact is absent…* and *P1 offers from suspended or unapproved stores stay out…*
- **Impact:** a private contact was exposed. Suspended or unapproved stores were still promoted.
- **Fix:**
  - One shared `isPublicMerchant` / `HIDDEN_MERCHANT_STATUSES` in `utils/merchantWorkflow.js`, now used on every public surface, replacing three inline copies.
  - Sections select `status` instead of `contactInfo` and filter on output, so cached sections can't outlive a suspension.
  - The nearby `$geoNear` query excludes hidden stores.
  - Suggestions require `active`/`scheduled`, a future `endDate`, and a query of 100 characters or fewer.
  - Favorites and followed stores exclude `contactInfo`, `reviews` and `promotions`.

**D4 — P1 Server-side request forgery (SSRF) through web-push subscriptions.**
- **Location:** `POST /api/notifications/subscribe`, and D1's route.
- **Evidence:** any `subscription.endpoint` was stored. `POST /notifications/test` and the scheduled jobs then make the server POST to that URL, including internal addresses such as `http://169.254.169.254/…`. Test: *P1 push subscriptions must target a known push service over HTTPS.*
- **Impact:** blind POST requests from the server to internal or arbitrary hosts.
- **Fix:** the endpoint must be `https:` on FCM, Mozilla, Apple or `*.notify.windows.com`, with string `p256dh` and `auth` keys. Only `{endpoint, keys}` is stored. FCM tokens must be strings of at most 4096 characters.

**D5 — P1 Unbounded comment and report input.**
- **Location:** `POST /api/promotions/:id/comments`; `POST /api/promotions/:id/reports`; `POST /api/merchants/:id/reports`.
- **Evidence:** comment `text` had no type or length check (an object caused a 500), and comments are embedded in the promotion document. Report descriptions had no length limit. Test: *P1 comments and reports are bounded strings.*
- **Impact:** repeated large comments (bodies up to 15 MB are accepted) push the offer document toward MongoDB's 16 MB limit, after which the offer can no longer be saved.
- **Fix:** comments must be trimmed strings of 1–1000 characters; report descriptions are limited to 2000.

**D6 — P1 "Up to X%" was treated as a guaranteed saving.**
- **Location:** `getDiscountSignal` in `routes/promotionRoutes.js` (`minDiscount` filter, `discount` sort); `percentage()` in `frontend-next/lib/offer-display.ts`; `OfferPresentation.percentage` in `mobile_app/lib/src/utils/offer_presentation.dart`.
- **Evidence:** "Up to 60% off" passed `minDiscount=50`. Test: *P1 an "up to" discount cap is not treated as a guaranteed saving.*
- **Impact:** filters and sorting overstated savings.
- **Fix:** a cap no longer counts as a percentage saving on the server, web or mobile. A saving from real prices is still used. Displayed text is unchanged.

**D7 — P0 (policy) Image deletion approved traversal URLs.**
- **Location:** `canDelete` in `utils/imagePolicy.js`, used by `DELETE /api/images/delete` and store logo/banner cleanup.
- **Evidence:** `https://host/victim/../u<me>-images/<uuid>.png` was approved, because the check ran on the normalized path. The R2 provider derives its key from the raw, decoded string. Test: *P0 encoded or traversal image URLs are refused…*
- **Impact:** the policy and the storage layer disagreed about which object would be deleted. Whether R2 normalizes such keys was not tested against a real bucket.
- **Fix:** reject `%`, `..`, `\`, `?` and `#`, none of which appear in generated URLs.

**D8 — P2 Dead push subscriptions were retried forever.**
- **Location:** `services/NotificationService.js`.
- **Evidence:** 404/410 responses from web push and unregistered FCM tokens were only logged. Test: *P2 expired web push subscriptions are removed…*
- **Impact:** wasted sends and noisy logs.
- **Fix:** the subscription or token is unset and the channel disabled.

## 4. Potential risks (not fixed)

**R2 — P2 Discover loads every active offer into memory on each request.** `GET /api/promotions` filters and sorts in Node so that all filters apply before pagination. This is correct today but grows linearly with catalogue size. **Upgrade:** move the filters into a MongoDB aggregation (`$geoNear` + `$match` + `$sort` + `$facet`) once there are thousands of active offers.

**R3 — P2 AI search ranks a sample.** `searchPromotions` fetches at most 160 candidates (featured, then newest) before ranking. Relevant older offers can be missed. Results are labelled as search results, not as complete coverage.

**R4 — P2 Store profile edits skip review.** `PUT /api/merchants/:id` (and the merchant branch of `PUT /api/users/:id`) let a merchant change their public name, address, location and logo immediately. Offers go through review; store details don't. This is a product decision.

**R5 — P2 The global JSON body limit is 15 MB.** `server.js` applies it to every route. Base64 images in profile fields are the likely reason. Lowering it to around 1 MB means first moving those fields to `/api/images`.

**R6 — P2 No security headers.** There is no `helmet` or equivalent. The Next.js frontend is served through the same process in production.

**R7 — P2 Notification de-duplication is check-then-send.** `hasRecentNotification` followed by a send can produce duplicates when two instances run, or two job runs overlap.

**R8 — P3 Low-risk input gaps.**
- Ratings, comments and clicks are accepted on non-public offers when the ID is known.
- `GET /notifications/deal-alerts/:id` returns 500 for a malformed ID.
- Malformed favorite or follow IDs return 500 instead of 400.

## 5. Missing functionality

| Pri | Item | Note |
|---|---|---|
| P2 | Remove dead Postgres code | Postgres is no longer used. `models-pg/`, `services/postgres*.js`, `scripts/pg/`, about 40 `DATA_SOURCE === 'postgres'` branches, and the `pg`/`sequelize` packages can be deleted. That also clears the `sequelize`/`uuid` advisories. |
| P2 | Persistent job queue | Jobs run in-process with `node-cron`: work is lost on restart and duplicated across instances. Retries are missing too. |
| P2 | Structured logging and monitoring | Logs are `console.*` only. There are no request IDs, metrics or alerting. |
| P2 | Backup and restore | The procedure has never been exercised. |
| P2 | Dependency upgrades | 3 high and 10 moderate npm advisories remain, all requiring semver-major upgrades. The high ones come from `http-proxy-middleware` (via `braces`/`micromatch`). The moderate ones come from the `firebase-admin` chain → 14.x, `sequelize`/`uuid`, and `node-cron` → 4.x. No critical advisories remain. |

## 6. Unverified integrations

These were exercised only with stubs. Each needs a staging run with real credentials.

| Integration | What was stubbed |
|---|---|
| Firebase Admin / Google sign-in | `verifyIdToken` returned a fixture identity |
| SMTP (Microsoft 365) password reset | The transport captured the message |
| R2 / Azure Blob image storage | `uploadImage` / `deleteImage` were counted, not executed. D7 key normalization was not tested against a real bucket. |
| Web push / FCM delivery | `webpush.sendNotification` was replaced. D4's host allowlist should be checked against real browser subscriptions. |
| Azure OpenAI query understanding | Not configured, so the heuristic path was used |

## 7. Deploy notes

- **All users must sign in once more.** Access tokens without a session ID (`sid`) are now rejected (round 1).
- **Restart running backends** so they load the fixes.
- **Existing stored data:**
  - Web-push subscriptions stored before D4 that point to non-allowlisted hosts stay in the database. They will fail and be cleaned up by D8 on the next send.
  - Notification-preference documents whose `userId` was already reassigned can't be told apart from legitimate ones without production access. An admin should check for users whose stored push channel belongs to another account.
