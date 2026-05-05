'use client';
import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { MerchantAPI, PromotionAPI } from '@/lib/api';
import toast from 'react-hot-toast';

export default function MerchantProfilePageClient() {
  const { merchantId } = useParams<{ merchantId: string }>();
  const router = useRouter();
  const [merchant, setMerchant] = useState<any>(null);
  const [promotions, setPromotions] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('active');
  const [isFollowing, setIsFollowing] = useState(false);

  useEffect(() => {
    Promise.all([MerchantAPI.getById(merchantId), PromotionAPI.getByMerchant(merchantId)])
      .then(([m, p]) => { setMerchant(m); setPromotions(Array.isArray(p) ? p : []); const f = JSON.parse(localStorage.getItem('dealFinderFollowing') || '[]'); setIsFollowing(f.some((x: any) => x.id === merchantId)); })
      .catch(() => toast.error('Failed to load merchant.'))
      .finally(() => setLoading(false));
  }, [merchantId]);

  const handleFollow = () => {
    const next = !isFollowing; setIsFollowing(next);
    const f = JSON.parse(localStorage.getItem('dealFinderFollowing') || '[]');
    if (next) { if (!f.some((x: any) => x.id === merchantId)) f.push({ id: merchantId, name: merchant.name, logo: merchant.logo, category: merchant.category }); }
    else { const i = f.findIndex((x: any) => x.id === merchantId); if (i !== -1) f.splice(i, 1); }
    localStorage.setItem('dealFinderFollowing', JSON.stringify(f));
    toast.success(next ? 'Following!' : 'Unfollowed');
  };

  const filtered = promotions.filter(p => activeTab === 'active' ? new Date(p.endDate) >= new Date() : new Date(p.endDate) < new Date());
  const getSafeLogo = (logo: string, name: string) => (logo && (logo.startsWith('data:') || logo.startsWith('http'))) ? logo : `https://ui-avatars.com/api/?name=${encodeURIComponent(name || 'M')}&background=random&size=300`;
  const CAT_ICONS: Record<string, string> = { fashion: 'fa-tshirt', electronics: 'fa-laptop', travel: 'fa-plane', health: 'fa-heart-pulse', entertainment: 'fa-gamepad', home: 'fa-home', food: 'fa-utensils' };

  if (loading) return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      <div className="skeleton" style={{ height: '220px', borderRadius: '1rem', marginBottom: '1.5rem' }}></div>
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6"><div className="skeleton-card" style={{ height: '200px' }}></div><div className="md:col-span-3 skeleton-card" style={{ height: '200px' }}></div></div>
    </div>
  );

  if (!merchant) return <div className="text-center py-16"><div style={{ fontSize: '3rem' }}>😕</div><h2>Merchant not found</h2><button className="btn btn-primary mt-4" onClick={() => router.back()}>Go Back</button></div>;

  return (
    <div>
      <div style={{ height: '220px', backgroundImage: merchant.banner ? `url(${merchant.banner})` : 'linear-gradient(135deg,#6366f1,#8b5cf6,#f43f5e)', backgroundSize: 'cover', backgroundPosition: 'center', position: 'relative' }}>
        <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)' }}></div>
        <div className="max-w-7xl mx-auto px-4 h-full flex items-end pb-6" style={{ position: 'relative' }}>
          <div className="flex items-center gap-4">
            <img src={getSafeLogo(merchant.logo, merchant.name)} alt={merchant.name} style={{ width: '80px', height: '80px', borderRadius: '50%', border: '3px solid #fff', objectFit: 'cover', flexShrink: 0 }} />
            <div>
              <h1 style={{ color: '#fff', fontSize: '1.75rem', fontWeight: 800, margin: 0 }}>{merchant.name}</h1>
              <div style={{ color: 'rgba(255,255,255,0.85)', fontSize: '0.875rem', display: 'flex', gap: '0.5rem', alignItems: 'center', marginTop: '0.25rem' }}>
                <i className={`fas ${CAT_ICONS[merchant.category] || 'fa-store'}`}></i>
                <span>{merchant.category || 'Other'}</span><span>•</span>
                <span>{promotions.filter(p => new Date(p.endDate) >= new Date()).length} active deals</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 py-6">
        <div className="flex flex-col md:flex-row gap-6">
          <div style={{ width: '100%', maxWidth: '280px' }}>
            <div className="promotion-card" style={{ padding: '1.25rem' }}>
              <button onClick={handleFollow} className="btn w-full mb-4" style={{ width: '100%', justifyContent: 'center', background: isFollowing ? 'var(--light-gray)' : 'linear-gradient(135deg,var(--primary-color),var(--primary-dark))', color: isFollowing ? 'var(--text-primary)' : '#fff', border: isFollowing ? '1.5px solid var(--border-color)' : 'none' }}>
                <i className={`fas ${isFollowing ? 'fa-user-check' : 'fa-user-plus'}`}></i> {isFollowing ? 'Following' : 'Follow Store'}
              </button>
              {merchant.description && <><p style={{ fontWeight: 600, fontSize: '0.875rem', marginBottom: '0.4rem', color: 'var(--text-primary)' }}>About</p><p style={{ fontSize: '0.825rem', color: 'var(--text-secondary)', lineHeight: 1.6, marginBottom: '1rem' }}>{merchant.description}</p></>}
              {merchant.website && merchant.website !== '#' && <a href={merchant.website} target="_blank" rel="noopener noreferrer" style={{ fontSize: '0.825rem', color: 'var(--primary-color)', display: 'flex', alignItems: 'center', gap: '0.35rem', textDecoration: 'none' }}><i className="fas fa-external-link-alt"></i> Visit Website</a>}
            </div>
          </div>

          <div style={{ flex: 1 }}>
            <div className="promotion-card" style={{ padding: '1.25rem' }}>
              <div className="flex gap-1 mb-5 p-1 rounded-xl" style={{ background: 'var(--light-gray)', width: 'fit-content' }}>
                {['active', 'expired'].map(tab => (
                  <button key={tab} onClick={() => setActiveTab(tab)} style={{ padding: '0.4rem 1.25rem', borderRadius: '0.625rem', fontSize: '0.875rem', fontWeight: 600, border: 'none', cursor: 'pointer', background: activeTab === tab ? 'var(--card-bg)' : 'transparent', color: activeTab === tab ? 'var(--primary-color)' : 'var(--text-secondary)', boxShadow: activeTab === tab ? 'var(--box-shadow)' : 'none' }}>
                    {tab === 'active' ? '✅ Active' : '⏰ Expired'} ({promotions.filter(p => tab === 'active' ? new Date(p.endDate) >= new Date() : new Date(p.endDate) < new Date()).length})
                  </button>
                ))}
              </div>
              {filtered.length === 0 ? <div className="text-center py-12"><div style={{ fontSize: '2.5rem', marginBottom: '0.75rem' }}>🏷️</div><p style={{ color: 'var(--text-secondary)' }}>No {activeTab} deals</p></div> : (
                <div className="flex flex-col gap-3">
                  {filtered.map(p => (
                    <div key={p._id} onClick={() => router.push(`/deal/${p._id}`)} className="cursor-pointer" style={{ border: '1.5px solid var(--border-color)', borderRadius: '0.875rem', padding: '1rem', transition: 'all 0.2s', background: 'var(--card-bg)' }}
                      onMouseEnter={e => { (e.currentTarget as HTMLElement).style.borderColor = 'var(--primary-color)'; }} onMouseLeave={e => { (e.currentTarget as HTMLElement).style.borderColor = 'var(--border-color)'; }}>
                      <div className="flex justify-between items-start gap-3">
                        <div className="flex-1">
                          <h3 style={{ fontWeight: 700, fontSize: '0.95rem', color: 'var(--text-primary)', margin: '0 0 0.4rem' }}>{p.title}</h3>
                          <p style={{ fontSize: '0.825rem', color: 'var(--text-secondary)', marginBottom: '0.5rem' }}>{p.description}</p>
                          <div className="flex items-center gap-2 flex-wrap">
                            <code className="promo-code">{p.code}</code>
                            <span className="discount-badge" style={{ position: 'static', fontSize: '0.75rem' }}>{p.discount} OFF</span>
                          </div>
                        </div>
                        {p.image && <img src={p.image} alt={p.title} style={{ width: '64px', height: '64px', borderRadius: '0.5rem', objectFit: 'cover', flexShrink: 0 }} />}
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
