'use client';

import { useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import toast from 'react-hot-toast';
import PromotionCard from '@/components/ui/PromotionCard';
import SkeletonCard from '@/components/ui/SkeletonCard';
import { useAuth } from '@/contexts/AuthContext';
import { PromotionAPI, UserAPI, invalidateCache } from '@/lib/api';

const CATEGORIES = [
  { id: 'all', name: 'All Deals', icon: 'fa-layer-group', note: 'Browse every active offer' },
  { id: 'food', name: 'Food & Dining', icon: 'fa-utensils', note: 'Restaurants, cafes, takeaway' },
  { id: 'supermarkets', name: 'Supermarkets', icon: 'fa-cart-shopping', note: 'Daily savings and essentials' },
];

const VALUE_POINTS = [
  {
    icon: 'fa-location-crosshairs',
    title: 'Nearby discovery',
    text: 'Surface offers around you without digging through outdated posts and scattered pages.',
  },
  {
    icon: 'fa-bolt',
    title: 'Fresh daily updates',
    text: 'Featured and latest deals stay visible in one place so your best offers are easy to scan.',
  },
  {
    icon: 'fa-heart',
    title: 'Personal shortlist',
    text: 'Save favorites, revisit merchants quickly, and keep the offers worth tracking close by.',
  },
];

export default function HomePage() {
  const router = useRouter();
  const { user } = useAuth();
  const [featured, setFeatured] = useState<any[]>([]);
  const [latest, setLatest] = useState<any[]>([]);
  const [nearby, setNearby] = useState<any[]>([]);
  const [allPromotions, setAllPromotions] = useState<any[]>([]);
  const [favoriteIds, setFavoriteIds] = useState<Set<string>>(new Set());
  const [searchTerm, setSearchTerm] = useState('');
  const [isSearching, setIsSearching] = useState(false);
  const [searchResults, setSearchResults] = useState<any[]>([]);
  const [loadingDeals, setLoadingDeals] = useState(true);
  const [loadingNearby, setLoadingNearby] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const [hasMoreLatest, setHasMoreLatest] = useState(true);
  const [latestCount, setLatestCount] = useState(8);
  const [locationError, setLocationError] = useState('');
  const [userLocation, setUserLocation] = useState<{ lat: number; lon: number } | null>(null);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    const fetchData = async () => {
      try {
        invalidateCache('promotions');

        const homepagePromise: Promise<{ featured: any[]; latest: any[] }> = PromotionAPI.getHomepage().catch(() => {
          return PromotionAPI.getAll({ limit: 20 }).then((data: any[]) => ({
            featured: data.filter((promotion: any) => promotion.featured).slice(0, 6),
            latest: data,
          }));
        });

        let favoritesData: any[] = [];
        if (user) {
          const cacheKey = `favorites_${user._id}`;
          const cached = localStorage.getItem(cacheKey);
          const cacheTime = localStorage.getItem(`${cacheKey}_time`);
          const now = Date.now();

          if (cached && cacheTime && now - parseInt(cacheTime, 10) < 5 * 60 * 1000) {
            favoritesData = JSON.parse(cached);
          } else {
            favoritesData = await UserAPI.getFavorites(user._id).catch(() => []);
            localStorage.setItem(cacheKey, JSON.stringify(favoritesData));
            localStorage.setItem(`${cacheKey}_time`, now.toString());
          }
        }

        const homepageData = await homepagePromise;
        setFeatured(homepageData.featured);
        setLatest(homepageData.latest);
        setAllPromotions(homepageData.latest);
        setHasMoreLatest(homepageData.latest.length >= 20);

        if (favoritesData.length > 0) {
          setFavoriteIds(new Set(favoritesData.map((favorite: any) => favorite._id || favorite.id)));
        }
      } catch (error) {
        console.error('Failed to load deals:', error);
        toast.error('Failed to load deals.');
      } finally {
        setLoadingDeals(false);
      }
    };

    fetchData();

    if (navigator.geolocation) {
      setLoadingNearby(true);
      navigator.geolocation.getCurrentPosition(
        ({ coords }) => {
          setUserLocation({ lat: coords.latitude, lon: coords.longitude });
          PromotionAPI.getNearby(coords.latitude, coords.longitude, 10)
            .then((data) => {
              const sorted = [...data].sort(
                (a: any, b: any) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
              );
              setNearby(sorted);
            })
            .catch(() => setLocationError('Could not fetch nearby deals right now.'))
            .finally(() => setLoadingNearby(false));
        },
        (err) => {
          const messages: Record<number, string> = {
            1: 'Location permission denied.',
            2: 'Location unavailable.',
            3: 'Location timed out.',
          };
          setLocationError(messages[err.code] || 'Could not get location.');
          setLoadingNearby(false);
        }
      );
    }
  }, [user]);

  useEffect(() => {
    const timer = setTimeout(() => {
      if (!searchTerm.trim()) {
        setIsSearching(false);
        setSearchResults([]);
        return;
      }

      const term = searchTerm.toLowerCase();
      setIsSearching(true);
      setSearchResults(
        allPromotions.filter((promotion: any) => {
          const merchantName =
            typeof promotion.merchant === 'object' ? promotion.merchant?.name : promotion.merchant;

          return (
            promotion.title?.toLowerCase().includes(term) ||
            promotion.description?.toLowerCase().includes(term) ||
            merchantName?.toLowerCase().includes(term)
          );
        })
      );
    }, 300);

    return () => clearTimeout(timer);
  }, [searchTerm, allPromotions]);

  const loadMoreLatest = async () => {
    if (loadingMore || !hasMoreLatest) return;

    setLoadingMore(true);
    try {
      const moreDeals = await PromotionAPI.getAll({ limit: 20, skip: latest.length });
      if (moreDeals.length > 0) {
        setLatest((current) => [...current, ...moreDeals]);
        setAllPromotions((current) => [...current, ...moreDeals]);
        setHasMoreLatest(moreDeals.length >= 20);
      } else {
        setHasMoreLatest(false);
      }
    } catch {
      toast.error('Failed to load more deals.');
    } finally {
      setLoadingMore(false);
    }
  };

  const stats = useMemo(() => {
    const merchantCount = new Set(
      allPromotions.map((promotion: any) =>
        typeof promotion.merchant === 'object' ? promotion.merchant?._id : promotion.merchant
      )
    ).size;

    return [
      { value: `${allPromotions.length}+`, label: 'Active deals' },
      { value: `${merchantCount}+`, label: 'Trusted merchants' },
      { value: nearby.length > 0 ? `${nearby.length}` : 'Live', label: 'Nearby picks' },
    ];
  }, [allPromotions, nearby]);

  const DealGrid = ({ deals }: { deals: any[] }) => (
    <div
      style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))',
        gap: '1.5rem',
      }}
    >
      {deals.map((promotion) => (
        <PromotionCard
          key={promotion._id || promotion.id}
          promotion={promotion}
          isFavorite={favoriteIds.has(promotion._id || promotion.id)}
          onFavoriteToggle={(id, isFav) =>
            setFavoriteIds((current) => {
              const next = new Set(current);
              if (isFav) next.add(id);
              else next.delete(id);
              return next;
            })
          }
        />
      ))}
    </div>
  );

  const SkeletonGrid = ({ count }: { count: number }) => (
    <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
      {Array.from({ length: count }).map((_, index) => (
        <SkeletonCard key={index} />
      ))}
    </div>
  );

  return (
    <div>
      <section
        style={{
          position: 'relative',
          overflow: 'hidden',
          background:
            'radial-gradient(circle at top left, rgba(22,163,74,0.22), transparent 32%), radial-gradient(circle at bottom right, rgba(245,158,11,0.2), transparent 28%), linear-gradient(135deg, #0f172a 0%, #123b2a 45%, #0f766e 100%)',
          color: '#f8fafc',
        }}
      >
        <div
          style={{
            position: 'absolute',
            inset: 0,
            backgroundImage:
              'url(https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?auto=format&fit=crop&w=1600&q=80)',
            backgroundSize: 'cover',
            backgroundPosition: 'center',
            opacity: 0.16,
          }}
        />
        <div
          className="max-w-7xl mx-auto px-4"
          style={{
            position: 'relative',
            zIndex: 1,
            paddingTop: '4.5rem',
            paddingBottom: '4rem',
          }}
        >
          <div className="grid grid-cols-1 lg:grid-cols-[1.15fr_0.85fr] gap-8 items-center">
            <div>
              <div
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '0.5rem',
                  marginBottom: '1rem',
                  padding: '0.45rem 0.85rem',
                  borderRadius: '999px',
                  background: 'rgba(255,255,255,0.1)',
                  border: '1px solid rgba(255,255,255,0.18)',
                  fontSize: '0.82rem',
                  fontWeight: 700,
                  letterSpacing: '0.03em',
                  textTransform: 'uppercase',
                }}
              >
                <i className="fas fa-bolt" style={{ color: '#fbbf24' }}></i>
                Fresh offers from stores across Sri Lanka
              </div>

              <h1
                style={{
                  fontSize: 'clamp(2.4rem, 6vw, 4.6rem)',
                  lineHeight: 1.02,
                  margin: 0,
                  fontWeight: 900,
                  maxWidth: '11ch',
                }}
              >
                Find the right deal before it disappears.
              </h1>

              <p
                style={{
                  marginTop: '1.2rem',
                  marginBottom: '1.8rem',
                  maxWidth: '44rem',
                  fontSize: '1.05rem',
                  lineHeight: 1.7,
                  color: 'rgba(248,250,252,0.86)',
                }}
              >
                DealFinder brings featured offers, nearby promotions, and newest price drops into one cleaner feed so
                your shopping decisions are faster and less noisy.
              </p>

              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: 'minmax(0,1fr)',
                  gap: '0.9rem',
                  maxWidth: '42rem',
                }}
              >
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.75rem',
                    padding: '0.65rem',
                    borderRadius: '1rem',
                    background: 'rgba(255,255,255,0.1)',
                    border: '1px solid rgba(255,255,255,0.16)',
                    backdropFilter: 'blur(10px)',
                  }}
                >
                  <i className="fas fa-search" style={{ color: '#fbbf24', paddingLeft: '0.45rem' }}></i>
                  <input
                    type="text"
                    value={searchTerm}
                    onChange={(event) => setSearchTerm(event.target.value)}
                    placeholder="Search stores, categories, or deals"
                    style={{
                      flex: 1,
                      minWidth: 0,
                      border: 'none',
                      outline: 'none',
                      background: 'transparent',
                      color: '#fff',
                      fontSize: '1rem',
                    }}
                  />
                  {searchTerm ? (
                    <button
                      onClick={() => setSearchTerm('')}
                      style={{
                        border: 'none',
                        background: 'rgba(255,255,255,0.12)',
                        color: '#fff',
                        width: '2rem',
                        height: '2rem',
                        borderRadius: '999px',
                        cursor: 'pointer',
                      }}
                    >
                      <i className="fas fa-times"></i>
                    </button>
                  ) : null}
                </div>

                <div className="flex flex-wrap gap-3">
                  <button
                    onClick={() => router.push('/categories/all')}
                    className="btn"
                    style={{
                      background: '#f8fafc',
                      color: '#0f172a',
                      padding: '0.85rem 1.25rem',
                      fontWeight: 700,
                    }}
                  >
                    <i className="fas fa-fire"></i>
                    Explore All Deals
                  </button>
                  <button
                    onClick={() => router.push('/nearby')}
                    className="btn"
                    style={{
                      background: 'rgba(255,255,255,0.08)',
                      color: '#fff',
                      border: '1px solid rgba(255,255,255,0.18)',
                      padding: '0.85rem 1.25rem',
                    }}
                  >
                    <i className="fas fa-location-dot"></i>
                    Browse Nearby
                  </button>
                </div>
              </div>
            </div>

            <div
              style={{
                borderRadius: '1.5rem',
                padding: '1.25rem',
                background: 'rgba(15,23,42,0.42)',
                border: '1px solid rgba(255,255,255,0.12)',
                backdropFilter: 'blur(12px)',
              }}
            >
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
                      borderRadius: '1rem',
                      padding: '0.95rem',
                      background: 'rgba(255,255,255,0.08)',
                      border: '1px solid rgba(255,255,255,0.12)',
                    }}
                  >
                    <div style={{ fontSize: '1.35rem', fontWeight: 800 }}>{stat.value}</div>
                    <div style={{ fontSize: '0.82rem', color: 'rgba(255,255,255,0.72)' }}>{stat.label}</div>
                  </div>
                ))}
              </div>

              <div
                style={{
                  borderRadius: '1.25rem',
                  background: 'rgba(255,255,255,0.96)',
                  color: '#0f172a',
                  padding: '1.25rem',
                }}
              >
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    marginBottom: '1rem',
                  }}
                >
                  <div>
                    <div style={{ fontSize: '0.82rem', fontWeight: 700, color: '#0f766e', textTransform: 'uppercase' }}>
                      Right now
                    </div>
                    <div style={{ fontSize: '1.15rem', fontWeight: 800 }}>Shopping snapshot</div>
                  </div>
                  <div
                    style={{
                      width: '2.4rem',
                      height: '2.4rem',
                      borderRadius: '999px',
                      background: 'rgba(15,118,110,0.12)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      color: '#0f766e',
                    }}
                  >
                    <i className="fas fa-chart-line"></i>
                  </div>
                </div>

                <div className="grid grid-cols-1 gap-3">
                  {VALUE_POINTS.map((point) => (
                    <div
                      key={point.title}
                      style={{
                        display: 'grid',
                        gridTemplateColumns: '2.6rem 1fr',
                        gap: '0.85rem',
                        alignItems: 'start',
                        padding: '0.85rem',
                        borderRadius: '1rem',
                        background: '#f8fafc',
                        border: '1px solid #e2e8f0',
                      }}
                    >
                      <div
                        style={{
                          width: '2.6rem',
                          height: '2.6rem',
                          borderRadius: '0.85rem',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          color: '#0f766e',
                          background: 'rgba(15,118,110,0.1)',
                        }}
                      >
                        <i className={`fas ${point.icon}`}></i>
                      </div>
                      <div>
                        <div style={{ fontWeight: 800, marginBottom: '0.2rem' }}>{point.title}</div>
                        <div style={{ fontSize: '0.9rem', color: '#475569', lineHeight: 1.6 }}>{point.text}</div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="max-w-7xl mx-auto px-4" style={{ marginTop: '-1.5rem', position: 'relative', zIndex: 2 }}>
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(210px, 1fr))',
            gap: '1rem',
          }}
        >
          {CATEGORIES.map((category) => (
            <button
              key={category.id}
              onClick={() => router.push(`/categories/${category.id}`)}
              style={{
                textAlign: 'left',
                border: '1px solid var(--border-color)',
                background: 'var(--card-bg)',
                borderRadius: '1.2rem',
                padding: '1rem 1.1rem',
                boxShadow: 'var(--box-shadow)',
                cursor: 'pointer',
              }}
            >
              <div
                style={{
                  width: '2.8rem',
                  height: '2.8rem',
                  borderRadius: '0.95rem',
                  background: 'rgba(15,118,110,0.1)',
                  color: '#0f766e',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  marginBottom: '0.85rem',
                }}
              >
                <i className={`fas ${category.icon}`}></i>
              </div>
              <div style={{ fontWeight: 800, marginBottom: '0.2rem', color: 'var(--text-primary)' }}>{category.name}</div>
              <div style={{ color: 'var(--text-secondary)', fontSize: '0.9rem', lineHeight: 1.5 }}>{category.note}</div>
            </button>
          ))}
        </div>
      </section>

      <section className="max-w-7xl mx-auto px-4 py-10">
        {isSearching ? (
          <div>
            <div className="section-title">
              <i className="fas fa-magnifying-glass" style={{ color: 'var(--primary-color)' }}></i>
              Search Results
              <span style={{ fontSize: '0.9rem', color: 'var(--text-secondary)', fontWeight: 500 }}>
                {searchResults.length} matches
              </span>
            </div>
            {searchResults.length > 0 ? (
              <DealGrid deals={searchResults} />
            ) : (
              <div
                style={{
                  borderRadius: '1.25rem',
                  border: '1px solid var(--border-color)',
                  background: 'var(--card-bg)',
                  padding: '3rem 1.5rem',
                  textAlign: 'center',
                }}
              >
                <div style={{ fontSize: '2.7rem', color: 'var(--primary-color)', marginBottom: '0.85rem' }}>
                  <i className="fas fa-search"></i>
                </div>
                <h2 style={{ margin: 0, marginBottom: '0.5rem', fontSize: '1.4rem' }}>No deals found for "{searchTerm}"</h2>
                <p style={{ margin: 0, color: 'var(--text-secondary)', marginBottom: '1.2rem' }}>
                  Try a merchant name, a product type, or one of the quick categories above.
                </p>
                <button onClick={() => setSearchTerm('')} className="btn btn-primary">
                  Clear Search
                </button>
              </div>
            )}
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-12">
            <section>
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'end',
                  gap: '1rem',
                  marginBottom: '1.5rem',
                  flexWrap: 'wrap',
                }}
              >
                <div>
                  <div style={{ color: '#0f766e', fontSize: '0.82rem', fontWeight: 700, textTransform: 'uppercase' }}>
                    Featured now
                  </div>
                  <h2 className="section-title" style={{ marginBottom: 0 }}>
                    <i className="fas fa-star" style={{ color: '#f59e0b' }}></i>
                    Best Offers This Week
                  </h2>
                </div>
                <button
                  onClick={() => router.push('/categories/all')}
                  className="btn"
                  style={{
                    background: 'var(--card-bg)',
                    color: 'var(--text-primary)',
                    border: '1px solid var(--border-color)',
                  }}
                >
                  View All Deals
                </button>
              </div>
              {loadingDeals ? <SkeletonGrid count={4} /> : <DealGrid deals={featured} />}
            </section>

            <section
              style={{
                background: 'linear-gradient(135deg, rgba(15,118,110,0.08), rgba(245,158,11,0.08))',
                border: '1px solid var(--border-color)',
                borderRadius: '1.5rem',
                padding: '1.5rem',
              }}
            >
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'end',
                  gap: '1rem',
                  marginBottom: '1.5rem',
                  flexWrap: 'wrap',
                }}
              >
                <div>
                  <div style={{ color: '#0f766e', fontSize: '0.82rem', fontWeight: 700, textTransform: 'uppercase' }}>
                    Around you
                  </div>
                  <h2 className="section-title" style={{ marginBottom: 0 }}>
                    <i className="fas fa-location-dot" style={{ color: '#0f766e' }}></i>
                    Nearby Picks
                  </h2>
                </div>
                {userLocation ? (
                  <span style={{ color: 'var(--text-secondary)', fontSize: '0.92rem' }}>Showing deals within 10km</span>
                ) : null}
              </div>

              {loadingNearby ? (
                <SkeletonGrid count={4} />
              ) : locationError ? (
                <div
                  style={{
                    borderRadius: '1rem',
                    background: 'rgba(239,68,68,0.08)',
                    color: '#b91c1c',
                    border: '1px solid rgba(239,68,68,0.18)',
                    padding: '1rem 1.1rem',
                  }}
                >
                  <i className="fas fa-circle-exclamation" style={{ marginRight: '0.5rem' }}></i>
                  {locationError}
                </div>
              ) : nearby.length > 0 ? (
                <DealGrid deals={nearby} />
              ) : (
                <div
                  style={{
                    borderRadius: '1.1rem',
                    background: 'var(--card-bg)',
                    border: '1px solid var(--border-color)',
                    padding: '2rem 1.25rem',
                    textAlign: 'center',
                  }}
                >
                  <h3 style={{ marginTop: 0, marginBottom: '0.45rem', fontSize: '1.2rem' }}>No nearby deals yet</h3>
                  <p style={{ color: 'var(--text-secondary)', marginBottom: 0 }}>
                    We can still show featured and latest offers while location-based results catch up.
                  </p>
                </div>
              )}
            </section>

            <section>
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'end',
                  gap: '1rem',
                  marginBottom: '1.5rem',
                  flexWrap: 'wrap',
                }}
              >
                <div>
                  <div style={{ color: '#0f766e', fontSize: '0.82rem', fontWeight: 700, textTransform: 'uppercase' }}>
                    Just added
                  </div>
                  <h2 className="section-title" style={{ marginBottom: 0 }}>
                    <i className="fas fa-clock" style={{ color: 'var(--primary-color)' }}></i>
                    Latest Deals
                  </h2>
                </div>
                <div style={{ color: 'var(--text-secondary)', fontSize: '0.92rem' }}>
                  Recent offers from supermarkets, restaurants, and local merchants
                </div>
              </div>

              {loadingDeals ? (
                <SkeletonGrid count={8} />
              ) : (
                <>
                  <DealGrid deals={latest.slice(0, latestCount)} />
                  <div className="flex justify-center mt-8">
                    {latestCount < latest.length ? (
                      <button
                        onClick={() => setLatestCount((current) => current + 8)}
                        className="btn"
                        style={{
                          background: 'var(--card-bg)',
                          color: 'var(--text-primary)',
                          border: '1px solid var(--border-color)',
                          padding: '0.85rem 1.4rem',
                        }}
                      >
                        Show More
                      </button>
                    ) : hasMoreLatest ? (
                      <button
                        onClick={loadMoreLatest}
                        disabled={loadingMore}
                        className="btn btn-primary"
                        style={{ padding: '0.85rem 1.4rem' }}
                      >
                        {loadingMore ? 'Loading...' : 'Load More Deals'}
                      </button>
                    ) : null}
                  </div>
                </>
              )}
            </section>

            <section
              style={{
                borderRadius: '1.6rem',
                overflow: 'hidden',
                background:
                  'linear-gradient(135deg, rgba(15,23,42,1) 0%, rgba(17,94,89,1) 56%, rgba(245,158,11,0.95) 100%)',
              }}
            >
              <div className="grid grid-cols-1 lg:grid-cols-[1.1fr_0.9fr] gap-0 items-stretch">
                <div style={{ padding: '2.2rem', color: '#f8fafc' }}>
                  <div style={{ fontSize: '0.82rem', fontWeight: 700, textTransform: 'uppercase', color: '#fde68a' }}>
                    Keep saving
                  </div>
                  <h2 style={{ marginTop: '0.5rem', marginBottom: '0.85rem', fontSize: 'clamp(1.8rem, 4vw, 2.5rem)' }}>
                    {mounted && user ? 'Your next best deal is already waiting.' : 'Create an account and keep your best offers in reach.'}
                  </h2>
                  <p style={{ margin: 0, lineHeight: 1.7, color: 'rgba(248,250,252,0.86)', maxWidth: '34rem' }}>
                    {mounted && user
                      ? 'Use favorites and notifications to keep the offers you care about from slipping away.'
                      : 'Save favorites, revisit merchants faster, and build a smarter deal-hunting routine without bouncing between apps.'}
                  </p>
                  <div className="flex flex-wrap gap-3" style={{ marginTop: '1.5rem' }}>
                    <button
                      onClick={() => router.push(mounted && user ? '/profile' : '/register')}
                      className="btn"
                      style={{
                        background: '#f8fafc',
                        color: '#0f172a',
                        padding: '0.9rem 1.3rem',
                        fontWeight: 700,
                      }}
                    >
                      {mounted && user ? 'Open Profile' : 'Create Free Account'}
                    </button>
                    <button
                      onClick={() => router.push('/merchants')}
                      className="btn"
                      style={{
                        background: 'rgba(255,255,255,0.08)',
                        color: '#fff',
                        border: '1px solid rgba(255,255,255,0.16)',
                        padding: '0.9rem 1.3rem',
                      }}
                    >
                      Browse Stores
                    </button>
                  </div>
                </div>
                <div
                  style={{
                    background:
                      'linear-gradient(180deg, rgba(255,255,255,0.08), rgba(255,255,255,0.02))',
                    padding: '2rem',
                    display: 'grid',
                    alignItems: 'center',
                  }}
                >
                  <div
                    style={{
                      borderRadius: '1.25rem',
                      background: 'rgba(255,255,255,0.12)',
                      border: '1px solid rgba(255,255,255,0.16)',
                      padding: '1.25rem',
                      color: '#fff',
                    }}
                  >
                    <div style={{ fontWeight: 800, marginBottom: '1rem', fontSize: '1.05rem' }}>Why people keep coming back</div>
                    <div className="grid grid-cols-1 gap-3">
                      {[
                        'Clearer homepage flow with faster deal browsing',
                        'Featured, nearby, and latest offers on one screen',
                        'A stronger starting point for your live site refresh',
                      ].map((item) => (
                        <div
                          key={item}
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.7rem',
                            borderRadius: '0.9rem',
                            padding: '0.8rem 0.9rem',
                            background: 'rgba(15,23,42,0.22)',
                          }}
                        >
                          <i className="fas fa-check-circle" style={{ color: '#fde68a' }}></i>
                          <span style={{ lineHeight: 1.5 }}>{item}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            </section>
          </div>
        )}
      </section>
    </div>
  );
}
