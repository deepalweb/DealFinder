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
  const [imagePreviews, setImagePreviews] = useState<string[]>([]);
  const [activeTab, setActiveTab] = useState('details');
  const [currencySymbol, setCurrencySymbol] = useState('$');

  const today = new Date().toISOString().split('T')[0];
  const nextMonth = new Date(); nextMonth.setMonth(nextMonth.getMonth() + 1);

  const defaultForm = { title:'', description:'', discount:'', code:'', category:'electronics', startDate: today, endDate: nextMonth.toISOString().split('T')[0], image:'', images:[] as string[], url:'', featured: false, originalPrice:'', discountedPrice:'', dealType:'percentage', percentageOff:'' };
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
        const data = { title: p.title||'', description: p.description||'', discount: p.discount||'', code: p.code||'', category: p.category||'electronics', startDate: fmt(p.startDate), endDate: fmt(p.endDate), image: p.image||'', images: p.images||[], url: p.url||'', featured: !!p.featured, originalPrice: p.originalPrice?.toString()||'', discountedPrice: p.discountedPrice?.toString()||'', dealType:'percentage', percentageOff:'' };
        setForm(data); setOriginal(data); setImagePreviews(p.images?.length ? p.images : (p.image ? [p.image] : []));
      }).catch(() => toast.error('Failed to load promotion.'));
    }
  }, [user, editId]);

  useEffect(() => { setHasChanges(JSON.stringify(form) !== JSON.stringify(original)); }, [form, original]);
  useEffect(() => { if (form.image && form.image.startsWith('http')) setImagePreviews(prev => prev.length ? prev : [form.image]); }, [form.image]);

  const update = (k: string, v: any) => setForm(prev => ({ ...prev, [k]: v }));

  const handleImageFiles = (files: FileList) => {
    const remaining = 5 - imagePreviews.length;
    if (remaining <= 0) { toast.error('Maximum 5 images allowed'); return; }
    const toProcess = Array.from(files).slice(0, remaining);
    toProcess.forEach(file => {
      if (file.size > 5 * 1024 * 1024) { toast.error(`${file.name} exceeds 5MB limit`); return; }
      const reader = new FileReader();
      reader.onloadend = () => {
        const result = reader.result as string;
        setImagePreviews(prev => {
          const updated = [...prev, result];
          update('images', updated);
          if (updated.length === 1) update('image', result);
          return updated;
        });
      };
      reader.readAsDataURL(file);
    });
  };

  const removeImage = (index: number) => {
    setImagePreviews(prev => {
      const updated = prev.filter((_, i) => i !== index);
      update('images', updated);
      update('image', updated[0] || '');
      return updated;
    });
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
      if (!merchantId) { toast.error('Merchant profile not linked. Please contact support.'); setSaving(false); return; }
      const data: any = { ...form, featured: Boolean(form.featured), merchantId };
      if (!data.originalPrice || data.originalPrice === '') delete data.originalPrice;
      if (!data.discountedPrice || data.discountedPrice === '') delete data.discountedPrice;
      if (!data.url || data.url === '') delete data.url;
      if (editId) { await PromotionAPI.update(editId, data); toast.success('Promotion updated!'); }
      else { await PromotionAPI.create(data); toast.success('Promotion created!'); }
      router.push('/merchant/dashboard');
    } catch (err: any) { 
      toast.error(err.message || 'Failed to save promotion.'); 
    }
    finally { setSaving(false); }
  };

  const TABS = [{ id:'details', icon:'fa-tag', label:'Details' },{ id:'media', icon:'fa-image', label:'Media' },{ id:'settings', icon:'fa-cog', label:'Settings' }];

  // Auto-calculate discounted price when percentage or original price changes
  useEffect(() => {
    if (form.dealType === 'percentage' && form.originalPrice && form.percentageOff) {
      const original = parseFloat(form.originalPrice);
      const percent = parseFloat(form.percentageOff);
      if (!isNaN(original) && !isNaN(percent) && percent > 0 && percent <= 100) {
        const discounted = original * (1 - percent / 100);
        update('discountedPrice', discounted.toFixed(2));
        update('discount', `${percent}%`);
      }
    }
  }, [form.dealType, form.originalPrice, form.percentageOff]);

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
              {imagePreviews[0] ? <img src={imagePreviews[0]} alt="Preview" style={{ width:'100%', height:'100px', objectFit:'cover' }} /> : <div style={{ height:'100px', background:'var(--light-gray)', display:'flex', alignItems:'center', justifyContent:'center' }}><i className="fas fa-image" style={{ fontSize:'1.5rem', color:'var(--text-secondary)' }}></i></div>}
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

                    {/* Deal Type Dropdown */}
                    <div>
                      <label style={labelStyle}>Deal Type <span style={{ color:'#ef4444' }}>*</span></label>
                      <select style={inputStyle} value={form.dealType} onChange={e => { update('dealType', e.target.value); update('discount', ''); update('originalPrice', ''); update('discountedPrice', ''); update('percentageOff', ''); }} onFocus={focus} onBlur={blur}>
                        <option value="percentage">Percentage Discount (e.g., 20% off)</option>
                        <option value="bogo">Buy 1 Get 1 Free</option>
                        <option value="fixed">Fixed Amount Off (e.g., $50 off)</option>
                        <option value="price_drop">Price Drop</option>
                        <option value="bundle">Bundle Deal</option>
                        <option value="flash">Flash Sale</option>
                      </select>
                      <p style={hintStyle}>Select the type of discount you're offering</p>
                    </div>

                    {/* Conditional Fields Based on Deal Type */}
                    {form.dealType === 'percentage' && (
                      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                        <div>
                          <label style={labelStyle}>Original Price <span style={{ color:'#ef4444' }}>*</span></label>
                          <div style={{ position:'relative' }}>
                            <span style={{ position:'absolute', left:'1rem', top:'50%', transform:'translateY(-50%)', color:'var(--text-secondary)', fontWeight:600 }}>{currencySymbol}</span>
                            <input type="number" step="0.01" min="0" style={{ ...inputStyle, paddingLeft:'2rem' }} value={form.originalPrice} onChange={e => update('originalPrice', e.target.value)} placeholder="100.00" onFocus={focus} onBlur={blur} required />
                          </div>
                        </div>
                        <div>
                          <label style={labelStyle}>Discount % <span style={{ color:'#ef4444' }}>*</span></label>
                          <div style={{ position:'relative' }}>
                            <input type="number" step="1" min="1" max="100" style={{ ...inputStyle, paddingRight:'2rem' }} value={form.percentageOff} onChange={e => update('percentageOff', e.target.value)} placeholder="20" onFocus={focus} onBlur={blur} required />
                            <span style={{ position:'absolute', right:'1rem', top:'50%', transform:'translateY(-50%)', color:'var(--text-secondary)', fontWeight:600 }}>%</span>
                          </div>
                        </div>
                        <div>
                          <label style={labelStyle}>Final Price</label>
                          <div style={{ position:'relative' }}>
                            <span style={{ position:'absolute', left:'1rem', top:'50%', transform:'translateY(-50%)', color:'var(--text-secondary)', fontWeight:600 }}>{currencySymbol}</span>
                            <input type="number" step="0.01" min="0" style={{ ...inputStyle, paddingLeft:'2rem', background:'var(--light-gray)', cursor:'not-allowed' }} value={form.discountedPrice} readOnly placeholder="Auto" />
                          </div>
                          <p style={hintStyle}>Calculated automatically</p>
                        </div>
                      </div>
                    )}

                    {form.dealType === 'bogo' && (
                      <div>
                        <label style={labelStyle}>Product Price <span style={{ color:'#ef4444' }}>*</span></label>
                        <div style={{ position:'relative' }}>
                          <span style={{ position:'absolute', left:'1rem', top:'50%', transform:'translateY(-50%)', color:'var(--text-secondary)', fontWeight:600 }}>{currencySymbol}</span>
                          <input type="number" step="0.01" min="0" style={{ ...inputStyle, paddingLeft:'2rem' }} value={form.originalPrice} onChange={e => { update('originalPrice', e.target.value); update('discount', 'Buy 1 Get 1 Free'); }} placeholder="50.00" onFocus={focus} onBlur={blur} required />
                        </div>
                        <p style={hintStyle}>Price of one item</p>
                      </div>
                    )}

                    {form.dealType === 'fixed' && (
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                          <label style={labelStyle}>Original Price</label>
                          <div style={{ position:'relative' }}>
                            <span style={{ position:'absolute', left:'1rem', top:'50%', transform:'translateY(-50%)', color:'var(--text-secondary)', fontWeight:600 }}>{currencySymbol}</span>
                            <input type="number" step="0.01" min="0" style={{ ...inputStyle, paddingLeft:'2rem' }} value={form.originalPrice} onChange={e => update('originalPrice', e.target.value)} placeholder="100.00" onFocus={focus} onBlur={blur} />
                          </div>
                        </div>
                        <div>
                          <label style={labelStyle}>Discount Amount <span style={{ color:'#ef4444' }}>*</span></label>
                          <div style={{ position:'relative' }}>
                            <span style={{ position:'absolute', left:'1rem', top:'50%', transform:'translateY(-50%)', color:'var(--text-secondary)', fontWeight:600 }}>{currencySymbol}</span>
                            <input type="number" step="0.01" min="0" style={{ ...inputStyle, paddingLeft:'2rem' }} value={form.percentageOff} onChange={e => { update('percentageOff', e.target.value); update('discount', `${currencySymbol}${e.target.value} off`); }} placeholder="50" onFocus={focus} onBlur={blur} required />
                          </div>
                          <p style={hintStyle}>Fixed amount off the price</p>
                        </div>
                      </div>
                    )}

                    {form.dealType === 'price_drop' && (
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                          <label style={labelStyle}>Was <span style={{ color:'#ef4444' }}>*</span></label>
                          <div style={{ position:'relative' }}>
                            <span style={{ position:'absolute', left:'1rem', top:'50%', transform:'translateY(-50%)', color:'var(--text-secondary)', fontWeight:600 }}>{currencySymbol}</span>
                            <input type="number" step="0.01" min="0" style={{ ...inputStyle, paddingLeft:'2rem' }} value={form.originalPrice} onChange={e => update('originalPrice', e.target.value)} placeholder="100.00" onFocus={focus} onBlur={blur} required />
                          </div>
                        </div>
                        <div>
                          <label style={labelStyle}>Now <span style={{ color:'#ef4444' }}>*</span></label>
                          <div style={{ position:'relative' }}>
                            <span style={{ position:'absolute', left:'1rem', top:'50%', transform:'translateY(-50%)', color:'var(--text-secondary)', fontWeight:600 }}>{currencySymbol}</span>
                            <input type="number" step="0.01" min="0" style={{ ...inputStyle, paddingLeft:'2rem' }} value={form.discountedPrice} onChange={e => { update('discountedPrice', e.target.value); if (form.originalPrice && e.target.value) { const saved = ((parseFloat(form.originalPrice) - parseFloat(e.target.value)) / parseFloat(form.originalPrice) * 100).toFixed(0); update('discount', `${saved}%`); } }} placeholder="70.00" onFocus={focus} onBlur={blur} required />
                          </div>
                        </div>
                      </div>
                    )}

                    {(form.dealType === 'bundle' || form.dealType === 'flash') && (
                      <div>
                        <label style={labelStyle}>Discount <span style={{ color:'#ef4444' }}>*</span></label>
                        <input style={inputStyle} value={form.discount} onChange={e => update('discount', e.target.value)} required placeholder={form.dealType === 'bundle' ? 'e.g., 3 for $99' : 'e.g., 50% off'} onFocus={focus} onBlur={blur} />
                        <p style={hintStyle}>Describe the {form.dealType === 'bundle' ? 'bundle' : 'flash sale'} offer</p>
                      </div>
                    )}

                    {/* Savings Display */}
                    {form.originalPrice && form.discountedPrice && parseFloat(form.discountedPrice) < parseFloat(form.originalPrice) && (
                      <div className="fade-in" style={{ padding:'1rem', borderRadius:'0.875rem', background:'rgba(16,185,129,0.08)', border:'1px solid rgba(16,185,129,0.2)' }}>
                        <p style={{ margin:0, fontSize:'0.875rem', fontWeight:600, color:'#059669' }}>
                          <i className="fas fa-check-circle mr-2"></i>
                          Customers save {currencySymbol}{(parseFloat(form.originalPrice) - parseFloat(form.discountedPrice)).toFixed(2)} ({Math.round((1 - parseFloat(form.discountedPrice)/parseFloat(form.originalPrice))*100)}% off)
                        </p>
                      </div>
                    )}

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
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
                      <div>
                        <label style={labelStyle}>Category <span style={{ color:'#ef4444' }}>*</span></label>
                        <select style={inputStyle} value={form.category} onChange={e => update('category', e.target.value)} onFocus={focus} onBlur={blur}>
                          {CATS.map(c => <option key={c} value={c}>{c.charAt(0).toUpperCase()+c.slice(1)}</option>)}
                        </select>
                      </div>
                    </div>

                    <div>
                      <label style={labelStyle}>Promotion URL</label>
                      <div style={{ position:'relative' }}>
                        <i className="fas fa-link" style={{ position:'absolute', left:'1rem', top:'50%', transform:'translateY(-50%)', color:'var(--text-secondary)', pointerEvents:'none' }}></i>
                        <input type="url" style={{ ...inputStyle, paddingLeft:'2.5rem' }} value={form.url} onChange={e => update('url', e.target.value)} placeholder="https://yourstore.com/deal" onFocus={focus} onBlur={blur} />
                      </div>
                      <p style={hintStyle}>Customers will be redirected here when they click "Get This Deal"</p>
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



              {/* Media Tab */}
              {activeTab === 'media' && (
                <div className="fade-in">
                  <h2 style={{ fontSize:'1.1rem', fontWeight:700, color:'var(--text-primary)', marginBottom:'0.5rem', display:'flex', alignItems:'center', gap:'0.5rem' }}>
                    <i className="fas fa-images" style={{ color:'var(--primary-color)' }}></i> Promotion Images
                  </h2>
                  <p style={{ ...hintStyle, marginBottom:'1.5rem' }}>Upload up to 5 images (max 5MB each). The first image is used as the main display image.</p>

                  {/* Image grid */}
                  {imagePreviews.length > 0 && (
                    <div style={{ display:'grid', gridTemplateColumns:'repeat(auto-fill, minmax(120px, 1fr))', gap:'0.75rem', marginBottom:'1rem' }}>
                      {imagePreviews.map((src, i) => (
                        <div key={i} style={{ position:'relative', borderRadius:'0.75rem', overflow:'hidden', aspectRatio:'1', border: i === 0 ? '2px solid var(--primary-color)' : '1.5px solid var(--border-color)' }}>
                          <img src={src} alt={`Image ${i+1}`} style={{ width:'100%', height:'100%', objectFit:'cover' }} />
                          {i === 0 && (
                            <div style={{ position:'absolute', top:'0.3rem', left:'0.3rem', background:'var(--primary-color)', color:'#fff', fontSize:'0.6rem', fontWeight:700, padding:'0.15rem 0.4rem', borderRadius:'9999px' }}>MAIN</div>
                          )}
                          <button type="button" onClick={() => removeImage(i)}
                            style={{ position:'absolute', top:'0.3rem', right:'0.3rem', width:'22px', height:'22px', borderRadius:'50%', background:'rgba(239,68,68,0.9)', border:'none', color:'#fff', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', fontSize:'0.65rem' }}>
                            <i className="fas fa-times"></i>
                          </button>
                        </div>
                      ))}
                      {imagePreviews.length < 5 && (
                        <div onClick={() => imageInputRef.current?.click()}
                          style={{ borderRadius:'0.75rem', border:'2px dashed var(--border-color)', aspectRatio:'1', display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', cursor:'pointer', background:'var(--light-gray)', gap:'0.4rem', transition:'border-color 0.2s' }}
                          onMouseEnter={e => (e.currentTarget.style.borderColor = 'var(--primary-color)')}
                          onMouseLeave={e => (e.currentTarget.style.borderColor = 'var(--border-color)')}>
                          <i className="fas fa-plus" style={{ fontSize:'1.25rem', color:'var(--text-secondary)' }}></i>
                          <span style={{ fontSize:'0.7rem', color:'var(--text-secondary)', fontWeight:600 }}>Add</span>
                        </div>
                      )}
                    </div>
                  )}

                  {/* Upload area (shown when no images yet) */}
                  {imagePreviews.length === 0 && (
                    <div onClick={() => imageInputRef.current?.click()}
                      style={{ borderRadius:'1rem', border:'2px dashed var(--border-color)', marginBottom:'1rem', minHeight:'180px', background:'var(--light-gray)', display:'flex', alignItems:'center', justifyContent:'center', cursor:'pointer', transition:'border-color 0.2s' }}
                      onMouseEnter={e => (e.currentTarget.style.borderColor = 'var(--primary-color)')}
                      onMouseLeave={e => (e.currentTarget.style.borderColor = 'var(--border-color)')}>
                      <div className="text-center" style={{ padding:'2rem' }}>
                        <i className="fas fa-cloud-upload-alt" style={{ fontSize:'2.5rem', color:'var(--text-secondary)', marginBottom:'0.75rem', display:'block' }}></i>
                        <p style={{ fontWeight:600, fontSize:'0.9rem', color:'var(--text-primary)', margin:'0 0 0.25rem' }}>Click to upload images</p>
                        <p style={{ fontSize:'0.75rem', color:'var(--text-secondary)', margin:0 }}>PNG, JPG up to 5MB each · Max 5 images</p>
                      </div>
                    </div>
                  )}

                  <input ref={imageInputRef} type="file" accept="image/*" multiple style={{ display:'none' }}
                    onChange={e => e.target.files && handleImageFiles(e.target.files)} />

                  {imagePreviews.length > 0 && (
                    <p style={hintStyle}>{imagePreviews.length}/5 images · Click × to remove · First image is the main image</p>
                  )}

                  <div style={{ display:'flex', alignItems:'center', gap:'0.75rem', margin:'1rem 0 0.75rem' }}>
                    <div style={{ flex:1, height:'1px', background:'var(--border-color)' }}></div>
                    <span style={{ fontSize:'0.8rem', color:'var(--text-secondary)' }}>or paste URL for main image</span>
                    <div style={{ flex:1, height:'1px', background:'var(--border-color)' }}></div>
                  </div>

                  <input style={inputStyle} value={form.image.startsWith('data:') ? '' : form.image}
                    onChange={e => { update('image', e.target.value); if (e.target.value) setImagePreviews(prev => prev.length ? [e.target.value, ...prev.slice(1)] : [e.target.value]); }}
                    placeholder="https://example.com/image.jpg" onFocus={focus} onBlur={blur} />
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
