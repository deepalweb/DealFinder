const NearbyDealsPage = () => {
  const { useState, useEffect } = React;
  const { useNavigate } = ReactRouterDOM;
  const navigate = useNavigate();

  const [promotions, setPromotions] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [userLocation, setUserLocation] = useState(null);
  const [radius, setRadius] = useState(10);

  useEffect(() => {
    if ('geolocation' in navigator) {
      navigator.permissions.query({ name: 'geolocation' }).then(result => {
        if (result.state === 'granted') getCurrentLocationAndFetch();
      }).catch(() => {});
    }
  }, []);

  const getCurrentLocationAndFetch = () => {
    setLoading(true);
    setError('');
    navigator.geolocation.getCurrentPosition(
      pos => {
        const loc = { latitude: pos.coords.latitude, longitude: pos.coords.longitude };
        setUserLocation(loc);
        fetchDeals(loc, radius);
      },
      err => {
        setLoading(false);
        const msgs = {
          1: 'Location permission denied. Click the 🔒 lock icon in your address bar to allow access.',
          2: 'Location information is unavailable.',
          3: 'Location request timed out.'
        };
        setError(msgs[err.code] || 'Could not get your location.');
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 300000 }
    );
  };

  const fetchDeals = async (loc, r) => {
    setLoading(true);
    try {
      const res = await fetch(`/api/promotions/nearby?latitude=${loc.latitude}&longitude=${loc.longitude}&radius=${r}`);
      if (!res.ok) throw new Error();
      setPromotions(await res.json());
    } catch {
      setError('Failed to load nearby deals. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleRadiusChange = (r) => {
    setRadius(r);
    if (userLocation) fetchDeals(userLocation, r);
  };

  const SkeletonCard = () => (
    <div className="skeleton-card">
      <div className="skeleton" style={{height:'180px'}}></div>
      <div className="p-4">
        <div className="skeleton mb-2" style={{height:'12px',width:'40%'}}></div>
        <div className="skeleton mb-2" style={{height:'16px',width:'80%'}}></div>
        <div className="skeleton" style={{height:'36px'}}></div>
      </div>
    </div>
  );

  return (
    <div className="page-container">
      {/* Hero */}
      <div style={{background:'linear-gradient(135deg, #10b981 0%, #059669 50%, #0d9488 100%)'}} className="py-16 mb-8">
        <div className="container text-center text-white">
          <div className="inline-flex items-center justify-center mb-3" style={{width:'56px',height:'56px',background:'rgba(255,255,255,0.2)',borderRadius:'1rem',fontSize:'1.5rem'}}>
            <i className="fas fa-map-marker-alt"></i>
          </div>
          <h1 className="text-4xl md:text-5xl font-extrabold mb-3" style={{letterSpacing:'-0.03em',lineHeight:1.1}}>Nearby Deals</h1>
          <p style={{opacity:0.9,fontSize:'1rem',marginBottom:'1.5rem'}}>Discover amazing promotions close to you</p>

          {/* Radius Pills */}
          <div className="flex justify-center gap-2 flex-wrap mb-5">
            {[5, 10, 20, 50, 100].map(r => (
              <button key={r} onClick={() => handleRadiusChange(r)}
                style={{
                  padding:'0.4rem 1rem', borderRadius:'9999px', fontSize:'0.85rem', fontWeight:600,
                  border:'2px solid rgba(255,255,255,0.5)', cursor:'pointer', transition:'all 0.2s',
                  background: radius === r ? '#fff' : 'rgba(255,255,255,0.15)',
                  color: radius === r ? '#059669' : '#fff'
                }}>
                {r} km
              </button>
            ))}
          </div>

          <button onClick={getCurrentLocationAndFetch} disabled={loading}
            className="btn"
            style={{background:'#fff',color:'#059669',fontWeight:700,padding:'0.75rem 2rem',fontSize:'0.95rem',gap:'0.5rem',boxShadow:'0 4px 16px rgba(0,0,0,0.15)'}}>
            {loading ? <><i className="fas fa-spinner fa-spin"></i> Searching...</> : <><i className="fas fa-location-arrow"></i> Find Deals Near Me</>}
          </button>
        </div>
      </div>

      <div className="container pb-12">
        {/* Error */}
        {error && (
          <div className="flex items-start gap-3 p-4 rounded-xl mb-6" style={{background:'rgba(239,68,68,0.08)',border:'1px solid rgba(239,68,68,0.2)'}}>
            <i className="fas fa-exclamation-triangle mt-0.5" style={{color:'#ef4444',flexShrink:0}}></i>
            <p style={{color:'#ef4444',margin:0,fontSize:'0.875rem'}}>{error}</p>
          </div>
        )}

        {/* Loading skeletons */}
        {loading && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {[...Array(8)].map((_, i) => <SkeletonCard key={i} />)}
          </div>
        )}

        {/* Results */}
        {!loading && promotions.length > 0 && (
          <>
            <div className="flex items-center justify-between mb-5">
              <h2 className="section-title" style={{margin:0}}>
                <i className="fas fa-map-marker-alt"></i> {promotions.length} deals within {radius}km
              </h2>
              {userLocation && (
                <span style={{fontSize:'0.8rem',color:'var(--text-secondary)',display:'flex',alignItems:'center',gap:'0.35rem'}}>
                  <i className="fas fa-circle" style={{color:'#10b981',fontSize:'0.5rem'}}></i> Location active
                </span>
              )}
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              {promotions.map(p => (
                <div key={p._id} className="cursor-pointer fade-in" onClick={() => navigate(`/deal/${p._id || p.id}`)}>
                  <PromotionCard promotion={p} />
                </div>
              ))}
            </div>
          </>
        )}

        {/* No results */}
        {!loading && !error && userLocation && promotions.length === 0 && (
          <div className="text-center py-16">
            <div style={{fontSize:'3rem',marginBottom:'1rem'}}>📍</div>
            <h2 className="text-xl font-bold mb-2">No deals found nearby</h2>
            <p style={{color:'var(--text-secondary)',marginBottom:'1.5rem'}}>Try increasing the search radius</p>
            <div className="flex justify-center gap-2 flex-wrap">
              {[20, 50, 100].map(r => (
                <button key={r} onClick={() => handleRadiusChange(r)} className="btn btn-primary" style={{fontSize:'0.85rem',padding:'0.5rem 1rem'}}>
                  Try {r}km
                </button>
              ))}
            </div>
          </div>
        )}

        {/* No location yet */}
        {!loading && !error && !userLocation && (
          <div className="text-center py-16">
            <div style={{fontSize:'3rem',marginBottom:'1rem'}}>🗺️</div>
            <h2 className="text-xl font-bold mb-2">Share your location</h2>
            <p style={{color:'var(--text-secondary)',marginBottom:'1.5rem',maxWidth:'360px',margin:'0 auto 1.5rem'}}>
              Click "Find Deals Near Me" above to discover promotions in your area
            </p>
          </div>
        )}
      </div>
    </div>
  );
};

window.NearbyDealsPage = NearbyDealsPage;
