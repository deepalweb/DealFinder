# AI Implementation Plan

## Goal
Introduce backend-first AI capabilities for DealFinder so the web app can return faster, smarter, and more personalized deal results without pushing AI logic into the frontend.

This plan is designed around the current codebase:
- `backend/` is the main place to add AI orchestration, ranking, search, and profiling.
- `frontend-next/` should only call new backend endpoints and render returned results.
- `mobile_app/` can later reuse the same backend APIs.

## What Exists Today

### Data and behavior signals already available
- Promotions with category, merchant, pricing, dates, ratings, and comments
- Merchant location data with a `2dsphere` index
- User favorites in `backend/models/User.js`
- Promotion click/view/direction events in `backend/models/PromotionClick.js`
- Nearby deals endpoint in `backend/routes/promotionRoutes.js`
- Client-side recommendation logic in `mobile_app/lib/src/services/recommendation_service.dart`
- Client-side search history and advanced filtering logic in `mobile_app/lib/src/services/search_service.dart`

### Current limitations
- Search and recommendations are still mostly client-side
- Web homepage fetches broad promotion lists and scores locally
- User preference learning is weak and split across platforms
- There is no unified backend user profile for personalization
- There is no semantic search or AI-assisted ranking layer yet

## Core Design Principle
Do not send every search or recommendation request directly to GPT-5.

For speed, cost, and accuracy, use a layered backend pipeline:

1. Fast deterministic filtering in MongoDB
2. Candidate retrieval from MongoDB and, later, Azure AI Search
3. Rule-based and feature-based ranking
4. GPT-5 only where it adds real value:
   - natural-language query understanding
   - semantic reranking for ambiguous queries
   - explanation generation
   - user/category summarization
   - cold-start reasoning when behavior data is thin

This keeps the app responsive while still using AI meaningfully.

## Recommended AI Use Cases

### Phase 1 priorities for web
1. Intelligent search and filtering
2. Personalized recommendation feed
3. User preference profiling
4. Location-aware ranking
5. Admin-facing AI insights later, after core recommendation quality is stable

### Examples
- "cheap food deals near me ending today"
- "show me fashion offers similar to what I saved before"
- "recommend deals for users who like electronics and shop in Colombo"

## Target Architecture

### 1. AI gateway in backend
Add a dedicated backend module layer:
- `backend/services/ai/azureOpenAIClient.js`
- `backend/services/ai/queryUnderstandingService.js`
- `backend/services/ai/recommendationService.js`
- `backend/services/ai/userProfileService.js`
- `backend/services/ai/searchIndexService.js`
- `backend/services/ai/explanationService.js`

Responsibilities:
- call Azure OpenAI safely
- build prompts
- enforce timeouts and fallbacks
- cache AI outputs
- keep model usage isolated from route handlers

### 2. Event collection and user behavior pipeline
Create a unified event stream from web and mobile:
- search submitted
- search result clicked
- promotion viewed
- promotion favorited/unfavorited
- merchant viewed
- nearby search used
- category filter used
- direction intent
- share intent
- conversion or redemption event later

Recommended collection:
- `UserBehaviorEvent`

Suggested fields:
- `userId`
- `sessionId`
- `platform` (`web`, `mobile`)
- `eventType`
- `promotionId`
- `merchantId`
- `category`
- `query`
- `filters`
- `location`
- `timestamp`

### 3. Unified user preference profile
Create a materialized profile per user:
- favorite categories
- favorite merchants
- preferred discount band
- preferred distance range
- active hours/days
- high-engagement locations
- inferred price sensitivity
- inferred user segment

Recommended collection:
- `UserPreferenceProfile`

This profile should be updated asynchronously from behavior events rather than recomputed on every request.

### 4. Candidate retrieval layer

#### Stage A: Immediate approach
Use MongoDB/Cosmos queries for:
- active deals
- category filters
- price filters
- merchant filters
- nearby filtering
- freshness windows

#### Stage B: Search upgrade
Add Azure AI Search for:
- keyword + vector hybrid search
- semantic recall for natural-language queries
- suggestions and typeahead
- synonym handling
- better ranking over larger inventories

Recommended indexed content:
- promotion title
- description
- category
- merchant name
- tags
- normalized location labels
- structured ranking signals
- vector embedding for semantic search

### 5. Ranking layer
After retrieval, score the candidate set using weighted signals:
- query relevance
- category affinity
- merchant affinity
- favorite history
- location distance
- discount attractiveness
- freshness
- expiry urgency
- popularity
- rating quality
- personalization confidence

Start with a transparent weighted formula. Move to ML ranking later only if needed.

### 6. GPT-5 usage pattern
Use GPT-5 selectively:

#### Good uses
- parse natural-language search into structured filters
- infer intent and category
- generate short recommendation explanations
- classify users into soft segments
- summarize why a recommendation set was chosen

#### Avoid for hot-path ranking
- ranking hundreds of promotions per request
- basic filtering
- exact sorting logic
- geospatial calculations

## Backend APIs To Add

### Search
- `POST /api/ai/search`
  - input: free-text query, user context, filters, location
  - output: ranked promotions, interpreted filters, explanation metadata

- `GET /api/ai/search/suggestions`
  - input: partial query
  - output: query suggestions, category suggestions, merchant suggestions

### Recommendations
- `GET /api/ai/recommendations/home`
  - personalized feed for homepage

- `GET /api/ai/recommendations/nearby`
  - personalized nearby recommendations

- `GET /api/ai/recommendations/similar/:promotionId`
  - similar deals based on category, merchant, embeddings, and user profile

### Profiles and events
- `POST /api/ai/events`
  - unified behavior ingestion

- `GET /api/ai/profile/me`
  - user preference summary for debugging and future settings UI

### Admin and tuning
- `GET /api/admin/ai/recommendation-metrics`
- `POST /api/admin/ai/rebuild-profiles`
- `POST /api/admin/ai/reindex-search`

## Data Model Additions

### New collections
- `UserBehaviorEvent`
- `UserPreferenceProfile`
- `RecommendationSnapshot` for offline analysis
- `SearchQueryLog`

### Optional later collections
- `PromotionEmbedding`
- `MerchantEmbedding`
- `UserSegment`

## Search Strategy

### Version 1
Use deterministic filters plus lightweight AI query understanding:
- GPT-5 converts user text into a structured search request
- backend applies validated filters to MongoDB
- backend ranks top candidates using business and behavior signals

Example structured output:
- normalized query text
- categories
- price intent
- location intent
- urgency intent
- merchant intent

### Version 2
Introduce Azure AI Search hybrid search:
- keyword search
- vector similarity search
- metadata filters
- backend reranking

This is the right long-term path if the deal catalog grows and query variety increases.

## Recommendation Strategy

### Home recommendations
Candidate generation:
- active promotions
- top categories
- favorite merchants
- trending deals
- location-relevant deals

Ranking signals:
- favorite overlap
- recent behavior
- category strength
- merchant strength
- deal freshness
- distance
- quality score

### Nearby recommendations
Primary signals:
- merchant proximity
- category affinity
- popularity in that area
- urgency and expiry

### Cold-start users
Fallback ranking:
- featured deals
- trending deals
- geo-relevant deals
- high-quality deals by rating and engagement
- onboarding preference capture

## Speed Strategy

### Keep the hot path fast
- avoid calling GPT-5 for every request when cached or inferred data exists
- only send top candidate sets into expensive AI steps
- use short request timeouts and deterministic fallback ranking
- precompute user profiles on a schedule or via event-triggered updates
- cache recommendations per user for a short TTL
- cache parsed search intents for repeated queries

### Recommended caching
- Redis if available
- otherwise start with in-memory cache and move to Redis before scale

Cache targets:
- parsed query intents
- homepage recommendations
- nearby recommendation result sets
- user preference profiles
- similar-deal computations

## Accuracy Strategy

### Make recommendations trustworthy
- combine behavior signals with hard business constraints
- never recommend expired or invalid promotions
- weight recent interactions more than old ones
- validate AI-generated filters before querying
- log AI decisions for inspection
- keep deterministic fallbacks for all critical flows

### Recommended evaluation metrics
- search click-through rate
- recommendation click-through rate
- favorites per recommended impression
- conversion or redemption rate later
- repeat visit rate
- query success rate
- latency p50 and p95
- GPT request cost per 1,000 requests

## Security and Privacy

### Required safeguards
- do not give GPT direct unrestricted database access
- backend fetches only the needed fields and sends minimal context to the model
- redact secrets, tokens, and sensitive user fields
- avoid sending raw personal identifiers unless required
- store only coarse location when possible for profiling
- add audit logging for model prompts and outputs in non-sensitive form

### Practical rule
The model should see a curated payload, not the database connection and not full user documents.

## Infrastructure Changes

### Needed soon
- Azure OpenAI environment variables in backend config
  - endpoint
  - api key or managed identity
  - deployment name
  - API version if required by SDK choice

### Likely needed next
- Azure AI Search service
- optional Redis cache
- background worker or scheduled jobs for profile rebuilding and indexing

### Infra note
Current `azure.yaml` and `infra/main.bicep` do not yet provision Azure OpenAI or Azure AI Search, so AI infra should be added as a separate step.

## Recommended Rollout Phases

## Phase 0: Foundation
Objective: create the data and integration base.

Deliverables:
- Azure OpenAI connection from backend
- AI service layer in backend
- unified event ingestion endpoint
- behavior event schema
- user preference profile schema
- feature flags for AI search and AI recommendations

## Phase 1: AI search for web
Objective: improve search quality first because it is high-intent traffic.

Deliverables:
- `POST /api/ai/search`
- GPT-assisted query parsing
- deterministic backend filtering
- weighted ranking
- search suggestions endpoint
- query logging and evaluation dashboard basics

Success criteria:
- lower zero-result searches
- better click-through on search results
- acceptable p95 latency

## Phase 2: Personalized home recommendations
Objective: personalize the homepage and recommendation carousels.

Deliverables:
- profile builder job
- `GET /api/ai/recommendations/home`
- `GET /api/ai/recommendations/similar/:promotionId`
- explanation labels like "Because you save food deals" or "Popular near you"

Success criteria:
- higher homepage engagement
- more favorites from recommended deals
- measurable lift versus non-personalized baseline

## Phase 3: Location and segment intelligence
Objective: strengthen nearby and segment-based ranking.

Deliverables:
- profile enrichment with location and time-of-day behavior
- `GET /api/ai/recommendations/nearby`
- user segment inference
- merchant/category demand insights

Success criteria:
- stronger nearby click-through
- better relevance for returning users

## Phase 4: Azure AI Search hybrid retrieval
Objective: scale search quality and semantic recall.

Deliverables:
- search index design
- promotion indexing pipeline
- embeddings pipeline
- hybrid query endpoint
- backend reranking

Success criteria:
- improved recall for natural-language queries
- better long-tail search performance
- stable latency and controlled cost

## Phase 5: Mobile reuse
Objective: move mobile from local scoring to shared backend intelligence.

Deliverables:
- mobile app consumes AI recommendation and AI search endpoints
- mobile behavior events flow into the same backend pipeline
- local-only recommendation logic becomes fallback only

## Recommended Build Order

1. Event tracking unification
2. User preference profile
3. AI search endpoint
4. Personalized homepage recommendations
5. Similar deals
6. Nearby personalized ranking
7. Azure AI Search hybrid search
8. Mobile adoption

## Practical First Sprint

If we start now, the best first sprint is:

1. Add backend AI module scaffold and Azure OpenAI config
2. Add `UserBehaviorEvent` and `UserPreferenceProfile`
3. Add `POST /api/ai/events`
4. Add `POST /api/ai/search` with:
   - query understanding
   - deterministic filters
   - weighted ranking
   - fallback when AI is unavailable
5. Update web frontend to call the new search API
6. Instrument metrics and latency logging

This gives the fastest visible value with manageable implementation risk.

## Recommendations Specific To This Repo

### Reuse existing strengths
- Keep using `PromotionClick` as one input signal
- Reuse merchant geolocation for nearby ranking
- Reuse favorites as a strong personalization signal
- Reuse existing homepage and nearby endpoints as fallback sources

### Move logic out of clients
- web homepage recommendation scoring should move out of `frontend-next/app/page.tsx`
- mobile recommendation logic in `mobile_app/lib/src/services/recommendation_service.dart` should become fallback only
- mobile search filtering in `mobile_app/lib/src/services/search_service.dart` should eventually call backend AI search

## Risks To Manage

### Product risks
- weak personalization if event volume is too low at the start
- inconsistent behavior if web and mobile do not log the same events
- cold-start quality for anonymous users

### Technical risks
- high latency if GPT-5 is placed directly in the hot path too often
- prompt drift if structured output is not validated
- higher infra cost if embeddings and model calls are not cached
- search index staleness if indexing is not automated

## Final Recommendation
Start with backend AI search and profile-driven recommendation using a hybrid approach:
- deterministic filtering and ranking for speed
- Azure OpenAI GPT-5 for query understanding and selective reasoning
- Azure AI Search added after the first version proves user value

That path is the best balance of speed, accuracy, implementation complexity, and future scalability for this project.
