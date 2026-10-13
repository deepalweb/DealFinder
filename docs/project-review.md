# DealFinder project review

Reviewed on 13 October 2026 from the local repository. This is a source review with local checks, not verification of the live website, cloud accounts, or production data.

## Product

DealFinder is a Sri Lankan deals discovery platform with consumer, merchant, and administrator roles. The configured public origin is `https://dealfinderapp.lk`. The code supports English, Sinhala, and Tamil, including Flutter localization resources and a web language context; translation completeness was not audited.

Consumers can browse categories, search deals, discover nearby offers, save favorites, follow merchants, view bank/card offers, and leave ratings, comments, reports, and redemption feedback. The mobile app also includes deal comparison (up to five deals), history, sharing, location permissions, QR display/scanning, and notification preferences.

Merchants have profiles, dashboards, promotion creation/editing, image uploads, engagement analytics, and QR redemption verification. Administrators have dashboards and interfaces for users, merchants, promotions, bank offers, reports, notifications, and homepage section curation.

These capabilities are present in source; their end-to-end operation depends on the selected database and configured services.

## Components and stack

| Component | Location | Technology and purpose |
| --- | --- | --- |
| API | `backend/` | Node.js (20.x declared), Express 4, CommonJS, JWT, bcrypt, express-validator, rate limiting, compression |
| Website | `frontend-next/` | Next.js 16.2.1, React 19.2.4, TypeScript, Tailwind CSS 4, App Router, Leaflet |
| Mobile | `mobile_app/` | Flutter/Dart, version `1.0.2+3`, Firebase, flutter_map, geolocation, shared preferences |
| MongoDB | `backend/models/` | Mongoose models; default application database path |
| PostgreSQL | `backend/models-pg/`, `backend/services/postgres*` | Sequelize and pg; partial alternative database path, configured for Supabase |
| Cloudflare | `cloudflare/`, root `Dockerfile` | Worker, Durable Object container binding, combined web/API container, R2 images |
| Azure | `infra/`, `azure.yaml`, `.github/workflows/main_dealfinder.yml` | App Service configuration and automated deployment |
| Mobile CI | `.github/workflows/mobile-build.yml` | Flutter Android release APK build and artifact upload |

## Request flow and hosting

In local development, Express normally listens on port 8080 and Next.js runs separately on port 3000. Web API origin resolution lives in `frontend-next/lib/config/api.ts`; mobile origin resolution lives in `mobile_app/lib/src/config/app_config.dart`.

The root production Dockerfile builds Next.js standalone output and installs the API. Express starts Next.js on loopback port 3000 and proxies requests that are not handled by API/static routes to it. The Cloudflare Worker forwards traffic to Express on port 8080, overrides forwarded client IP headers, forces R2 image storage, and sets the server-side backend origin to loopback.

Cloudflare is configured for one `basic` container instance. A five-minute cron request keeps it awake so in-process notification jobs can run. Custom domain routes are commented out in the checked-in Wrangler configuration. Azure deployment on pushes to `main` remains enabled. These files establish available deployment paths, not which host currently serves production traffic.

Image storage is selected through `IMAGE_STORAGE_PROVIDER`: local disk by default, Azure Blob Storage, or Cloudflare R2. Cloudflare container disk is ephemeral, so its Worker forces `r2`.

## Domain and API

Main entities include User, Merchant, Promotion, BankOffer, SectionAssignment, Redemption, Report, PromotionClick, NotificationPreference, NotificationLog, DealAlert, SearchQueryLog, UserBehaviorEvent, and UserPreferenceProfile. PostgreSQL additionally normalizes ratings, reviews, comments, redemption feedback, and preference categories into separate models.

Promotions contain title, description, discount/coupon code, merchant, category, date range, images, optional prices, bank/card conditions, and fulfillment mode (`visit`, `order`, or `hybrid`). Lifecycle statuses include draft, scheduled, active, expired, rejected, and admin paused. Verification metadata and consumer trust signals are also represented.

Major API groups:

- `/api/users`: registration, login, Google/Firebase authentication, refresh, password reset, profiles, favorites, followed merchants.
- `/api/promotions`: listings, homepage sections, nearby/recommended deals, CRUD, analytics, comments, ratings, reports, feedback, and QR redemptions.
- `/api/merchants`: directory, profiles, ratings/reviews, reports, dashboard, CRUD.
- `/api/bank-offers`: public offers and administrator management.
- `/api/notifications`: inbox, preferences, subscriptions, deal alerts, test/broadcast, analytics.
- `/api/ai`: behavior events, user preference profile, natural-language search, suggestions, status.
- `/api/admin`: promotion management, dashboard, section assignments/publishing, report moderation.
- `/api/images`: single/multiple upload and deletion.
- `/api/status` and `/api/config`: basic status and public client configuration.

Homepage section keys include `banner`, `hot_deals` (displayed as Ending Soon), `new_this_week`, and `flash_sales`, with manual assignments and automatic fill rules. Nearby is automatically ranked by location.

## Authentication, AI, and notifications

JWT access tokens last seven days; refresh tokens last thirty days and are tracked in an in-memory Set. Role and resource authorization middleware protect many routes. Web sessions are persisted in localStorage. Firebase ID tokens and Google OAuth are supported alongside email/password authentication.

AI search uses Azure OpenAI Responses calls to interpret queries, with heuristic parsing for categories, prices, discount, proximity, and urgency. Behavior events and preference profiles support recommendations. Azure credentials and feature flags govern availability. AI services inspected use MongoDB models.

Push delivery uses Firebase Cloud Messaging for mobile and VAPID/web-push for browsers, with email support. Scheduled jobs cover nearby offers, favorite store updates, expiring favorites, price drops, flash sales, category offers, weekly digest, and merchant expiry. Jobs run inside the API process and are disabled in PostgreSQL mode.

## Local setup

1. Install the declared Node.js runtime, Flutter SDK, and dependencies in the individual component directories.
2. Copy `backend/.env.example` to `backend/.env`; provide MongoDB connection and both JWT secrets. The backend loads this specific file, rather than the root `.env` automatically.
3. Use `PORT=8080` for the backend. The backend example currently sets port 3000, which conflicts with the normal Next.js development port.
4. Run `npm ci` and `npm start` in `backend/`.
5. Run `npm ci` and `npm run dev` in `frontend-next/`. Set `NEXT_PUBLIC_BACKEND_URL=http://localhost:8080` in `.env.local` if needed.
6. Configure mobile `.env` and Firebase platform files; `scripts/generate-mobile-secrets.js` supports generating them from environment variables. Run `flutter pub get` and `flutter run` in `mobile_app/`. Override `MOBILE_API_BASE_URL` for an emulator/device; the checked-in fallback targets production.

Google/Firebase authentication, push, email, Azure AI, and remote image storage require their respective configuration. Both JWT secrets are mandatory at API startup.

PostgreSQL mode uses `DATA_SOURCE=postgres` and `DATABASE_URL`. Migration and data-copy scripts exist under `backend/scripts/pg/`, but database switching should follow a feature parity review; it does not currently enable all product workflows. No migration or seed script was run during this review.

## Findings

| Priority | Finding and evidence | Effect |
| --- | --- | --- |
| High | `backend/routes/imageRoutes.js` deletion requires authentication but does not check owner/admin authorization; the R2 provider deletes a supplied key within its public URL prefix. | An authenticated user can request deletion of another user's image if its URL is known. |
| High | PostgreSQL login exists, but registration, Firebase sync, refresh, favorites, profile operations, notification routes, AI services, and QR redemption still use MongoDB models in inspected paths. `backend/server.js` skips MongoDB connection and notification jobs in PostgreSQL mode. | PostgreSQL is a partial implementation, not a complete replacement for MongoDB. |
| Medium | Refresh tokens live only in process memory (`backend/routes/userRoutes.js`); web logout clears local state without calling the server logout endpoint (`frontend-next/contexts/AuthContext.tsx`). | Restarts invalidate refresh sessions; web logout does not revoke the server-side refresh token. |
| Medium | `/api/status` always returns success independently of database readiness; connection failures are logged without blocking listen (`backend/server.js`). | Container/cloud health checks can report healthy while database-backed requests fail. |
| Medium | Notification scheduler specifies no timezone; merchant expiry is scheduled by cron and also invoked at startup/every 24 hours. | Schedule times depend on runtime timezone; overlapping expiry paths need deduplication verification. |
| Medium | Android release Gradle configuration requires signing credentials, but the mobile workflow does not visibly provision a keystore or signing properties. | Clean CI release builds may fail unless signing material is provided through another mechanism. |
| Medium | Both Azure and Cloudflare deployment paths remain; Wrangler domain routes are commented out. Root and component configuration examples differ. | Deployment ownership and cutover state are unclear from source alone. |
| Low | Root README contains only a title and old deployment trigger; frontend README is largely scaffold documentation. | Project onboarding relies on reading implementation and scattered configuration. |

Other review targets: image uploads validate extensions rather than actual image content, and allow up to five 20 MB files buffered in memory; Next.js permits broad remote image hosts; promotion route code exceeds 2,000 lines and combines many concerns. These deserve targeted validation before treating them as confirmed production incidents.

## Validation

- `node --check`: passed for all 111 backend JavaScript files discovered outside dependencies.
- `npx tsc --noEmit` in `frontend-next`: passed.
- `npm run lint` in `frontend-next`: passed with 29 warnings and zero errors. Warnings concern React Hook dependencies and unoptimized `<img>` elements.
- `flutter test --no-pub` in `mobile_app`: all four widget tests passed.
- No backend or web automated test script is declared in their package manifests. Backend diagnostic scripts exist, but some interact with real data or services and were not executed.
- Mobile test source contains four widget tests for authenticated/unauthenticated routing, loading, and preserved navigation tab state.
- Cloud deployment, Docker build, database migrations, external integrations, and full end-to-end user flows were not exercised.

Application source was not changed. Four pre-existing untracked mobile screenshots were left untouched.

## Missing and incomplete items: follow-up check

Checked on 13 October 2026. Configuration status below refers to local `backend/.env`, not cloud environment variables. Only presence was reported; secret values were not included. A read-only PostgreSQL connection/authentication attempt failed with server error code `XX000`; this does not prove the database is absent or identify the underlying cause. No records were queried or changed.

| Priority | Area | Missing or incomplete | Next action |
| --- | --- | --- | --- |
| P0 | Working local database connection | Local `DATA_SOURCE=postgres` and `DATABASE_URL` exist, but connection/authentication failed. `MONGO_URI` is absent locally. | Diagnose PostgreSQL URL, pooler settings, credentials, and service status. Do not assume the database needs creating. |
| P0 | PostgreSQL feature parity | Several auth/account paths, notifications, AI services, and QR redemption still access MongoDB. PostgreSQL mode skips Mongo connection and scheduled notification jobs. | Complete and verify database support across these flows before relying on PostgreSQL as the sole database. |
| P0 | Image ownership | Image deletion has no owner/admin permission check. | Persist/resolve ownership and enforce it before deleting. |
| P1 | Web password reset | Request handler generates a token but logs a localhost reset URL; it does not send email. The web page has only the request form, with no token/new-password confirmation flow, and does not check the HTTP response status. | Implement email delivery, the confirmation UI, correct public URLs, and error handling. Mobile separately uses Firebase password reset; that does not complete the web/API password flow. |
| P1 | Contact submission | Contact page only shows a success toast and clears the form; no request is sent. | Add an actual submission destination and show success only after delivery/acceptance. |
| P1 | Persistent sessions and revocation | Refresh tokens are stored in memory; web logout does not revoke the backend refresh token. | Use durable session storage, revoke on logout, and verify session behavior after restart/password changes. |
| P1 | Web push configuration | Local VAPID public/private keys are missing. | Configure and verify browser subscription and delivery; PostgreSQL notification support also needs completion. |
| P1 | Email configuration | Local M365 sender/password and email password are missing. Mailer implementation uses Office 365 SMTP rather than the generic host settings in the template. | Configure the actual mailer and verify delivery. Credentials alone do not fix the unfinished password-reset handler. |
| P1 | Database readiness | Health endpoint does not test database availability. | Separate liveness from readiness and make readiness fail when required dependencies are unavailable. |
| P1 | Automated regression coverage | No backend/web test scripts; only four mobile widget tests. Deployment workflows do not run regression tests. | Cover auth, permissions, PostgreSQL parity, promotion lifecycle, and redemption; run checks in CI. |
| P2 | Durable notification scheduling | `NotificationService.scheduleNotification` is a stub that logs and returns success. Jobs otherwise run in-process with no explicit scheduler timezone. | Implement durable scheduling/retry and specify intended timezone. The stub was not found in use elsewhere. |
| P2 | Production image storage selection | Local provider is unset, so uploads use local disk even though an Azure storage connection string exists. R2 settings are absent locally. | Explicitly select/configure the intended persistent provider for each production host. Local disk is valid for development. |
| P2 | AI configuration | Local Azure OpenAI endpoint/API key/model settings are missing. | Configure them if AI-assisted query interpretation is intended; heuristic search remains available, subject to database support. |
| P2 | iOS build configuration | Local `GoogleService-Info.plist` is absent; Firebase Dart iOS options exist. No iOS build workflow was found. | Verify the chosen Firebase iOS setup, bundle identity, signing, and a real iOS build. Absence of the plist alone does not establish all Firebase initialization is broken. |
| P2 | Mobile release CI signing | Local Android signing properties exist, but CI does not visibly provision signing material required by Gradle. | Supply signing material securely in CI and verify a clean release build. |
| P2 | True mobile background work | `BackgroundLocationService` uses a Dart timer started/stopped with the nearby screen. | If notifications must work with the app suspended/closed, implement and verify an OS-supported background mechanism or server-driven approach. |
| P2 | Account deletion completeness | Only admin user deletion was found; that handler deletes the user document without related-data cleanup. | Define account deletion/anonymization and related-record handling; add a consumer flow if required by the product. |
| P2 | Operational procedures | No repository backup/restore runbook, restore test, centralized error reporting integration, or admin action audit trail was identified in the inspected code. Cloud-managed facilities may exist independently. | Verify external facilities first, then document and fill actual operational gaps. |
| P2 | Deployment clarity | Azure CI remains enabled, Cloudflare routes are commented out, and Wrangler defaults to Mongo while local backend selects PostgreSQL. | Document the intended host/database combination and align deployment configuration. |

Already present locally: backend/web/mobile environment files, PostgreSQL URL, JWT secrets, Firebase backend credential entries, Android Firebase JSON, and Android signing properties. Presence does not validate these credentials or prove the associated services work. Database schemas and PostgreSQL migration scripts also exist; the main database gaps are connectivity and incomplete application integration.

## Database configuration update

On 13 October 2026, the local backend was switched to the newly supplied MongoDB connection using `DATA_SOURCE=mongo` in the ignored `backend/.env` file. Connection, authentication, and a read-only ping passed. The supplied database name is `test`; five existing collections were visible. No records were changed, migrated, or seeded, and the connection credentials are not recorded here.

The earlier local PostgreSQL connectivity finding describes the configuration before this change. PostgreSQL feature parity remains incomplete, but the backend now selects its MongoDB code paths. Following startup log review, the legacy `DATABASE_URL` was commented out locally to disable its connection attempt, and the misspelled `NODE_ENV` value was corrected to `development`. PostgreSQL configuration remains in a comment for reference. Browser push still requires VAPID keys. Cloud deployment secrets were not updated. Restart an existing backend process to load the new configuration.

## Mobile development discounts

Added six fictional `[DEMO]` merchants and ten `DFDEV-` discounts to the MongoDB `test` database: eight active, one upcoming, and one expired. Prices use LKR. Categories cover food, electronics, shopping, groceries, wellness, and beauty. Demo locations are around Colombo for nearby search; offers include visit, order, and hybrid fulfillment, a flash sale ending today, and three featured deals. Images use external sample photo URLs; ordering links point to example.com and do not place orders.

Five section assignments populate the banner, flash sales, and ending-soon sections. Existing records were preserved; no user accounts were created. Verified saved merchant links and prices/currency, and checked the running local API: listings, nearby search, and homepage sections all returned HTTP 200 with demo data.

To refresh the sample dates/data, run `npm run seed:mobile-demo` from `backend/`. The script is restricted to MongoDB database `test` and updates the same demo records rather than duplicating them. Its dates follow the current runtime date in Asia/Colombo. The old `seedDatabase.js` deletes existing data and should not be used for this task.

Point the mobile app at this local API to see the new samples: Android emulator `http://10.0.2.2:8080/api/`; a physical phone needs the development computer's reachable LAN IP. The mobile fallback currently points to the public website, which does not receive these local configuration changes.

## Web and mobile database connection

Both local clients now use the Express API connected to MongoDB; neither client receives database credentials. `frontend-next/.env.local` sets both public API origin variables and the server-side backend origin to `http://localhost:8080`. The running web server returned HTTP 200 and its served JavaScript contained port 8080 with no stale port 8082 configuration. API listing requests from the web origin passed CORS and returned eight active demo discounts.

The connected Samsung Android phone uses `MOBILE_API_BASE_URL=http://localhost:8080/api/` and `MOBILE_PUBLIC_BASE_URL=http://localhost:8080` in the ignored mobile `.env`. Debug builds permit local HTTP through the debug-only Android manifest. Built, installed, and launched the updated debug APK; its logs confirmed eight promotions and eight merchants fetched/cached from the network, and a nearby request returned HTTP 200 with eight promotions.

This computer also has an unrelated camera-management service listening on IPv4 localhost port 8080. Direct USB forwarding to that port reached the wrong service, so `scripts/mobile-api-forward.js` bridges `127.0.0.1:18080` to the actual DealFinder backend on `[::1]:8080`. The phone forwards its port 8080 to this bridge. The bridge is running in the current development session.

For a future USB development session, keep the backend and web app running, run `npm run mobile:api` at the repository root, then run `adb reverse tcp:8080 tcp:18080` with the phone connected (add `-s <device-id>` if more than one device is attached). USB forwarding must be restored after a disconnect/reboot. Rebuild/restart Flutter after changing its bundled `.env`. This setup is local development only; production hosting configuration was not changed.

## Mobile design update

The Flutter app now uses the sapphire visual system, shared light/dark/high-contrast themes, updated navigation, redesigned discovery/store/account layouts, and themed supporting screens. See [mobile-design.md](mobile-design.md) for decisions, accessibility measurements, scope, and validation. The app continues to use the same Express API and MongoDB data.
