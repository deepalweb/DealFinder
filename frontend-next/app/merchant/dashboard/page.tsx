'use client';
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { PromotionAPI, MerchantAPI } from '@/lib/api';
import { getPromotionImage } from '@/lib/utils/promotion-image';
import toast from 'react-hot-toast';

const CATS = ['fashion','electronics','travel','health','entertainment','home','pets','food','education'];

export default function MerchantDashboard() {
  const { user } = useAuth();
  const router = useRouter();
  const [merchant, setMerchant] = useState<any>(null);
  const [promotions, setPromotions] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('active');
  const [modalOpen, setModalOpen] = useState(false);
  const [profileModalOpen, setProfileModalOpen] = useState(false);
  const [editing, setEditing] = useState<any>(null);
  const [form, setForm] = useState({ title:'', description:'', discount:'', code:'', category:'electronics', startDate:'', endDate:'', image:'', url:'', featured:false, originalPrice:'', discountedPrice:'' });
  const [profileForm, setProfileForm] = useState({ name:'', profile:'', contactInfo:'', contactNumber:'', address:'', logo:'', socialMedia:{ facebook:'', instagram:'', twitter:'', tiktok:'' } });

  useEffect(() => {
    if (!user) { router.push('/login'); return; }
    if (user.role !== 'merchant') { router.push('/'); return; }
    Promise.all([MerchantAPI.getById(user.merchantId!), PromotionAPI.getByMerchant(user.merchantId!)])
      .then(([m, p]) => { setMerchant(m); setPromotions(Array.isArray(p) ? p.map((x:any) => ({...x, id: x._id})) : []); })
      .catch(() => toast.error('Failed to load dashboard.'))
      .finally(() => setLoading(false));
  }, [user]);

  useEffect(() => {
    if (merchant && profileModalOpen) setProfileForm({ name: merchant.name||'', profile: merchant.profile||'', contactInfo: merchant.contactInfo||'', contactNumber: merchant.contactNumber||'', address: merchant.address||'', logo: merchant.logo||'', socialMedia: { facebook: merchant.socialMedia?.facebook||'', instagram: merchant.socialMedia?.instagram||'', twitter: merchant.socialMedia?.twitter||'', tiktok: merchant.socialMedia?.tiktok||'' } });
  }, [merchant, profileModalOpen]);

  useEffect(() => {
    if (modalOpen && !editing) { const today = new Date().toISOString().split('T')[0]; const next = new Date(); next.setMonth(next.getMonth()+1); setForm({ title:'', description:'', discount:'', code:'', category:'electronics', startDate:today, endDate:next.toISOString().split('T')[0], image:'', url:'', featured:false, originalPrice:'', discountedPrice:'' }); }
    if (editing) { const fmt = (d:string) => new Date(d).toISOString().split('T')[0]; setForm({ title:editing.title, description:editing.description, discount:editing.discount, code:editing.code, category:editing.category, startDate:fmt(editing.startDate), endDate:fmt(editing.endDate), image:editing.image||'', url:editing.url||'', featured:!!editing.featured, originalPrice:editing.originalPrice||'', discountedPrice:editing.discountedPrice||'' }); setModalOpen(true); }
  }, [modalOpen, editing]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const data = { ...form, featured: Boolean(form.featured), merchantId: user!.merchantId };
      if (editing) { const updated = await PromotionAPI.update(editing._id, data); setPromotions(prev => prev.map(p => p.id === editing.id ? {...updated, id: updated._id} : p)); toast.success('Promotion updated!'); }
      else { const created = await PromotionAPI.create(data); setPromotions(prev => [...prev, {...created, id: created._id}]); toast.success('Promotion created!'); }
      setModalOpen(false); setEditing(null);
    } catch (err: any) { toast.error(err.message || 'Failed to save promotion.'); }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Delete this promotion?')) return;
    try { await PromotionAPI.delete(id); setPromotions(prev => prev.filter(p => p.id !== id)); toast.success('Deleted!'); } catch { toast.error('Failed to delete.'); }
  };

  const handleProfileSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try { const updated = await MerchantAPI.update(user!.merchantId!, profileForm); setMerchant(updated); setProfileModalOpen(false); toast.success('Profile updated!'); } catch { toast.error('Failed to update profile.'); }
  };

  const filtered = promotions.filter(p => activeTab === 'active' ? ['active','approved','pending_approval','scheduled'].includes(p.status) : activeTab === 'expired' ? ['expired','rejected'].includes(p.status) : true);
  const fmt = (d: string) => new Date(d).toLocaleDateString('en-US', { month:'short', day:'numeric', year:'numeric' });
  const inputStyle = { width:'100%', padding:'0.7rem 1rem', borderRadius:'0.625rem', border:'1.5px solid var(--border-color)', background:'var(--card-bg)', color:'var(--text-primary)', fontSize:'0.9rem', outline:'none', boxSizing:'border-box' as const };

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
                <h3 style={{ fontWeight: 800, fontSize: '1rem', color: 'var(--text-primary)', margin: 0 }}>Welcome! Let's get your store ready 🎉</h3>
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
          <div className="text-center py-16"><div style={{ fontSize:'3rem', marginBottom:'1rem' }}>🏷️</div><h2 style={{ fontWeight:700, marginBottom:'0.5rem' }}>No promotions yet</h2><p style={{ color:'var(--text-secondary)', marginBottom:'1.5rem' }}>Create your first promotion to start attracting customers</p><button className="btn btn-primary" onClick={() => { setEditing(null); setModalOpen(true); }}><i className="fas fa-plus"></i> Create Promotion</button></div>
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
                          <img src={getPromotionImage(p)} alt={p.title} style={{ width:'40px', height:'40px', borderRadius:'0.5rem', objectFit:'cover', flexShrink:0 }} />
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

      {/* Promotion Modal */}
      {modalOpen && (
        <div style={{ position:'fixed', inset:0, background:'rgba(0,0,0,0.6)', display:'flex', alignItems:'center', justifyContent:'center', zIndex:50, padding:'1rem', overflowY:'auto', backdropFilter:'blur(4px)' }}>
          <div style={{ background:'var(--card-bg)', borderRadius:'1.25rem', width:'100%', maxWidth:'640px', maxHeight:'90vh', overflowY:'auto', boxShadow:'0 24px 64px rgba(0,0,0,0.3)' }}>
            <div style={{ padding:'1.5rem', borderBottom:'1px solid var(--border-color)', display:'flex', justifyContent:'space-between', alignItems:'center', position:'sticky', top:0, background:'var(--card-bg)', zIndex:1 }}>
              <div><h2 style={{ fontSize:'1.25rem', fontWeight:800, color:'var(--text-primary)', margin:0 }}>{editing ? 'Edit Promotion' : 'New Promotion'}</h2><p style={{ fontSize:'0.8rem', color:'var(--text-secondary)', margin:0 }}>Fill in the details below</p></div>
              <button onClick={() => { setModalOpen(false); setEditing(null); }} style={{ width:'32px', height:'32px', borderRadius:'50%', border:'1.5px solid var(--border-color)', background:'var(--light-gray)', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', color:'var(--text-secondary)' }}><i className="fas fa-times"></i></button>
            </div>
            <form onSubmit={handleSubmit} style={{ padding:'1.5rem' }}>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="md:col-span-2"><label style={{ display:'block', fontSize:'0.85rem', fontWeight:600, marginBottom:'0.4rem', color:'var(--text-primary)' }}>Title *</label><input style={inputStyle} value={form.title} onChange={e=>setForm({...form,title:e.target.value})} required placeholder="e.g. Summer Sale 20% Off" /></div>
                <div className="md:col-span-2"><label style={{ display:'block', fontSize:'0.85rem', fontWeight:600, marginBottom:'0.4rem', color:'var(--text-primary)' }}>Description *</label><textarea style={{...inputStyle,resize:'vertical'}} value={form.description} onChange={e=>setForm({...form,description:e.target.value})} required rows={3}></textarea></div>
                {[['discount','Discount *','e.g. 20%',true],['code','Promo Code *','e.g. SAVE20',true],['originalPrice','Original Price','e.g. 100.00',false],['discountedPrice','Discounted Price','e.g. 80.00',false]].map(([k,l,p,r]) => (
                  <div key={k as string}><label style={{ display:'block', fontSize:'0.85rem', fontWeight:600, marginBottom:'0.4rem', color:'var(--text-primary)' }}>{l as string}</label><input style={inputStyle} value={(form as any)[k as string]} onChange={e=>setForm({...form,[k as string]:e.target.value})} placeholder={p as string} required={r as boolean} /></div>
                ))}
                <div><label style={{ display:'block', fontSize:'0.85rem', fontWeight:600, marginBottom:'0.4rem', color:'var(--text-primary)' }}>Category *</label><select style={inputStyle} value={form.category} onChange={e=>setForm({...form,category:e.target.value})} required>{CATS.map(c=><option key={c} value={c}>{c.charAt(0).toUpperCase()+c.slice(1)}</option>)}</select></div>
                <div><label style={{ display:'block', fontSize:'0.85rem', fontWeight:600, marginBottom:'0.4rem', color:'var(--text-primary)' }}>Start Date *</label><input type="date" style={inputStyle} value={form.startDate} onChange={e=>setForm({...form,startDate:e.target.value})} required /></div>
                <div><label style={{ display:'block', fontSize:'0.85rem', fontWeight:600, marginBottom:'0.4rem', color:'var(--text-primary)' }}>End Date *</label><input type="date" style={inputStyle} value={form.endDate} onChange={e=>setForm({...form,endDate:e.target.value})} required /></div>
                <div className="md:col-span-2"><label style={{ display:'block', fontSize:'0.85rem', fontWeight:600, marginBottom:'0.4rem', color:'var(--text-primary)' }}>Image URL</label><input style={inputStyle} value={form.image} onChange={e=>setForm({...form,image:e.target.value})} placeholder="https://..." /></div>
                <div className="md:col-span-2"><label style={{ display:'block', fontSize:'0.85rem', fontWeight:600, marginBottom:'0.4rem', color:'var(--text-primary)' }}>Promotion URL</label><input type="url" style={inputStyle} value={form.url} onChange={e=>setForm({...form,url:e.target.value})} placeholder="https://yourstore.com/deal" /></div>
                <div className="md:col-span-2"><label style={{ display:'flex', alignItems:'center', gap:'0.75rem', padding:'0.875rem', borderRadius:'0.75rem', border:'1.5px solid var(--border-color)', cursor:'pointer', background:'var(--card-bg)' }}><input type="checkbox" checked={form.featured} onChange={e=>setForm({...form,featured:e.target.checked})} style={{ width:'16px', height:'16px', accentColor:'var(--primary-color)', cursor:'pointer' }} /><div><span style={{ fontSize:'0.875rem', fontWeight:600, color:'var(--text-primary)' }}>⭐ Mark as Featured Deal</span><p style={{ fontSize:'0.75rem', color:'var(--text-secondary)', margin:0 }}>Featured deals appear on the homepage</p></div></label></div>
              </div>
              <div className="flex justify-end gap-3 mt-4">
                <button type="button" onClick={() => { setModalOpen(false); setEditing(null); }} style={{ padding:'0.6rem 1.25rem', borderRadius:'0.625rem', border:'1.5px solid var(--border-color)', background:'var(--card-bg)', color:'var(--text-secondary)', fontWeight:600, cursor:'pointer' }}>Cancel</button>
                <button type="submit" className="btn btn-primary"><i className={`fas ${editing?'fa-save':'fa-plus'}`}></i> {editing ? 'Update' : 'Create'}</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Profile Modal */}
      {profileModalOpen && (
        <div style={{ position:'fixed', inset:0, background:'rgba(0,0,0,0.6)', display:'flex', alignItems:'center', justifyContent:'center', zIndex:50, padding:'1rem', overflowY:'auto', backdropFilter:'blur(4px)' }}>
          <div style={{ background:'var(--card-bg)', borderRadius:'1.25rem', width:'100%', maxWidth:'600px', maxHeight:'90vh', overflowY:'auto', boxShadow:'0 24px 64px rgba(0,0,0,0.3)' }}>
            <div style={{ padding:'1.5rem', borderBottom:'1px solid var(--border-color)', display:'flex', justifyContent:'space-between', alignItems:'center', position:'sticky', top:0, background:'var(--card-bg)', zIndex:1 }}>
              <div><h2 style={{ fontSize:'1.25rem', fontWeight:800, color:'var(--text-primary)', margin:0 }}>Edit Store Profile</h2><p style={{ fontSize:'0.8rem', color:'var(--text-secondary)', margin:0 }}>Update your store information</p></div>
              <button onClick={() => setProfileModalOpen(false)} style={{ width:'32px', height:'32px', borderRadius:'50%', border:'1.5px solid var(--border-color)', background:'var(--light-gray)', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', color:'var(--text-secondary)' }}><i className="fas fa-times"></i></button>
            </div>
            <form onSubmit={handleProfileSubmit} style={{ padding:'1.5rem' }}>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="md:col-span-2"><label style={{ display:'block', fontSize:'0.85rem', fontWeight:600, marginBottom:'0.4rem', color:'var(--text-primary)' }}>Business Name *</label><input style={inputStyle} value={profileForm.name} onChange={e=>setProfileForm({...profileForm,name:e.target.value})} required /></div>
                <div className="md:col-span-2"><label style={{ display:'block', fontSize:'0.85rem', fontWeight:600, marginBottom:'0.4rem', color:'var(--text-primary)' }}>Description</label><textarea style={{...inputStyle,resize:'vertical'}} value={profileForm.profile} onChange={e=>setProfileForm({...profileForm,profile:e.target.value})} rows={3}></textarea></div>
                <div><label style={{ display:'block', fontSize:'0.85rem', fontWeight:600, marginBottom:'0.4rem', color:'var(--text-primary)' }}>Contact Info</label><input style={inputStyle} value={profileForm.contactInfo} onChange={e=>setProfileForm({...profileForm,contactInfo:e.target.value})} /></div>
                <div><label style={{ display:'block', fontSize:'0.85rem', fontWeight:600, marginBottom:'0.4rem', color:'var(--text-primary)' }}>Contact Number</label><input style={inputStyle} value={profileForm.contactNumber} onChange={e=>setProfileForm({...profileForm,contactNumber:e.target.value})} /></div>
                <div className="md:col-span-2"><label style={{ display:'block', fontSize:'0.85rem', fontWeight:600, marginBottom:'0.4rem', color:'var(--text-primary)' }}>Address</label><input style={inputStyle} value={profileForm.address} onChange={e=>setProfileForm({...profileForm,address:e.target.value})} /></div>
                <div className="md:col-span-2"><label style={{ display:'block', fontSize:'0.85rem', fontWeight:600, marginBottom:'0.4rem', color:'var(--text-primary)' }}>Logo URL</label><input style={inputStyle} value={profileForm.logo} onChange={e=>setProfileForm({...profileForm,logo:e.target.value})} placeholder="https://..." /></div>
                <div className="md:col-span-2"><p style={{ fontSize:'0.875rem', fontWeight:700, color:'var(--text-primary)', marginBottom:'0.75rem' }}>Social Media</p>
                  <div className="grid grid-cols-2 gap-3">
                    {(['facebook','instagram','twitter','tiktok'] as const).map(k => (
                      <div key={k}><label style={{ display:'block', fontSize:'0.8rem', fontWeight:600, marginBottom:'0.3rem', color:'var(--text-secondary)', textTransform:'capitalize' }}><i className={`fab fa-${k} mr-1`}></i>{k}</label><input style={inputStyle} value={profileForm.socialMedia[k]} onChange={e=>setProfileForm({...profileForm,socialMedia:{...profileForm.socialMedia,[k]:e.target.value}})} placeholder={`@your${k}`} /></div>
                    ))}
                  </div>
                </div>
              </div>
              <div className="flex justify-end gap-3 mt-4">
                <button type="button" onClick={() => setProfileModalOpen(false)} style={{ padding:'0.6rem 1.25rem', borderRadius:'0.625rem', border:'1.5px solid var(--border-color)', background:'var(--card-bg)', color:'var(--text-secondary)', fontWeight:600, cursor:'pointer' }}>Cancel</button>
                <button type="submit" className="btn btn-primary"><i className="fas fa-save"></i> Save Profile</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
