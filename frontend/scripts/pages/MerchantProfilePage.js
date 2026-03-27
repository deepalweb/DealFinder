function MerchantProfilePage() {
  const { useState, useEffect } = React;
  const { useParams, useNavigate } = ReactRouterDOM;
  const { merchantId } = useParams();
  const navigate = useNavigate();

  const [merchant, setMerchant] = useState(null);
  const [promotions, setPromotions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('active');
  const [isFollowing, setIsFollowing] = useState(false);
  const [error, setError] = useState(null);

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

  useEffect(() => {
    const fetchMerchantData = async () => {
      try {
        setLoading(true);
        const merchantData = await window.API.Merchants.getById(merchantId);
        setMerchant({ ...merchantData, id: merchantData._id });
        let merchantPromotions = await window.API.Promotions.getByMerchant(merchantId);
        if (!Array.isArray(merchantPromotions)) merchantPromotions = [];
        setPromotions(merchantPromotions.map(p => ({ ...p, id: p._id })));
        const followed = JSON.parse(localStorage.getItem('dealFinderFollowing') || '[]');
        setIsFollowing(followed.some(m => m.id === merchantId));
      } catch {
        setError('Failed to load merchant profile. Please try again.');
      } finally {
        setLoading(false);
      }
    };
    fetchMerchantData();
  }, [merchantId]);

  const handleFollowToggle = () => {
    const newStatus = !isFollowing;
    setIsFollowing(newStatus);
    const followed = JSON.parse(localStorage.getItem('dealFinderFollowing') || '[]');
    if (newStatus) {
      if (!followed.some(m => m.id === merchant.id)) {
        followed.push({ id: merchant.id, name: merchant.name, logo: merchant.logo, category: merchant.category });
      }
    } else {
      const idx = followed.findIndex(m => m.id === merchant.id);
      if (idx !== -1) followed.splice(idx, 1);
    }
    localStorage.setItem('dealFinderFollowing', JSON.stringify(followed));
  };

  const filteredPromotions = promotions.filter(p => {
    const expired = new Date(p.endDate) < new Date();
    return activeTab === 'active' ? !expired : expired;
  });

  // Skeleton
  if (loading) {
    return (
      <div className="page-container">
        {/* Banner skeleton */}
        <div className="skeleton" style={{height:'220px',borderRadius:0}}></div>
        <div className="container py-6">
          <div className="flex flex-col md:flex-row gap-6">
            <div className="md:w-1/3 lg:w-1/4">
              <div className="skeleton-card p-5">
                <div className="skeleton mb-4" style={{height:'40px'}}></div>
                <div className="skeleton mb-2" style={{height:'12px',width:'40%'}}></div>
                <div className="skeleton mb-2" style={{height:'12px',width:'100%'}}></div>
                <div className="skeleton" style={{height:'12px',width:'80%'}}></div>
              </div>
            </div>
            <div className="md:w-2/3 lg:w-3/4">
              <div className="skeleton-card p-5">
                {[...Array(3)].map((_, i) => (
                  <div key={i} className="mb-4 pb-4" style={{borderBottom:'1px solid var(--border-color)'}}>
                    <div className="skeleton mb-2" style={{height:'16px',width:'60%'}}></div>
                    <div className="skeleton mb-2" style={{height:'12px',width:'90%'}}></div>
                    <div className="skeleton" style={{height:'12px',width:'40%'}}></div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="page-container">
        <div className="container py-16 text-center">
          <div style={{fontSize:'3rem',marginBottom:'1rem'}}>😕</div>
          <h2 className="text-xl font-bold mb-2">Something went wrong</h2>
          <p style={{color:'var(--text-secondary)',marginBottom:'1.5rem'}}>{error}</p>
          <button className="btn btn-primary" onClick={() => window.location.reload()}>Try Again</button>
        </div>
      </div>
    );
  }

  return (
    <div className="page-container">
      {/* Banner */}
      <div style={{
        height:'220px',
        backgroundImage: merchant.banner ? `url(${merchant.banner})` : 'linear-gradient(135deg, #6366f1 0%, #8b5cf6 50%, #f43f5e 100%)',
        backgroundSize:'cover',
        backgroundPosition:'center',
        position:'relative'
      }}>
        <div style={{position:'absolute',inset:0,background:'rgba(0,0,0,0.35)'}}></div>
        <div className="container h-full flex items-end" style={{position:'relative',paddingBottom:'1.5rem'}}>
          <div className="flex items-center gap-4">
            <img
              src={getSafeLogo(merchant.logo, merchant.name)}
              alt={merchant.name}
              style={{width:'80px',height:'80px',borderRadius:'50%',border:'3px solid #fff',objectFit:'cover',boxShadow:'0 4px 12px rgba(0,0,0,0.3)',flexShrink:0}}
              onError={e => { e.target.onerror=null; e.target.src=`https://ui-avatars.com/api/?name=${encodeURIComponent(merchant.name)}&background=random&size=300`; }}
            />
            <div>
              <h1 style={{color:'#fff',fontSize:'1.75rem',fontWeight:800,letterSpacing:'-0.02em',margin:0}}>{merchant.name}</h1>
              <div style={{color:'rgba(255,255,255,0.85)',fontSize:'0.875rem',display:'flex',alignItems:'center',gap:'0.5rem',marginTop:'0.25rem'}}>
                <i className={`fas ${categoryIcon(merchant.category)}`}></i>
                <span>{merchant.category ? merchant.category.charAt(0).toUpperCase() + merchant.category.slice(1) : 'Other'}</span>
                <span>•</span>
                <span>{typeof merchant.followers === 'number' ? merchant.followers.toLocaleString() : '0'} followers</span>
                <span>•</span>
                <span>{promotions.filter(p => new Date(p.endDate) >= new Date()).length} active deals</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="container py-6">
        <div className="flex flex-col md:flex-row md:items-start gap-6">

          {/* Sidebar */}
          <div className="md:w-1/3 lg:w-1/4">
            <div className="promotion-card p-5 mb-4">
              <button
                onClick={handleFollowToggle}
                className="btn w-full mb-4"
                style={{
                  background: isFollowing ? 'var(--light-gray)' : 'linear-gradient(135deg,var(--primary-color),var(--primary-dark))',
                  color: isFollowing ? 'var(--text-primary)' : '#fff',
                  border: isFollowing ? '1.5px solid var(--border-color)' : 'none',
                  justifyContent:'center', gap:'0.5rem'
                }}>
                <i className={`fas ${isFollowing ? 'fa-user-check' : 'fa-user-plus'}`}></i>
                {isFollowing ? 'Following' : 'Follow Store'}
              </button>

              {merchant.description && (
                <div className="mb-4">
                  <p style={{fontSize:'0.875rem',fontWeight:600,marginBottom:'0.5rem',color:'var(--text-primary)'}}>About</p>
                  <p style={{fontSize:'0.825rem',color:'var(--text-secondary)',lineHeight:1.6}}>{merchant.description}</p>
                </div>
              )}

              {merchant.website && merchant.website !== '#' && (
                <div className="mb-4">
                  <p style={{fontSize:'0.875rem',fontWeight:600,marginBottom:'0.5rem',color:'var(--text-primary)'}}>Website</p>
                  <a href={merchant.website} target="_blank" rel="noopener noreferrer"
                    style={{fontSize:'0.825rem',color:'var(--primary-color)',display:'flex',alignItems:'center',gap:'0.35rem',textDecoration:'none'}}>
                    <i className="fas fa-external-link-alt"></i> Visit Website
                  </a>
                </div>
              )}

              {merchant.socialMedia && (merchant.socialMedia.facebook || merchant.socialMedia.instagram || merchant.socialMedia.twitter || merchant.socialMedia.tiktok) && (
                <div>
                  <p style={{fontSize:'0.875rem',fontWeight:600,marginBottom:'0.5rem',color:'var(--text-primary)'}}>Social Media</p>
                  <div className="flex gap-2">
                    {merchant.socialMedia.facebook && (
                      <a href={`https://facebook.com/${merchant.socialMedia.facebook}`} target="_blank" rel="noopener noreferrer" className="social-icon" style={{background:'#1877f2',borderColor:'#1877f2',color:'#fff'}}>
                        <i className="fab fa-facebook-f"></i>
                      </a>
                    )}
                    {merchant.socialMedia.instagram && (
                      <a href={`https://instagram.com/${merchant.socialMedia.instagram}`} target="_blank" rel="noopener noreferrer" className="social-icon" style={{background:'linear-gradient(135deg,#833ab4,#fd1d1d,#fcb045)',borderColor:'transparent',color:'#fff'}}>
                        <i className="fab fa-instagram"></i>
                      </a>
                    )}
                    {merchant.socialMedia.twitter && (
                      <a href={`https://twitter.com/${merchant.socialMedia.twitter}`} target="_blank" rel="noopener noreferrer" className="social-icon" style={{background:'#1da1f2',borderColor:'#1da1f2',color:'#fff'}}>
                        <i className="fab fa-twitter"></i>
                      </a>
                    )}
                    {merchant.socialMedia.tiktok && (
                      <a href={`https://tiktok.com/@${merchant.socialMedia.tiktok}`} target="_blank" rel="noopener noreferrer" className="social-icon" style={{background:'#010101',borderColor:'#010101',color:'#fff'}}>
                        <i className="fab fa-tiktok"></i>
                      </a>
                    )}
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Main Content */}
          <div className="md:w-2/3 lg:w-3/4">
            <div className="promotion-card p-5">
              {/* Tabs */}
              <div className="flex gap-1 mb-5 p-1 rounded-xl" style={{background:'var(--light-gray)',width:'fit-content'}}>
                {['active','expired'].map(tab => (
                  <button key={tab} onClick={() => setActiveTab(tab)}
                    style={{
                      padding:'0.4rem 1.25rem',
                      borderRadius:'0.625rem',
                      fontSize:'0.875rem',
                      fontWeight:600,
                      border:'none',
                      cursor:'pointer',
                      transition:'all 0.2s',
                      background: activeTab === tab ? 'var(--card-bg)' : 'transparent',
                      color: activeTab === tab ? 'var(--primary-color)' : 'var(--text-secondary)',
                      boxShadow: activeTab === tab ? 'var(--box-shadow)' : 'none'
                    }}>
                    {tab === 'active' ? '✅ Active' : '⏰ Expired'} ({promotions.filter(p => {
                      const expired = new Date(p.endDate) < new Date();
                      return tab === 'active' ? !expired : expired;
                    }).length})
                  </button>
                ))}
              </div>

              {filteredPromotions.length === 0 ? (
                <div className="text-center py-12">
                  <div style={{fontSize:'2.5rem',marginBottom:'0.75rem'}}>🏷️</div>
                  <p style={{color:'var(--text-secondary)'}}>No {activeTab} deals available</p>
                </div>
              ) : (
                <div className="flex flex-col gap-3">
                  {filteredPromotions.map(promo => (
                    <div key={promo.id}
                      className="cursor-pointer"
                      onClick={() => navigate(`/deal/${promo.id}`)}
                      style={{
                        border:'1.5px solid var(--border-color)',
                        borderRadius:'0.875rem',
                        padding:'1rem',
                        transition:'all 0.2s',
                        background:'var(--card-bg)'
                      }}
                      onMouseEnter={e => { e.currentTarget.style.borderColor='var(--primary-color)'; e.currentTarget.style.boxShadow='0 4px 16px rgba(99,102,241,0.12)'; }}
                      onMouseLeave={e => { e.currentTarget.style.borderColor='var(--border-color)'; e.currentTarget.style.boxShadow='none'; }}
                    >
                      <div className="flex justify-between items-start gap-3">
                        <div className="flex-1">
                          <div className="flex items-center gap-2 mb-1 flex-wrap">
                            <h3 style={{fontWeight:700,fontSize:'0.95rem',color:'var(--text-primary)',margin:0}}>{promo.title}</h3>
                            {promo.featured && (
                              <span style={{background:'linear-gradient(135deg,#fbbf24,#f59e0b)',color:'#fff',fontSize:'0.7rem',fontWeight:700,padding:'0.15rem 0.5rem',borderRadius:'9999px'}}>
                                ⭐ Featured
                              </span>
                            )}
                          </div>
                          <p style={{fontSize:'0.825rem',color:'var(--text-secondary)',marginBottom:'0.5rem',lineHeight:1.5}}>{promo.description}</p>
                          <div style={{fontSize:'0.75rem',color:'var(--text-secondary)',marginBottom:'0.75rem',display:'flex',alignItems:'center',gap:'0.35rem'}}>
                            <i className="far fa-calendar-alt"></i>
                            {new Date(promo.startDate).toLocaleDateString()} — {new Date(promo.endDate).toLocaleDateString()}
                          </div>
                          <div className="flex items-center gap-2 flex-wrap">
                            <code className="promo-code">{promo.code}</code>
                            <span className="discount-badge" style={{position:'static',fontSize:'0.75rem'}}>{promo.discount} OFF</span>
                          </div>
                        </div>
                        {promo.image && (
                          <img
                            src={promo.image}
                            alt={promo.title}
                            style={{width:'72px',height:'72px',borderRadius:'0.625rem',objectFit:'cover',flexShrink:0,border:'1px solid var(--border-color)'}}
                            onError={e => { e.target.onerror=null; e.target.style.display='none'; }}
                          />
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}

window.MerchantProfilePage = MerchantProfilePage;
