'use client';

import { useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import toast from 'react-hot-toast';
import PromotionCard from '@/components/ui/PromotionCard';
import SkeletonCard from '@/components/ui/SkeletonCard';
import { useAuth } from '@/contexts/AuthContext';
import { DEALFINDER_CATEGORIES, getCategoryLabel, normalizeCategoryId } from '@/lib/categories';
import { PromotionAPI, UserAPI, invalidateCache } from '@/lib/api';

type Promotion = {
  _id?: string;
  id?: string;
  title?: string;
  description?: string;
  category?: string;
  discount?: string | number;
  featured?: boolean;
  url?: string;
  image?: string;
  createdAt?: string;
  endDate?: string;
  merchant?: string | {
    _id?: string;
    name?: string;
    location?: {
      coordinates?: [number, number];
    };
  };
};

type FavoritePromotion = Promotion;

const CATEGORIES = DEALFINDER_CATEGORIES.filter((category) =>
  ['electronics', 'fashion', 'food_bev', 'travel', 'beauty_health', 'home_garden', 'entertainment', 'all'].includes(category.id)
).map((category) => ({
  id: category.id,
  name: category.id === 'all' ? 'More' : category.name,
  icon: category.icon,
}));

function getPromotionId(promotion: Promotion) {
  return promotion._id || promotion.id || '';
}

function getMerchantName(promotion: Promotion) {
  return typeof promotion.merchant === 'object' ? promotion.merchant?.name || 'Unknown Merchant' : promotion.merchant || 'Unknown Merchant';
}

function getMerchantId(promotion: Promotion) {
  return typeof promotion.merchant === 'object' ? promotion.merchant?._id || promotion.merchant?.name || '' : promotion.merchant || '';
}

function getDiscountValue(discount: Promotion['discount']) {
  const numeric = Number.parseFloat(String(discount ?? '').replace(/[^\d.]/g, ''));
  return Number.isFinite(numeric) ? numeric : 0;
}

function getTimestamp(value?: string) {
  const time = value ? new Date(value).getTime() : 0;
  return Number.isFinite(time) ? time : 0;
}

function isActiveDeal(promotion: Promotion, now: number) {
  return getTimestamp(promotion.endDate) >= now;
}

function scoreRecommendation(
  promotion: Promotion,
  favoriteMerchantIds: Set<string>,
  favoriteCategories: Set<string>,
  now: number
) {
  let score = 0;

  if (promotion.featured) score += 30;
  if (favoriteCategories.has(normalizeCategoryId(promotion.category || ''))) score += 35;
  if (favoriteMerchantIds.has(getMerchantId(promotion))) score += 40;
  score += Math.min(getDiscountValue(promotion.discount), 60);

  const daysLeft = Math.ceil((getTimestamp(promotion.endDate) - now) / 86400000);
  if (daysLeft >= 0 && daysLeft <= 3) score += 16;

  return score;
}

function SectionHeader({
  eyebrow,
  title,
  icon,
  meta,
  actionLabel,
  onAction,
  accent,
}: {
  eyebrow: string;
  title: string;
  icon: string;
  meta?: string;
  actionLabel?: string;
  onAction?: () => void;
  accent?: string;
}) {
  return (
    <div
      style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'end',
        gap: '1rem',
        flexWrap: 'wrap',
        marginBottom: '1.4rem',
      }}
    >
      <div>
        <div style={{ color: accent || 'var(--primary-color)', fontSize: '0.82rem', fontWeight: 800, textTransform: 'uppercase' }}>
          {eyebrow}
        </div>
        <h2 className="section-title" style={{ marginBottom: 0 }}>
          <i className={`fas ${icon}`} style={{ color: accent || 'var(--primary-color)' }}></i>
          {title}
        </h2>
      </div>
      <div className="flex items-center gap-3 flex-wrap">
        {meta ? <span style={{ color: 'var(--text-secondary)', fontSize: '0.92rem' }}>{meta}</span> : null}
        {actionLabel && onAction ? (
          <button
            onClick={onAction}
            className="btn"
            style={{
              background: 'var(--card-bg)',
              color: 'var(--text-primary)',
              border: '1px solid var(--border-color)',
            }}
          >
            {actionLabel}
          </button>
        ) : null}
      </div>
    </div>
  );
}

function DealGrid({
  deals,
  favoriteIds,
  onFavoriteToggle,
}: {
  deals: Promotion[];
  favoriteIds: Set<string>;
  onFavoriteToggle: (id: string, isFav: boolean) => void;
}) {
  return (
    <div
      style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))',
        gap: '1.5rem',
      }}
    >
      {deals.map((promotion) => (
        <PromotionCard
          key={getPromotionId(promotion)}
          promotion={promotion}
          isFavorite={favoriteIds.has(getPromotionId(promotion))}
          onFavoriteToggle={onFavoriteToggle}
        />
      ))}
    </div>
  );
}

function SkeletonGrid({ count }: { count: number }) {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
      {Array.from({ length: count }).map((_, index) => (
        <SkeletonCard key={index} />
      ))}
    </div>
  );
}

export default function HomePage() {
  const router = useRouter();
  const { user } = useAuth();
  const [allPromotions, setAllPromotions] = useState<Promotion[]>([]);
  const [favoriteDeals, setFavoriteDeals] = useState<FavoritePromotion[]>([]);
  const [favoriteIds, setFavoriteIds] = useState<Set<string>>(new Set());
  const [nearbyDeals, setNearbyDeals] = useState<Promotion[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [loadingDeals, setLoadingDeals] = useState(true);
  const [loadingNearby, setLoadingNearby] = useState(false);
  const [locationError, setLocationError] = useState('');
  const [currentTimestamp] = useState(() => Date.now());

  useEffect(() => {
    const fetchData = async () => {
      try {
        invalidateCache('promotions');
        const promotionsPromise = PromotionAPI.getAll({ limit: 48 });
        const favoritesPromise = user ? UserAPI.getFavorites(user._id).catch(() => []) : Promise.resolve([]);

        const [promotionsData, favoritesData] = await Promise.all([promotionsPromise, favoritesPromise]);
        const sortedPromotions = [...promotionsData].sort(
          (a, b) => getTimestamp(b.createdAt) - getTimestamp(a.createdAt)
        );

        setAllPromotions(sortedPromotions);
        setFavoriteDeals(favoritesData);
        setFavoriteIds(new Set(favoritesData.map((favorite: Promotion) => getPromotionId(favorite))));
      } catch (error) {
        console.error('Failed to load homepage data:', error);
        toast.error('Failed to load deals.');
      } finally {
        setLoadingDeals(false);
      }
    };

    fetchData();
  }, [user]);

  useEffect(() => {
    if (!navigator.geolocation) return;

    setLoadingNearby(true);
    navigator.geolocation.getCurrentPosition(
      ({ coords }) => {
        PromotionAPI.getNearby(coords.latitude, coords.longitude, 10)
          .then((data: Promotion[]) => {
            const sorted = [...data].sort((a, b) => getTimestamp(b.createdAt) - getTimestamp(a.createdAt));
            setNearbyDeals(sorted);
          })
          .catch(() => setLocationError('Nearby deals are not available right now.'))
          .finally(() => setLoadingNearby(false));
      },
      () => {
        setLocationError('Location is off, so we are focusing on the best platform-wide deals instead.');
        setLoadingNearby(false);
      }
    );
  }, []);

  const activePromotions = useMemo(
    () => allPromotions.filter((promotion) => isActiveDeal(promotion, currentTimestamp)),
    [allPromotions, currentTimestamp]
  );

  const featuredDeals = useMemo(
    () =>
      [...activePromotions]
        .sort((a, b) => {
          if (Boolean(a.featured) !== Boolean(b.featured)) return a.featured ? -1 : 1;
          return getDiscountValue(b.discount) - getDiscountValue(a.discount);
        })
        .slice(0, 6),
    [activePromotions]
  );

  const endingSoonDeals = useMemo(
    () =>
      [...activePromotions]
        .sort((a, b) => getTimestamp(a.endDate) - getTimestamp(b.endDate))
        .slice(0, 3),
    [activePromotions]
  );

  const favoriteMerchantIds = useMemo(
    () => new Set(favoriteDeals.map((promotion) => getMerchantId(promotion))),
    [favoriteDeals]
  );

  const favoriteCategories = useMemo(
    () => new Set(favoriteDeals.map((promotion) => normalizeCategoryId(promotion.category || ''))),
    [favoriteDeals]
  );

  const recommendedDeals = useMemo(() => {
    const source = activePromotions.filter((promotion) => !favoriteIds.has(getPromotionId(promotion)));

    if (favoriteDeals.length > 0) {
      return [...source]
        .sort(
          (a, b) =>
            scoreRecommendation(b, favoriteMerchantIds, favoriteCategories, currentTimestamp) -
            scoreRecommendation(a, favoriteMerchantIds, favoriteCategories, currentTimestamp)
        )
        .slice(0, 3);
    }

    if (nearbyDeals.length > 0) return nearbyDeals.slice(0, 3);
    return featuredDeals.slice(0, 3);
  }, [activePromotions, currentTimestamp, favoriteCategories, favoriteDeals.length, favoriteIds, favoriteMerchantIds, featuredDeals, nearbyDeals]);

  const featuredDeal = useMemo(() => {
    const pool = featuredDeals.length > 0 ? featuredDeals : activePromotions;
    return pool[0] || null;
  }, [activePromotions, featuredDeals]);

  const searchResults = useMemo(() => {
    const term = searchTerm.trim().toLowerCase();
    if (!term) return [];

    return activePromotions
      .filter((promotion) => {
        return (
          promotion.title?.toLowerCase().includes(term) ||
          promotion.description?.toLowerCase().includes(term) ||
          promotion.category?.toLowerCase().includes(term) ||
          getMerchantName(promotion).toLowerCase().includes(term)
        );
      })
      .slice(0, 6);
  }, [activePromotions, searchTerm]);

  const savedPreview = useMemo(() => favoriteDeals.slice(0, 2), [favoriteDeals]);

  const stats = useMemo(() => {
    const merchantCount = new Set(activePromotions.map((promotion) => getMerchantId(promotion))).size;
    return [
      { label: 'Active deals', value: activePromotions.length },
      { label: 'Merchants', value: merchantCount },
      { label: 'Saved by you', value: favoriteDeals.length },
    ];
  }, [activePromotions, favoriteDeals.length]);

  const handleFavoriteToggle = (id: string, isFav: boolean) => {
    setFavoriteIds((current) => {
      const next = new Set(current);
      if (isFav) next.add(id);
      else next.delete(id);
      return next;
    });
  };

  const openDeals = (query?: string) => {
    const trimmed = query?.trim();
    router.push(trimmed ? `/categories/all?q=${encodeURIComponent(trimmed)}` : '/categories/all');
  };

  const compareRows = [
    {
      side: 'Other platforms',
      icon: 'fa-xmark',
      color: 'var(--danger-color)',
      items: ['Endless scrolling', 'No clear best option', 'Too many tabs'],
      background: 'rgba(220,38,38,0.06)',
      border: 'rgba(220,38,38,0.12)',
    },
    {
      side: 'DealFinder',
      icon: 'fa-check',
      color: 'var(--success-color)',
      items: ['Smart deal ranking', 'Compare instantly', 'Save and track deals'],
      background: 'rgba(22,163,74,0.08)',
      border: 'rgba(22,163,74,0.14)',
    },
  ];

  return (
    <div>
      <section
        style={{
          position: 'relative',
          overflow: 'hidden',
          background:
            'radial-gradient(circle at top left, rgba(108,59,255,0.24), transparent 24%), radial-gradient(circle at top right, rgba(59,130,246,0.22), transparent 30%), linear-gradient(135deg, #24145f 0%, #3f2aa3 44%, #215bc9 100%)',
          color: '#f8fafc',
        }}
      >
        <div
          style={{
            position: 'absolute',
            inset: 0,
            backgroundImage: 'url(https://images.unsplash.com/photo-1515169067868-5387ec356754?auto=format&fit=crop&w=1600&q=80)',
            backgroundSize: 'cover',
            backgroundPosition: 'center',
            opacity: 0.14,
          }}
        />
        <div className="max-w-7xl mx-auto px-4" style={{ position: 'relative', zIndex: 1, paddingTop: '4.5rem', paddingBottom: '4rem' }}>
          <div className="grid grid-cols-1 lg:grid-cols-[1.15fr_0.85fr] gap-8 items-center">
            <div>
              <div
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '0.5rem',
                  marginBottom: '1rem',
                  padding: '0.45rem 0.9rem',
                  borderRadius: '999px',
                  background: 'rgba(255,255,255,0.12)',
                  border: '1px solid rgba(255,255,255,0.14)',
                  fontSize: '0.8rem',
                  fontWeight: 800,
                  textTransform: 'uppercase',
                }}
              >
                <i className="fas fa-bolt" style={{ color: '#fbbf24' }}></i>
                Fast. Smart. Local-first.
              </div>

              <h1
                style={{
                  fontSize: 'clamp(2.4rem, 5.5vw, 4.8rem)',
                  lineHeight: 1.02,
                  margin: 0,
                  fontWeight: 900,
                  maxWidth: '10ch',
                }}
              >
                Find the best deals near you, instantly
              </h1>

              <p
                style={{
                  marginTop: '1.2rem',
                  marginBottom: '1.6rem',
                  maxWidth: '42rem',
                  fontSize: '1.06rem',
                  lineHeight: 1.75,
                  color: 'rgba(248,250,252,0.86)',
                }}
              >
                Grab top local offers, track urgency, and move faster with clear Sri Lanka-first deal discovery built for action.
              </p>

              <div
                style={{
                  display: 'grid',
                  gap: '0.9rem',
                  maxWidth: '44rem',
                }}
              >
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.75rem',
                    padding: '0.7rem',
                    borderRadius: '1.15rem',
                    background: 'rgba(255,255,255,0.1)',
                    border: '1px solid rgba(255,255,255,0.16)',
                    backdropFilter: 'blur(10px)',
                    flexWrap: 'wrap',
                  }}
                >
                  <i className="fas fa-search" style={{ color: '#fbbf24', paddingLeft: '0.45rem' }}></i>
                  <input
                    type="text"
                    value={searchTerm}
                    onChange={(event) => setSearchTerm(event.target.value)}
                    onKeyDown={(event) => {
                      if (event.key === 'Enter') openDeals(searchTerm);
                    }}
                    placeholder="Search deals, stores, categories, nearby offers..."
                    style={{
                      flex: 1,
                      minWidth: '220px',
                      border: 'none',
                      outline: 'none',
                      background: 'transparent',
                      color: '#fff',
                      fontSize: '1rem',
                    }}
                  />
                  <button
                    onClick={() => openDeals(searchTerm)}
                    className="btn"
                    style={{
                      background: '#f8fafc',
                      color: '#0f172a',
                      padding: '0.8rem 1rem',
                      fontWeight: 800,
                    }}
                  >
                    Grab now
                  </button>
                </div>

                <div className="flex flex-wrap gap-3">
                  <button
                    onClick={() => router.push('/categories/all')}
                    className="btn"
                    style={{
                      background: 'linear-gradient(135deg, #fbbf24 0%, #f59e0b 100%)',
                      color: '#0f172a',
                      padding: '0.9rem 1.3rem',
                      fontWeight: 800,
                    }}
                  >
                    <i className="fas fa-fire"></i>
                    Get Deal
                  </button>
                  <button
                    onClick={() => router.push('/nearby')}
                    className="btn"
                    style={{
                      background: 'rgba(255,255,255,0.08)',
                      color: '#fff',
                      border: '1px solid rgba(255,255,255,0.18)',
                      padding: '0.9rem 1.3rem',
                    }}
                  >
                    <i className="fas fa-location-dot"></i>
                    View Nearby
                  </button>
                </div>
              </div>
            </div>

            <div className="surface-panel" style={{ background: 'rgba(255,255,255,0.1)', borderColor: 'rgba(255,255,255,0.16)' }}>
              <div className="panel-pad">
                <div
                  style={{
                    display: 'grid',
                    gridTemplateColumns: 'repeat(3, minmax(0, 1fr))',
                    gap: '0.75rem',
                    marginBottom: '1rem',
                  }}
                >
                  {stats.map((stat) => (
                    <div
                      key={stat.label}
                      style={{
                        padding: '0.95rem',
                        borderRadius: '1rem',
                        background: 'rgba(15,23,42,0.32)',
                        border: '1px solid rgba(255,255,255,0.12)',
                      }}
                    >
                      <div style={{ fontSize: '1.3rem', fontWeight: 900, color: '#fff' }}>{loadingDeals ? '--' : stat.value}</div>
                      <div style={{ fontSize: '0.78rem', color: 'rgba(255,255,255,0.72)' }}>{stat.label}</div>
                    </div>
                  ))}
                </div>

                <div
                  style={{
                    borderRadius: '1.2rem',
                    padding: '1.2rem',
                    background: 'rgba(255,255,255,0.96)',
                    color: '#0f172a',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '1rem', marginBottom: '1rem' }}>
                    <div>
                      <div style={{ fontSize: '0.78rem', fontWeight: 800, textTransform: 'uppercase', color: 'var(--primary-color)' }}>
                        Today on DealFinder
                      </div>
                      <div style={{ fontSize: '1.15rem', fontWeight: 900 }}>Best local savings, surfaced fast</div>
                    </div>
                    <div
                      style={{
                        width: '2.5rem',
                        height: '2.5rem',
                        borderRadius: '999px',
                        background: 'rgba(37,99,235,0.1)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        color: 'var(--primary-color)',
                      }}
                    >
                      <i className="fas fa-chart-line"></i>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 gap-3">
                    {[
                      { icon: 'fa-fire', label: 'Best Deals Today', note: 'High-value offers surfaced first.' },
                      { icon: 'fa-hourglass-half', label: 'Ending Soon', note: 'Urgency visible before deals expire.' },
                      { icon: 'fa-star', label: 'Recommended For You', note: 'Smarter picks based on what you save.' },
                    ].map((item) => (
                      <div
                        key={item.label}
                        style={{
                          display: 'grid',
                          gridTemplateColumns: '2.4rem 1fr',
                          gap: '0.8rem',
                          alignItems: 'start',
                          padding: '0.85rem',
                          borderRadius: '1rem',
                          background: '#f8fafc',
                          border: '1px solid #e2e8f0',
                        }}
                      >
                        <div
                          style={{
                            width: '2.4rem',
                            height: '2.4rem',
                            borderRadius: '0.85rem',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            color: 'var(--primary-color)',
                            background: 'rgba(37,99,235,0.1)',
                          }}
                        >
                          <i className={`fas ${item.icon}`}></i>
                        </div>
                        <div>
                          <div style={{ fontWeight: 800, marginBottom: '0.2rem' }}>{item.label}</div>
                          <div style={{ fontSize: '0.9rem', color: '#475569', lineHeight: 1.6 }}>{item.note}</div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="max-w-7xl mx-auto px-4" style={{ marginTop: '-1.6rem', position: 'relative', zIndex: 2 }}>
        <div className="surface-panel panel-pad">
          <div className="flex items-center justify-between gap-4 flex-wrap">
            <div>
              <div className="page-eyebrow">
                <i className="fas fa-bullseye"></i>
                Search preview
              </div>
              <div style={{ marginTop: '0.8rem', fontSize: '1.15rem', fontWeight: 800, color: 'var(--text-primary)' }}>
                {searchTerm.trim() ? `${searchResults.length} quick matches for "${searchTerm}"` : 'Search deals, stores, or categories to jump straight to the right results.'}
              </div>
            </div>
            <button
              onClick={() => openDeals(searchTerm)}
              className="btn btn-primary"
              style={{ padding: '0.85rem 1.15rem' }}
            >
              Open Full Results
            </button>
          </div>
        </div>
      </section>

      <section className="max-w-7xl mx-auto px-4 py-10">
        {searchTerm.trim() ? (
          <section style={{ marginBottom: '3rem' }}>
            <SectionHeader
              eyebrow="Search results"
              title="Fast matches"
              icon="fa-magnifying-glass"
              meta={searchResults.length > 0 ? 'Quick preview from live deals' : 'No matching preview yet'}
              actionLabel="View All Deals"
              onAction={() => openDeals(searchTerm)}
            />
            {searchResults.length > 0 ? (
              <DealGrid deals={searchResults} favoriteIds={favoriteIds} onFavoriteToggle={handleFavoriteToggle} />
            ) : (
              <div className="empty-state">
                <div className="empty-icon">
                  <i className="fas fa-search"></i>
                </div>
                <h2 style={{ marginTop: 0, marginBottom: '0.5rem', fontWeight: 800 }}>No quick matches found</h2>
                <p style={{ color: 'var(--text-secondary)', marginBottom: '1.2rem', maxWidth: '34rem', marginInline: 'auto', lineHeight: 1.7 }}>
                  Try a store name, category, or broader keyword. The full deals page will still give you more room to explore.
                </p>
                <button onClick={() => openDeals(searchTerm)} className="btn btn-primary">
                  Search All Deals
                </button>
              </div>
            )}
          </section>
        ) : null}

        <div className="grid grid-cols-1 gap-12">
          <section>
            <SectionHeader
              eyebrow="High conversion"
              title="Best Deals Today"
              icon="fa-fire"
              meta="The strongest offers surfaced first"
              actionLabel="Get Deal"
              onAction={() => router.push('/categories/all')}
              accent="var(--highlight-color)"
            />
            {loadingDeals ? (
              <SkeletonGrid count={3} />
            ) : (
              <DealGrid deals={featuredDeals.slice(0, 3)} favoriteIds={favoriteIds} onFavoriteToggle={handleFavoriteToggle} />
            )}
          </section>

          <section>
            <SectionHeader
              eyebrow="Urgency"
              title="Ending Soon"
              icon="fa-hourglass-half"
              meta="Grab now before they disappear"
              actionLabel="Ending soon"
              onAction={() => router.push('/categories/all')}
              accent="var(--warning-color)"
            />
            {loadingDeals ? (
              <SkeletonGrid count={3} />
            ) : (
              <DealGrid deals={endingSoonDeals} favoriteIds={favoriteIds} onFavoriteToggle={handleFavoriteToggle} />
            )}
          </section>

          <section>
            <SectionHeader
              eyebrow="Personalization"
              title="Recommended For You"
              icon="fa-star"
              meta={user ? 'Based on what you save and revisit' : locationError || 'Smart picks to get you started'}
              actionLabel={user ? 'Save Offer' : 'Create Account'}
              onAction={() => router.push(user ? '/favorites' : '/register')}
            />
            {loadingDeals || loadingNearby ? (
              <SkeletonGrid count={3} />
            ) : (
              <DealGrid deals={recommendedDeals} favoriteIds={favoriteIds} onFavoriteToggle={handleFavoriteToggle} />
            )}
          </section>

          <section>
            <SectionHeader
              eyebrow="Quick navigation"
              title="Browse by Category"
              icon="fa-compass"
              meta="Tap once and narrow the noise"
            />
            <div className="flex gap-3 overflow-x-auto pb-2" style={{ scrollbarWidth: 'none' }}>
              {CATEGORIES.map((category) => (
                <button
                  key={category.id}
                  onClick={() => router.push(`/categories/${category.id}`)}
                  style={{
                    minWidth: '170px',
                    textAlign: 'left',
                    border: '1px solid var(--border-color)',
                    background: 'var(--card-bg)',
                    borderRadius: '1.1rem',
                    padding: '1rem',
                    boxShadow: 'var(--box-shadow)',
                    cursor: 'pointer',
                    flexShrink: 0,
                  }}
                >
                  <div
                    style={{
                      width: '2.8rem',
                      height: '2.8rem',
                      borderRadius: '0.95rem',
                      background: 'linear-gradient(135deg, rgba(37,99,235,0.16), rgba(56,189,248,0.12))',
                      color: 'var(--primary-color)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      marginBottom: '0.8rem',
                    }}
                  >
                    <i className={`fas ${category.icon}`}></i>
                  </div>
                  <div style={{ fontWeight: 800, color: 'var(--text-primary)' }}>{category.name}</div>
                </button>
              ))}
            </div>
          </section>

          {featuredDeal ? (
            <section className="surface-panel" style={{ overflow: 'hidden' }}>
              <div className="grid grid-cols-1 lg:grid-cols-[1fr_0.9fr]">
                <div
                  style={{
                    minHeight: '320px',
                    backgroundImage: `url(${featuredDeal.image || 'https://placehold.co/900x700?text=Featured+Deal'})`,
                    backgroundSize: 'cover',
                    backgroundPosition: 'center',
                  }}
                />
                <div className="panel-pad" style={{ display: 'grid', alignContent: 'center', gap: '1rem' }}>
                  <div className="page-eyebrow">
                    <i className="fas fa-star"></i>
                    Featured Deal
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', flexWrap: 'wrap' }}>
                    <span className="discount-badge" style={{ fontSize: '1rem', padding: '0.45rem 0.85rem' }}>
                      {featuredDeal.discount || 'Top'} OFF
                    </span>
                    <span className="status-chip" style={{ background: 'rgba(249,115,22,0.12)', color: 'var(--warning-color)' }}>
                      <i className="fas fa-hourglass-half"></i>
                      Ending soon
                    </span>
                  </div>
                  <h2 style={{ margin: 0, fontSize: 'clamp(1.8rem, 4vw, 2.8rem)', lineHeight: 1.05 }}>
                    {featuredDeal.title || 'Summer Mega Sale'}
                  </h2>
                  <p style={{ margin: 0, color: 'var(--text-secondary)', lineHeight: 1.7 }}>
                    {featuredDeal.description || 'One standout offer with strong savings, clean urgency, and a faster path to action.'}
                  </p>
                  <div style={{ color: 'var(--text-secondary)', fontSize: '0.92rem' }}>
                    {getMerchantName(featuredDeal)}{featuredDeal.category ? ` • ${getCategoryLabel(featuredDeal.category)}` : ''}
                  </div>
                  <div className="flex gap-3 flex-wrap">
                    <button
                      onClick={() => router.push(`/deal/${getPromotionId(featuredDeal)}`)}
                      className="btn btn-primary"
                      style={{ padding: '0.9rem 1.2rem' }}
                    >
                      <i className="fas fa-bolt"></i>
                      Get Deal
                    </button>
                    <button
                      onClick={() => handleFavoriteToggle(getPromotionId(featuredDeal), !favoriteIds.has(getPromotionId(featuredDeal)))}
                      className="btn"
                      style={{
                        padding: '0.9rem 1.2rem',
                        background: 'var(--card-bg)',
                        color: 'var(--text-primary)',
                        border: '1px solid var(--border-color)',
                      }}
                    >
                      <i className="fas fa-heart"></i>
                      Save Offer
                    </button>
                  </div>
                </div>
              </div>
            </section>
          ) : null}

          <section className="surface-panel panel-pad">
            <SectionHeader
              eyebrow="Trust builder"
              title="Why use DealFinder?"
              icon="fa-scale-balanced"
              meta="Less noise, faster decisions"
            />
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {compareRows.map((row) => (
                <div
                  key={row.side}
                  style={{
                    borderRadius: '1.2rem',
                    padding: '1.25rem',
                    background: row.background,
                    border: `1px solid ${row.border}`,
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem', marginBottom: '1rem', fontWeight: 900, fontSize: '1.08rem' }}>
                    <span
                      style={{
                        width: '2.2rem',
                        height: '2.2rem',
                        borderRadius: '999px',
                        background: '#fff',
                        color: row.color,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                      }}
                    >
                      <i className={`fas ${row.icon}`}></i>
                    </span>
                    {row.side}
                  </div>
                  <div className="grid grid-cols-1 gap-3">
                    {row.items.map((item) => (
                      <div
                        key={item}
                        style={{
                          borderRadius: '0.95rem',
                          background: '#fff',
                          padding: '0.9rem 1rem',
                          color: 'var(--text-primary)',
                          fontWeight: 600,
                        }}
                      >
                        {item}
                      </div>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          </section>

          <section>
            <SectionHeader
              eyebrow="Simple flow"
              title="How it works"
              icon="fa-diagram-project"
              meta="Three steps, no extra friction"
            />
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {[
                { step: '1', title: 'Discover nearby deals', text: 'Search fast and surface the strongest offers around you.' },
                { step: '2', title: 'Spot value instantly', text: 'See urgency, discounts, and categories without the clutter.' },
                { step: '3', title: 'Grab now or save later', text: 'Take the deal now or keep it ready for the next step.' },
              ].map((item) => (
                <div key={item.step} className="surface-panel panel-pad">
                  <div
                    style={{
                      width: '2.4rem',
                      height: '2.4rem',
                      borderRadius: '0.85rem',
                      background: 'var(--primary-gradient)',
                      color: '#fff',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontWeight: 900,
                      marginBottom: '0.85rem',
                    }}
                  >
                    {item.step}
                  </div>
                  <div style={{ fontWeight: 900, fontSize: '1.05rem', marginBottom: '0.4rem' }}>{item.title}</div>
                  <div style={{ color: 'var(--text-secondary)', lineHeight: 1.65 }}>{item.text}</div>
                </div>
              ))}
            </div>
          </section>

          {user ? (
            <section>
              <SectionHeader
                eyebrow="Your picks"
                title="Continue where you left off"
                icon="fa-heart"
                meta={savedPreview.length > 0 ? 'Your saved deals are ready' : 'Start building your shortlist'}
                actionLabel="Open Saved"
                onAction={() => router.push('/favorites')}
              />
              {savedPreview.length > 0 ? (
                <DealGrid deals={savedPreview} favoriteIds={favoriteIds} onFavoriteToggle={handleFavoriteToggle} />
              ) : (
                <div className="empty-state">
                  <div className="empty-icon">
                    <i className="fas fa-heart"></i>
                  </div>
                  <h2 style={{ marginTop: 0, marginBottom: '0.5rem', fontWeight: 800 }}>No saved deals yet</h2>
                  <p style={{ color: 'var(--text-secondary)', marginBottom: '1.2rem' }}>
                    Tap save on any deal and your shortlist will show up here.
                  </p>
                  <button onClick={() => router.push('/categories/all')} className="btn btn-primary">
                    Start Saving
                  </button>
                </div>
              )}
            </section>
          ) : null}

          <section
            style={{
              borderRadius: '1.6rem',
              overflow: 'hidden',
              background: 'linear-gradient(135deg, rgba(15,23,42,1) 0%, rgba(29,78,216,0.96) 60%, rgba(245,158,11,0.9) 100%)',
              color: '#fff',
            }}
          >
            <div className="grid grid-cols-1 lg:grid-cols-[1fr_0.9fr] gap-0 items-stretch">
              <div style={{ padding: '2.2rem' }}>
                <div className="page-eyebrow" style={{ background: 'rgba(255,255,255,0.12)', borderColor: 'rgba(255,255,255,0.14)', color: '#fff' }}>
                  <i className="fas fa-mobile-screen"></i>
                  Mobile app
                </div>
                <h2 style={{ marginTop: '1rem', marginBottom: '0.8rem', fontSize: 'clamp(1.8rem, 4vw, 2.5rem)', lineHeight: 1.08 }}>
                  Take DealFinder everywhere
                </h2>
                <p style={{ margin: 0, color: 'rgba(255,255,255,0.84)', lineHeight: 1.75, maxWidth: '34rem' }}>
                  Stay close to nearby deals, savings alerts, and quick local discovery while you move.
                </p>
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3" style={{ marginTop: '1.4rem' }}>
                  {['Nearby deals', 'Smart savings', 'Simple alerts'].map((item) => (
                    <div
                      key={item}
                      style={{
                        borderRadius: '1rem',
                        padding: '0.95rem 1rem',
                        background: 'rgba(255,255,255,0.12)',
                        border: '1px solid rgba(255,255,255,0.14)',
                      }}
                    >
                      <i className="fas fa-check-circle" style={{ color: '#fde68a', marginRight: '0.45rem' }}></i>
                      {item}
                    </div>
                  ))}
                </div>
                <a
                  href="https://drive.google.com/uc?export=download&id=12xY8BPO4HqN6oH4vj0wcJSwXiDM0tDKu"
                  className="btn"
                  style={{
                    marginTop: '1.5rem',
                    background: '#fff',
                    color: '#0f172a',
                    padding: '0.9rem 1.2rem',
                    fontWeight: 800,
                    display: 'inline-block',
                    textDecoration: 'none',
                  }}
                >
                  Get the App
                </a>
              </div>
              <div
                style={{
                  minHeight: '280px',
                  backgroundImage: 'url(https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?auto=format&fit=crop&w=1200&q=80)',
                  backgroundSize: 'cover',
                  backgroundPosition: 'center',
                }}
              />
            </div>
          </section>

          <section className="surface-panel panel-pad" style={{ textAlign: 'center' }}>
            <div className="page-eyebrow" style={{ marginInline: 'auto' }}>
              <i className="fas fa-rocket"></i>
              Final CTA
            </div>
            <h2 style={{ marginTop: '1rem', marginBottom: '0.75rem', fontSize: 'clamp(1.8rem, 4vw, 2.8rem)', lineHeight: 1.08 }}>
              Ready to find your next local deal?
            </h2>
            <p style={{ margin: '0 auto 1.5rem', maxWidth: '40rem', color: 'var(--text-secondary)', lineHeight: 1.7 }}>
              Start with the strongest offers, save what matters, and act before the best ones end.
            </p>
            <div className="flex justify-center gap-3 flex-wrap">
              <button onClick={() => router.push('/categories/all')} className="btn btn-primary" style={{ padding: '0.95rem 1.3rem' }}>
                <i className="fas fa-fire"></i>
                Get Deal
              </button>
              <button
                onClick={() => router.push(user ? '/favorites' : '/register')}
                className="btn"
                style={{
                  padding: '0.95rem 1.3rem',
                  background: 'var(--card-bg)',
                  color: 'var(--text-primary)',
                  border: '1px solid var(--border-color)',
                }}
              >
                <i className="fas fa-heart"></i>
                Save Offer
              </button>
            </div>
          </section>
        </div>
      </section>

      <div
        className="md:hidden"
        style={{
          position: 'fixed',
          left: '1rem',
          right: '1rem',
          bottom: '1rem',
          zIndex: 60,
        }}
      >
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(3, minmax(0, 1fr))',
            gap: '0.65rem',
            padding: '0.7rem',
            borderRadius: '1.25rem',
            background: 'color-mix(in srgb, var(--card-bg) 94%, transparent)',
            border: '1px solid var(--border-color)',
            backdropFilter: 'blur(14px)',
            boxShadow: '0 18px 36px rgba(15,23,42,0.16)',
          }}
        >
          {[
            { label: 'Explore', icon: 'fa-compass', onClick: () => router.push('/categories/all') },
            { label: 'Saved', icon: 'fa-heart', onClick: () => router.push('/favorites') },
            { label: 'Profile', icon: 'fa-user', onClick: () => router.push(user ? '/profile' : '/login') },
          ].map((item) => (
            <button
              key={item.label}
              onClick={item.onClick}
              style={{
                minHeight: '3.2rem',
                borderRadius: '1rem',
                border: 'none',
                background: item.label === 'Explore' ? 'var(--primary-gradient)' : 'var(--light-gray)',
                color: item.label === 'Explore' ? '#fff' : 'var(--text-primary)',
                fontWeight: 800,
                display: 'grid',
                placeItems: 'center',
                gap: '0.2rem',
                cursor: 'pointer',
              }}
            >
              <i className={`fas ${item.icon}`}></i>
              <span style={{ fontSize: '0.76rem' }}>{item.label}</span>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}


