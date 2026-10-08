-- Adds columns that were missed in 001 (verified against the actual Mongoose models).

ALTER TABLE bank_offers
  ADD COLUMN IF NOT EXISTS title TEXT,
  ADD COLUMN IF NOT EXISTS description TEXT,
  ADD COLUMN IF NOT EXISTS discount TEXT,
  ADD COLUMN IF NOT EXISTS code TEXT,
  ADD COLUMN IF NOT EXISTS card_types TEXT[],
  ADD COLUMN IF NOT EXISTS applicable_categories TEXT[],
  ADD COLUMN IF NOT EXISTS minimum_spend NUMERIC CHECK (minimum_spend >= 0),
  ADD COLUMN IF NOT EXISTS maximum_benefit NUMERIC CHECK (maximum_benefit >= 0),
  ADD COLUMN IF NOT EXISTS terms_and_conditions TEXT,
  ADD COLUMN IF NOT EXISTS image TEXT,
  ADD COLUMN IF NOT EXISTS images JSONB,
  ADD COLUMN IF NOT EXISTS url TEXT,
  ADD COLUMN IF NOT EXISTS featured BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS is_sponsored BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS priority INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS start_date TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS end_date TIMESTAMPTZ;

ALTER TABLE redemptions
  ADD COLUMN IF NOT EXISTS redeemed_at TIMESTAMPTZ;

ALTER TABLE reports
  ADD COLUMN IF NOT EXISTS description TEXT,
  ADD COLUMN IF NOT EXISTS resolution_note TEXT,
  ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMPTZ;

ALTER TABLE search_query_logs
  ADD COLUMN IF NOT EXISTS query TEXT,
  ADD COLUMN IF NOT EXISTS result_count INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS ai_used BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS fallback_used BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS latency_ms INTEGER DEFAULT 0;

ALTER TABLE section_assignments
  ADD COLUMN IF NOT EXISTS banner_image_url TEXT,
  ADD COLUMN IF NOT EXISTS radius_km NUMERIC,
  ADD COLUMN IF NOT EXISTS min_distance_km NUMERIC,
  ADD COLUMN IF NOT EXISTS max_distance_km NUMERIC,
  ADD COLUMN IF NOT EXISTS exclude_from_auto BOOLEAN DEFAULT false;

ALTER TABLE user_behavior_events
  ADD COLUMN IF NOT EXISTS query TEXT;

ALTER TABLE user_preference_profiles
  ADD COLUMN IF NOT EXISTS top_categories TEXT[],
  ADD COLUMN IF NOT EXISTS top_query_terms TEXT[],
  ADD COLUMN IF NOT EXISTS preferred_radius_km NUMERIC DEFAULT 10,
  ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_bank_offers_status_enddate_startdate_priority ON bank_offers (status, end_date, start_date, priority DESC, id DESC);
CREATE INDEX IF NOT EXISTS idx_bank_offers_category_status ON bank_offers (category, status, id DESC);
CREATE INDEX IF NOT EXISTS idx_bank_offers_featured_status ON bank_offers (featured, status, id DESC);
