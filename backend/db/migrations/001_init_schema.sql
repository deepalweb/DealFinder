-- DealFinder: initial Postgres schema (MongoDB -> Postgres migration, Batch 0)
-- Idempotent: safe to re-run.

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS postgis;

-- ========================================================================
-- Core tables
-- ========================================================================

CREATE TABLE IF NOT EXISTS merchants (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  name TEXT NOT NULL UNIQUE,
  profile TEXT,
  description TEXT,
  category TEXT,
  merchant_type TEXT NOT NULL DEFAULT 'offline'
    CHECK (merchant_type IN ('offline', 'online', 'hybrid')),
  website TEXT,
  order_link TEXT,
  delivery_available BOOLEAN DEFAULT false,
  pickup_available BOOLEAN DEFAULT false,
  opening_hours JSONB,
  contact_info JSONB,
  logo TEXT,
  banner TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  address TEXT,
  contact_number TEXT,
  social_media JSONB,
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'pending_approval', 'approved', 'rejected', 'suspended', 'needs_review')),
  currency TEXT DEFAULT 'USD',
  location_geog GEOGRAPHY(Point, 4326)
);
CREATE INDEX IF NOT EXISTS idx_merchants_category ON merchants (category);
CREATE INDEX IF NOT EXISTS idx_merchants_merchant_type ON merchants (merchant_type);
CREATE INDEX IF NOT EXISTS idx_merchants_created_at ON merchants (created_at);
CREATE INDEX IF NOT EXISTS idx_merchants_status ON merchants (status);
CREATE INDEX IF NOT EXISTS idx_merchants_location_geog ON merchants USING GIST (location_geog);

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'merchant', 'admin')),
  merchant_id TEXT REFERENCES merchants(id),
  business_name TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  logo TEXT,
  reset_password_token TEXT,
  reset_password_expires TIMESTAMPTZ,
  profile_picture TEXT,
  push_subscription JSONB,
  preferences JSONB
);
CREATE INDEX IF NOT EXISTS idx_users_merchant_id ON users (merchant_id);

CREATE TABLE IF NOT EXISTS promotions (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  discount TEXT NOT NULL,
  code TEXT NOT NULL,
  category TEXT NOT NULL,
  merchant_id TEXT NOT NULL REFERENCES merchants(id),
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  images JSONB,
  image TEXT,
  url TEXT,
  fulfillment_type TEXT NOT NULL DEFAULT 'visit'
    CHECK (fulfillment_type IN ('visit', 'order', 'hybrid')),
  order_link TEXT,
  visit_available BOOLEAN DEFAULT true,
  delivery_available BOOLEAN DEFAULT false,
  pickup_available BOOLEAN DEFAULT false,
  featured BOOLEAN DEFAULT false,
  original_price NUMERIC,
  discounted_price NUMERIC,
  bank_name TEXT,
  card_types TEXT[],
  offer_type TEXT CHECK (offer_type IN (
    'discount', 'cashback', 'installment', 'dining', 'grocery',
    'fuel', 'travel', 'electronics', 'online', 'other'
  )),
  minimum_spend NUMERIC CHECK (minimum_spend >= 0),
  maximum_benefit NUMERIC CHECK (maximum_benefit >= 0),
  status TEXT NOT NULL DEFAULT 'draft'
    CHECK (status IN ('active', 'scheduled', 'expired', 'rejected', 'admin_paused', 'draft')),
  admin_verified BOOLEAN DEFAULT false,
  verified_at TIMESTAMPTZ,
  verified_by TEXT REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_promotions_status_enddate_startdate_id ON promotions (status, end_date, start_date, id DESC);
CREATE INDEX IF NOT EXISTS idx_promotions_merchant_status ON promotions (merchant_id, status);
CREATE INDEX IF NOT EXISTS idx_promotions_featured_status_id ON promotions (featured, status, id DESC);
CREATE INDEX IF NOT EXISTS idx_promotions_fulfillment_status_enddate ON promotions (fulfillment_type, status, end_date);
CREATE INDEX IF NOT EXISTS idx_promotions_admin_verified ON promotions (admin_verified);

CREATE TABLE IF NOT EXISTS bank_offers (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  bank_name TEXT,
  offer_type TEXT CHECK (offer_type IN (
    'discount', 'cashback', 'installment', 'dining', 'grocery',
    'fuel', 'travel', 'electronics', 'online', 'other'
  )),
  status TEXT NOT NULL DEFAULT 'draft',
  created_by TEXT REFERENCES users(id),
  updated_by TEXT REFERENCES users(id),
  category TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_bank_offers_bank_name ON bank_offers (bank_name);
CREATE INDEX IF NOT EXISTS idx_bank_offers_offer_type ON bank_offers (offer_type);
CREATE INDEX IF NOT EXISTS idx_bank_offers_status ON bank_offers (status);
CREATE INDEX IF NOT EXISTS idx_bank_offers_status_endedge ON bank_offers (status, offer_type);

CREATE TABLE IF NOT EXISTS deal_alerts (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id TEXT NOT NULL REFERENCES users(id),
  promotion_id TEXT NOT NULL REFERENCES promotions(id),
  alert_types TEXT[],
  active BOOLEAN DEFAULT true,
  last_expiry_notified_at TIMESTAMPTZ,
  last_price_drop_notified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (user_id, promotion_id)
);
CREATE INDEX IF NOT EXISTS idx_deal_alerts_user_id ON deal_alerts (user_id);
CREATE INDEX IF NOT EXISTS idx_deal_alerts_promotion_active ON deal_alerts (promotion_id, active);

CREATE TABLE IF NOT EXISTS notification_logs (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id TEXT NOT NULL REFERENCES users(id),
  type TEXT NOT NULL CHECK (type IN (
    'nearby_deal', 'favorite_store', 'expiring_deal', 'price_drop',
    'category_deal', 'flash_sale', 'deal_redeemed', 'merchant_expiry',
    'weekly_digest', 'account_activity'
  )),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}',
  channels TEXT[],
  status_push_sent BOOLEAN DEFAULT false,
  status_push_delivered BOOLEAN DEFAULT false,
  status_push_opened BOOLEAN DEFAULT false,
  status_push_error TEXT,
  status_email_sent BOOLEAN DEFAULT false,
  status_email_opened BOOLEAN DEFAULT false,
  status_email_error TEXT,
  status_web_sent BOOLEAN DEFAULT false,
  status_web_clicked BOOLEAN DEFAULT false,
  status_web_error TEXT,
  priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  read BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_notification_logs_user_created ON notification_logs (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notification_logs_type_created ON notification_logs (type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notification_logs_read_user ON notification_logs (read, user_id);

CREATE TABLE IF NOT EXISTS notification_preferences (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id TEXT NOT NULL UNIQUE REFERENCES users(id),
  push_enabled BOOLEAN DEFAULT false,
  push_token TEXT,
  email_enabled BOOLEAN DEFAULT true,
  web_enabled BOOLEAN DEFAULT false,
  web_subscription JSONB,
  preferences JSONB,
  quiet_hours JSONB,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS promotion_clicks (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  promotion_id TEXT NOT NULL REFERENCES promotions(id),
  merchant_id TEXT NOT NULL REFERENCES merchants(id),
  user_id TEXT REFERENCES users(id),
  "timestamp" TIMESTAMPTZ DEFAULT now(),
  type TEXT DEFAULT 'click'
);
CREATE INDEX IF NOT EXISTS idx_promotion_clicks_promotion ON promotion_clicks (promotion_id);
CREATE INDEX IF NOT EXISTS idx_promotion_clicks_merchant ON promotion_clicks (merchant_id);
CREATE INDEX IF NOT EXISTS idx_promotion_clicks_timestamp ON promotion_clicks ("timestamp");

CREATE TABLE IF NOT EXISTS redemptions (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  promotion_id TEXT NOT NULL REFERENCES promotions(id),
  merchant_id TEXT NOT NULL REFERENCES merchants(id),
  user_id TEXT NOT NULL REFERENCES users(id),
  token TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'issued',
  expires_at TIMESTAMPTZ,
  redeemed_by TEXT REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_redemptions_promotion ON redemptions (promotion_id);
CREATE INDEX IF NOT EXISTS idx_redemptions_merchant ON redemptions (merchant_id);
CREATE INDEX IF NOT EXISTS idx_redemptions_user ON redemptions (user_id);
CREATE INDEX IF NOT EXISTS idx_redemptions_status ON redemptions (status);
CREATE INDEX IF NOT EXISTS idx_redemptions_expires_at ON redemptions (expires_at);
CREATE INDEX IF NOT EXISTS idx_redemptions_promotion_user_status ON redemptions (promotion_id, user_id, status);

CREATE TABLE IF NOT EXISTS reports (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  target_type TEXT NOT NULL CHECK (target_type IN ('promotion', 'merchant')),
  promotion_id TEXT REFERENCES promotions(id),
  merchant_id TEXT REFERENCES merchants(id),
  reporter TEXT REFERENCES users(id),
  resolved_by TEXT REFERENCES users(id),
  reason TEXT,
  status TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  CHECK (
    (target_type = 'promotion' AND promotion_id IS NOT NULL AND merchant_id IS NULL) OR
    (target_type = 'merchant' AND merchant_id IS NOT NULL AND promotion_id IS NULL)
  )
);
CREATE INDEX IF NOT EXISTS idx_reports_target_type ON reports (target_type);
CREATE INDEX IF NOT EXISTS idx_reports_promotion ON reports (promotion_id);
CREATE INDEX IF NOT EXISTS idx_reports_merchant ON reports (merchant_id);
CREATE INDEX IF NOT EXISTS idx_reports_reporter ON reports (reporter);
CREATE INDEX IF NOT EXISTS idx_reports_status_created ON reports (status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_targettype_status_created ON reports (target_type, status, created_at DESC);

CREATE TABLE IF NOT EXISTS search_query_logs (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id TEXT REFERENCES users(id),
  session_id TEXT,
  explicit_filters JSONB,
  interpreted_filters JSONB,
  latitude NUMERIC,
  longitude NUMERIC,
  radius_km NUMERIC,
  top_promotion_ids TEXT[],
  normalized_query TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_search_query_logs_user ON search_query_logs (user_id);
CREATE INDEX IF NOT EXISTS idx_search_query_logs_session ON search_query_logs (session_id);
CREATE INDEX IF NOT EXISTS idx_search_query_logs_normalized ON search_query_logs (normalized_query);
CREATE INDEX IF NOT EXISTS idx_search_query_logs_normalized_created ON search_query_logs (normalized_query, created_at DESC);

CREATE TABLE IF NOT EXISTS section_assignments (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  section_key TEXT NOT NULL CHECK (section_key IN ('banner', 'hot_deals', 'new_this_week', 'flash_sales', 'nearby')),
  promotion_id TEXT NOT NULL REFERENCES promotions(id),
  mode TEXT CHECK (mode IN ('manual', 'auto', 'forced', 'hidden', 'boosted', 'excluded')),
  metadata JSONB DEFAULT '{}',
  updated_by TEXT REFERENCES users(id),
  enabled BOOLEAN DEFAULT true,
  priority INTEGER DEFAULT 0,
  start_at TIMESTAMPTZ,
  end_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (section_key, promotion_id)
);
CREATE INDEX IF NOT EXISTS idx_section_assignments_key_enabled_priority ON section_assignments (section_key, enabled, priority DESC, start_at, end_at);

CREATE TABLE IF NOT EXISTS user_behavior_events (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id TEXT REFERENCES users(id),
  session_id TEXT,
  platform TEXT,
  event_type TEXT,
  promotion_id TEXT REFERENCES promotions(id),
  merchant_id TEXT REFERENCES merchants(id),
  category TEXT,
  filters JSONB,
  metadata JSONB,
  latitude NUMERIC,
  longitude NUMERIC,
  radius_km NUMERIC,
  label TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_user_behavior_events_user ON user_behavior_events (user_id);
CREATE INDEX IF NOT EXISTS idx_user_behavior_events_session ON user_behavior_events (session_id);
CREATE INDEX IF NOT EXISTS idx_user_behavior_events_platform ON user_behavior_events (platform);
CREATE INDEX IF NOT EXISTS idx_user_behavior_events_type ON user_behavior_events (event_type);
CREATE INDEX IF NOT EXISTS idx_user_behavior_events_promotion ON user_behavior_events (promotion_id);
CREATE INDEX IF NOT EXISTS idx_user_behavior_events_merchant ON user_behavior_events (merchant_id);
CREATE INDEX IF NOT EXISTS idx_user_behavior_events_category ON user_behavior_events (category);
CREATE INDEX IF NOT EXISTS idx_user_behavior_events_user_created ON user_behavior_events (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_behavior_events_type_created ON user_behavior_events (event_type, created_at DESC);

CREATE TABLE IF NOT EXISTS user_preference_profiles (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id TEXT NOT NULL UNIQUE REFERENCES users(id),
  category_affinity JSONB,
  merchant_affinity JSONB,
  top_merchant_ids TEXT[],
  latitude NUMERIC,
  longitude NUMERIC,
  location_updated_at TIMESTAMPTZ,
  segment_name TEXT,
  segment_confidence NUMERIC,
  stats_search_count INTEGER DEFAULT 0,
  stats_view_count INTEGER DEFAULT 0,
  stats_click_count INTEGER DEFAULT 0,
  stats_favorite_count INTEGER DEFAULT 0,
  stats_nearby_search_count INTEGER DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ========================================================================
-- Child / junction tables
-- ========================================================================

CREATE TABLE IF NOT EXISTS user_favorites (
  user_id TEXT NOT NULL REFERENCES users(id),
  promotion_id TEXT NOT NULL REFERENCES promotions(id),
  PRIMARY KEY (user_id, promotion_id)
);
CREATE INDEX IF NOT EXISTS idx_user_favorites_promotion ON user_favorites (promotion_id);

CREATE TABLE IF NOT EXISTS user_following_merchants (
  user_id TEXT NOT NULL REFERENCES users(id),
  merchant_id TEXT NOT NULL REFERENCES merchants(id),
  PRIMARY KEY (user_id, merchant_id)
);
CREATE INDEX IF NOT EXISTS idx_user_following_merchants_merchant ON user_following_merchants (merchant_id);

CREATE TABLE IF NOT EXISTS bank_offer_applicable_merchants (
  bank_offer_id TEXT NOT NULL REFERENCES bank_offers(id),
  merchant_id TEXT NOT NULL REFERENCES merchants(id),
  PRIMARY KEY (bank_offer_id, merchant_id)
);

CREATE TABLE IF NOT EXISTS merchant_ratings (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  merchant_id TEXT NOT NULL REFERENCES merchants(id),
  user_id TEXT NOT NULL REFERENCES users(id),
  value SMALLINT NOT NULL CHECK (value BETWEEN 1 AND 5),
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_merchant_ratings_merchant ON merchant_ratings (merchant_id);

CREATE TABLE IF NOT EXISTS merchant_reviews (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  merchant_id TEXT NOT NULL REFERENCES merchants(id),
  user_id TEXT NOT NULL REFERENCES users(id),
  text TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_merchant_reviews_merchant ON merchant_reviews (merchant_id);

CREATE TABLE IF NOT EXISTS promotion_comments (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  promotion_id TEXT NOT NULL REFERENCES promotions(id),
  user_id TEXT NOT NULL REFERENCES users(id),
  text TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_promotion_comments_promotion ON promotion_comments (promotion_id);

CREATE TABLE IF NOT EXISTS promotion_ratings (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  promotion_id TEXT NOT NULL REFERENCES promotions(id),
  user_id TEXT NOT NULL REFERENCES users(id),
  value SMALLINT NOT NULL CHECK (value BETWEEN 1 AND 5),
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_promotion_ratings_promotion ON promotion_ratings (promotion_id);

CREATE TABLE IF NOT EXISTS promotion_redemption_feedback (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  promotion_id TEXT NOT NULL REFERENCES promotions(id),
  user_id TEXT NOT NULL REFERENCES users(id),
  worked BOOLEAN NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_promotion_redemption_feedback_promotion ON promotion_redemption_feedback (promotion_id);

CREATE TABLE IF NOT EXISTS user_preference_categories (
  user_id TEXT NOT NULL REFERENCES users(id),
  category TEXT NOT NULL,
  PRIMARY KEY (user_id, category)
);
