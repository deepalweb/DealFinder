'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { PromotionAPI } from '@/lib/api';
import PromotionCard from '@/components/ui/PromotionCard';
import SkeletonCard from '@/components/ui/SkeletonCard';
import toast from 'react-hot-toast';

export default function NearbyPage() {
  const router = useRouter();
  const [promotions, setPromotions] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [userLocation, setUserLocation] = useState<{ lat: number; lon: number } | null>(null);
  const [radius, setRadius] = useState(10);

  const fetchDeals = async (lat: number, lon: number, r: number) => {
    setLoading(true);
    try {
      const data = await PromotionAPI.getNearby(lat, lon, r);
      setPromotions(data);
      if (data.length > 0) toast.success(`Found ${data.length} deals within ${r}km!`);
    } catch { setError('Failed to load nearby deals.'); }
    finally { setLoading(false); }
  };

  const getLocation = () => {
    setError(''); setLoading(true);
    if (!navigator.geolocation) { setError('Geolocation not supported.'); setLoading(false); return; }
    navigator.geolocation.getCurrentPosition(
      ({ coords }) => { const loc = { lat: coords.latitude, lon: coords.longitude }; setUserLocation(loc); fetchDeals(loc.lat, loc.lon, radius); },
      (err) => { const msgs: Record<number, string> = { 1: 'Location permission denied.', 2: 'Location unavailable.', 3: 'Request timed out.' }; setError(msgs[err.code] || 'Could not get location.'); setLoading(false); },
      { enableHighAccuracy: true, timeout: 10000 }
    );
  };

  const handleRadiusChange = (r: number) => { setRadius(r); if (userLocation) fetchDeals(userLocation.lat, userLocation.lon, r); };

  useEffect(() => { getLocation(); }, []);

  return (
    <div>
      <div style={{ background: 'linear-gradient(135deg, #10b981 0%, #059669 50%, #0d9488 100%)', padding: '4rem 0 3rem' }}>
        <div className="max-w-7xl mx-auto px-4 text-center text-white">
          <div style={{ width: '56px', height: '56px', background: 'rgba(255,255,255,0.2)', borderRadius: '1rem', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '1.5rem', margin: '0 auto 0.75rem' }}>
            <i className="fas fa-map-marker-alt"></i>
          </div>
          <h1 style={{ fontSize: 'clamp(2rem,5vw,3.5rem)', fontWeight: 800, letterSpacing: '-0.03em', lineHeight: 1.1, marginBottom: '0.75rem' }}>Nearby Deals</h1>
          <p style={{ opacity: 0.9, marginBottom: '1.5rem' }}>Discover amazing promotions close to you</p>
          <div className="flex justify-center gap-2 flex-wrap mb-5">
            {[5, 10, 20, 50, 100].map(r => (
              <button key={r} onClick={() => handleRadiusChange(r)}
                style={{ padding: '0.4rem 1rem', borderRadius: '9999px', fontSize: '0.85rem', fontWeight: 600, border: '2px solid rgba(255,255,255,0.5)', cursor: 'pointer', transition: 'all 0.2s', background: radius === r ? '#fff' : 'rgba(255,255,255,0.15)', color: radius === r ? '#059669' : '#fff' }}>
                {r} km
              </button>
            ))}
          </div>
          <button onClick={getLocation} disabled={loading} className="btn"
            style={{ background: '#fff', color: '#059669', fontWeight: 700, padding: '0.75rem 2rem', fontSize: '0.95rem', boxShadow: '0 4px 16px rgba(0,0,0,0.15)' }}>
            {loading ? <><i className="fas fa-spinner fa-spin"></i> Searching...</> : <><i className="fas fa-location-arrow"></i> Find Deals Near Me</>}
          </button>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 py-8">
        {error && (
          <div style={{ background: 'rgba(239,68,68,0.08)', border: '1px solid rgba(239,68,68,0.2)', borderRadius: '0.875rem', padding: '1rem', display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1.5rem' }}>
            <i className="fas fa-exclamation-triangle" style={{ color: '#ef4444' }}></i>
            <p style={{ color: '#ef4444', margin: 0, fontSize: '0.875rem' }}>{error}</p>
          </div>
        )}

        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {Array.from({ length: 8 }).map((_, i) => <SkeletonCard key={i} />)}
          </div>
        ) : promotions.length > 0 ? (
          <>
            <div className="flex items-center justify-between mb-5">
              <h2 className="section-title" style={{ margin: 0 }}>
                <i className="fas fa-map-marker-alt" style={{ color: 'var(--primary-color)' }}></i>
                {promotions.length} deals within {radius}km
              </h2>
              {userLocation && <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '0.35rem' }}><i className="fas fa-circle" style={{ color: '#10b981', fontSize: '0.5rem' }}></i> Location active</span>}
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              {promotions.map(p => <PromotionCard key={p._id || p.id} promotion={p} />)}
            </div>
          </>
        ) : !loading && !error && userLocation ? (
          <div className="text-center py-16">
            <div style={{ fontSize: '3rem', marginBottom: '1rem' }}>📍</div>
            <h2 style={{ fontWeight: 700, marginBottom: '0.5rem' }}>No deals found nearby</h2>
            <p style={{ color: 'var(--text-secondary)', marginBottom: '1.5rem' }}>Try increasing the search radius</p>
            <div className="flex justify-center gap-2 flex-wrap">
              {[20, 50, 100].map(r => <button key={r} onClick={() => handleRadiusChange(r)} className="btn btn-primary" style={{ fontSize: '0.85rem' }}>Try {r}km</button>)}
            </div>
          </div>
        ) : !loading && !error && (
          <div className="text-center py-16">
            <div style={{ fontSize: '3rem', marginBottom: '1rem' }}>🗺️</div>
            <h2 style={{ fontWeight: 700, marginBottom: '0.5rem' }}>Share your location</h2>
            <p style={{ color: 'var(--text-secondary)' }}>Click &quot;Find Deals Near Me&quot; to discover promotions in your area</p>
          </div>
        )}
      </div>
    </div>
  );
}
