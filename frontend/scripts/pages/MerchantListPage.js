function MerchantListPage() {
  const { useState, useEffect } = React;
  const { Link } = ReactRouterDOM;

  const [merchants, setMerchants] = useState([]);
  const [filteredMerchants, setFilteredMerchants] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchMerchants = async () => {
      try {
        setLoading(true);
        let merchantsData = await window.API.Merchants.getAll();
        if (!Array.isArray(merchantsData)) merchantsData = [];
        merchantsData = merchantsData.map(m => ({ ...m, id: m._id }));
        setMerchants(merchantsData);
        setFilteredMerchants(merchantsData);
      } catch {
        setError('Failed to load merchants. Please try again later.');
      } finally {
        setLoading(false);
      }
    };
    fetchMerchants();
  }, []);

  useEffect(() => {
    let results = [...merchants];
    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      results = results.filter(m =>
        m.name.toLowerCase().includes(term) ||
        (m.description && m.description.toLowerCase().includes(term))
      );
    }
    if (selectedCategory !== 'all') {
      results = results.filter(m => m.category === selectedCategory);
    }
    setFilteredMerchants(results);
  }, [searchTerm, selectedCategory, merchants]);

  function getSafeLogo(logo, name) {
    if (logo && typeof logo === 'string') {
      if (logo.startsWith('data:image') || logo.startsWith('http')) return logo;
    }
    return `https://ui-avatars.com/api/?name=${encodeURIComponent(name || 'M')}&background=random&size=300`;
  }

  const categoryIcon = (cat) => ({
    fashion: 'fa-tshirt', electronics: 'fa-laptop', travel: 'fa-plane',
    health: 'fa-heart-pulse', entertainment: 'fa-gamepad', home: 'fa-home',
    pets: 'fa-paw', food: 'fa-utensils'
  }[cat] || 'fa-store');

  const SkeletonCard = () => (
    <div className="skeleton-card p-4">
      <div className="flex items-center mb-4 gap-3">
        <div className="skeleton rounded-full flex-shrink-0" style={{width:'64px',height:'64px'}}></div>
        <div className="flex-1">
          <div className="skeleton mb-2" style={{height:'16px',width:'60%'}}></div>
          <div className="skeleton" style={{height:'12px',width:'40%'}}></div>
        </div>
      </div>
      <div className="skeleton mb-2" style={{height:'12px',width:'100%'}}></div>
      <div className="skeleton mb-4" style={{height:'12px',width:'75%'}}></div>
      <div className="skeleton" style={{height:'36px'}}></div>
    </div>
  );

  return (
    <div className="page-container">
      {/* Hero */}
      <div style={{background:'linear-gradient(135deg, #6366f1 0%, #8b5cf6 50%, #f43f5e 100%)'}} className="py-16 mb-8">
        <div className="container">
          <div className="text-center text-white mb-8">
            <div className="inline-flex items-center gap-2 bg-white bg-opacity-20 rounded-full px-4 py-1.5 text-sm font-medium mb-4">
              <i className="fas fa-store"></i> {merchants.length} stores available
            </div>
            <h1 className="text-4xl md:text-5xl font-extrabold mb-4" style={{letterSpacing:'-0.03em',lineHeight:1.1}}>
              Discover Your<br/>Favorite Stores
            </h1>
            <p className="text-lg max-w-xl mx-auto mb-8" style={{opacity:0.9}}>
              Follow merchants to get personalized deal recommendations and notifications.
            </p>
            {/* Search */}
            <div style={{position:'relative',maxWidth:'520px',margin:'0 auto'}}>
              <i className="fas fa-search" style={{position:'absolute',left:'1.1rem',top:'50%',transform:'translateY(-50%)',color:'rgba(255,255,255,0.7)',pointerEvents:'none'}}></i>
              <input
                type="text"
                placeholder="Search stores..."
                value={searchTerm}
                onChange={e => setSearchTerm(e.target.value)}
                style={{width:'100%',padding:'0.875rem 3rem',border:'2px solid rgba(255,255,255,0.3)',borderRadius:'9999px',fontSize:'1rem',background:'rgba(255,255,255,0.15)',color:'#fff',backdropFilter:'blur(8px)',boxSizing:'border-box'}}
              />
              {searchTerm && (
                <button onClick={() => setSearchTerm('')} style={{position:'absolute',right:'1.1rem',top:'50%',transform:'translateY(-50%)',background:'none',border:'none',color:'rgba(255,255,255,0.7)',cursor:'pointer',fontSize:'0.9rem'}}>
                  <i className="fas fa-times"></i>
                </button>
              )}
            </div>
          </div>
        </div>
      </div>

      <div className="container pb-8">
        {/* Category Filter */}
        <div className="category-list mb-8">
          <button
            className={`category-item ${selectedCategory === 'all' ? 'active' : ''}`}
            onClick={() => setSelectedCategory('all')}>
            <i className="fas fa-th-large"></i> All
          </button>
          {categories.slice(1).map(cat => (
            <button
              key={cat.id}
              className={`category-item ${selectedCategory === cat.id ? 'active' : ''}`}
              onClick={() => setSelectedCategory(cat.id)}>
              <i className={`fas ${cat.icon}`}></i> {cat.name}
            </button>
          ))}
        </div>

        {error && (
          <div className="flex items-center gap-3 p-4 rounded-xl mb-6" style={{background:'rgba(239,68,68,0.08)',border:'1px solid rgba(239,68,68,0.2)'}}>
            <i className="fas fa-exclamation-triangle" style={{color:'#ef4444'}}></i>
            <p style={{color:'#ef4444',margin:0,fontSize:'0.875rem'}}>{error}</p>
            <button className="btn btn-primary ml-auto" style={{fontSize:'0.8rem',padding:'0.3rem 0.75rem'}} onClick={() => window.location.reload()}>Retry</button>
          </div>
        )}

        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[...Array(6)].map((_, i) => <SkeletonCard key={i} />)}
          </div>
        ) : filteredMerchants.length === 0 ? (
          <div className="text-center py-16">
            <div style={{fontSize:'3rem',marginBottom:'1rem'}}>🏪</div>
            <h2 className="text-xl font-bold mb-2">No stores found</h2>
            <p style={{color:'var(--text-secondary)'}}>Try a different search term or category</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredMerchants.map(merchant => (
              <div key={merchant.id} className="promotion-card fade-in">
                <div className="p-5">
                  <div className="flex items-center mb-4 gap-3">
                    <img
                      src={getSafeLogo(merchant.logo, merchant.name)}
                      alt={merchant.name}
                      className="rounded-full object-cover flex-shrink-0"
                      style={{width:'60px',height:'60px',border:'2px solid var(--border-color)'}}
                      onError={e => { e.target.onerror=null; e.target.src=`https://ui-avatars.com/api/?name=${encodeURIComponent(merchant.name)}&background=random&size=300`; }}
                    />
                    <div>
                      <h2 className="font-bold" style={{fontSize:'1.05rem',color:'var(--text-primary)'}}>{merchant.name}</h2>
                      <div className="flex items-center gap-1" style={{fontSize:'0.8rem',color:'var(--text-secondary)'}}>
                        <i className={`fas ${categoryIcon(merchant.category)}`}></i>
                        <span>{merchant.category ? merchant.category.charAt(0).toUpperCase() + merchant.category.slice(1) : 'Other'}</span>
                        <span style={{margin:'0 0.25rem'}}>•</span>
                        <span>{typeof merchant.followers === 'number' ? merchant.followers.toLocaleString() : '0'} followers</span>
                      </div>
                    </div>
                  </div>

                  <p style={{fontSize:'0.85rem',color:'var(--text-secondary)',marginBottom:'1rem',lineHeight:1.5}}>
                    {merchant.description || `${merchant.name} offers great deals and promotions.`}
                  </p>

                  <div className="flex justify-between items-center">
                    <span style={{fontSize:'0.8rem',fontWeight:600,color:'var(--primary-color)'}}>
                      <i className="fas fa-tag mr-1"></i>
                      {typeof merchant.activeDeals === 'number' ? merchant.activeDeals : 0} active deals
                    </span>
                    <Link to={`/merchants/${merchant.id}`} className="btn btn-primary" style={{fontSize:'0.8rem',padding:'0.4rem 1rem'}}>
                      Visit Store
                    </Link>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

window.MerchantListPage = MerchantListPage;
