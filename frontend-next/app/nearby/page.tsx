'use client';

import { useState, useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { PromotionAPI } from '@/lib/api';
import PromotionCard from '@/components/ui/PromotionCard';
import SkeletonCard from '@/components/ui/SkeletonCard';
import HeroSection from '@/components/ui/HeroSection';
import toast from 'react-hot-toast';

export default function NearbyPage() {
  const router = useRouter();
  const mapRef = useRef<any>(null);
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const markersRef = useRef<any[]>([]);

  const [promotions, setPromotions] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [userLocation, setUserLocation] = useState<{ lat: number; lon: number } | null>(null);
  const [radius, setRadius] = useState(10);
  const [view, setView] = useState<'list' | 'map'>('list');

  const fetchDeals = async (lat: number, lon: number, r: number) => {
    setLoading(true);
    try {
      const data = await PromotionAPI.getNearby(lat, lon, r);
      setPromotions([...data].sort((a: any, b: any) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()));
      if (data.length > 0) toast.success(`Found ${data.length} deals within ${r}km!`);
    } catch { setError('Failed to load nearby deals.'); }
    finally { setLoading(false); }
  };

  const getLocation = () => {
    setError(''); setLoading(true);
    if (!navigator.geolocation) { setError('Geolocation not supported.'); setLoading(false); return; }
    navigator.geolocation.getCurrentPosition(
      ({ coords }) => {
        const loc = { lat: coords.latitude, lon: coords.longitude };
        setUserLocation(loc);
        fetchDeals(loc.lat, loc.lon, radius);
      },
      (err) => {
        const msgs: Record<number, string> = { 1: 'Location permission denied.', 2: 'Location unavailable.', 3: 'Request timed out.' };
        setError(msgs[err.code] || 'Could not get location.');
        setLoading(false);
      },
      { enableHighAccuracy: true, timeout: 10000 }
    );
  };

  const handleRadiusChange = (r: number) => {
    setRadius(r);
    if (userLocation) fetchDeals(userLocation.lat, userLocation.lon, r);
  };

  // Initialize map when switching to map view
  useEffect(() => {
    if (view !== 'map' || !mapContainerRef.current) return;

    import('leaflet').then(L => {
      delete (L.Icon.Default.prototype as any)._getIconUrl;
      L.Icon.Default.mergeOptions({
        iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
        iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
        shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
      });

      if (mapRef.current) {
        mapRef.current.remove();
        mapRef.current = null;
      }

      const center: [number, number] = userLocation ? [userLocation.lat, userLocation.lon] : [6.9271, 79.8612];
      const map = L.map(mapContainerRef.current!).setView(center, 13);
      mapRef.current = map;

      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors',
      }).addTo(map);

      // User location marker
      if (userLocation) {
        const userIcon = L.divIcon({
          html: '<div style="width:16px;height:16px;background:#6366f1;border:3px solid #fff;border-radius:50%;box-shadow:0 2px 8px rgba(99,102,241,0.5)"></div>',
          className: '',
          iconSize: [16, 16],
          iconAnchor: [8, 8],
        });
        L.marker([userLocation.lat, userLocation.lon], { icon: userIcon })
          .addTo(map)
          .bindPopup('<b>📍 You are here</b>');

        // Radius circle
        L.circle([userLocation.lat, userLocation.lon], {
          radius: radius * 1000,
          color: '#6366f1',
          fillColor: '#6366f1',
          fillOpacity: 0.05,
          weight: 1.5,
          dashArray: '6',
        }).addTo(map);
      }

      // Deal markers
      markersRef.current = [];
      promotions.forEach(p => {
        const coords = p.merchant?.location?.coordinates;
        if (!coords || coords.length < 2) return;
        const [lng, lat] = coords;

        const dealIcon = L.divIcon({
          html: `<div style="background:linear-gradient(135deg,#ef4444,#f97316);color:#fff;padding:4px 8px;border-radius:9999px;font-size:11px;font-weight:700;white-space:nowrap;box-shadow:0 2px 8px rgba(0,0,0,0.2)">${p.discount} OFF</div>`,
          className: '',
          iconAnchor: [20, 10],
        });

        const distKm = p.merchant?.distance ? (p.merchant.distance / 1000).toFixed(1) : null;
        const marker = L.marker([lat, lng], { icon: dealIcon })
          .addTo(map)
          .bindPopup(`
            <div style="min-width:180px">
              ${p.image ? `<img src="${p.image}" style="width:100%;height:80px;object-fit:cover;border-radius:6px;margin-bottom:8px" />` : ''}
              <b style="font-size:13px">${p.title}</b><br/>
              <span style="color:#6366f1;font-weight:700">${p.discount} OFF</span>
              ${distKm ? `<br/><span style="color:#64748b;font-size:12px">📍 ${distKm} km away</span>` : ''}
              <br/><code style="background:#f1f5f9;padding:2px 6px;border-radius:4px;font-size:11px">${p.code}</code>
            </div>
          `);
        markersRef.current.push(marker);
      });

      // Fit bounds to show all markers
      if (promotions.length > 0 && userLocation) {
        const bounds = L.latLngBounds([[userLocation.lat, userLocation.lon]]);
        promotions.forEach(p => {
          const coords = p.merchant?.location?.coordinates;
          if (coords?.length >= 2) bounds.extend([coords[1], coords[0]]);
        });
        map.fitBounds(bounds, { padding: [40, 40] });
      }
    });

    return () => {
      if (mapRef.current) { mapRef.current.remove(); mapRef.current = null; }
    };
  }, [view, promotions, userLocation, radius]);

  useEffect(() => { getLocation(); }, []);

  const distanceLabel = (p: any) => {
    const d = p.merchant?.distance;
    if (!d) return null;
    return d < 1000 ? `${Math.round(d)}m away` : `${(d / 1000).toFixed(1)}km away`;
  };

  return (
    <div>
      <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />

      {/* Hero */}
      <HeroSection
        icon="fa-map-marker-alt"
        title="Nearby Deals"
        subtitle="Discover amazing promotions close to you"
        gradient="linear-gradient(135deg, rgba(16,185,129,0.92) 0%, rgba(5,150,105,0.9) 50%, rgba(13,148,136,0.88) 100%)"
        bgImage="https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=1600&auto=format&fit=crop&q=60"
      >
        <div className="flex justify-center gap-2 flex-wrap mb-4">
          {[5, 10, 20, 50, 100].map(r => (
            <button key={r} onClick={() => handleRadiusChange(r)}
              style={{ padding: '0.4rem 1rem', borderRadius: '9999px', fontSize: '0.85rem', fontWeight: 600, border: '2px solid rgba(255,255,255,0.5)', cursor: 'pointer', transition: 'all 0.2s', background: radius === r ? '#fff' : 'rgba(255,255,255,0.15)', color: radius === r ? '#059669' : '#fff' }}>
              {r} km
            </button>
          ))}
        </div>
        <div className="flex justify-center gap-3 flex-wrap">
          <button onClick={getLocation} disabled={loading} className="btn"
            style={{ background: '#fff', color: '#059669', fontWeight: 700, padding: '0.75rem 1.75rem', fontSize: '0.95rem', boxShadow: '0 4px 16px rgba(0,0,0,0.15)' }}>
            {loading ? <><i className="fas fa-spinner fa-spin"></i> Searching...</> : <><i className="fas fa-location-arrow"></i> Find Deals Near Me</>}
          </button>
          {promotions.length > 0 && (
            <div style={{ display: 'flex', background: 'rgba(255,255,255,0.15)', borderRadius: '9999px', padding: '4px', border: '2px solid rgba(255,255,255,0.3)' }}>
              {(['list', 'map'] as const).map(v => (
                <button key={v} onClick={() => setView(v)}
                  style={{ padding: '0.4rem 1rem', borderRadius: '9999px', fontSize: '0.85rem', fontWeight: 600, border: 'none', cursor: 'pointer', transition: 'all 0.2s', background: view === v ? '#fff' : 'transparent', color: view === v ? '#059669' : '#fff' }}>
                  <i className={`fas ${v === 'list' ? 'fa-list' : 'fa-map'} mr-1`}></i>{v === 'list' ? 'List' : 'Map'}
                </button>
              ))}
            </div>
          )}
        </div>
      </HeroSection>

      <div className="page-shell">
        {error && (
          <div className="surface-panel panel-pad" style={{ background: 'linear-gradient(135deg, rgba(239,68,68,0.08), rgba(249,115,22,0.08))', borderColor: 'rgba(239,68,68,0.2)', display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1.5rem' }}>
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
            <div className="flex items-center justify-between mb-5 flex-wrap gap-3">
              <h2 className="section-title" style={{ margin: 0 }}>
                <i className="fas fa-map-marker-alt" style={{ color: 'var(--primary-color)' }}></i>
                {promotions.length} deals within {radius}km
              </h2>
              {userLocation && <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '0.35rem' }}><i className="fas fa-circle" style={{ color: '#10b981', fontSize: '0.5rem' }}></i> Location active</span>}
            </div>

            {/* Map view */}
            {view === 'map' && (
              <div ref={mapContainerRef} className="surface-panel" style={{ height: '520px', width: '100%', borderRadius: '1.5rem', overflow: 'hidden', marginBottom: '2rem' }} />
            )}

            {/* List view */}
            {view === 'list' && (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                {promotions.map(p => {
                  const coords = p.merchant?.location?.coordinates;
                  const dist = distanceLabel(p);
                  return (
                    <div key={p._id || p.id} style={{ position: 'relative' }}>
                      {dist && (
                        <div style={{ position: 'absolute', top: '0.6rem', right: '0.6rem', zIndex: 20, display: 'flex', flexDirection: 'column', gap: '0.3rem', alignItems: 'flex-end' }}>
                          <div style={{ background: 'rgba(16,185,129,0.9)', color: '#fff', fontSize: '0.7rem', fontWeight: 700, padding: '0.2rem 0.5rem', borderRadius: '9999px', backdropFilter: 'blur(4px)' }}>
                            <i className="fas fa-map-marker-alt mr-1"></i>{dist}
                          </div>
                          {coords && (
                            <a href={`https://www.google.com/maps/dir/?api=1&destination=${coords[1]},${coords[0]}`}
                              target="_blank" rel="noopener noreferrer"
                              onClick={e => e.stopPropagation()}
                              style={{ background: 'rgba(99,102,241,0.9)', color: '#fff', fontSize: '0.7rem', fontWeight: 700, padding: '0.2rem 0.5rem', borderRadius: '9999px', backdropFilter: 'blur(4px)', textDecoration: 'none', display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                              <i className="fas fa-directions"></i> Directions
                            </a>
                          )}
                        </div>
                      )}
                      <PromotionCard promotion={p} />
                    </div>
                  );
                })}
              </div>
            )}
          </>
        ) : !loading && !error && userLocation ? (
          <div className="empty-state">
            <div className="empty-icon"><i className="fas fa-map-pin"></i></div>
            <h2 style={{ fontWeight: 800, marginBottom: '0.5rem', color: 'var(--text-primary)' }}>No deals found nearby</h2>
            <p style={{ color: 'var(--text-secondary)', marginBottom: '1.5rem' }}>Try increasing the search radius</p>
            <div className="flex justify-center gap-2 flex-wrap">
              {[20, 50, 100].map(r => <button key={r} onClick={() => handleRadiusChange(r)} className="btn btn-primary" style={{ fontSize: '0.85rem' }}>Try {r}km</button>)}
            </div>
          </div>
        ) : !loading && !error && (
          <div className="empty-state">
            <div className="empty-icon"><i className="fas fa-map-location-dot"></i></div>
            <h2 style={{ fontWeight: 800, marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Share your location</h2>
            <p style={{ color: 'var(--text-secondary)' }}>Click &quot;Find Deals Near Me&quot; to discover promotions in your area</p>
          </div>
        )}
      </div>
    </div>
  );
}
