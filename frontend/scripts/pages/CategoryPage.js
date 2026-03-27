function CategoryPage() {
  const { useState, useEffect } = React;
  const { useParams, useNavigate } = ReactRouterDOM;
  const { categoryId } = useParams();
  const navigate = useNavigate();

  const [promotions, setPromotions] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState('newest');
  const [isOnlyActive, setIsOnlyActive] = useState(true);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    filterAndSortPromotions();
  }, [categoryId, searchTerm, sortBy, isOnlyActive]);

  const filterAndSortPromotions = async () => {
    try {
      setLoading(true);
      const allPromotions = await window.getPromotionsData();
      window.promotionsData = allPromotions;
      const filtered = filterPromotions(allPromotions, {
        category: categoryId === 'all' ? '' : categoryId,
        searchTerm,
        onlyActive: isOnlyActive
      });
      setPromotions(sortPromotions(filtered, sortBy));
    } catch {
      // silent
    } finally {
      setLoading(false);
    }
  };

  const currentCategory = categories.find(c => c.id === categoryId) || { name: 'All Deals', icon: 'fa-tag' };

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
      <div style={{background:'linear-gradient(135deg, #6366f1 0%, #8b5cf6 50%, #f43f5e 100%)'}} className="py-12 mb-8">
        <div className="container text-center text-white">
          <div className="inline-flex items-center justify-center mb-3" style={{width:'56px',height:'56px',background:'rgba(255,255,255,0.2)',borderRadius:'1rem',fontSize:'1.5rem'}}>
            <i className={`fas ${currentCategory.icon}`}></i>
          </div>
          <h1 className="text-3xl md:text-4xl font-extrabold mb-2" style={{letterSpacing:'-0.02em'}}>{currentCategory.name}</h1>
          <p style={{opacity:0.85,fontSize:'1rem'}}>{loading ? '...' : `${promotions.length} deals found`}</p>
        </div>
      </div>

      <div className="container pb-12">
        <CategoryList selectedCategory={categoryId} onCategoryChange={() => {}} />

        {/* Filters */}
        <div className="flex flex-col md:flex-row md:items-center gap-3 mb-6 mt-4">
          {/* Search */}
          <div style={{position:'relative',flex:1,maxWidth:'400px'}}>
            <i className="fas fa-search" style={{position:'absolute',left:'0.875rem',top:'50%',transform:'translateY(-50%)',color:'var(--text-secondary)',pointerEvents:'none'}}></i>
            <input
              type="text"
              placeholder="Search deals..."
              value={searchTerm}
              onChange={e => setSearchTerm(e.target.value)}
              style={{width:'100%',padding:'0.625rem 2.5rem',border:'1.5px solid var(--border-color)',borderRadius:'9999px',background:'var(--card-bg)',color:'var(--text-primary)',fontSize:'0.875rem',outline:'none',boxSizing:'border-box'}}
            />
            {searchTerm && (
              <button onClick={() => setSearchTerm('')} style={{position:'absolute',right:'0.875rem',top:'50%',transform:'translateY(-50%)',background:'none',border:'none',color:'var(--text-secondary)',cursor:'pointer'}}>
                <i className="fas fa-times"></i>
              </button>
            )}
          </div>

          <div className="flex items-center gap-3 flex-wrap">
            {/* Sort */}
            <select
              value={sortBy}
              onChange={e => setSortBy(e.target.value)}
              style={{padding:'0.5rem 0.875rem',border:'1.5px solid var(--border-color)',borderRadius:'0.5rem',background:'var(--card-bg)',color:'var(--text-primary)',fontSize:'0.85rem',cursor:'pointer'}}>
              <option value="newest">Newest</option>
              <option value="ending-soon">Ending Soon</option>
              <option value="discount">Biggest Discount</option>
            </select>

            {/* Active toggle */}
            <button
              onClick={() => setIsOnlyActive(!isOnlyActive)}
              style={{
                display:'flex',alignItems:'center',gap:'0.5rem',
                padding:'0.5rem 0.875rem',borderRadius:'0.5rem',fontSize:'0.85rem',fontWeight:600,cursor:'pointer',
                border:'1.5px solid',transition:'all 0.2s',
                borderColor: isOnlyActive ? 'var(--primary-color)' : 'var(--border-color)',
                background: isOnlyActive ? 'rgba(99,102,241,0.08)' : 'var(--card-bg)',
                color: isOnlyActive ? 'var(--primary-color)' : 'var(--text-secondary)'
              }}>
              <i className={`fas ${isOnlyActive ? 'fa-toggle-on' : 'fa-toggle-off'}`}></i>
              Active only
            </button>
          </div>
        </div>

        {/* Grid */}
        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {[...Array(8)].map((_, i) => <SkeletonCard key={i} />)}
          </div>
        ) : promotions.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {promotions.map(p => (
              <div key={p.id || p._id} className="cursor-pointer fade-in" onClick={() => navigate(`/deal/${p.id || p._id}`)}>
                <PromotionCard promotion={p} />
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-16">
            <div style={{fontSize:'3rem',marginBottom:'1rem'}}>🔍</div>
            <h2 className="text-xl font-bold mb-2">No deals found</h2>
            <p style={{color:'var(--text-secondary)',marginBottom:'1.5rem'}}>
              {searchTerm ? 'Try different keywords' : 'No active deals in this category right now'}
            </p>
            {isOnlyActive && (
              <button className="btn btn-primary" onClick={() => setIsOnlyActive(false)}>
                Show Expired Deals
              </button>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

window.CategoryPage = CategoryPage;
