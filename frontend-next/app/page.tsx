'use client';

import { useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import toast from 'react-hot-toast';
import PromotionCard from '@/components/ui/PromotionCard';
import SkeletonCard from '@/components/ui/SkeletonCard';
import { useAuth } from '@/contexts/AuthContext';
import { DEALFINDER_CATEGORIES, normalizeCategoryId } from '@/lib/categories';
import { AiAPI, BankOfferAPI, PromotionAPI, UserAPI, invalidateCache } from '@/lib/api';

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
  recommendationReasons?: string[];
  aiMeta?: {
    score?: number;
    distanceKm?: number | null;
  };
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
  singleRow = false,
}: {
  deals: Promotion[];
  favoriteIds: Set<string>;
  onFavoriteToggle: (id: string, isFav: boolean) => void;
  singleRow?: boolean;
}) {
  return (
    <div
      style={{
        display: 'grid',
        gridTemplateColumns: singleRow ? 'repeat(5, minmax(260px, 1fr))' : 'repeat(auto-fit, minmax(260px, 1fr))',
        gap: '1.5rem',
        overflowX: singleRow ? 'auto' : 'visible',
        paddingBottom: singleRow ? '0.35rem' : 0,
        scrollbarWidth: singleRow ? 'thin' : 'auto',
      }}
    >
      {deals.map((promotion) => (
        <div key={getPromotionId(promotion)} style={singleRow ? { minWidth: '260px' } : undefined}>
          <PromotionCard
            promotion={promotion}
            isFavorite={favoriteIds.has(getPromotionId(promotion))}
            onFavoriteToggle={onFavoriteToggle}
          />
        </div>
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
  const [aiSearchResults, setAiSearchResults] = useState<Promotion[]>([]);
  const [loadingAiSearch, setLoadingAiSearch] = useState(false);
  const [userLocation, setUserLocation] = useState<{ latitude: number; longitude: number; radiusKm?: number } | null>(null);
  const [loadingDeals, setLoadingDeals] = useState(true);
  const [loadingNearby, setLoadingNearby] = useState(false);
  const [locationError, setLocationError] = useState('');
  const [currentTimestamp] = useState(() => Date.now());

  useEffect(() => {
    const fetchData = async () => {
      try {
        invalidateCache('promotions');
        invalidateCache('bank-offers');
        const promotionsPromise = Promise.all([
          PromotionAPI.getAll({ limit: 48 }),
          BankOfferAPI.getAll({ limit: 24 }).catch(() => []),
        ]).then(([promotions, bankOffers]) => [...promotions, ...bankOffers]);
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
        const currentLocation = {
          latitude: coords.latitude,
          longitude: coords.longitude,
          radiusKm: 20,
        };
        setUserLocation(currentLocation);
        PromotionAPI.getNearby(coords.latitude, coords.longitude, 20)
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

  useEffect(() => {
    const trimmed = searchTerm.trim();
    if (!trimmed) {
      setAiSearchResults([]);
      setLoadingAiSearch(false);
      return;
    }

    let cancelled = false;
    const timeoutId = window.setTimeout(async () => {
      setLoadingAiSearch(true);
      try {
        const response = await AiAPI.search({
          query: trimmed,
          location: userLocation,
          limit: 6,
        });
        if (!cancelled) {
          setAiSearchResults(response.results || []);
        }
      } catch (error) {
        console.error('AI search preview failed:', error);
        if (!cancelled) {
          setAiSearchResults([]);
        }
      } finally {
        if (!cancelled) {
          setLoadingAiSearch(false);
        }
      }
    }, 250);

    return () => {
      cancelled = true;
      window.clearTimeout(timeoutId);
    };
  }, [searchTerm, userLocation]);

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

  const searchResults = aiSearchResults;

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
          background: 'linear-gradient(135deg, #0f172a 0%, #1e40af 50%, #2563eb 100%)',
          color: '#fff',
        }}
      >
        {/* Background Image */}
        <div
          style={{
            position: 'absolute',
            inset: 0,
            backgroundImage: 'url(https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1600&h=900&fit=crop)',
            backgroundSize: 'cover',
            backgroundPosition: 'center',
            opacity: 0.12,
          }}
        />
        {/* Gradient Overlay */}
        <div
          style={{
            position: 'absolute',
            inset: 0,
            background:
              'radial-gradient(circle at 20% 50%, rgba(59,130,246,0.4) 0%, transparent 50%), radial-gradient(circle at 80% 80%, rgba(168,85,247,0.3) 0%, transparent 50%)',
          }}
        />
        <div className="max-w-7xl mx-auto px-4" style={{ position: 'relative', zIndex: 1, paddingTop: '3.5rem', paddingBottom: '4rem' }}>
          <div className="grid grid-cols-1 lg:grid-cols-[1.1fr_0.9fr] gap-12 items-center">
            {/* LEFT: Text Content */}
            <div>
              <div
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '0.5rem',
                  marginBottom: '1.2rem',
                  padding: '0.5rem 1rem',
                  borderRadius: '999px',
                  background: 'rgba(34,197,94,0.15)',
                  border: '1px solid rgba(34,197,94,0.3)',
                  fontSize: '0.8rem',
                  fontWeight: 700,
                }}
              >
                <span
                  style={{
                    width: '6px',
                    height: '6px',
                    borderRadius: '50%',
                    background: '#22c55e',
                    animation: 'pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite',
                  }}
                />
                Updated Daily • 1000+ Active Users • Verified Deals
              </div>

              <h1
                style={{
                  fontSize: 'clamp(2.2rem, 5vw, 3.8rem)',
                  lineHeight: 1.1,
                  margin: 0,
                  fontWeight: 900,
                  marginBottom: '1rem',
                }}
              >
                Find Sri Lanka's Best Deals in Seconds
              </h1>

              <p
                style={{
                  marginBottom: '1.8rem',
                  fontSize: '1.05rem',
                  lineHeight: 1.7,
                  color: 'rgba(248,250,252,0.9)',
                  maxWidth: '540px',
                }}
              >
                Discover verified deals from restaurants, supermarkets, hotels, electronics stores, and top Sri Lankan brands near you.
              </p>

              {/* CTA Buttons */}
              <div className="flex flex-wrap gap-3" style={{ marginBottom: '2rem' }}>
                <a
                  href="https://drive.google.com/uc?export=download&id=12xY8BPO4HqN6oH4vj0wcJSwXiDM0tDKu"
                  className="btn"
                  style={{
                    background: 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)',
                    color: '#fff',
                    padding: '1rem 1.8rem',
                    fontWeight: 800,
                    fontSize: '1rem',
                    boxShadow: '0 10px 30px rgba(245,158,11,0.4)',
                    textDecoration: 'none',
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '0.6rem',
                  }}
                >
                  <i className="fas fa-mobile-screen-button"></i>
                  Download App
                </a>
                <button
                  onClick={() => router.push('/categories/all')}
                  className="btn"
                  style={{
                    background: 'rgba(255,255,255,0.1)',
                    color: '#fff',
                    border: '2px solid rgba(255,255,255,0.2)',
                    padding: '1rem 1.8rem',
                    fontWeight: 700,
                    fontSize: '1rem',
                    backdropFilter: 'blur(10px)',
                  }}
                >
                  <i className="fas fa-compass"></i>
                  Browse Deals
                </button>
              </div>

              {/* Trust Elements */}
              <div
                style={{
                  display: 'flex',
                  flexWrap: 'wrap',
                  gap: '1rem',
                  paddingTop: '1.5rem',
                  borderTop: '1px solid rgba(255,255,255,0.15)',
                }}
              >
                {[
                  { icon: 'fa-location-dot', text: 'Colombo • Kandy • Galle' },
                  { icon: 'fa-shield-halved', text: 'Verified Deals' },
                ].map((item) => (
                  <div
                    key={item.text}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.5rem',
                      fontSize: '0.88rem',
                      color: 'rgba(248,250,252,0.8)',
                    }}
                  >
                    <i className={`fas ${item.icon}`} style={{ color: '#fbbf24' }}></i>
                    {item.text}
                  </div>
                ))}
              </div>

              {/* Trending Searches */}
              <div style={{ marginTop: '1.5rem' }}>
                <div
                  style={{
                    fontSize: '0.8rem',
                    fontWeight: 600,
                    color: 'rgba(248,250,252,0.7)',
                    marginBottom: '0.6rem',
                  }}
                >
                  Trending searches:
                </div>
                <div className="flex flex-wrap gap-2">
                  {['Pizza deals', 'Bank offers', 'Buffet discounts', 'Daraz sales', 'Dialog packages'].map((term) => (
                    <button
                      key={term}
                      onClick={() => {
                        setSearchTerm(term);
                        openDeals(term);
                      }}
                      style={{
                        padding: '0.5rem 0.9rem',
                        borderRadius: '999px',
                        background: 'rgba(255,255,255,0.1)',
                        border: '1px solid rgba(255,255,255,0.2)',
                        color: '#fff',
                        fontSize: '0.85rem',
                        fontWeight: 600,
                        cursor: 'pointer',
                        transition: 'all 0.2s ease',
                      }}
                      onMouseEnter={(e) => {
                        e.currentTarget.style.background = 'rgba(255,255,255,0.2)';
                        e.currentTarget.style.borderColor = 'rgba(255,255,255,0.3)';
                      }}
                      onMouseLeave={(e) => {
                        e.currentTarget.style.background = 'rgba(255,255,255,0.1)';
                        e.currentTarget.style.borderColor = 'rgba(255,255,255,0.2)';
                      }}
                    >
                      {term}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* RIGHT: Mobile Device Mockup */}
            <div className="hidden lg:flex justify-center items-center">
              <div
                style={{
                  position: 'relative',
                  width: '280px',
                  height: '570px',
                  background: '#1f2937',
                  borderRadius: '2.5rem',
                  padding: '0.8rem',
                  boxShadow: '0 25px 50px rgba(0,0,0,0.5), 0 0 0 1px rgba(255,255,255,0.1)',
                }}
              >
                {/* Phone notch */}
                <div
                  style={{
                    position: 'absolute',
                    top: '0.8rem',
                    left: '50%',
                    transform: 'translateX(-50%)',
                    width: '120px',
                    height: '25px',
                    background: '#1f2937',
                    borderRadius: '0 0 1rem 1rem',
                    zIndex: 2,
                  }}
                />

                {/* Phone screen */}
                <div
                  style={{
                    width: '100%',
                    height: '100%',
                    background: 'linear-gradient(180deg, #f8fafc 0%, #e2e8f0 100%)',
                    borderRadius: '2rem',
                    overflow: 'hidden',
                    position: 'relative',
                  }}
                >
                  {/* App Header */}
                  <div
                    style={{
                      background: 'linear-gradient(135deg, #2563eb 0%, #1e40af 100%)',
                      padding: '2.5rem 1rem 1rem',
                      color: '#fff',
                    }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.8rem' }}>
                      <div
                        style={{
                          width: '1.8rem',
                          height: '1.8rem',
                          borderRadius: '0.5rem',
                          background: 'rgba(251,191,36,1)',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          fontWeight: 900,
                          fontSize: '1rem',
                        }}
                      >
                        %
                      </div>
                      <span style={{ fontWeight: 800, fontSize: '0.95rem' }}>DealFinder</span>
                    </div>
                    <div
                      style={{
                        background: 'rgba(255,255,255,0.2)',
                        borderRadius: '0.8rem',
                        padding: '0.6rem 0.8rem',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '0.5rem',
                        fontSize: '0.8rem',
                      }}
                    >
                      <i className="fas fa-search" style={{ fontSize: '0.75rem' }}></i>
                      <span style={{ opacity: 0.9 }}>Search deals...</span>
                    </div>
                  </div>

                  {/* App Content - Deal Cards */}
                  <div style={{ padding: '1rem', overflowY: 'auto', height: 'calc(100% - 140px)' }}>
                    {/* Deal Card 1 - Pizza */}
                    <div
                      style={{
                        background: '#fff',
                        borderRadius: '1rem',
                        marginBottom: '0.8rem',
                        overflow: 'hidden',
                        boxShadow: '0 2px 8px rgba(0,0,0,0.08)',
                      }}
                    >
                      <div
                        style={{
                          height: '100px',
                          backgroundImage: 'url(https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&h=200&fit=crop)',
                          backgroundSize: 'cover',
                          backgroundPosition: 'center',
                          position: 'relative',
                        }}
                      >
                        <div
                          style={{
                            position: 'absolute',
                            inset: 0,
                            background: 'linear-gradient(to bottom, rgba(0,0,0,0.1), rgba(0,0,0,0.3))',
                          }}
                        />
                        <div
                          style={{
                            position: 'absolute',
                            top: '0.5rem',
                            right: '0.5rem',
                            background: '#ef4444',
                            color: '#fff',
                            padding: '0.3rem 0.6rem',
                            borderRadius: '0.5rem',
                            fontSize: '0.7rem',
                            fontWeight: 800,
                          }}
                        >
                          50% OFF
                        </div>
                      </div>
                      <div style={{ padding: '0.8rem' }}>
                        <div style={{ fontWeight: 800, fontSize: '0.85rem', marginBottom: '0.3rem', color: '#0f172a' }}>
                          Pizza Hut Mega Deal
                        </div>
                        <div style={{ fontSize: '0.7rem', color: '#64748b', marginBottom: '0.5rem' }}>
                          <i className="fas fa-location-dot" style={{ marginRight: '0.3rem' }}></i>
                          Colombo City Centre
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                          <div
                            style={{
                              fontSize: '0.65rem',
                              background: '#fef3c7',
                              color: '#92400e',
                              padding: '0.2rem 0.5rem',
                              borderRadius: '0.4rem',
                              fontWeight: 700,
                            }}
                          >
                            <i className="fas fa-clock" style={{ marginRight: '0.2rem' }}></i>
                            2 days left
                          </div>
                        </div>
                      </div>
                    </div>

                    {/* Deal Card 2 - Supermarket */}
                    <div
                      style={{
                        background: '#fff',
                        borderRadius: '1rem',
                        marginBottom: '0.8rem',
                        overflow: 'hidden',
                        boxShadow: '0 2px 8px rgba(0,0,0,0.08)',
                      }}
                    >
                      <div
                        style={{
                          height: '100px',
                          backgroundImage: 'url(https://images.unsplash.com/photo-1542838132-92c53300491e?w=400&h=200&fit=crop)',
                          backgroundSize: 'cover',
                          backgroundPosition: 'center',
                          position: 'relative',
                        }}
                      >
                        <div
                          style={{
                            position: 'absolute',
                            inset: 0,
                            background: 'linear-gradient(to bottom, rgba(0,0,0,0.1), rgba(0,0,0,0.3))',
                          }}
                        />
                        <div
                          style={{
                            position: 'absolute',
                            top: '0.5rem',
                            right: '0.5rem',
                            background: '#10b981',
                            color: '#fff',
                            padding: '0.3rem 0.6rem',
                            borderRadius: '0.5rem',
                            fontSize: '0.7rem',
                            fontWeight: 800,
                          }}
                        >
                          30% OFF
                        </div>
                      </div>
                      <div style={{ padding: '0.8rem' }}>
                        <div style={{ fontWeight: 800, fontSize: '0.85rem', marginBottom: '0.3rem', color: '#0f172a' }}>
                          Cargills Food City
                        </div>
                        <div style={{ fontSize: '0.7rem', color: '#64748b', marginBottom: '0.5rem' }}>
                          <i className="fas fa-location-dot" style={{ marginRight: '0.3rem' }}></i>
                          Kandy
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                          <div
                            style={{
                              fontSize: '0.65rem',
                              background: '#dbeafe',
                              color: '#1e40af',
                              padding: '0.2rem 0.5rem',
                              borderRadius: '0.4rem',
                              fontWeight: 700,
                            }}
                          >
                            <i className="fas fa-tag" style={{ marginRight: '0.2rem' }}></i>
                            Groceries
                          </div>
                        </div>
                      </div>
                    </div>

                    {/* Deal Card 3 (Partial) - Hotel/Restaurant */}
                    <div
                      style={{
                        background: '#fff',
                        borderRadius: '1rem',
                        overflow: 'hidden',
                        boxShadow: '0 2px 8px rgba(0,0,0,0.08)',
                      }}
                    >
                      <div
                        style={{
                          height: '80px',
                          backgroundImage: 'url(https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&h=200&fit=crop)',
                          backgroundSize: 'cover',
                          backgroundPosition: 'center',
                          position: 'relative',
                        }}
                      >
                        <div
                          style={{
                            position: 'absolute',
                            inset: 0,
                            background: 'linear-gradient(to bottom, rgba(0,0,0,0.1), rgba(0,0,0,0.3))',
                          }}
                        />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>


        </div>
      </section>

      {/* Stats / Social Proof Section */}
      <section
        style={{
          background: 'linear-gradient(180deg, #f8fafc 0%, #e2e8f0 100%)',
          padding: '4rem 0',
        }}
      >
        <div className="max-w-7xl mx-auto px-4">
          <div style={{ textAlign: 'center', marginBottom: '3rem' }}>
            <div
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '0.5rem',
                marginBottom: '0.8rem',
                padding: '0.5rem 1rem',
                borderRadius: '999px',
                background: 'rgba(37,99,235,0.1)',
                border: '1px solid rgba(37,99,235,0.2)',
                fontSize: '0.8rem',
                fontWeight: 700,
                color: '#2563eb',
              }}
            >
              <i className="fas fa-chart-line"></i>
              Platform Statistics
            </div>
            <h2
              style={{
                fontSize: 'clamp(1.8rem, 4vw, 2.5rem)',
                fontWeight: 900,
                color: '#0f172a',
                marginBottom: '0.5rem',
              }}
            >
              Trusted by Thousands Across Sri Lanka
            </h2>
            <p
              style={{
                fontSize: '1.05rem',
                color: '#64748b',
                maxWidth: '600px',
                margin: '0 auto',
              }}
            >
              Join the growing community of smart shoppers and businesses
            </p>
          </div>

          <div className="grid grid-cols-2 lg:grid-cols-4 gap-6">
            {[
              {
                icon: 'fa-tags',
                number: loadingDeals ? '...' : `${activePromotions.length}+`,
                label: 'Active Promotions',
                color: '#ef4444',
                bgColor: 'rgba(239,68,68,0.1)',
              },
              {
                icon: 'fa-store',
                number: loadingDeals ? '...' : `${new Set(activePromotions.map((p) => getMerchantId(p))).size}+`,
                label: 'Partner Stores',
                color: '#3b82f6',
                bgColor: 'rgba(59,130,246,0.1)',
              },
              {
                icon: 'fa-users',
                number: '12,000+',
                label: 'Monthly Users',
                color: '#10b981',
                bgColor: 'rgba(16,185,129,0.1)',
              },
              {
                icon: 'fa-location-dot',
                number: '25+',
                label: 'Cities Covered',
                color: '#f59e0b',
                bgColor: 'rgba(245,158,11,0.1)',
              },
            ].map((stat) => (
              <div
                key={stat.label}
                style={{
                  background: '#fff',
                  borderRadius: '1.2rem',
                  padding: '2rem 1.5rem',
                  textAlign: 'center',
                  boxShadow: '0 4px 12px rgba(0,0,0,0.08)',
                  border: '1px solid #e2e8f0',
                  transition: 'all 0.3s ease',
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.transform = 'translateY(-8px)';
                  e.currentTarget.style.boxShadow = '0 12px 24px rgba(0,0,0,0.12)';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.transform = 'translateY(0)';
                  e.currentTarget.style.boxShadow = '0 4px 12px rgba(0,0,0,0.08)';
                }}
              >
                <div
                  style={{
                    width: '4rem',
                    height: '4rem',
                    borderRadius: '1rem',
                    background: stat.bgColor,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    margin: '0 auto 1.2rem',
                  }}
                >
                  <i className={`fas ${stat.icon}`} style={{ fontSize: '1.8rem', color: stat.color }}></i>
                </div>
                <div
                  style={{
                    fontSize: 'clamp(2rem, 4vw, 2.8rem)',
                    fontWeight: 900,
                    color: '#0f172a',
                    marginBottom: '0.5rem',
                    lineHeight: 1,
                  }}
                >
                  {stat.number}
                </div>
                <div style={{ fontSize: '0.95rem', fontWeight: 600, color: '#64748b' }}>{stat.label}</div>
              </div>
            ))}
          </div>

          <div
            style={{
              marginTop: '3rem',
              display: 'flex',
              flexWrap: 'wrap',
              justifyContent: 'center',
              gap: '2rem',
              alignItems: 'center',
            }}
          >
            {[
              { icon: 'fa-shield-halved', text: 'Verified Deals' },
              { icon: 'fa-clock', text: 'Updated Daily' },
              { icon: 'fa-mobile-screen-button', text: 'Mobile App Available' },
              { icon: 'fa-map-location-dot', text: 'Island-wide Coverage' },
            ].map((badge) => (
              <div
                key={badge.text}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.6rem',
                  padding: '0.8rem 1.2rem',
                  background: '#fff',
                  borderRadius: '999px',
                  border: '1px solid #e2e8f0',
                  fontSize: '0.9rem',
                  fontWeight: 600,
                  color: '#475569',
                  boxShadow: '0 2px 8px rgba(0,0,0,0.06)',
                }}
              >
                <i className={`fas ${badge.icon}`} style={{ color: '#2563eb' }}></i>
                {badge.text}
              </div>
            ))}
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
              meta={
                loadingAiSearch
                  ? 'AI is ranking live matches'
                  : searchResults.length > 0
                    ? 'Quick preview from backend-ranked results'
                    : 'No matching preview yet'
              }
              actionLabel="View All Deals"
              onAction={() => openDeals(searchTerm)}
            />
            {loadingAiSearch ? (
              <SkeletonGrid count={3} />
            ) : searchResults.length > 0 ? (
              <DealGrid deals={searchResults} favoriteIds={favoriteIds} onFavoriteToggle={handleFavoriteToggle} />
            ) : (
              <div className="empty-state">
                <div className="empty-icon">
                  <i className="fas fa-search"></i>
                </div>
                <h2 style={{ marginTop: 0, marginBottom: '0.5rem', fontWeight: 800 }}>No quick matches found</h2>
                <p style={{ color: 'var(--text-secondary)', marginBottom: '1.2rem', maxWidth: '34rem', marginInline: 'auto', lineHeight: 1.7 }}>
                  Try a store name, category, or broader keyword. The full results page will still give you more room to explore.
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
              meta="Top featured offers in one quick row"
              actionLabel="View More"
              onAction={() => router.push('/categories/all')}
              accent="var(--highlight-color)"
            />
            {loadingDeals ? (
              <div className="grid gap-6" style={{ gridTemplateColumns: 'repeat(3, minmax(260px, 1fr))' }}>
                {Array.from({ length: 3 }).map((_, index) => (
                  <div key={index} style={{ minWidth: '260px' }}>
                    <SkeletonCard />
                  </div>
                ))}
              </div>
            ) : (
              <DealGrid deals={featuredDeals.slice(0, 3)} favoriteIds={favoriteIds} onFavoriteToggle={handleFavoriteToggle} />
            )}
          </section>

          <section>
            <SectionHeader
              eyebrow="Urgency"
              title="Ending Soon"
              icon="fa-hourglass-half"
              meta="Search before they disappear"
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

          {nearbyDeals.length > 0 && (
            <section>
              <SectionHeader
                eyebrow="Location-based"
                title="Nearby Deals"
                icon="fa-location-dot"
                meta="Deals close to your location"
                actionLabel="View All Nearby"
                onAction={() => router.push('/nearby')}
                accent="#10b981"
              />
              {loadingNearby ? (
                <SkeletonGrid count={3} />
              ) : (
                <DealGrid deals={nearbyDeals.slice(0, 3)} favoriteIds={favoriteIds} onFavoriteToggle={handleFavoriteToggle} />
              )}
            </section>
          )}

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

          <section
            style={{
              background: 'linear-gradient(180deg, #ffffff 0%, #fffbf5 100%)',
              padding: '6rem 0',
            }}
          >
            <div className="max-w-7xl mx-auto px-4">
              {/* Header */}
              <div style={{ textAlign: 'center', marginBottom: '4rem' }}>
                <div
                  style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '0.5rem',
                    marginBottom: '1rem',
                    padding: '0.5rem 1rem',
                    borderRadius: '999px',
                    background: 'rgba(249,115,22,0.1)',
                    border: '1px solid rgba(249,115,22,0.2)',
                    fontSize: '0.75rem',
                    fontWeight: 700,
                    color: '#ea580c',
                    textTransform: 'uppercase',
                    letterSpacing: '0.05em',
                  }}
                >
                  <i className="fas fa-fire"></i>
                  Trusted by Smart Shoppers
                </div>
                <h2
                  style={{
                    fontSize: 'clamp(2rem, 4vw, 3rem)',
                    fontWeight: 900,
                    color: '#0f172a',
                    marginBottom: '1rem',
                    lineHeight: 1.2,
                  }}
                >
                  Why Thousands Use <span style={{ color: '#ea580c' }}>DealFinder</span> Daily
                </h2>
                <p
                  style={{
                    fontSize: '1.1rem',
                    color: '#64748b',
                    maxWidth: '600px',
                    margin: '0 auto',
                    lineHeight: 1.7,
                  }}
                >
                  Compare offers faster, discover better deals, and save money without endless searching.
                </p>
              </div>

              {/* Feature Cards */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
                {[
                  {
                    icon: 'fa-sparkles',
                    title: 'Smart Deal Discovery',
                    description: 'Find the best restaurant, shopping, and hotel offers in seconds — all in one place.',
                    badge: 'Updated Daily',
                    color: '#3b82f6',
                    bgColor: 'rgba(59,130,246,0.1)',
                  },
                  {
                    icon: 'fa-arrows-left-right',
                    title: 'Compare Before You Buy',
                    description: 'Quickly compare prices, discounts, and offers from multiple stores without opening dozens of tabs.',
                    badge: 'Save Time',
                    color: '#8b5cf6',
                    bgColor: 'rgba(139,92,246,0.1)',
                  },
                  {
                    icon: 'fa-bell',
                    title: 'Never Miss a Good Deal',
                    description: 'Save your favorite offers and get notified when prices drop or new promotions appear.',
                    badge: 'Smart Alerts',
                    color: '#10b981',
                    bgColor: 'rgba(16,185,129,0.1)',
                  },
                ].map((feature) => (
                  <div
                    key={feature.title}
                    style={{
                      background: '#fff',
                      borderRadius: '1.5rem',
                      padding: '2.5rem 2rem',
                      border: '1px solid #e2e8f0',
                      boxShadow: '0 4px 12px rgba(0,0,0,0.06)',
                      transition: 'all 0.3s ease',
                      textAlign: 'center',
                    }}
                    onMouseEnter={(e) => {
                      e.currentTarget.style.transform = 'translateY(-8px)';
                      e.currentTarget.style.boxShadow = '0 12px 28px rgba(0,0,0,0.12)';
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.transform = 'translateY(0)';
                      e.currentTarget.style.boxShadow = '0 4px 12px rgba(0,0,0,0.06)';
                    }}
                  >
                    <div
                      style={{
                        width: '4.5rem',
                        height: '4.5rem',
                        borderRadius: '1.2rem',
                        background: feature.bgColor,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        margin: '0 auto 1.5rem',
                      }}
                    >
                      <i
                        className={`fas ${feature.icon}`}
                        style={{
                          fontSize: '2rem',
                          color: feature.color,
                        }}
                      ></i>
                    </div>
                    <h3
                      style={{
                        fontSize: '1.3rem',
                        fontWeight: 800,
                        color: '#0f172a',
                        marginBottom: '1rem',
                      }}
                    >
                      {feature.title}
                    </h3>
                    <p
                      style={{
                        fontSize: '0.95rem',
                        color: '#64748b',
                        lineHeight: 1.7,
                        marginBottom: '1.5rem',
                      }}
                    >
                      {feature.description}
                    </p>
                    <div
                      style={{
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: '0.4rem',
                        padding: '0.4rem 0.9rem',
                        borderRadius: '999px',
                        background: feature.bgColor,
                        color: feature.color,
                        fontSize: '0.8rem',
                        fontWeight: 700,
                      }}
                    >
                      <i className="fas fa-check-circle"></i>
                      {feature.badge}
                    </div>
                  </div>
                ))}
              </div>

              {/* Bottom Trust Row */}
              <div
                style={{
                  marginTop: '4rem',
                  textAlign: 'center',
                  padding: '1.5rem',
                  borderRadius: '1rem',
                  background: 'rgba(249,115,22,0.05)',
                  border: '1px solid rgba(249,115,22,0.1)',
                }}
              >
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.6rem',
                    fontSize: '1rem',
                    color: '#475569',
                    fontWeight: 600,
                    flexWrap: 'wrap',
                  }}
                >
                  <i className="fas fa-store" style={{ color: '#ea580c' }}></i>
                  <span>Deals from restaurants, supermarkets, hotels & top local brands</span>
                  <span style={{ color: '#cbd5e1' }}>•</span>
                  <span>Used by shoppers across Colombo, Kandy, Galle & more</span>
                </div>
              </div>
            </div>
          </section>

          <section style={{ padding: '5rem 0', background: '#fff' }}>
            <div className="max-w-7xl mx-auto px-4">
              {/* Header */}
              <div style={{ textAlign: 'center', marginBottom: '4rem' }}>
                <div
                  style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '0.5rem',
                    marginBottom: '1rem',
                    padding: '0.5rem 1rem',
                    borderRadius: '999px',
                    background: 'rgba(59,130,246,0.1)',
                    border: '1px solid rgba(59,130,246,0.2)',
                    fontSize: '0.75rem',
                    fontWeight: 700,
                    color: '#2563eb',
                    textTransform: 'uppercase',
                    letterSpacing: '0.05em',
                  }}
                >
                  Simple & Fast
                </div>
                <h2
                  style={{
                    fontSize: 'clamp(2rem, 4vw, 3rem)',
                    fontWeight: 900,
                    color: '#0f172a',
                    marginBottom: '1rem',
                    lineHeight: 1.2,
                  }}
                >
                  Save More in 3 Simple Steps
                </h2>
                <p
                  style={{
                    fontSize: '1.1rem',
                    color: '#64748b',
                    maxWidth: '600px',
                    margin: '0 auto',
                    lineHeight: 1.7,
                  }}
                >
                  Find deals, compare offers, and save money in seconds.
                </p>
              </div>

              {/* Steps */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-8" style={{ position: 'relative' }}>
                {/* Connecting Line (Desktop) */}
                <div
                  className="hidden md:block"
                  style={{
                    position: 'absolute',
                    top: '3rem',
                    left: '25%',
                    right: '25%',
                    height: '2px',
                    background: 'linear-gradient(to right, #3b82f6 0%, #8b5cf6 50%, #10b981 100%)',
                    opacity: 0.2,
                    zIndex: 0,
                  }}
                />

                {[
                  {
                    number: '01',
                    icon: 'fa-location-dot',
                    title: 'Discover Deals Near You',
                    description: 'Browse restaurant offers, shopping discounts, hotel deals, and nearby promotions instantly.',
                    color: '#3b82f6',
                    bgColor: 'rgba(59,130,246,0.1)',
                  },
                  {
                    number: '02',
                    icon: 'fa-bolt',
                    title: 'Compare & Find the Best Offer',
                    description: 'Quickly see prices, discounts, and limited-time deals without opening multiple apps or tabs.',
                    color: '#8b5cf6',
                    bgColor: 'rgba(139,92,246,0.1)',
                  },
                  {
                    number: '03',
                    icon: 'fa-bookmark',
                    title: 'Save or Redeem Anytime',
                    description: 'Bookmark deals for later or grab the offer before it expires.',
                    color: '#10b981',
                    bgColor: 'rgba(16,185,129,0.1)',
                  },
                ].map((step) => (
                  <div
                    key={step.number}
                    style={{
                      position: 'relative',
                      zIndex: 1,
                      textAlign: 'center',
                    }}
                  >
                    {/* Number Badge */}
                    <div
                      style={{
                        width: '4rem',
                        height: '4rem',
                        borderRadius: '50%',
                        background: '#fff',
                        border: `3px solid ${step.color}`,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        margin: '0 auto 1.5rem',
                        fontSize: '1.5rem',
                        fontWeight: 900,
                        color: step.color,
                        boxShadow: '0 4px 12px rgba(0,0,0,0.08)',
                      }}
                    >
                      {step.number}
                    </div>

                    {/* Icon */}
                    <div
                      style={{
                        width: '3.5rem',
                        height: '3.5rem',
                        borderRadius: '1rem',
                        background: step.bgColor,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        margin: '0 auto 1.5rem',
                      }}
                    >
                      <i
                        className={`fas ${step.icon}`}
                        style={{
                          fontSize: '1.5rem',
                          color: step.color,
                        }}
                      ></i>
                    </div>

                    {/* Title */}
                    <h3
                      style={{
                        fontSize: '1.3rem',
                        fontWeight: 800,
                        color: '#0f172a',
                        marginBottom: '1rem',
                      }}
                    >
                      {step.title}
                    </h3>

                    {/* Description */}
                    <p
                      style={{
                        fontSize: '0.95rem',
                        color: '#64748b',
                        lineHeight: 1.7,
                        maxWidth: '320px',
                        margin: '0 auto',
                      }}
                    >
                      {step.description}
                    </p>
                  </div>
                ))}
              </div>
            </div>
          </section>

          {user ? (
            <section
              style={{
                background: 'linear-gradient(135deg, rgba(59,130,246,0.05) 0%, rgba(139,92,246,0.05) 100%)',
                borderRadius: '1.5rem',
                padding: '3rem 2rem',
                border: '1px solid rgba(59,130,246,0.1)',
              }}
            >
              <div style={{ marginBottom: '2rem' }}>
                <div
                  style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '0.5rem',
                    marginBottom: '1rem',
                    padding: '0.5rem 1rem',
                    borderRadius: '999px',
                    background: 'rgba(239,68,68,0.1)',
                    border: '1px solid rgba(239,68,68,0.2)',
                    fontSize: '0.75rem',
                    fontWeight: 700,
                    color: '#dc2626',
                    textTransform: 'uppercase',
                    letterSpacing: '0.05em',
                  }}
                >
                  <i className="fas fa-heart"></i>
                  Your Saved Deals
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'end', gap: '1rem', flexWrap: 'wrap' }}>
                  <div>
                    <h2
                      style={{
                        fontSize: 'clamp(1.8rem, 4vw, 2.5rem)',
                        fontWeight: 900,
                        color: '#0f172a',
                        marginBottom: '0.5rem',
                        lineHeight: 1.2,
                      }}
                    >
                      {savedPreview.length > 0 ? 'Continue Where You Left Off' : 'Start Saving Your Favorite Deals'}
                    </h2>
                    <p
                      style={{
                        fontSize: '1rem',
                        color: '#64748b',
                        margin: 0,
                      }}
                    >
                      {savedPreview.length > 0
                        ? `You have ${favoriteDeals.length} saved deal${favoriteDeals.length !== 1 ? 's' : ''} ready to grab`
                        : 'Bookmark deals you love and come back to them anytime'}
                    </p>
                  </div>
                  {savedPreview.length > 0 && (
                    <button
                      onClick={() => router.push('/favorites')}
                      className="btn"
                      style={{
                        background: 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)',
                        color: '#fff',
                        padding: '0.9rem 1.5rem',
                        fontWeight: 700,
                        boxShadow: '0 4px 12px rgba(239,68,68,0.3)',
                      }}
                    >
                      <i className="fas fa-heart"></i>
                      View All Saved
                    </button>
                  )}
                </div>
              </div>

              {savedPreview.length > 0 ? (
                <DealGrid deals={savedPreview} favoriteIds={favoriteIds} onFavoriteToggle={handleFavoriteToggle} />
              ) : (
                <div
                  style={{
                    textAlign: 'center',
                    padding: '3rem 2rem',
                    background: '#fff',
                    borderRadius: '1.2rem',
                    border: '1px solid #e2e8f0',
                  }}
                >
                  <div
                    style={{
                      width: '5rem',
                      height: '5rem',
                      borderRadius: '50%',
                      background: 'rgba(239,68,68,0.1)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      margin: '0 auto 1.5rem',
                    }}
                  >
                    <i className="fas fa-heart" style={{ fontSize: '2rem', color: '#ef4444' }}></i>
                  </div>
                  <h3 style={{ fontSize: '1.5rem', fontWeight: 800, color: '#0f172a', marginBottom: '0.8rem' }}>
                    No Saved Deals Yet
                  </h3>
                  <p style={{ color: '#64748b', marginBottom: '1.8rem', fontSize: '1rem', maxWidth: '400px', margin: '0 auto 1.8rem' }}>
                    Start saving deals you're interested in. Tap the heart icon on any deal to add it here.
                  </p>
                  <button
                    onClick={() => router.push('/categories/all')}
                    className="btn"
                    style={{
                      background: 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)',
                      color: '#fff',
                      padding: '1rem 2rem',
                      fontWeight: 700,
                      fontSize: '1rem',
                    }}
                  >
                    <i className="fas fa-compass"></i>
                    Explore Deals
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

          <section
            style={{
              background: 'linear-gradient(135deg, #0f172a 0%, #1e40af 100%)',
              borderRadius: '2rem',
              padding: '4rem 2rem',
              textAlign: 'center',
              position: 'relative',
              overflow: 'hidden',
            }}
          >
            {/* Background Pattern */}
            <div
              style={{
                position: 'absolute',
                inset: 0,
                backgroundImage:
                  'radial-gradient(circle at 20% 50%, rgba(59,130,246,0.3) 0%, transparent 50%), radial-gradient(circle at 80% 80%, rgba(168,85,247,0.2) 0%, transparent 50%)',
                opacity: 0.5,
              }}
            />

            <div style={{ position: 'relative', zIndex: 1, maxWidth: '800px', margin: '0 auto' }}>
              <div
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '0.5rem',
                  marginBottom: '1.5rem',
                  padding: '0.6rem 1.2rem',
                  borderRadius: '999px',
                  background: 'rgba(251,191,36,0.2)',
                  border: '1px solid rgba(251,191,36,0.3)',
                  fontSize: '0.8rem',
                  fontWeight: 700,
                  color: '#fbbf24',
                  textTransform: 'uppercase',
                  letterSpacing: '0.05em',
                }}
              >
                <i className="fas fa-bolt"></i>
                Start Saving Today
              </div>

              <h2
                style={{
                  fontSize: 'clamp(2.2rem, 5vw, 3.5rem)',
                  fontWeight: 900,
                  color: '#fff',
                  marginBottom: '1.2rem',
                  lineHeight: 1.2,
                }}
              >
                Ready to Save Money on Every Purchase?
              </h2>

              <p
                style={{
                  fontSize: '1.15rem',
                  color: 'rgba(248,250,252,0.9)',
                  marginBottom: '2.5rem',
                  lineHeight: 1.7,
                  maxWidth: '600px',
                  margin: '0 auto 2.5rem',
                }}
              >
                Join thousands of smart shoppers across Sri Lanka. Discover the best deals from restaurants, stores, and brands near you.
              </p>

              <div className="flex justify-center gap-4 flex-wrap">
                <button
                  onClick={() => router.push('/categories/all')}
                  className="btn"
                  style={{
                    background: 'linear-gradient(135deg, #fbbf24 0%, #f59e0b 100%)',
                    color: '#0f172a',
                    padding: '1.1rem 2.5rem',
                    fontSize: '1.05rem',
                    fontWeight: 800,
                    boxShadow: '0 8px 24px rgba(251,191,36,0.4)',
                  }}
                >
                  <i className="fas fa-fire"></i>
                  Browse All Deals
                </button>
                <a
                  href="https://drive.google.com/uc?export=download&id=12xY8BPO4HqN6oH4vj0wcJSwXiDM0tDKu"
                  className="btn"
                  style={{
                    background: 'rgba(255,255,255,0.1)',
                    color: '#fff',
                    border: '2px solid rgba(255,255,255,0.3)',
                    padding: '1.1rem 2.5rem',
                    fontSize: '1.05rem',
                    fontWeight: 700,
                    backdropFilter: 'blur(10px)',
                    textDecoration: 'none',
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '0.6rem',
                  }}
                >
                  <i className="fas fa-mobile-screen-button"></i>
                  Download App
                </a>
              </div>

              {/* Trust Indicators */}
              <div
                style={{
                  marginTop: '3rem',
                  display: 'flex',
                  justifyContent: 'center',
                  gap: '2rem',
                  flexWrap: 'wrap',
                  paddingTop: '2rem',
                  borderTop: '1px solid rgba(255,255,255,0.1)',
                }}
              >
                {[
                  { icon: 'fa-users', text: '12,000+ Users' },
                  { icon: 'fa-tags', text: `${activePromotions.length}+ Active Deals` },
                  { icon: 'fa-shield-halved', text: 'Verified Offers' },
                ].map((item) => (
                  <div
                    key={item.text}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.6rem',
                      color: 'rgba(248,250,252,0.8)',
                      fontSize: '0.9rem',
                      fontWeight: 600,
                    }}
                  >
                    <i className={`fas ${item.icon}`} style={{ color: '#fbbf24' }}></i>
                    {item.text}
                  </div>
                ))}
              </div>
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


