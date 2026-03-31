'use client';

import { useState, useEffect, useRef, Suspense } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { PromotionAPI } from '@/lib/api';
import { getCurrencySymbol } from '@/lib/currency';
import toast from 'react-hot-toast';

const CATS = ['fashion','electronics','travel','health','entertainment','home','pets','food','education'];

function NewPromotionContent() {
  const { user } = useAuth();
  const router = useRouter();
  const searchParams = useSearchParams();
  const editId = searchParams.get('edit');
  const imageInputRef = useRef<HTMLInputElement>(null);

  const [saving, setSaving] = useState(false);
  const [hasChanges, setHasChanges] = useState(false);
  const [imagePreview, setImagePreview] = useState('');
  const [activeTab, setActiveTab] = useState('details');
  const [currencySymbol, setCurrencySymbol] = useState('$');

  const today = new Date().toISOString().split('T')[0];
  const nextMonth = new Date(); nextMonth.setMonth(nextMonth.getMonth() + 1);

  const defaultForm = { title:'', description:'', discount:'', code:'', category:'electronics', startDate: today, endDate: nextMonth.toISOString().split('T')[0], image:'', url:'', featured: false, originalPrice:'', discountedPrice:'' };
  const [form, setForm] = useState(defaultForm);
  const [original, setOriginal] = useState(defaultForm);

  useEffect(() => {
    if (!user) { router.push('/login'); return; }
    if (user.role !== 'merchant') { router.push('/'); return; }
    // Load merchant currency
    import('@/lib/api').then(({ MerchantAPI }) => {
      MerchantAPI.getById(user.merchantId!).then(m => {
        setCurrencySymbol(getCurrencySymbol(m.currency));
      }).catch(() => {});
    });
    if (editId) {
      PromotionAPI.getById(editId).then(p => {
        const fmt = (d: string) => new Date(d).toISOString().split('T')[0];
        const data = { title: p.title||'', description: p.description||'', discount: p.discount||'', code: p.code||'', category: p.category||'electronics', startDate: fmt(p.startDate), endDate: fmt(p.endDate), image: p.image||'', url: p.url||'', featured: !!p.featured, originalPrice: p.originalPrice?.toString()||'', discountedPrice: p.discountedPrice?.toString()||'' };
        setForm(data); setOriginal(data); setImagePreview(p.image||'');
      }).catch(() => toast.error('Failed to load promotion.'));
    }
  }, [user, editId]);

  useEffect(() => { setHasChanges(JSON.stringify(form) !== JSON.stringify(original)); }, [form, original]);
  useEffect(() => { if (form.image && form.image.startsWith('http')) setImagePreview(form.image); }, [form.image]);

  const update = (k: string, v: any) => setForm(prev => ({ ...prev, [k]: v }));

  const handleImageFile = (file: File) => {
    if (file.size > 2 * 1024 * 1024) { toast.error('Image must be under 2MB'); return; }
    const reader = new FileReader();
    reader.onloadend = () => { const r = reader.result as string; update('image', r); setImagePreview(r); };
    reader.readAsDataURL(file);
  };

  const generateCode = () => {
    const code = (form.title.split(' ').map(w => w[0]).join('').toUpperCase() || 'DEAL') + Math.floor(Math.random() * 90 + 10);
    update('code', code);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.title.trim()) { toast.error('Title is required'); setActiveTab('details'); return; }
    if (!form.discount.trim()) { toast.error('Discount is required'); setActiveTab('details'); return; }
    if (!form.code.trim()) { toast.error('Promo code is required'); setActiveTab('details'); return; }
    if (form.originalPrice && form.discountedPrice && parseFloat(form.discountedPrice) >= parseFloat(form.originalPrice)) { toast.error('Discounted price must be less than original price'); setActiveTab('pricing'); return; }
    setSaving(true);
    try {
      const merchantId = user!.merchantId?.toString() || user!.merchantId;
      if (!merchantId) { toast.error('Merchant profile not linked. Please contact support.'); return; }
      const data = { ...form, featured: Boolean(form.featured), merchantId };
      if (editId) { await PromotionAPI.update(editId, data); toast.success('Promotion updated!'); }
      else { await PromotionAPI.create(data); toast.success('Promotion created!'); }
      router.push('/merchant/dashboard');
    } catch (err: any) { toast.error(err.message || 'Failed to save promotion.'); }
    finally { setSaving(false); }
  };

  const TABS = [{ id:'details', icon:'fa-tag', label:'Details' },{ id:'pricing', icon:'fa-dollar-sign', label:'Pricing' },{ id:'media', icon:'fa-image', label:'Media' },{ id:'settings', icon:'fa-cog', label:'Settings' }];

  const inputStyle = { width:'100%', padding:'0.75rem 1rem', borderRadius:'0.75rem', border:'1.5px solid var(--border-color)', background:'var(--card-bg)', color:'var(--text-primary)', fontSize:'0.9rem', outline:'none', boxSizing:'border-box' as const, transition:'border-color 0.2s' };
  const labelStyle = { display:'block', fontSize:'0.85rem', fontWeight:600 as const, marginBottom:'0.4rem', color:'var(--text-primary)' };
  const hintStyle = { fontSize:'0.75rem', color:'var(--text-secondary)', marginTop:'0.3rem' };
  const focus = (e: any) => e.target.style.borderColor = 'var(--primary-color)';
  const blur = (e: any) => e.target.style.borderColor = 'var(--border-color)';

  const daysLeft = form.endDate ? Math.ceil((new Date(form.endDate).getTime() - new Date(form.startDate).getTime()) / 86400000) : 0;

  return (
    <div className="max-w-4xl mx-auto px-4 py-8">
      {/* Header */}
      <div className="flex items-center justify-between mb-6 flex-wrap gap-3">
        <div className="flex items-center gap-3">
          <button type="button" onClick={() => router.push('/merchant/dashboard')}
            style={{ width:'36px', height:'36px', borderRadius:'50%', border:'1.5px solid var(--border-color)', background:'var(--card-bg)', color:'var(--text-secondary)', display:'flex', alignItems:'center', justifyContent:'center', cursor:'pointer' }}>
            <i className="fas fa-arrow-left"></i>
          </button>
          <div>
            <h1 style={{ fontSize:'1.5rem', fontWeight:800, color:'var(--text-primary)', margin:0, letterSpacing:'-0.02em' }}>{editId ? 'Edit Promotion' : 'New Promotion'}</h1>
            <p style={{ fontSize:'0.85rem', color:'var(--text-secondary)', margin:0 }}>{editId ? 'Update your promotion details' : 'Create a new deal for your customers'}</p>
          </div>
        </div>
        {hasChanges && (
          <div className="flex items-center gap-2 fade-in" style={{ padding:'0.4rem 0.875rem', borderRadius:'9999px', background:'rgba(245,158,11,0.1)', border:'1px solid rgba(245,158,11,0.3)' }}>
            <div style={{ width:'6px', height:'6px', borderRadius:'50%', background:'#f59e0b' }}></div>
            <span style={{ fontSize:'0.8rem', fontWeight:600, color:'#d97706' }}>Unsaved changes</span>
          </div>
        )}
      </div>

      <form onSubmit={handleSubmit}>
        <div className="flex flex-col md:flex-row gap-6">
          {/* Sidebar */}
          <div style={{ width:'100%', maxWidth:'200px', flexShrink:0 }}>
            <div className="promotion-card" style={{ padding:'0.5rem' }}>
              {TABS.map(tab => (
                <button key={tab.id} type="button" onClick={() => setActiveTab(tab.id)}
                  style={{ display:'flex', alignItems:'center', gap:'0.625rem', width:'100%', padding:'0.75rem 1rem', borderRadius:'0.625rem', border:'none', cursor:'pointer', fontSize:'0.875rem', fontWeight:600, textAlign:'left', transition:'all 0.15s', marginBottom:'0.125rem', background: activeTab===tab.id ? 'linear-gradient(135deg,var(--primary-color),var(--primary-dark))' : 'transparent', color: activeTab===tab.id ? '#fff' : 'var(--text-secondary)' }}>
                  <i className={`fas ${tab.icon}`} style={{ width:'16px', textAlign:'center' }}></i> {tab.label}
                </button>
              ))}
            </div>

            {/* Live Preview */}
            <div className="promotion-card mt-4 overflow-hidden">
              {imagePreview ? <img src={imagePreview} alt="Preview" style={{ width:'100%', height:'100px', objectFit:'cover' }} /> : <div style={{ height:'100px', background:'var(--light-gray)', display:'flex', alignItems:'center', justifyContent:'center' }}><i className="fas fa-image" style={{ fontSize:'1.5rem', color:'var(--text-secondary)' }}></i></div>}
              <div style={{ padding:'0.75rem' }}>
                <p style={{ fontWeight:700, fontSize:'0.8rem', color:'var(--text-primary)', margin:'0 0 0.25rem', overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap' }}>{form.title || 'Promotion Title'}</p>
                <div className="flex items-center justify-between">
                  <code className="promo-code" style={{ fontSize:'0.7rem' }}>{form.code || 'CODE'}</code>
                  {form.discount && <span className="discount-badge" style={{ position:'static', fontSize:'0.65rem', padding:'0.15rem 0.4rem' }}>{form.discount} OFF</span>}
                </div>
                {daysLeft > 0 && <p style={{ fontSize:'0.7rem', color:'var(--text-secondary)', margin:'0.4rem 0 0' }}><i className="far fa-clock mr-1"></i>{daysLeft} days</p>}
              </div>
            </div>
          </div>

          {/* Content */}
          <div style={{ flex:1 }}>
            <div className="promotion-card" style={{ padding:'1.75rem' }}>

              {/* Details Tab */}
              {activeTab === 'details' && (
                <div className="fade-in">
                  <h2 style={{ fontSize:'1.1rem', fontWeight:700, color:'var(--text-primary)', marginBottom:'1.5rem', display:'flex', alignItems:'center', gap:'0.5rem' }}>
                    <i className="fas fa-tag" style={{ color:'var(--primary-color)' }}></i> Promotion Details
                  </h2>
                  <div className="flex flex-col gap-4">
                    <div>
                      <label style={labelStyle}>Title <span style={{ color:'#ef4444' }}>*</span></label>
                      <input style={inputStyle} value={form.title} onChange={e => update('title', e.target.value)} required placeholder="e.g. Summer Sale — 20% Off Everything" onFocus={focus} onBlur={blur} />
                      <p style={hintStyle}>Make it catchy and clear</p>
                    </div>
                    <div>
                      <label style={labelStyle}>Description <span style={{ color:'#ef4444' }}>*</span></label>
                      <textarea style={{ ...inputStyle, resize:'vertical', minHeight:'100px' }} value={form.description} onChange={e => update('description', e.target.value)} required placeholder="Describe what customers get with this deal..." onFocus={focus} onBlur={blur}></textarea>
                      <p style={hintStyle}>{form.description.length}/300 characters</p>
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div>
                        <label style={labelStyle}>Discount <span style={{ color:'#ef4444' }}>*</span></label>
                        <input style={inputStyle} value={form.discount} onChange={e => update('discount', e.target.value)} required placeholder="e.g. 20%, $50, BOGO" onFocus={focus} onBlur={blur} />
                        <p style={hintStyle}>Percentage, fixed amount, or type</p>
                      </div>
                      <div>
                        <label style={labelStyle}>Promo Code <span style={{ color:'#ef4444' }}>*</span></label>
                        <div style={{ position:'relative' }}>
                          <input style={{ ...inputStyle, paddingRight:'5rem', textTransform:'uppercase' }} value={form.code} onChange={e => update('code', e.target.value.toUpperCase())} required placeholder="SAVE20" onFocus={focus} onBlur={blur} />
                          <button type="button" onClick={generateCode} style={{ position:'absolute', right:'0.5rem', top:'50%', transform:'translateY(-50%)', fontSize:'0.72rem', fontWeight:600, padding:'0.25rem 0.5rem', borderRadius:'0.375rem', border:'1px solid var(--border-color)', background:'var(--light-gray)', color:'var(--text-secondary)', cursor:'pointer' }}>
                            Auto
                          </button>
                        </div>
                        <p style={hintStyle}>Click Auto to generate from title</p>
                      </div>
                    </div>
                    <div>
                      <label style={labelStyle}>Category <span style={{ color:'#ef4444' }}>*</span></label>
                      <select style={inputStyle} value={form.category} onChange={e => update('category', e.target.value)} onFocus={focus} onBlur={blur}>
                        {CATS.map(c => <option key={c} value={c}>{c.charAt(0).toUpperCase()+c.slice(1)}</option>)}
                      </select>
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div>
                        <label style={labelStyle}>Start Date <span style={{ color:'#ef4444' }}>*</span></label>
                        <input type="date" style={inputStyle} value={form.startDate} onChange={e => update('startDate', e.target.value)} required onFocus={focus} onBlur={blur} />
                      </div>
                      <div>
                        <label style={labelStyle}>End Date <span style={{ color:'#ef4444' }}>*</span></label>
                        <input type="date" style={inputStyle} value={form.endDate} onChange={e => update('endDate', e.target.value)} required min={form.startDate} onFocus={focus} onBlur={blur} />
                        {daysLeft > 0 && <p style={{ ...hintStyle, color:'var(--primary-color)' }}><i className="fas fa-check-circle mr-1"></i>{daysLeft} day{daysLeft !== 1 ? 's' : ''} active</p>}
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* Pricing Tab */}
              {activeTab === 'pricing' && (
                <div className="fade-in">
                  <h2 style={{ fontSize:'1.1rem', fontWeight:700, color:'var(--text-primary)', marginBottom:'0.5rem', display:'flex', alignItems:'center', gap:'0.5rem' }}>
                    <i className="fas fa-dollar-sign" style={{ color:'var(--primary-color)' }}></i> Pricing (Optional)
                  </h2>
                  <p style={{ ...hintStyle, marginBottom:'1.5rem' }}>Show customers how much they save by adding original and discounted prices</p>
                  <div className="flex flex-col gap-4">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div>
                        <label style={labelStyle}>Original Price</label>
                        <div style={{ position:'relative' }}>
                          <span style={{ position:'absolute', left:'1rem', top:'50%', transform:'translateY(-50%)', color:'var(--text-secondary)', fontWeight:600 }}>$</span>
                          <input type="number" step="0.01" min="0" style={{ ...inputStyle, paddingLeft:'2rem' }} value={form.originalPrice} onChange={e => update('originalPrice', e.target.value)} placeholder="100.00" onFocus={focus} onBlur={blur} />
                        </div>
                      </div>
                      <div>
                        <label style={labelStyle}>Discounted Price</label>
                        <div style={{ position:'relative' }}>
                          <span style={{ position:'absolute', left:'1rem', top:'50%', transform:'translateY(-50%)', color:'var(--text-secondary)', fontWeight:600 }}>$</span>
                          <input type="number" step="0.01" min="0" style={{ ...inputStyle, paddingLeft:'2rem' }} value={form.discountedPrice} onChange={e => update('discountedPrice', e.target.value)} placeholder="80.00" onFocus={focus} onBlur={blur} />
                        </div>
                      </div>
                    </div>
                    {form.originalPrice && form.discountedPrice && parseFloat(form.discountedPrice) < parseFloat(form.originalPrice) && (
                      <div className="fade-in" style={{ padding:'1rem', borderRadius:'0.875rem', background:'rgba(16,185,129,0.08)', border:'1px solid rgba(16,185,129,0.2)' }}>
                        <p style={{ margin:0, fontSize:'0.875rem', fontWeight:600, color:'#059669' }}>
                          <i className="fas fa-check-circle mr-2"></i>
                          Customers save `\${currencySymbol}\${(parseFloat(form.originalPrice) - parseFloat(form.discountedPrice)).toFixed(2)} ({Math.round((1 - parseFloat(form.discountedPrice)/parseFloat(form.originalPrice))*100)}% off)
                        </p>
                      </div>
                    )}
                    <div>
                      <label style={labelStyle}>Promotion URL</label>
                      <div style={{ position:'relative' }}>
                        <i className="fas fa-link" style={{ position:'absolute', left:'1rem', top:'50%', transform:'translateY(-50%)', color:'var(--text-secondary)', pointerEvents:'none' }}></i>
                        <input type="url" style={{ ...inputStyle, paddingLeft:'2.5rem' }} value={form.url} onChange={e => update('url', e.target.value)} placeholder="https://yourstore.com/deal" onFocus={focus} onBlur={blur} />
                      </div>
                      <p style={hintStyle}>Customers will be redirected here when they click &quot;Get This Deal&quot;</p>
                    </div>
                  </div>
                </div>
              )}

              {/* Media Tab */}
              {activeTab === 'media' && (
                <div className="fade-in">
                  <h2 style={{ fontSize:'1.1rem', fontWeight:700, color:'var(--text-primary)', marginBottom:'0.5rem', display:'flex', alignItems:'center', gap:'0.5rem' }}>
                    <i className="fas fa-image" style={{ color:'var(--primary-color)' }}></i> Promotion Image
                  </h2>
                  <p style={{ ...hintStyle, marginBottom:'1.5rem' }}>Add an eye-catching image to make your deal stand out</p>

                  {/* Upload area */}
                  <div onClick={() => imageInputRef.current?.click()}
                    style={{ borderRadius:'1rem', overflow:'hidden', border:'2px dashed var(--border-color)', marginBottom:'1rem', position:'relative', minHeight:'200px', background: imagePreview ? `url(${imagePreview}) center/cover` : 'var(--light-gray)', display:'flex', alignItems:'center', justifyContent:'center', cursor:'pointer', transition:'border-color 0.2s' }}
                    onMouseEnter={e => (e.currentTarget.style.borderColor = 'var(--primary-color)')}
                    onMouseLeave={e => (e.currentTarget.style.borderColor = 'var(--border-color)')}>
                    {imagePreview && <div style={{ position:'absolute', inset:0, background:'rgba(0,0,0,0.4)' }}></div>}
                    <div className="text-center" style={{ position:'relative', zIndex:1, padding:'2rem' }}>
                      <i className="fas fa-cloud-upload-alt" style={{ fontSize:'2.5rem', color: imagePreview ? '#fff' : 'var(--text-secondary)', marginBottom:'0.75rem', display:'block' }}></i>
                      <p style={{ fontWeight:600, fontSize:'0.9rem', color: imagePreview ? '#fff' : 'var(--text-primary)', margin:'0 0 0.25rem' }}>{imagePreview ? 'Click to change image' : 'Click to upload image'}</p>
                      <p style={{ fontSize:'0.75rem', color: imagePreview ? 'rgba(255,255,255,0.8)' : 'var(--text-secondary)', margin:0 }}>PNG, JPG up to 2MB</p>
                    </div>
                    <input ref={imageInputRef} type="file" accept="image/*" style={{ display:'none' }} onChange={e => e.target.files?.[0] && handleImageFile(e.target.files[0])} />
                  </div>

                  <div style={{ display:'flex', alignItems:'center', gap:'0.75rem', marginBottom:'0.75rem' }}>
                    <div style={{ flex:1, height:'1px', background:'var(--border-color)' }}></div>
                    <span style={{ fontSize:'0.8rem', color:'var(--text-secondary)' }}>or paste URL</span>
                    <div style={{ flex:1, height:'1px', background:'var(--border-color)' }}></div>
                  </div>

                  <input style={inputStyle} value={form.image.startsWith('data:') ? '' : form.image} onChange={e => { update('image', e.target.value); setImagePreview(e.target.value); }} placeholder="https://example.com/image.jpg" onFocus={focus} onBlur={blur} />

                  {imagePreview && (
                    <button type="button" onClick={() => { update('image', ''); setImagePreview(''); }} style={{ marginTop:'0.75rem', fontSize:'0.8rem', padding:'0.4rem 0.875rem', borderRadius:'0.625rem', border:'1.5px solid rgba(239,68,68,0.3)', background:'rgba(239,68,68,0.06)', color:'#ef4444', cursor:'pointer' }}>
                      <i className="fas fa-trash mr-1"></i> Remove Image
                    </button>
                  )}
                </div>
              )}

              {/* Settings Tab */}
              {activeTab === 'settings' && (
                <div className="fade-in">
                  <h2 style={{ fontSize:'1.1rem', fontWeight:700, color:'var(--text-primary)', marginBottom:'0.5rem', display:'flex', alignItems:'center', gap:'0.5rem' }}>
                    <i className="fas fa-cog" style={{ color:'var(--primary-color)' }}></i> Settings
                  </h2>
                  <p style={{ ...hintStyle, marginBottom:'1.5rem' }}>Configure visibility and display options</p>

                  <label style={{ display:'flex', alignItems:'flex-start', gap:'1rem', padding:'1.25rem', borderRadius:'1rem', border:`2px solid ${form.featured ? 'var(--primary-color)' : 'var(--border-color)'}`, cursor:'pointer', background: form.featured ? 'rgba(99,102,241,0.04)' : 'var(--card-bg)', transition:'all 0.2s', marginBottom:'1rem' }}>
                    <input type="checkbox" checked={form.featured} onChange={e => update('featured', e.target.checked)} style={{ width:'18px', height:'18px', accentColor:'var(--primary-color)', cursor:'pointer', marginTop:'0.1rem', flexShrink:0 }} />
                    <div>
                      <div style={{ display:'flex', alignItems:'center', gap:'0.5rem', marginBottom:'0.25rem' }}>
                        <span style={{ fontSize:'0.95rem', fontWeight:700, color:'var(--text-primary)' }}>⭐ Featured Deal</span>
                        {form.featured && <span style={{ fontSize:'0.7rem', fontWeight:700, padding:'0.15rem 0.5rem', borderRadius:'9999px', background:'linear-gradient(135deg,#fbbf24,#f59e0b)', color:'#fff' }}>Active</span>}
                      </div>
                      <p style={{ fontSize:'0.825rem', color:'var(--text-secondary)', margin:0, lineHeight:1.5 }}>Featured deals appear on the homepage hero section and get significantly more visibility. Use this for your best promotions.</p>
                    </div>
                  </label>

                  {/* Summary */}
                  <div style={{ padding:'1.25rem', borderRadius:'1rem', background:'var(--light-gray)', border:'1px solid var(--border-color)' }}>
                    <p style={{ fontWeight:700, fontSize:'0.875rem', color:'var(--text-primary)', marginBottom:'0.875rem' }}>Promotion Summary</p>
                    <div className="flex flex-col gap-2">
                      {[
                        ['Title', form.title || '—'],
                        ['Discount', form.discount || '—'],
                        ['Code', form.code || '—'],
                        ['Category', form.category],
                        ['Duration', daysLeft > 0 ? `${daysLeft} days (${form.startDate} → ${form.endDate})` : '—'],
                        ['Featured', form.featured ? 'Yes ⭐' : 'No'],
                      ].map(([k, v]) => (
                        <div key={k} className="flex items-center justify-between">
                          <span style={{ fontSize:'0.8rem', color:'var(--text-secondary)' }}>{k}</span>
                          <span style={{ fontSize:'0.8rem', fontWeight:600, color:'var(--text-primary)' }}>{v}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              )}
            </div>

            {/* Navigation + Save */}
            <div className="flex items-center justify-between mt-4 flex-wrap gap-3">
              <div className="flex gap-2">
                {TABS.findIndex(t => t.id === activeTab) > 0 && (
                  <button type="button" onClick={() => setActiveTab(TABS[TABS.findIndex(t => t.id === activeTab) - 1].id)} className="btn" style={{ border:'1.5px solid var(--border-color)', background:'var(--card-bg)', color:'var(--text-secondary)' }}>
                    <i className="fas fa-arrow-left"></i> Previous
                  </button>
                )}
                {TABS.findIndex(t => t.id === activeTab) < TABS.length - 1 && (
                  <button type="button" onClick={() => setActiveTab(TABS[TABS.findIndex(t => t.id === activeTab) + 1].id)} className="btn" style={{ border:'1.5px solid var(--border-color)', background:'var(--card-bg)', color:'var(--text-secondary)' }}>
                    Next <i className="fas fa-arrow-right"></i>
                  </button>
                )}
              </div>
              <div className="flex gap-3">
                <button type="button" onClick={() => router.push('/merchant/dashboard')} style={{ padding:'0.6rem 1.25rem', borderRadius:'0.625rem', border:'1.5px solid var(--border-color)', background:'var(--card-bg)', color:'var(--text-secondary)', fontWeight:600, cursor:'pointer', fontSize:'0.875rem' }}>Cancel</button>
                <button type="submit" disabled={saving} className="btn btn-primary">
                  {saving ? <><i className="fas fa-spinner fa-spin"></i> Saving...</> : <><i className={`fas ${editId ? 'fa-save' : 'fa-plus'}`}></i> {editId ? 'Update Promotion' : 'Create Promotion'}</>}
                </button>
              </div>
            </div>
          </div>
        </div>
      </form>
    </div>
  );
}

export default function NewPromotionPage() {
  return (
    <Suspense fallback={<div className="max-w-4xl mx-auto px-4 py-8"><div className="skeleton-card" style={{ height: '500px' }}></div></div>}>
      <NewPromotionContent />
    </Suspense>
  );
}
