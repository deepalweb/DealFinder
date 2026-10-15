# Merchant workspace redesign

Implemented against `DealFinder_Merchant_Codex_Prompt.md`, supplied on 15 October 2026. This changes the existing **Next.js merchant web flow**, with one mobile API compatibility adjustment. The consumer web redesign and other pending mobile work remain in place. No deployment, GitHub push, destructive seed or production record edits were performed.

## Review and design decisions

The brief is appropriate for DealFinder: reusable store information, conditional offer fields, a customer preview, drafts and honest review status. The old profile form displayed category, website and banner but omitted them from its update payload. The old promotion editor required a code for every offer, had no server draft persistence, and the backend immediately published merchant creations. Its dashboard also grouped pending and scheduled records as active and appended “OFF” to all benefits.

Kept sapphire and existing typography/theme tokens, solid surfaces and the three-tab promotion editor. Desktop uses a form plus preview; compact screens use one column and an explicit preview action. Labels, error summaries, keyboard tabs, meaningful upload feedback and restrained status text replace the previous decorative dashboard. No new motion is necessary for this workflow.

Guidance: `.design-rules/SKILL.md` is present. Shared web principles were taken from `references/hig/entering-data.md` (Best practices), `text-fields.md` (Best practices) and `feedback.md` (Best practices), alongside the previously read accessibility/layout/type/color references. UI UX Pro Max’s `error summary validation --domain ux` matched focusable summaries, field links and inline errors. The Next.js stack query recommended input authorization/validation; the existing Express API client was retained instead of introducing Server Actions.

[Groupon's public signup](https://www.groupon.com/merchant/signup) confirms the business-information intake pattern. The supplied Campaign Builder article timed out when fetched; signed-in Groupon forms were not inspected or copied.

## Field and workflow map

| Area | Implementation / contract |
| --- | --- |
| Store identity | Existing `name`, `profile`/`description`, `category`, `currency`; use current category IDs and retain the merchant's currency. New empty forms default to LKR. |
| Public contacts | Existing `contactNumber`, `contactInfo` (public contact email), website and social URLs. Account email is not copied into the merchant payload. Sri Lankan local numbers normalize to +94; supported international numbers remain valid. |
| Business mode | Existing `merchantType`: offline, online, hybrid. Conditional address/pin or online destination requirements. |
| Location | Existing address includes city/area; Google MapPicker preserves `[longitude, latitude]`. Bounded coordinates are validated. No branches or invented city field. |
| Availability | Existing opening hours, optional same-day windows in Asia/Colombo; no temporary-closure control. |
| Branding | Existing logo/banner now included in saves; bounded upload, indeterminate progress, failure/retry and local fallback. Optional fields are clearly presented. |
| Offer basics | Existing title/category/description and visit/order/hybrid semantics. Merchant is resolved from the authenticated linked account. |
| Benefit | Percentage, fixed saving, special price, BOGO and descriptive benefit inputs. Discount text stays consumer-compatible; additive `benefitType`/`benefitValue` preserve edit intent. Percentage prices derive from the stated percentage. Empty monetary fields remain absent. |
| Eligibility | Existing bank/card types and min/max conditions persist through the draft flow. These are merchant-declared conditions. Standalone BankOffer creation remains admin-only. |
| Conditions | Additive `termsAndConditions`, plain text; already supported by consumer details. Booking, weekdays, exclusions and membership are descriptive conditions, not automated enforcement. |
| Images | Up to five ordered images; first is cover. Make-cover/remove operates on draft references. Upload is completed before save/submit; original file remains available for retry after upload failure. |
| Dates | Date-only entry, Asia/Colombo start/end boundaries; full end day included. Existing lifecycle is day-based. No claim of precise intraday activation. |
| How to use | Optional coupon; valid online destination; physical location/directions. Consumer detail now prioritizes `orderLink` and suppresses directions for online-only offers. Existing QR endpoints/mobile scanner are preserved. |
| Drafts | New MongoDB `MerchantDraft`: owner + merchant + unique client key, allowlisted incomplete data, stable promotion ID. Private workspace reads bypass the public client cache. |
| Recovery | Same-tab session recovery keyed by account/merchant and draft/source. Public form fields only; no tokens or private account contacts in recovery data. Saved server drafts survive revisits. |
| Preview | Uses the same typed `displayOffer` pricing/image/benefit model as consumer cards/details, with clear unpublished labeling and no consumer mutation/analytics calls. |
| Submission | New MongoDB `pending_review` state. Submission is idempotent by stable promotion ID, does not feature/verify the offer and does not trigger consumer notifications. Administrator approval validates the complete offer before selecting the existing active/scheduled lifecycle. |
| Workspace | Separate draft/review/scheduled/active/expired/rejected/paused views. Metrics count promotions, not purchases or measured visits. |
| Editing existing offers | Web action creates a **separate revised offer** for review. It explicitly does not replace the live offer. Previous published terms remain intact. Existing legacy mobile edits to already published offers retain their current immediate-update policy; draft/rejected/paused/review records cannot use date edits to bypass review. |

## API and authorization changes

- `/api/merchant-workspace` and `/drafts/:id` require merchant role and a fresh account-to-store link. Draft reads, writes and submissions are scoped to both owner and merchant.
- Draft payloads cannot set ownership, publication status, featuring, verification or arbitrary account fields. Submission constructs public promotion data on the server.
- MongoDB merchant creation through the legacy promotion route also starts in `pending_review`; merchants cannot directly approve it.
- Public merchant promotion lists/details exclude private review states. Authenticated owners retain their own complete promotion list. The mobile owner-dashboard API now sends its existing authenticated GET so private review records remain reachable; public store browsing remains anonymous.
- Store mutations use fresh Mongo account ownership, existing writable-field allowlists, URL/phone/hour/coordinate validation and actual API acceptance.
- Image uploads are capped at 20 MB and inspect format signatures, not extension alone. New files use account namespaces. Standalone deletion and automatic store-image cleanup allow the uploader or an administrator; legacy unscoped files require an administrator. Removing a draft image does not immediately delete a remote blob.
- Administrator UI exposes Pending review, Approve and Reject. Pending/draft offers are excluded from bulk resume; individual review is required. No auto-verification or curated placement is granted.

## Verification

- `npm run build` in `frontend-next`: passed, all 31 routes compiled.
- `flutter analyze lib/src/services/api_service.dart` in `mobile_app`: passed with no issues for the compatibility change.
- TypeScript and targeted ESLint for merchant screens/components/helpers, admin integration and affected consumer detail: passed.
- `node --test backend/tests/merchant-workflow.test.js`: 8 passing tests. Covers writable-field restrictions, actual Mongoose field casting, incomplete drafts, tenant isolation, fresh ownership, pricing/dates/conditional requirements, image policy and duplicate review submission. HTTP integration uses isolated in-memory model doubles; no live database writes.
- `node --experimental-strip-types --test frontend-next/tests/merchant-form.test.mjs frontend-next/tests/offer-display.test.mjs`: 11 passing tests, including benefit/pricing/date round trips and consumer presentation regressions.
- Headless Chrome on the local Next.js app, with intercepted API fixtures: passed save failure/retry, upload failure/retry, persisted-draft reload, bank/percentage serialization, submit failure/retry, pending-review feedback, private-email exclusion, error-summary focus, unsaved recovery scoped to the current merchant even with a stale session claim, zero preview analytics/redemption calls, online destination/directions, and administrator approval controls.
- Browser layouts: 320, 390, 768, 1024 and 1440px; English/Sinhala/Tamil; dark theme and 24px root text. No horizontal overflow or page exceptions in the checked scenarios. This is not a screen-reader audit or a real mobile device check.
- Rendered screenshots: [preview gallery](merchant-workspace-preview/index.html). Screenshots use a fictional merchant and controlled API data, including a deliberate image fallback. They are not production account evidence.

## Deferred and operational limits

- **Backend restart is needed** to load the new routes/models. The running backend process was not restarted because startup initializes notification jobs. No real merchant account mutations, live cloud upload/delete, or Atlas persistence/approval journey were performed in this review run. Verify those on a development account after restarting the backend.
- Draft/review implementation targets the project's current MongoDB mode. PostgreSQL receives an explicit unsupported-workflow response rather than silently using MongoDB or permitting merchant self-publication. No PostgreSQL schema or provider configuration was changed.
- Live-version replacement, withdrawal, structured rejection reasons and revision history require a deliberate versioning/moderation design. Revised web submissions are separate offers; administrators must manage overlap with the original offer.
- WhatsApp, branches, private verification documents, temporary closure, structured promotion weekdays/time windows, automated membership/redemption limits and standalone merchant BankOffer authoring are deferred. No functional-looking controls were added for them.
- Full image decoding/scan and orphan upload garbage collection are not included; content validation is signature-based. Legacy image administration remains available to administrators.
- Google map tile/API authorization, real screen readers, translation review by native speakers and real-device/release checks remain to be verified. No production verification or deployment is claimed.
