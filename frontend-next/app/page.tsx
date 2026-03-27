'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { PromotionAPI } from '@/lib/api';
import PromotionCard from '@/components/ui/PromotionCard';
import SkeletonCard from '@/components/ui/SkeletonCard';
import toast from 'react-hot-toast';

const CATEGORIES = [
  { id: 'all', name: 'All', icon: 'fa-th-large' },
  { id: 'fashion', name: 'Fashion', icon: 'fa-tshirt' },
  { id: 'electronics', name: 'Electronics', icon: 'fa-laptop' },
  { id: 'food', name: 'Food', icon: 'fa-utensils' },
  { id: 'travel', name: 'Travel', icon: 'fa-plane' },
  { id: 'health', name: 'Health', icon: 'fa-heart-pulse' },
  { id: 'entertainment', name: 'Entertainment', icon: 'fa-gamepad' },
  { id: 'home', name: 'Home', icon: 'fa-home' },
];

export default function HomePage() {
  const router = useRouter();
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

  useEffect(() => {
    PromotionAPI.getAll().then(data => {
      setAllPromotions(data);
      setFeatured(data.filter((p: any) => p.featured));
      setLatest([...data].sort((a: any, b: any) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()).slice(0, 8));
    }).catch(() => toast.error('Failed to load deals.')).finally(() => setLoadingDeals(false));

    // Fetch nearby
    if (navigator.geolocation) {
      setLoadingNearby(true);
      navigator.geolocation.getCurrentPosition(
        ({ coords }) => {
          setUserLocation({ lat: coords.latitude, lon: coords.longitude });
          PromotionAPI.getNearby(coords.latitude, coords.longitude, 10).then(data => {
            setNearby(data);
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
  }, []);

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
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
      {deals.map(p => <PromotionCard key={p._id || p.id} promotion={p} />)}
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
      <div style={{ background: 'linear-gradient(135deg, #6366f1 0%, #8b5cf6 50%, #f43f5e 100%)', padding: '4rem 0 3rem' }}>
        <div className="max-w-7xl mx-auto px-4 text-center text-white">
          <div className="inline-flex items-center gap-2 mb-4" style={{ background: 'rgba(255,255,255,0.2)', borderRadius: '9999px', padding: '0.375rem 1rem', fontSize: '0.875rem', fontWeight: 500 }}>
            <i className="fas fa-bolt"></i> New deals added daily
          </div>
          <h1 style={{ fontSize: 'clamp(2rem, 5vw, 3.5rem)', fontWeight: 800, letterSpacing: '-0.03em', lineHeight: 1.1, marginBottom: '1rem' }}>
            Discover Amazing<br />Discounts & Deals
          </h1>
          <p style={{ fontSize: '1.1rem', opacity: 0.9, maxWidth: '480px', margin: '0 auto 2rem' }}>
            Find the best offers from your favorite stores, all in one place.
          </p>
          {/* Search */}
          <div style={{ position: 'relative', maxWidth: '560px', margin: '0 auto' }}>
            <i className="fas fa-search" style={{ position: 'absolute', left: '1.1rem', top: '50%', transform: 'translateY(-50%)', color: 'rgba(255,255,255,0.7)', pointerEvents: 'none' }}></i>
            <input type="text" placeholder="Search deals, stores, categories..." value={searchTerm} onChange={e => setSearchTerm(e.target.value)}
              style={{ width: '100%', padding: '0.875rem 3rem', border: '2px solid rgba(255,255,255,0.3)', borderRadius: '9999px', fontSize: '1rem', background: 'rgba(255,255,255,0.15)', color: '#fff', backdropFilter: 'blur(8px)', outline: 'none', boxSizing: 'border-box' }} />
            {searchTerm && (
              <button onClick={() => setSearchTerm('')} style={{ position: 'absolute', right: '1.1rem', top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', color: 'rgba(255,255,255,0.7)', cursor: 'pointer' }}>
                <i className="fas fa-times"></i>
              </button>
            )}
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 py-8">
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
              <div className="text-center py-16">
                <div style={{ fontSize: '3rem', marginBottom: '1rem' }}>🔍</div>
                <h3 style={{ fontWeight: 700, marginBottom: '0.5rem' }}>No results found</h3>
                <p style={{ color: 'var(--text-secondary)' }}>Try different keywords or browse categories</p>
              </div>
            )}
          </div>
        ) : (
          <>
            {/* Featured */}
            <div className="mb-12">
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
                  <div className="text-center py-12">
                    <div style={{ fontSize: '2.5rem', marginBottom: '0.75rem' }}>📍</div>
                    <p style={{ color: 'var(--text-secondary)' }}>No deals found near your location.</p>
                  </div>
                ) : <DealGrid deals={nearby} />}
              </div>
            )}

            {/* Latest */}
            <div className="mb-12">
              <h2 className="section-title"><i className="fas fa-clock" style={{ color: 'var(--primary-color)' }}></i> Latest Deals</h2>
              {loadingDeals ? <SkeletonGrid count={8} /> : <DealGrid deals={latest} />}
            </div>
          </>
        )}
      </div>
    </div>
  );
}
