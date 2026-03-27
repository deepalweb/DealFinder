function DealPage() {
  const { useParams, useNavigate } = ReactRouterDOM;
  const { useState, useEffect } = React;
  const { dealId } = useParams();
  const navigate = useNavigate();
  const [deal, setDeal] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    async function fetchDeal() {
      setLoading(true);
      try {
        const res = await fetch(`/api/promotions/${dealId}`);
        if (!res.ok) throw new Error('Deal not found');
        setDeal(await res.json());
      } catch {
        setError('Deal not found or failed to load.');
      }
      setLoading(false);
    }
    fetchDeal();
  }, [dealId]);

  const handleCopy = () => {
    if (deal?.code) {
      navigator.clipboard.writeText(deal.code);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  const handleShare = () => {
    const url = window.location.href;
    if (navigator.share) {
      navigator.share({ title: deal.title, text: deal.description, url });
    } else {
      navigator.clipboard.writeText(url);
    }
  };

  function getMerchantName(merchant) {
    if (!merchant) return '';
    if (typeof merchant === 'string') return merchant;
    return merchant.name || '';
  }

  if (loading) return (
    <div className="page-container">
      <div className="container py-8" style={{maxWidth:'800px'}}>
        <div className="skeleton mb-4" style={{height:'16px',width:'80px'}}></div>
        <div className="skeleton-card">
          <div className="skeleton" style={{height:'320px',borderRadius:'1.25rem 1.25rem 0 0'}}></div>
          <div className="p-6">
            <div className="skeleton mb-3" style={{height:'12px',width:'30%'}}></div>
            <div className="skeleton mb-3" style={{height:'28px',width:'70%'}}></div>
            <div className="skeleton mb-3" style={{height:'16px',width:'100%'}}></div>
            <div className="skeleton mb-6" style={{height:'16px',width:'80%'}}></div>
            <div className="skeleton" style={{height:'48px'}}></div>
          </div>
        </div>
      </div>
    </div>
  );

  if (error || !deal) return (
    <div className="page-container">
      <div className="container py-16 text-center">
        <div style={{fontSize:'3rem',marginBottom:'1rem'}}>😕</div>
        <h2 className="text-xl font-bold mb-2">Deal not found</h2>
        <p style={{color:'var(--text-secondary)',marginBottom:'1.5rem'}}>{error}</p>
        <button className="btn btn-primary" onClick={() => navigate(-1)}>Go Back</button>
      </div>
    </div>
  );

  const daysLeft = Math.ceil((new Date(deal.endDate) - new Date()) / (1000 * 60 * 60 * 24));
  const isExpired = daysLeft < 0;

  return (
    <div className="page-container">
      <div className="container py-8" style={{maxWidth:'800px'}}>
        <button onClick={() => navigate(-1)} className="flex items-center gap-2 mb-6 font-medium" style={{color:'var(--primary-color)',background:'none',border:'none',cursor:'pointer',fontSize:'0.9rem'}}>
          <i className="fas fa-arrow-left"></i> Back
        </button>

        <div className="promotion-card fade-in overflow-hidden">
          {/* Deal Image */}
          {deal.image && (
            <div style={{position:'relative',overflow:'hidden',maxHeight:'360px'}}>
              <img src={deal.image} alt={deal.title} style={{width:'100%',height:'360px',objectFit:'cover'}} />
              <div style={{position:'absolute',inset:0,background:'linear-gradient(to top, rgba(0,0,0,0.5) 0%, transparent 60%)'}}></div>
              {/* Badges */}
              <div style={{position:'absolute',top:'1rem',left:'1rem',display:'flex',gap:'0.5rem',flexWrap:'wrap'}}>
                {deal.featured && (
                  <span style={{background:'linear-gradient(135deg,#fbbf24,#f59e0b)',color:'#fff',fontSize:'0.75rem',fontWeight:700,padding:'0.3rem 0.75rem',borderRadius:'9999px'}}>
                    ⭐ Featured
                  </span>
                )}
                {isExpired && (
                  <span style={{background:'rgba(239,68,68,0.9)',color:'#fff',fontSize:'0.75rem',fontWeight:700,padding:'0.3rem 0.75rem',borderRadius:'9999px'}}>
                    Expired
                  </span>
                )}
              </div>
              <div style={{position:'absolute',top:'1rem',right:'1rem'}}>
                <span className="discount-badge" style={{position:'static',fontSize:'0.9rem'}}>{deal.discount} OFF</span>
              </div>
            </div>
          )}

          <div className="p-6">
            {/* Merchant & Category */}
            <div className="flex items-center justify-between mb-3 flex-wrap gap-2">
              <span className="promo-merchant">
                <i className="fas fa-store-alt mr-1"></i>{getMerchantName(deal.merchant)}
              </span>
              <div className="flex items-center gap-2">
                {deal.category && (
                  <span style={{fontSize:'0.75rem',padding:'0.2rem 0.6rem',borderRadius:'9999px',background:'var(--light-gray)',color:'var(--text-secondary)',border:'1px solid var(--border-color)'}}>
                    {deal.category.charAt(0).toUpperCase() + deal.category.slice(1)}
                  </span>
                )}
                <span className="expiry-tag">
                  <i className="far fa-clock"></i>
                  {isExpired ? 'Expired' : daysLeft === 0 ? 'Ends today' : `${daysLeft}d left`}
                </span>
              </div>
            </div>

            {/* Title */}
            <h1 style={{fontSize:'1.6rem',fontWeight:800,letterSpacing:'-0.02em',color:'var(--text-primary)',marginBottom:'0.75rem',lineHeight:1.3}}>{deal.title}</h1>

            {/* Description */}
            <p style={{color:'var(--text-secondary)',lineHeight:1.7,marginBottom:'1.5rem',fontSize:'0.95rem'}}>{deal.description}</p>

            {/* Dates */}
            <div className="flex items-center gap-2 mb-5" style={{fontSize:'0.8rem',color:'var(--text-secondary)'}}>
              <i className="far fa-calendar-alt" style={{color:'var(--primary-color)'}}></i>
              <span>{new Date(deal.startDate).toLocaleDateString('en-US',{month:'short',day:'numeric',year:'numeric'})}</span>
              <span>→</span>
              <span>{new Date(deal.endDate).toLocaleDateString('en-US',{month:'short',day:'numeric',year:'numeric'})}</span>
            </div>

            {/* Promo Code + Actions */}
            <div style={{background:'var(--light-gray)',borderRadius:'1rem',padding:'1.25rem',marginBottom:'1.5rem',border:'1px solid var(--border-color)'}}>
              <p style={{fontSize:'0.75rem',fontWeight:600,color:'var(--text-secondary)',marginBottom:'0.5rem',textTransform:'uppercase',letterSpacing:'0.05em'}}>Promo Code</p>
              <div className="flex items-center gap-3 flex-wrap">
                <code className="promo-code" style={{fontSize:'1.1rem',letterSpacing:'0.12em'}}>{deal.code}</code>
                <button onClick={handleCopy} className="btn btn-primary" style={{fontSize:'0.85rem',padding:'0.4rem 1rem',gap:'0.4rem'}}>
                  <i className={`fas ${copied ? 'fa-check' : 'fa-copy'}`}></i>
                  {copied ? 'Copied!' : 'Copy Code'}
                </button>
              </div>
            </div>

            {/* CTA Buttons */}
            <div className="flex gap-3 flex-wrap">
              {deal.url && (
                <a href={deal.url} target="_blank" rel="noopener noreferrer"
                  className="btn flex-1"
                  style={{background:'linear-gradient(135deg,var(--primary-color),var(--primary-dark))',color:'#fff',justifyContent:'center',gap:'0.5rem',minWidth:'160px'}}>
                  <i className="fas fa-external-link-alt"></i> Get This Deal
                </a>
              )}
              <button onClick={handleShare} className="btn" style={{border:'1.5px solid var(--border-color)',background:'var(--card-bg)',color:'var(--text-primary)',gap:'0.5rem'}}>
                <i className="fas fa-share-alt"></i> Share
              </button>
            </div>
          </div>

          {/* Comments & Ratings */}
          <div style={{borderTop:'1px solid var(--border-color)',padding:'1.5rem'}}>
            <h3 style={{fontWeight:700,fontSize:'1rem',marginBottom:'1rem',color:'var(--text-primary)'}}>
              <i className="fas fa-comments mr-2" style={{color:'var(--primary-color)'}}></i>Ratings & Comments
            </h3>
            <PromotionCard promotion={deal} singlePageMode={true} />
          </div>
        </div>
      </div>
    </div>
  );
}

window.DealPage = DealPage;
