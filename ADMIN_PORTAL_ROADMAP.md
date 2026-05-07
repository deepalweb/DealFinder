# Admin Portal Roadmap

## Goal
Transform the current admin portal from a basic operations console into a decision-ready control center for marketplace growth, moderation, merchandising, and platform health.

This roadmap is grounded in the current codebase:
- Frontend admin pages in `frontend-next/app/admin/*`
- Admin shell in `frontend-next/app/admin/layout.tsx`
- Admin dashboard API in `backend/routes/adminRoutes/adminDashboardRoutes.js`
- Admin promotions API in `backend/routes/adminRoutes/adminPromotionRoutes.js`

## Current State Summary

### What already exists
- Admin shell and sidebar navigation
- Dashboard with summary counts, expiring promotions, and recent activity
- Admin pages for users, merchants, promotions, sections, and notifications
- Section manager for homepage merchandising
- Basic CRUD and moderation actions for users, merchants, and promotions

### Main weaknesses today
- Most admin pages are table-first, not insight-first
- Limited trend analysis and almost no business intelligence
- Filtering logic is inconsistent across pages
- No shared admin data normalization layer
- Little drill-down from dashboard to actionable records
- No audit trail for admin actions
- No real system health or background job visibility
- No merchant success or promotion performance scoring
- Notification analytics is present but not tightly integrated into the admin workflow

## Product Vision

The next-level admin portal should let administrators answer five critical questions quickly:

1. What is happening in the marketplace right now?
2. What needs attention immediately?
3. Which merchants, promotions, and users are driving value?
4. What is broken, risky, or stale?
5. What actions should the admin take next?

## Guiding Principles

### 1. Accurate before advanced
No advanced charts or automation should be built on inconsistent status logic.

### 2. Drill-down everywhere
Every summary card should lead to a filtered operational view.

### 3. Shared admin infrastructure
Filtering, pagination, sorting, badges, and lifecycle status logic should be reusable across all admin pages.

### 4. Action-oriented design
Each page should surface recommended actions, not only raw data.

### 5. Marketplace-first thinking
The portal should manage supply, quality, conversion, engagement, and reliability as one connected system.

## Recommended Information Architecture

### Overview
- Dashboard
- Alerts
- Recent activity

### Marketplace
- Promotions
- Merchants
- Sections
- Campaigns

### Users
- Users
- Segments
- Engagement

### Notifications
- Analytics
- Campaigns
- Failures

### Operations
- Moderation queue
- Audit log
- System health
- Background jobs

### Settings
- Roles and permissions
- Feature flags
- App configuration

## Roadmap

## Phase 1: Admin Foundation
Objective: make admin data accurate, consistent, and reusable.

### Frontend work
- Create shared admin utilities for:
  - promotion lifecycle status
  - merchant status display
  - category normalization
  - date formatting
  - search token extraction
- Build reusable admin components:
  - filter bar
  - sortable table
  - pagination footer
  - bulk action toolbar
  - stat badge and lifecycle chip
- Move page filters into URL state where useful

### Backend work
- Normalize admin list APIs to a standard response shape:
  - `data`
  - `totalCount`
  - `page`
  - `pageSize`
  - `filters`
- Add server-side filtering and sorting support for:
  - promotions
  - merchants
  - users
- Add server-side date filters

### Data work
- Define one shared lifecycle status policy:
  - `expired` when `endDate < now`
  - `scheduled` when `startDate > now`
  - `active` when current date is within live window
  - preserve operational overrides like `pending_approval`, `rejected`, `admin_paused`, `draft`

### Deliverables
- Shared admin utility layer
- Shared admin table infrastructure
- Consistent filter behavior across admin pages
- Accurate status chips and counts

## Phase 2: Dashboard 2.0
Objective: create a true overview and action center.

### New dashboard modules
- Executive KPI strip
  - total users
  - active users
  - total merchants
  - approved merchants
  - total promotions
  - active promotions
  - expiring this week
  - notification delivery rate
- Trend cards
  - new users over time
  - new merchants over time
  - promotions created over time
  - active promotions over time
  - notification volume over time
- Marketplace health
  - dormant merchants
  - promotions missing image
  - promotions expiring today
  - merchants with no active deals
  - paused promotions
- Alert center
  - pending approvals
  - invalid or stale content
  - high-priority failures
  - sudden drop in activity

### Backend API additions
- `GET /api/admin/dashboard/overview`
- `GET /api/admin/dashboard/trends`
- `GET /api/admin/dashboard/alerts`
- `GET /api/admin/dashboard/funnels`

### Deliverables
- redesigned dashboard page
- alert cards with drill-through links
- trend APIs and chart-ready payloads

## Phase 3: Promotion Intelligence
Objective: turn promotions into a performance and moderation workspace.

### Promotions page upgrades
- Strong filtering
  - status
  - category
  - merchant
  - featured
  - date range
  - quality issues only
- Sorting
  - newest
  - oldest
  - ending soon
  - highest clicks
  - highest favorites
  - lowest quality
- New columns
  - views
  - clicks
  - CTR
  - favorites
  - comments
  - rating
  - created date
  - time remaining
- QA flags
  - expired but featured
  - no image
  - no URL
  - invalid discount
  - conflicting dates

### Bulk actions
- bulk approve
- bulk reject
- bulk pause
- bulk feature
- bulk unfeature
- bulk category change
- bulk export CSV

### Promotion details drawer/page
- status history
- performance snapshot
- merchant info
- user engagement
- comments and moderation context
- preview for web/mobile presentation

### Backend API additions
- `GET /api/admin/promotions`
  - add pagination
  - add quality filters
  - add metrics joins
- `GET /api/admin/promotions/:id`
- `GET /api/admin/promotions/:id/analytics`
- `POST /api/admin/promotions/bulk-update`

### Deliverables
- next-gen promotions page
- promotion details panel
- promotion QA and analytics support

## Phase 4: Merchant Success Console
Objective: help admin manage supply health and merchant growth.

### Merchant page upgrades
- richer filters
  - status
  - dormant only
  - low-performing only
  - no active deals
  - incomplete profile
- merchant health indicators
  - profile completeness
  - total promotions
  - active promotions
  - click volume
  - last activity date
  - approval state

### Merchant detail page
- merchant overview
- promotion portfolio
- performance summary
- contact and verification fields
- inactivity warning
- approval history
- growth recommendations

### Merchant cohorts
- newly joined
- pending approval
- dormant
- growing
- top performers
- at risk

### Backend API additions
- `GET /api/admin/merchants`
  - add pagination and filters
- `GET /api/admin/merchants/:id`
- `GET /api/admin/merchants/:id/analytics`
- `GET /api/admin/merchants/cohorts`

### Deliverables
- merchant health dashboard
- merchant detail experience
- cohort and intervention views

## Phase 5: User Intelligence
Objective: help admin understand user growth and engagement.

### User analytics
- registrations over time
- daily active users
- weekly active users
- monthly active users
- favorites per user
- notification opt-in trends
- returning user rate

### User admin improvements
- filters by:
  - role
  - created date
  - recent activity
  - has favorites
  - notification enabled
- user detail page
  - profile
  - favorites summary
  - recent interactions
  - device / notification state if available

### Segmentation
- most engaged users
- churn-risk users
- users by category preference
- users by region or location if available

### Backend API additions
- `GET /api/admin/users`
  - add pagination and analytics-aware filters
- `GET /api/admin/users/:id`
- `GET /api/admin/users/trends`
- `GET /api/admin/users/segments`

### Deliverables
- user insights page
- user detail page
- engagement-focused segmentation

## Phase 6: Merchandising and Growth Control
Objective: let admin actively shape discovery and conversion.

### Section manager evolution
- scheduling calendar
- drag-and-drop priority ordering
- content preview by section
- expiry-aware assignment warnings
- banner and campaign preview

### Campaign module
- create cross-surface campaigns
  - homepage placement
  - featured promotions
  - notification pushes
  - seasonal collections
- performance reporting by campaign

### Experimentation
- A/B test support for:
  - section order
  - featured mix
  - notification copy
  - homepage content rules

### Backend API additions
- `GET /api/admin/campaigns`
- `POST /api/admin/campaigns`
- `GET /api/admin/experiments`
- campaign performance endpoints

### Deliverables
- campaign manager
- better section scheduling
- experimentation support

## Phase 7: Reliability, Governance, and Trust
Objective: make the portal operationally safe for a real production platform.

### Audit log
- every admin action recorded:
  - approvals
  - rejects
  - deletes
  - featured toggles
  - role changes
  - merchant status changes
- searchable by admin, entity, action, date

### Moderation queue
- suspicious promotions
- duplicate content
- invalid URLs
- abusive merchants
- repeated failed submissions

### System health
- API health
- background job health
- cache freshness
- failed notifications
- upload failures
- cron/job last-run status

### Permissions
- introduce sub-roles:
  - super admin
  - content admin
  - support admin
  - analytics viewer

### Backend API additions
- `GET /api/admin/audit-log`
- `GET /api/admin/moderation/queue`
- `GET /api/admin/system-health`
- `GET /api/admin/jobs`

### Deliverables
- audit log module
- moderation queue
- system health page
- role-aware access controls

## Cross-Cutting Backend Work

### Query and aggregation layer
The admin portal will need dedicated aggregation endpoints instead of relying on frontend joins.

Recommended backend additions:
- admin analytics service layer
- reusable Mongo aggregation helpers
- paginated list helpers
- time-series query helpers
- status normalization utilities shared across admin routes

### Likely new backend modules
- `backend/routes/adminRoutes/adminAnalyticsRoutes.js`
- `backend/routes/adminRoutes/adminAuditRoutes.js`
- `backend/routes/adminRoutes/adminSystemRoutes.js`
- `backend/services/adminAnalyticsService.js`
- `backend/services/adminModerationService.js`

## Cross-Cutting Frontend Work

### Shared admin UI modules
Recommended components:
- `AdminPageHeader`
- `AdminStatCard`
- `AdminFilterBar`
- `AdminDataTable`
- `AdminDrawer`
- `AdminEmptyState`
- `AdminAlertStrip`
- `LifecycleStatusChip`
- `QualityFlagPill`

### Shared admin hooks
Recommended hooks:
- `useAdminTableState`
- `useAdminFilters`
- `useAdminPagination`
- `useAdminSelection`
- `useAdminAnalyticsRange`

## Suggested Build Order

### Milestone 1
- Admin foundation
- Shared filters/tables
- Status normalization everywhere

### Milestone 2
- Dashboard 2.0
- Drill-down alerts

### Milestone 3
- Promotions intelligence
- Bulk actions
- Promotion analytics drawer

### Milestone 4
- Merchant success console
- Merchant health scoring

### Milestone 5
- Audit log
- System health

### Milestone 6
- User analytics and segmentation

### Milestone 7
- Campaigns
- Experiments
- Advanced merchandising

## Recommended MVP for the Upgrade

If the team wants the highest-value first release, build this slice first:

### Admin Portal MVP+
- Dashboard with trends and alert cards
- Promotions page with:
  - accurate statuses
  - analytics columns
  - bulk moderation actions
- Merchants page with:
  - dormant and at-risk merchants
  - merchant health indicators
- Audit log for admin actions
- Shared admin filtering and pagination framework

This would make the portal feel significantly more mature without waiting for every analytics feature.

## Success Metrics

The upgraded admin portal should improve:
- time to approve or reject merchants/promotions
- time to detect broken or stale marketplace content
- number of dormant merchants reactivated
- quality of homepage merchandising
- admin confidence in data accuracy
- ability to act on trends without external reporting tools

## Proposed Next Execution Step

The best immediate implementation step is:

1. Build shared admin data utilities and table infrastructure
2. Redesign the dashboard around trends and alerts
3. Upgrade promotions page into the first analytics-rich admin workspace

That sequence creates the foundation for every later phase and gives the fastest visible improvement.
