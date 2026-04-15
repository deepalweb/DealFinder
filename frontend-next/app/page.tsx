'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { PromotionAPI, UserAPI } from '@/lib/api';
import { useAuth } from '@/contexts/AuthContext';
import PromotionCard from '@/components/ui/PromotionCard';
import SkeletonCard from '@/components/ui/SkeletonCard';
import toast from 'react-hot-toast';

const CATEGORIES = [
  { id: 'all', name: 'All', icon: 'fa-th-large' },
  { id: 'food', name: 'Food & Dining', icon: 'fa-utensils' },
  { id: 'supermarkets', name: 'Supermarkets', icon: 'fa-shopping-cart' },
];

export default function HomePage() {
  const router = useRouter();
  const { user } = useAuth();
  const [featured, setFeatured] = useState<any[]>([]);
  const [latest, setLatest] = useState<any[]>([]);
  const [nearby, setNearby] = useState<any[]>([]);
  const [searchResults, setSearchResults] = useState<any[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [isSearching, setIsSearching] = useState(false);
  const [loadingDeals, setLoadingDeals] = useState(true);
  const [loadingNearby, setLoadingNearby] = useState(false);
  const [locationError, setLocationError] = useState('');
  const [userLocation, setUserLocation] = useState<{ lat: number; lon: number } | null>(null);
  const [allPromotions, setAllPromotions] = useState<any[]>([]);
  const [favoriteIds, setFavoriteIds] = useState<Set<string>>(new Set());
  const [latestCount, setLatestCount] = useState(8);
  const [loadingMore, setLoadingMore] = useState(false);
  const [hasMoreLatest, setHasMoreLatest] = useState(true);
  const [mounted, setMounted] = useState(false);

  const heroStats = useMemo(() => [
    { icon: 'fa-tag', value: `${allPromotions.length}+`, label: 'Active Deals' },
    { icon: 'fa-store', value: `${new Set(allPromotions.map((p: any) => typeof p.merchant === 'object' ? p.merchant?._id : p.merchant)).size}+`, label: 'Merchants' },
    { icon: 'fa-map-marker-alt', value: nearby.length > 0 ? `${nearby.length}` : 'Find', label: nearby.length > 0 ? 'Nearby' : 'Near You' },
  ], [allPromotions, nearby]);

  useEffect(() => { setMounted(true); }, []);

  useEffect(() => {
    // Optimized: Single API call for homepage data + cached favorites
    const fetchData = async () => {
      try {
        const homepagePromise: Promise<{ featured: any[]; latest: any[] }> =
          PromotionAPI.getHomepage().catch(() => {
            console.warn('Homepage endpoint failed, falling back to getAll');
            return PromotionAPI.getAll({ limit: 20 }).then((data: any[]) => ({
              featured: data.filter((p: any) => p.featured).slice(0, 8) as any[],
              latest: data as any[]
            }));
          });

        // Check cache first for favorites (5 minute TTL)
        let favoritesData: any[] = [];
        if (user) {
          const cacheKey = `favorites_${user._id}`;
          const cached = localStorage.getItem(cacheKey);
          const cacheTime = localStorage.getItem(`${cacheKey}_time`);
          const now = Date.now();
          
          if (cached && cacheTime && (now - parseInt(cacheTime)) < 5 * 60 * 1000) {
            // Use cached data
            favoritesData = JSON.parse(cached);
          } else {
            // Fetch fresh data
            favoritesData = await UserAPI.getFavorites(user._id).catch(() => []);
            localStorage.setItem(cacheKey, JSON.stringify(favoritesData));
            localStorage.setItem(`${cacheKey}_time`, now.toString());
          }
        }

        const homepageData = await homepagePromise;

        // Set featured and latest from optimized endpoint
        setFeatured(homepageData.featured);
        setLatest(homepageData.latest);
        setAllPromotions(homepageData.latest); // Use latest for search
        setHasMoreLatest(homepageData.latest.length >= 20); // Check if there might be more
        
        if (favoritesData.length > 0) {
          setFavoriteIds(new Set(favoritesData.map((f: any) => f._id || f.id)));
        }
      } catch (error) {
        console.error('Failed to load deals:', error);
        toast.error('Failed to load deals.');
      } finally {
        setLoadingDeals(false);
      }
    };

    fetchData();

    // Fetch nearby separately (non-blocking)
    if (navigator.geolocation) {
      setLoadingNearby(true);
      navigator.geolocation.getCurrentPosition(
        ({ coords }) => {
          setUserLocation({ lat: coords.latitude, lon: coords.longitude });
          PromotionAPI.getNearby(coords.latitude, coords.longitude, 10).then(data => {
            setNearby([...data].sort((a: any, b: any) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()));
            if (data.length > 0) toast.success(`Found ${data.length} deals near you!`);
          }).catch(() => setLocationError('Could not fetch nearby deals.')).finally(() => setLoadingNearby(false));
        },
        (err) => {
          const msgs: Record<number, string> = { 1: 'Location permission denied.', 2: 'Location unavailable.', 3: 'Location timed out.' };
          setLocationError(msgs[err.code] || 'Could not get location.');
          setLoadingNearby(false);
        }
      );
    }
  }, [user]);

  const loadMoreLatest = async () => {
    if (loadingMore || !hasMoreLatest) return;
    
    setLoadingMore(true);
    try {
      const moreDeals = await PromotionAPI.getAll({ limit: 20, skip: latest.length });
      if (moreDeals.length > 0) {
        setLatest(prev => [...prev, ...moreDeals]);
        setHasMoreLatest(moreDeals.length >= 20);
      } else {
        setHasMoreLatest(false);
      }
    } catch (error) {
      toast.error('Failed to load more deals');
    } finally {
      setLoadingMore(false);
    }
  };

  // Debounced search
  useEffect(() => {
    const t = setTimeout(() => {
      if (!searchTerm.trim()) { setIsSearching(false); return; }
      setIsSearching(true);
      const term = searchTerm.toLowerCase();
      setSearchResults(allPromotions.filter((p: any) =>
        p.title?.toLowerCase().includes(term) ||
        p.description?.toLowerCase().includes(term) ||
        (typeof p.merchant === 'object' ? p.merchant?.name : p.merchant)?.toLowerCase().includes(term)
      ));
    }, 400);
    return () => clearTimeout(t);
  }, [searchTerm, allPromotions]);

  const DealGrid = ({ deals }: { deals: any[] }) => (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(260px, 1fr))', gap: '1.5rem', alignItems: 'stretch' }}>
      {deals.map(p => (
        <div key={p._id || p.id} style={{ display: 'flex' }}>
          <PromotionCard
            promotion={p}
            isFavorite={favoriteIds.has(p._id || p.id)}
            onFavoriteToggle={(id, fav) => setFavoriteIds(prev => { const s = new Set(prev); fav ? s.add(id) : s.delete(id); return s; })}
          />
        </div>
      ))}
    </div>
  );

  const SkeletonGrid = ({ count }: { count: number }) => (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
      {Array.from({ length: count }).map((_, i) => <SkeletonCard key={i} />)}
    </div>
  );

  return (
    <div>
      {/* Hero */}
      <div style={{
        position: 'relative',
        padding: '5rem 0 4rem',
        overflow: 'hidden',
        background: 'linear-gradient(135deg, #1e1b4b 0%, #312e81 40%, #4c1d95 70%, #7c3aed 100%)',
      }}>
        {/* Background image with overlay */}
        <div style={{
          position: 'absolute', inset: 0,
          backgroundImage: 'url(https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=1600&auto=format&fit=crop&q=60)',
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          opacity: 0.12,
        }} />
        {/* Gradient overlay */}
        <div style={{
          position: 'absolute', inset: 0,
          background: 'linear-gradient(135deg, rgba(99,102,241,0.92) 0%, rgba(139,92,246,0.88) 50%, rgba(244,63,94,0.85) 100%)',
        }} />
        {/* Decorative blobs */}
        <div style={{ position: 'absolute', top: '-80px', right: '-80px', width: '320px', height: '320px', borderRadius: '50%', background: 'rgba(255,255,255,0.05)', pointerEvents: 'none' }} />
        <div style={{ position: 'absolute', bottom: '-60px', left: '-60px', width: '240px', height: '240px', borderRadius: '50%', background: 'rgba(255,255,255,0.04)', pointerEvents: 'none' }} />

        <div className="max-w-7xl mx-auto px-4 text-center text-white" style={{ position: 'relative', zIndex: 1 }}>
          {/* Badge */}
          <div className="inline-flex items-center gap-2 mb-5" style={{ background: 'rgba(255,255,255,0.15)', borderRadius: '9999px', padding: '0.4rem 1.1rem', fontSize: '0.85rem', fontWeight: 600, backdropFilter: 'blur(8px)', border: '1px solid rgba(255,255,255,0.2)' }}>
            <i className="fas fa-bolt" style={{ color: '#fbbf24' }}></i> New deals added daily
          </div>

          {/* Headline */}
          <h1 style={{ fontSize: 'clamp(2.2rem, 6vw, 4rem)', fontWeight: 900, letterSpacing: '-0.04em', lineHeight: 1.05, marginBottom: '1.25rem', textShadow: '0 2px 20px rgba(0,0,0,0.3)' }}>
            Sri Lanka's Smartest Way<br />
            <span style={{ background: 'linear-gradient(135deg, #fbbf24, #f97316)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>to Find Deals</span>
          </h1>

          <p style={{ fontSize: '1.1rem', opacity: 0.9, maxWidth: '580px', margin: '0 auto 2rem', lineHeight: 1.6 }}>
            Discover exclusive discounts from top stores near you. Smart search, real-time updates, personalized recommendations.
          </p>

          {/* Search */}
          <div style={{ position: 'relative', maxWidth: '580px', margin: '0 auto 2.5rem' }}>
            <i className="fas fa-search" style={{ position: 'absolute', left: '1.25rem', top: '50%', transform: 'translateY(-50%)', color: 'rgba(255,255,255,0.6)', pointerEvents: 'none', fontSize: '1rem' }}></i>
            <input type="text" placeholder="Search deals, stores, categories..." value={searchTerm} onChange={e => setSearchTerm(e.target.value)}
              style={{ width: '100%', padding: '1rem 3.5rem', border: '2px solid rgba(255,255,255,0.25)', borderRadius: '9999px', fontSize: '1rem', background: 'rgba(255,255,255,0.12)', color: '#fff', backdropFilter: 'blur(12px)', outline: 'none', boxSizing: 'border-box', boxShadow: '0 8px 32px rgba(0,0,0,0.2)' }} />
            {searchTerm && (
              <button onClick={() => setSearchTerm('')} style={{ position: 'absolute', right: '1.25rem', top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', color: 'rgba(255,255,255,0.7)', cursor: 'pointer', fontSize: '1rem' }}>
                <i className="fas fa-times"></i>
              </button>
            )}
          </div>

          {/* Stats */}
          <div className="flex justify-center gap-6 flex-wrap">
            {heroStats.map(s => (
              <div key={s.label} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', background: 'rgba(255,255,255,0.1)', borderRadius: '9999px', padding: '0.4rem 1rem', backdropFilter: 'blur(8px)', border: '1px solid rgba(255,255,255,0.15)' }}>
                <i className={`fas ${s.icon}`} style={{ color: '#fbbf24', fontSize: '0.85rem' }}></i>
                <span style={{ fontWeight: 700, fontSize: '0.9rem' }}>{s.value}</span>
                <span style={{ opacity: 0.75, fontSize: '0.8rem' }}>{s.label}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 py-8">
        {/* Why Choose DealFinder */}
        {!isSearching && (
          <div className="mb-12">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {[
                { icon: 'fa-search-location', title: 'Smart Location Search', desc: 'Find deals near you with intelligent geolocation', color: '#6366f1' },
                { icon: 'fa-bolt', title: 'Real-Time Updates', desc: 'Get notified instantly when new deals are added', color: '#f59e0b' },
                { icon: 'fa-heart', title: 'Personalized Favorites', desc: 'Save and track your favorite deals in one place', color: '#ec4899' },
              ].map(feature => (
                <div key={feature.title} style={{ background: 'var(--card-bg)', border: '1.5px solid var(--border-color)', borderRadius: '1rem', padding: '1.75rem', textAlign: 'center', transition: 'all 0.3s ease' }}
                  onMouseEnter={(e) => { e.currentTarget.style.transform = 'translateY(-4px)'; e.currentTarget.style.boxShadow = '0 12px 24px rgba(0,0,0,0.1)'; }}
                  onMouseLeave={(e) => { e.currentTarget.style.transform = 'translateY(0)'; e.currentTarget.style.boxShadow = 'none'; }}>
                  <div style={{ width: '56px', height: '56px', borderRadius: '50%', background: `${feature.color}15`, display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 1rem' }}>
                    <i className={`fas ${feature.icon}`} style={{ fontSize: '1.5rem', color: feature.color }}></i>
                  </div>
                  <h3 style={{ fontSize: '1.1rem', fontWeight: 700, marginBottom: '0.5rem', color: 'var(--text-primary)' }}>{feature.title}</h3>
                  <p style={{ fontSize: '0.9rem', color: 'var(--text-secondary)', lineHeight: 1.6, margin: 0 }}>{feature.desc}</p>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Categories */}
        <div className="flex gap-2 overflow-x-auto pb-2 mb-8" style={{ scrollbarWidth: 'none' }}>
          {CATEGORIES.map(cat => (
            <button key={cat.id} onClick={() => router.push(`/categories/${cat.id}`)}
              className="category-item" style={{ flexShrink: 0 }}>
              <i className={`fas ${cat.icon}`}></i> {cat.name}
            </button>
          ))}
        </div>

        {isSearching ? (
          <div className="mb-8">
            <h2 className="section-title">
              <i className="fas fa-search" style={{ color: 'var(--primary-color)' }}></i>
              Search Results
              <span style={{ fontSize: '0.875rem', fontWeight: 400, color: 'var(--text-secondary)' }}>({searchResults.length} found)</span>
            </h2>
            {searchResults.length > 0 ? <DealGrid deals={searchResults} /> : (
              <div className="text-center py-16" style={{ background: 'var(--card-bg)', borderRadius: '1.25rem', border: '1.5px solid var(--border-color)' }}>
                <div style={{ fontSize: '3.5rem', marginBottom: '1rem' }}>🔍</div>
                <h3 style={{ fontWeight: 700, fontSize: '1.3rem', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>No deals found for "{searchTerm}"</h3>
                <p style={{ color: 'var(--text-secondary)', marginBottom: '1.5rem' }}>Try different keywords or browse our categories below</p>
                <button onClick={() => setSearchTerm('')} className="btn btn-primary" style={{ padding: '0.75rem 1.5rem' }}>
                  <i className="fas fa-times-circle mr-2"></i>Clear Search
                </button>
              </div>
            )}
          </div>
        ) : (
          <>
            {/* Featured */}
            <div className="mb-12" id="featured-section">
              <h2 className="section-title"><i className="fas fa-star" style={{ color: 'var(--primary-color)' }}></i> Featured Deals</h2>
              {loadingDeals ? <SkeletonGrid count={4} /> : <DealGrid deals={featured} />}
            </div>

            {/* Nearby */}
            {(userLocation || locationError || loadingNearby) && (
              <div className="mb-12">
                <h2 className="section-title">
                  <i className="fas fa-map-marker-alt" style={{ color: 'var(--primary-color)' }}></i> Nearby Deals
                  {userLocation && <span style={{ fontSize: '0.875rem', fontWeight: 400, color: 'var(--text-secondary)' }}>within 10km</span>}
                </h2>
                {loadingNearby ? <SkeletonGrid count={4} /> : locationError ? (
                  <div style={{ background: 'rgba(239,68,68,0.08)', border: '1px solid rgba(239,68,68,0.2)', borderRadius: '0.875rem', padding: '1rem', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    <i className="fas fa-exclamation-triangle" style={{ color: '#ef4444' }}></i>
                    <p style={{ color: '#ef4444', margin: 0, fontSize: '0.875rem' }}>{locationError}</p>
                  </div>
                ) : nearby.length === 0 ? (
                  <div className="text-center py-12" style={{ background: 'var(--card-bg)', borderRadius: '1.25rem', border: '1.5px solid var(--border-color)' }}>
                    <div style={{ fontSize: '3rem', marginBottom: '0.75rem' }}>📍</div>
                    <h3 style={{ fontWeight: 700, fontSize: '1.2rem', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>No deals found nearby</h3>
                    <p style={{ color: 'var(--text-secondary)', marginBottom: '1rem' }}>Check out our featured and latest deals instead</p>
                    <button onClick={() => document.getElementById('featured-section')?.scrollIntoView({ behavior: 'smooth' })} className="btn" style={{ border: '1.5px solid var(--border-color)', background: 'var(--card-bg)', color: 'var(--primary-color)', padding: '0.6rem 1.25rem' }}>
                      <i className="fas fa-star mr-2"></i>View Featured Deals
                    </button>
                  </div>
                ) : <DealGrid deals={nearby} />}
              </div>
            )}

            {/* Latest */}
            <div className="mb-12">
              <h2 className="section-title"><i className="fas fa-clock" style={{ color: 'var(--primary-color)' }}></i> Latest Deals</h2>
              {loadingDeals ? <SkeletonGrid count={8} /> : (
                <>
                  <DealGrid deals={latest.slice(0, latestCount)} />
                  {latestCount < latest.length && (
                    <div className="text-center mt-6">
                      <button onClick={() => setLatestCount(c => c + 8)} className="btn" style={{ border: '1.5px solid var(--border-color)', background: 'var(--card-bg)', color: 'var(--text-primary)', padding: '0.75rem 2rem', fontSize: '0.9rem' }}>
                        <i className="fas fa-chevron-down mr-2"></i>Show More ({latest.length - latestCount} remaining)
                      </button>
                    </div>
                  )}
                  {latestCount >= latest.length && hasMoreLatest && (
                    <div className="text-center mt-6">
                      <button onClick={loadMoreLatest} disabled={loadingMore} className="btn" style={{ border: '1.5px solid var(--border-color)', background: 'var(--card-bg)', color: 'var(--text-primary)', padding: '0.75rem 2rem', fontSize: '0.9rem' }}>
                        {loadingMore ? (
                          <><i className="fas fa-spinner fa-spin mr-2"></i>Loading...</>
                        ) : (
                          <><i className="fas fa-chevron-down mr-2"></i>Load More Deals</>
                        )}
                      </button>
                    </div>
                  )}
                </>
              )}
            </div>
          </>
        )}

        {/* CTA Banner */}
        {!isSearching && (
          <div style={{ background: 'linear-gradient(135deg, #6366f1 0%, #8b5cf6 50%, #ec4899 100%)', borderRadius: '1.5rem', padding: '3rem 2rem', textAlign: 'center', position: 'relative', overflow: 'hidden', marginTop: '3rem' }}>
            <div style={{ position: 'absolute', top: '-50px', right: '-50px', width: '200px', height: '200px', borderRadius: '50%', background: 'rgba(255,255,255,0.1)' }} />
            <div style={{ position: 'absolute', bottom: '-30px', left: '-30px', width: '150px', height: '150px', borderRadius: '50%', background: 'rgba(255,255,255,0.08)' }} />
            <div style={{ position: 'relative', zIndex: 1 }}>
              <h2 style={{ fontSize: 'clamp(1.5rem, 4vw, 2.2rem)', fontWeight: 800, color: '#fff', marginBottom: '1rem', textShadow: '0 2px 10px rgba(0,0,0,0.2)' }}>
                {mounted && user ? 'Never Miss a Deal!' : 'Join DealFinder Today'}
              </h2>
              <p style={{ fontSize: '1.05rem', color: 'rgba(255,255,255,0.9)', marginBottom: '1.75rem', maxWidth: '600px', margin: '0 auto 1.75rem' }}>
                {mounted && user ? 'Enable notifications to get instant alerts when new deals match your interests' : 'Create a free account to save favorites, get personalized recommendations, and never miss exclusive deals'}
              </p>
              <button onClick={() => router.push(mounted && user ? '/profile' : '/register')} className="btn" style={{ background: '#fff', color: '#6366f1', padding: '0.875rem 2rem', fontSize: '1rem', fontWeight: 700, border: 'none', boxShadow: '0 4px 14px rgba(0,0,0,0.15)' }}>
                <i className={`fas ${mounted && user ? 'fa-bell' : 'fa-user-plus'} mr-2`}></i>
                {mounted && user ? 'Manage Notifications' : 'Sign Up Free'}
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
