function FavoritesPage() {
  const { useState, useEffect } = React;
  const { Link, useNavigate } = ReactRouterDOM;
  const navigate = useNavigate();

  const [favorites, setFavorites] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => { loadFavorites(); }, []);

  const loadFavorites = async () => {
    setLoading(true);
    try {
      const userData = localStorage.getItem('dealFinderUser');
      if (!userData) { setFavorites([]); setLoading(false); return; }
      const user = JSON.parse(userData);
      const data = await window.API.Users.getFavorites(user._id);
      setFavorites(data.map(p => ({ ...p, id: p.id || p._id })));
    } catch {
      setFavorites([]);
    }
    setLoading(false);
  };

  const handleFavoriteToggle = async (promotionId, isFavorite) => {
    if (!isFavorite) {
      try {
        const userData = localStorage.getItem('dealFinderUser');
        if (!userData) return;
        const user = JSON.parse(userData);
        await window.API.Users.removeFavorite(user._id, promotionId);
        setFavorites(prev => prev.filter(p => p.id !== promotionId));
      } catch {}
    }
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

  return (
    <div className="page-container">
      {/* Hero */}
      <div style={{background:'linear-gradient(135deg, #f43f5e 0%, #ec4899 50%, #8b5cf6 100%)'}} className="py-12 mb-8">
        <div className="container text-center text-white">
          <div className="inline-flex items-center justify-center mb-3" style={{width:'56px',height:'56px',background:'rgba(255,255,255,0.2)',borderRadius:'1rem',fontSize:'1.5rem'}}>
            <i className="fas fa-heart"></i>
          </div>
          <h1 className="text-3xl md:text-4xl font-extrabold mb-2" style={{letterSpacing:'-0.02em'}}>My Favorites</h1>
          <p style={{opacity:0.85,fontSize:'1rem'}}>
            {loading ? '...' : `${favorites.length} saved deal${favorites.length !== 1 ? 's' : ''}`}
          </p>
        </div>
      </div>

      <div className="container pb-12">
        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {[...Array(4)].map((_, i) => <SkeletonCard key={i} />)}
          </div>
        ) : favorites.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {favorites.map(p => (
              <div key={p.id} className="cursor-pointer fade-in" onClick={() => navigate(`/deal/${p.id}`)}>
                <PromotionCard promotion={p} onFavoriteToggle={handleFavoriteToggle} />
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-16">
            <div style={{fontSize:'4rem',marginBottom:'1rem'}}>💔</div>
            <h2 className="text-xl font-bold mb-2">No favorites yet</h2>
            <p style={{color:'var(--text-secondary)',marginBottom:'1.5rem',maxWidth:'360px',margin:'0 auto 1.5rem'}}>
              Click the ❤️ on any deal to save it here for quick access
            </p>
            <Link to="/categories/all" className="btn btn-primary" style={{gap:'0.5rem'}}>
              <i className="fas fa-search"></i> Browse All Deals
            </Link>
          </div>
        )}
      </div>
    </div>
  );
}

window.FavoritesPage = FavoritesPage;
