function HomePage() {
  const { useState, useEffect } = React;
  const { useNavigate } = ReactRouterDOM;
  const navigate = useNavigate();

  const [featuredPromotions, setFeaturedPromotions] = useState([]);
  const [latestPromotions, setLatestPromotions] = useState([]);
  const [searchResults, setSearchResults] = useState([]);
  const [isSearching, setIsSearching] = useState(false);
  const [nearbyDeals, setNearbyDeals] = useState([]);
  const [userLocation, setUserLocation] = useState(null);
  const [locationError, setLocationError] = useState(null);
  const [loadingNearby, setLoadingNearby] = useState(false);
  const [loadingDeals, setLoadingDeals] = useState(true);
  const [toasts, setToasts] = useState([]);

  const showToast = (message, type = 'info') => {
    const id = Date.now();
    setToasts(prev => [...prev, { id, message, type }]);
    setTimeout(() => {
      setToasts(prev => prev.map(t => t.id === id ? { ...t, removing: true } : t));
      setTimeout(() => setToasts(prev => prev.filter(t => t.id !== id)), 300);
    }, 3000);
  };

  useEffect(() => {
    const loadStandardPromotions = async () => {
      try {
        const allPromotions = await window.getPromotionsData();
        window.promotionsData = allPromotions;
        setFeaturedPromotions(allPromotions.filter(p => p.featured));
        setLatestPromotions([...allPromotions].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)).slice(0, 8));
      } catch {
        showToast('Failed to load deals. Please refresh.', 'error');
      } finally {
        setLoadingDeals(false);
      }
    };

    const fetchNearbyDeals = async () => {
      setLoadingNearby(true);
      if (!navigator.geolocation) {
        setLocationError('Geolocation not supported.');
        setLoadingNearby(false);
        return;
      }
      navigator.geolocation.getCurrentPosition(
        async ({ coords: { latitude, longitude } }) => {
          setUserLocation({ latitude, longitude });
          try {
            const deals = await window.API.Promotions.getNearby(latitude, longitude, 10);
            setNearbyDeals(deals);
            if (deals.length > 0) showToast(`Found ${deals.length} deals near you!`, 'success');
          } catch {
            setLocationError('Could not fetch nearby deals.');
          } finally {
            setLoadingNearby(false);
          }
        },
        (err) => {
          const msgs = { 1: 'Location permission denied.', 2: 'Location unavailable.', 3: 'Location request timed out.' };
          setLocationError(msgs[err.code] || 'Could not get location.');
          setLoadingNearby(false);
        }
      );
    };

    loadStandardPromotions();
    fetchNearbyDeals();
  }, []);

  const handleSearch = (searchTerm) => {
    if (!searchTerm.trim()) { setIsSearching(false); return; }
    setIsSearching(true);
    setSearchResults(filterPromotions(promotionsData, { searchTerm }));
  };

  const SkeletonCard = () => (
    <div className="skeleton-card">
      <div className="skeleton" style={{height:'180px'}}></div>
      <div className="p-4">
        <div className="skeleton mb-2" style={{height:'12px',width:'40%'}}></div>
        <div className="skeleton mb-2" style={{height:'16px',width:'80%'}}></div>
        <div className="skeleton mb-3" style={{height:'12px',width:'60%'}}></div>
        <div className="skeleton" style={{height:'36px'}}></div>
      </div>
    </div>
  );

  const DealGrid = ({ deals }) => (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
      {deals.map(p => (
        <div key={p.id || p._id} className="cursor-pointer fade-in" onClick={() => navigate(`/deal/${p.id || p._id}`)}>
          <PromotionCard promotion={p} />
        </div>
      ))}
    </div>
  );

  return (
    <div className="page-container">
      {/* Toast Container */}
      <div className="toast-container">
        {toasts.map(t => (
          <div key={t.id} className={`toast toast-${t.type} ${t.removing ? 'removing' : ''}`}>
            <i className={`fas ${t.type === 'success' ? 'fa-check-circle' : t.type === 'error' ? 'fa-exclamation-circle' : 'fa-info-circle'}`}></i>
            {t.message}
          </div>
        ))}
      </div>

      {/* Hero */}
      <div style={{background:'linear-gradient(135deg, #6366f1 0%, #8b5cf6 50%, #f43f5e 100%)'}} className="py-16 mb-8">
        <div className="container">
          <div className="text-center text-white mb-8">
            <div className="inline-flex items-center gap-2 bg-white bg-opacity-20 rounded-full px-4 py-1.5 text-sm font-medium mb-4">
              <i className="fas fa-bolt"></i> New deals added daily
            </div>
            <h1 className="text-4xl md:text-5xl font-extrabold mb-4" style={{letterSpacing:'-0.03em',lineHeight:1.1}}>
              Discover Amazing<br/>Discounts & Deals
            </h1>
            <p className="text-lg max-w-xl mx-auto mb-8" style={{opacity:0.9}}>
              Find the best offers from your favorite stores, all in one place.
            </p>
            <SearchBar onSearch={handleSearch} />
          </div>
        </div>
      </div>

      <div className="container">
        <CategoryList selectedCategory="all" onCategoryChange={(id) => navigate(`/categories/${id}`)} />

        {isSearching ? (
          <div className="mb-8">
            <h2 className="section-title">
              <i className="fas fa-search"></i> Search Results
              <span className="ml-2 text-sm font-normal" style={{color:'var(--text-secondary)'}}>({searchResults.length} found)</span>
            </h2>
            {searchResults.length > 0 ? <DealGrid deals={searchResults} /> : (
              <div className="text-center py-16">
                <div style={{fontSize:'3rem',marginBottom:'1rem'}}>🔍</div>
                <h3 className="text-xl font-bold mb-2">No results found</h3>
                <p style={{color:'var(--text-secondary)'}}>Try different keywords or browse categories</p>
              </div>
            )}
          </div>
        ) : (
          <>
            {/* Featured Deals */}
            <div className="mb-12">
              <h2 className="section-title"><i className="fas fa-star"></i> Featured Deals</h2>
              {loadingDeals ? (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                  {[...Array(4)].map((_, i) => <SkeletonCard key={i} />)}
                </div>
              ) : <DealGrid deals={featuredPromotions} />}
            </div>

            {/* Nearby Deals */}
            {(userLocation || locationError || loadingNearby) && (
              <div className="mb-12">
                <h2 className="section-title">
                  <i className="fas fa-map-marker-alt"></i> Nearby Deals
                  {userLocation && <span className="ml-2 text-sm font-normal" style={{color:'var(--text-secondary)'}}>within 10km</span>}
                </h2>
                {loadingNearby && (
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                    {[...Array(4)].map((_, i) => <SkeletonCard key={i} />)}
                  </div>
                )}
                {locationError && !loadingNearby && (
                  <div className="flex items-center gap-3 p-4 rounded-xl" style={{background:'rgba(239,68,68,0.08)',border:'1px solid rgba(239,68,68,0.2)'}}>
                    <i className="fas fa-exclamation-triangle" style={{color:'#ef4444'}}></i>
                    <p style={{color:'#ef4444',margin:0,fontSize:'0.875rem'}}>{locationError}</p>
                  </div>
                )}
                {!loadingNearby && !locationError && nearbyDeals.length === 0 && (
                  <div className="text-center py-12">
                    <div style={{fontSize:'2.5rem',marginBottom:'0.75rem'}}>📍</div>
                    <p style={{color:'var(--text-secondary)'}}>No deals found near your location.</p>
                  </div>
                )}
                {!loadingNearby && !locationError && nearbyDeals.length > 0 && <DealGrid deals={nearbyDeals} />}
              </div>
            )}

            {/* Latest Deals */}
            <div className="mb-12">
              <h2 className="section-title"><i className="fas fa-clock"></i> Latest Deals</h2>
              {loadingDeals ? (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                  {[...Array(8)].map((_, i) => <SkeletonCard key={i} />)}
                </div>
              ) : <DealGrid deals={latestPromotions} />}
            </div>
          </>
        )}
      </div>
    </div>
  );
}

window.HomePage = HomePage;
