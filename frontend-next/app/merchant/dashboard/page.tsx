'use client';
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { PromotionAPI, MerchantAPI, UserAPI } from '@/lib/api';
import toast from 'react-hot-toast';

export default function MerchantDashboard() {
  const { user, updateUser } = useAuth();
  const router = useRouter();
  const [merchant, setMerchant] = useState<any>(null);
  const [promotions, setPromotions] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('active');

  useEffect(() => {
    const loadDashboard = async () => {
      if (!user) { router.push('/login'); return; }
      if (user.role !== 'merchant') { router.push('/'); return; }

      let merchantId = user.merchantId;
      if (!merchantId) {
        try {
          const refreshedUser = await UserAPI.getProfile(user._id);
          merchantId = refreshedUser.merchantId?.toString();
          if (merchantId) {
            updateUser({ merchantId });
          }
        } catch {}
      }

      if (!merchantId) {
        toast.error('Merchant profile is still syncing. Please sign out and sign in again.');
        setLoading(false);
        return;
      }

      Promise.all([MerchantAPI.getById(merchantId), PromotionAPI.getByMerchant(merchantId)])
        .then(([m, p]) => { setMerchant(m); setPromotions(Array.isArray(p) ? p.map((x:any) => ({...x, id: x._id})) : []); })
        .catch(() => toast.error('Failed to load dashboard.'))
        .finally(() => setLoading(false));
    };

    loadDashboard();
  }, [router, updateUser, user]);

  const handleDelete = async (id: string) => {
    if (!confirm('Delete this promotion?')) return;
    try { await PromotionAPI.delete(id); setPromotions(prev => prev.filter(p => p.id !== id)); toast.success('Deleted!'); } catch { toast.error('Failed to delete.'); }
  };

  const filtered = promotions.filter(p => activeTab === 'active' ? ['active','approved','pending_approval','scheduled'].includes(p.status) : activeTab === 'expired' ? ['expired','rejected'].includes(p.status) : true);
  const fmt = (d: string) => new Date(d).toLocaleDateString('en-US', { month:'short', day:'numeric', year:'numeric' });

  if (loading) return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      <div className="skeleton" style={{ height: '160px', borderRadius: '1rem', marginBottom: '1.5rem' }}></div>
      <div className="skeleton-card" style={{ height: '400px' }}></div>
    </div>
  );

  if (!merchant) return <div className="text-center py-16"><div style={{ fontSize: '3rem' }}>⚠️</div><h2>Merchant profile not found</h2><button className="btn btn-primary mt-4" onClick={() => window.location.reload()}>Retry</button></div>;

  return (
    <div>
      {/* Header */}
      <div style={{ background: 'linear-gradient(135deg,#6366f1,#8b5cf6,#f43f5e)', padding: '2.5rem 0' }}>
        <div className="max-w-7xl mx-auto px-4">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 mb-6">
            <div className="flex items-center gap-4">
              <div style={{ width:'56px', height:'56px', borderRadius:'1rem', background:'rgba(255,255,255,0.2)', display:'flex', alignItems:'center', justifyContent:'center', fontSize:'1.5rem', color:'#fff' }}><i className="fas fa-store"></i></div>
              <div><h1 style={{ color:'#fff', fontSize:'1.5rem', fontWeight:800, margin:0 }}>{merchant.name}</h1><p style={{ color:'rgba(255,255,255,0.8)', fontSize:'0.875rem', margin:0 }}>{promotions.filter(p=>['active','approved'].includes(p.status)).length} active deals</p></div>
            </div>
            <div className="flex gap-2">
              <button onClick={() => router.push('/merchant/dashboard/edit-profile')} className="btn" style={{ background:'rgba(255,255,255,0.15)', color:'#fff', border:'1.5px solid rgba(255,255,255,0.3)' }}><i className="fas fa-user-edit"></i> Edit Profile</button>
              <button onClick={() => router.push('/merchant/dashboard/promotions/new')} className="btn" style={{ background:'#fff', color:'var(--primary-color)', fontWeight:700 }}><i className="fas fa-plus"></i> Add Promotion</button>
            </div>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            {[{label:'Total',value:promotions.length,icon:'fa-tag'},{label:'Active',value:promotions.filter(p=>['active','approved'].includes(p.status)).length,icon:'fa-check-circle'},{label:'Pending',value:promotions.filter(p=>p.status==='pending_approval').length,icon:'fa-clock'},{label:'Expired',value:promotions.filter(p=>p.status==='expired').length,icon:'fa-times-circle'}].map(s => (
              <div key={s.label} style={{ background:'rgba(255,255,255,0.15)', borderRadius:'0.875rem', padding:'0.875rem 1rem', backdropFilter:'blur(8px)' }}>
                <div style={{ color:'rgba(255,255,255,0.7)', fontSize:'0.75rem', fontWeight:600, marginBottom:'0.25rem', textTransform:'uppercase', letterSpacing:'0.04em' }}><i className={`fas ${s.icon} mr-1`}></i>{s.label}</div>
                <div style={{ color:'#fff', fontSize:'1.5rem', fontWeight:800 }}>{s.value}</div>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 py-6">
        {/* Onboarding checklist for new merchants */}
        {promotions.length === 0 && (
          <div className="promotion-card fade-in mb-6" style={{ padding: '1.5rem', border: '2px solid rgba(99,102,241,0.2)', background: 'linear-gradient(135deg, rgba(99,102,241,0.04), rgba(139,92,246,0.04))' }}>
            <div className="flex items-center gap-3 mb-4">
              <div style={{ width: '40px', height: '40px', borderRadius: '50%', background: 'linear-gradient(135deg,#6366f1,#8b5cf6)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontSize: '1.1rem', flexShrink: 0 }}>
                <i className="fas fa-rocket"></i>
              </div>
              <div>
                <h3 style={{ fontWeight: 800, fontSize: '1rem', color: 'var(--text-primary)', margin: 0 }}>Welcome! Let&apos;s get your store ready 🎉</h3>
                <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', margin: 0 }}>Complete these steps to start attracting customers</p>
              </div>
            </div>
            <div className="flex flex-col gap-3">
              {[
                { done: !!(merchant.profile && merchant.contactInfo), icon: 'fa-user-edit', label: 'Complete your store profile', action: () => router.push('/merchant/dashboard/edit-profile'), btn: 'Set Up Profile' },
                { done: !!(merchant.location?.coordinates), icon: 'fa-map-marker-alt', label: 'Add your store location so customers can find you', action: () => router.push('/merchant/dashboard/edit-profile'), btn: 'Add Location' },
                { done: promotions.length > 0, icon: 'fa-tag', label: 'Create your first promotion', action: () => router.push('/merchant/dashboard/promotions/new'), btn: 'Create Deal' },
              ].map((step, i) => (
                <div key={i} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0.875rem 1rem', borderRadius: '0.75rem', background: step.done ? 'rgba(16,185,129,0.06)' : 'var(--card-bg)', border: `1px solid ${step.done ? 'rgba(16,185,129,0.2)' : 'var(--border-color)'}`, gap: '1rem', flexWrap: 'wrap' as const }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: step.done ? 'rgba(16,185,129,0.15)' : 'var(--light-gray)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                      <i className={`fas ${step.done ? 'fa-check' : step.icon}`} style={{ fontSize: '0.8rem', color: step.done ? '#059669' : 'var(--primary-color)' }}></i>
                    </div>
                    <span style={{ fontSize: '0.875rem', fontWeight: 600, color: step.done ? '#059669' : 'var(--text-primary)', textDecoration: step.done ? 'line-through' : 'none' }}>{step.label}</span>
                  </div>
                  {!step.done && (
                    <button onClick={step.action} className="btn btn-primary" style={{ fontSize: '0.8rem', padding: '0.35rem 0.875rem', flexShrink: 0 }}>
                      {step.btn} <i className="fas fa-arrow-right ml-1"></i>
                    </button>
                  )}
                </div>
              ))}
            </div>
          </div>
        )}
        {/* Tabs */}
        <div className="flex gap-1 mb-6 p-1 rounded-xl" style={{ background:'var(--light-gray)', width:'fit-content' }}>
          {[['active','✅ Active'],['expired','⏰ Expired'],['all','📋 All']].map(([id,label]) => (
            <button key={id} onClick={() => setActiveTab(id)} style={{ padding:'0.4rem 1rem', borderRadius:'0.625rem', fontSize:'0.85rem', fontWeight:600, border:'none', cursor:'pointer', background:activeTab===id?'var(--card-bg)':'transparent', color:activeTab===id?'var(--primary-color)':'var(--text-secondary)', boxShadow:activeTab===id?'var(--box-shadow)':'none' }}>{label}</button>
          ))}
        </div>

        {filtered.length === 0 ? (
          <div className="text-center py-16"><div style={{ fontSize:'3rem', marginBottom:'1rem' }}>🏷️</div><h2 style={{ fontWeight:700, marginBottom:'0.5rem' }}>No promotions yet</h2><p style={{ color:'var(--text-secondary)', marginBottom:'1.5rem' }}>Create your first promotion to start attracting customers</p><button className="btn btn-primary" onClick={() => router.push('/merchant/dashboard/promotions/new')}><i className="fas fa-plus"></i> Create Promotion</button></div>
        ) : (
          <div className="promotion-card overflow-hidden">
            <div className="overflow-x-auto">
              <table style={{ width:'100%', borderCollapse:'collapse' }}>
                <thead><tr style={{ background:'var(--light-gray)', borderBottom:'1.5px solid var(--border-color)' }}>
                  {['Promotion','Discount','Code','Dates','Status','Actions'].map(h => <th key={h} style={{ padding:'0.75rem 1rem', textAlign:h==='Actions'?'right':'left', fontSize:'0.75rem', fontWeight:700, color:'var(--text-secondary)', textTransform:'uppercase', letterSpacing:'0.05em' }}>{h}</th>)}
                </tr></thead>
                <tbody>
                  {filtered.map(p => (
                    <tr key={p.id} style={{ borderBottom:'1px solid var(--border-color)' }} onMouseEnter={e=>(e.currentTarget.style.background='var(--light-gray)')} onMouseLeave={e=>(e.currentTarget.style.background='transparent')}>
                      <td style={{ padding:'0.75rem 1rem' }}>
                        <div className="flex items-center gap-3">
                          {p.image && <img src={p.image} alt={p.title} style={{ width:'40px', height:'40px', borderRadius:'0.5rem', objectFit:'cover', flexShrink:0 }} />}
                          <div><div style={{ fontWeight:600, fontSize:'0.875rem', color:'var(--text-primary)' }}>{p.title}</div><div style={{ fontSize:'0.75rem', color:'var(--text-secondary)' }}>{p.category}</div></div>
                        </div>
                      </td>
                      <td style={{ padding:'0.75rem 1rem' }}><span className="discount-badge" style={{ position:'static', fontSize:'0.75rem' }}>{p.discount} OFF</span></td>
                      <td style={{ padding:'0.75rem 1rem' }}><code className="promo-code" style={{ fontSize:'0.8rem' }}>{p.code}</code></td>
                      <td style={{ padding:'0.75rem 1rem', fontSize:'0.8rem', color:'var(--text-secondary)' }}>{fmt(p.startDate)}<br/>{fmt(p.endDate)}</td>
                      <td style={{ padding:'0.75rem 1rem' }}>
                        <span style={{ padding:'0.2rem 0.6rem', borderRadius:'9999px', fontSize:'0.72rem', fontWeight:700, background:['active','approved'].includes(p.status)?'rgba(16,185,129,0.1)':p.status==='pending_approval'?'rgba(245,158,11,0.1)':'rgba(100,116,139,0.1)', color:['active','approved'].includes(p.status)?'#059669':p.status==='pending_approval'?'#d97706':'#64748b' }}>
                          {p.status?.replace(/_/g,' ').replace(/\b\w/g,(l:string)=>l.toUpperCase()) || 'Expired'}
                        </span>
                      </td>
                      <td style={{ padding:'0.75rem 1rem', textAlign:'right' }}>
                        <div className="flex justify-end gap-2">
                          <button onClick={() => router.push(`/merchant/dashboard/promotions/new?edit=${p.id}`)} style={{ padding:'0.3rem 0.75rem', borderRadius:'0.5rem', border:'1.5px solid var(--border-color)', background:'var(--card-bg)', color:'var(--primary-color)', fontSize:'0.8rem', fontWeight:600, cursor:'pointer' }}><i className="fas fa-edit"></i> Edit</button>
                          <button onClick={() => handleDelete(p.id)} style={{ padding:'0.3rem 0.75rem', borderRadius:'0.5rem', border:'1.5px solid rgba(239,68,68,0.3)', background:'rgba(239,68,68,0.06)', color:'#ef4444', fontSize:'0.8rem', fontWeight:600, cursor:'pointer' }}><i className="fas fa-trash-alt"></i></button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>

    </div>
  );
}
