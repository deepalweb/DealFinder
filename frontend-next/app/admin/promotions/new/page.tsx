'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { MerchantAPI, PromotionAPI } from '@/lib/api';
import { PROMOTION_CATEGORIES, normalizeCategoryId } from '@/lib/categories';
import toast from 'react-hot-toast';

const BANK_OFFER_TYPES = [
  { value: 'discount', label: 'Discount' },
  { value: 'cashback', label: 'Cashback' },
  { value: 'installment', label: 'Installment' },
  { value: 'dining', label: 'Dining' },
  { value: 'grocery', label: 'Grocery' },
  { value: 'fuel', label: 'Fuel' },
  { value: 'travel', label: 'Travel' },
  { value: 'electronics', label: 'Electronics' },
  { value: 'online', label: 'Online' },
  { value: 'other', label: 'Other' },
] as const;

export default function AdminNewDealPage() {
  const router = useRouter();
  const [merchants, setMerchants] = useState<any[]>([]);
  const [saving, setSaving] = useState(false);

  const today = new Date().toISOString().split('T')[0];
  const nextMonth = new Date(); nextMonth.setMonth(nextMonth.getMonth() + 1);

  const [form, setForm] = useState({
    merchantId: '',
    title: '',
    description: '',
    discount: '',
    code: '',
    category: 'food',
    startDate: today,
    endDate: nextMonth.toISOString().split('T')[0],
    image: '',
    url: '',
    originalPrice: '',
    discountedPrice: '',
    featured: false,
    bankName: '',
    cardTypes: [] as string[],
    offerType: '',
    minimumSpend: '',
    maximumBenefit: '',
  });
  const isBankCardCategory = normalizeCategoryId(form.category) === 'bank_cards';

  useEffect(() => {
    MerchantAPI.getAll()
      .then(data => setMerchants(data.filter((m: any) => m.status === 'active')))
      .catch(() => toast.error('Failed to load merchants.'));
  }, []);

  const update = (k: string, v: any) => setForm(prev => ({ ...prev, [k]: v }));
  const toggleCardType = (value: string) =>
    setForm((prev) => ({
      ...prev,
      cardTypes: prev.cardTypes.includes(value)
        ? prev.cardTypes.filter((entry) => entry !== value)
        : [...prev.cardTypes, value],
    }));

  const generateCode = () => {
    const code = (form.title.split(' ').map((w: string) => w[0]).join('').toUpperCase() || 'DEAL') + Math.floor(Math.random() * 90 + 10);
    update('code', code);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.merchantId) { toast.error('Please select a merchant'); return; }
    if (!form.title.trim()) { toast.error('Title is required'); return; }
    if (!form.discount.trim()) { toast.error('Discount is required'); return; }
    if (!form.code.trim()) { toast.error('Promo code is required'); return; }
    if (isBankCardCategory && !form.bankName.trim()) { toast.error('Bank name is required'); return; }
    if (isBankCardCategory && !form.offerType) { toast.error('Offer type is required'); return; }
    if (isBankCardCategory && form.cardTypes.length === 0) { toast.error('Select at least one card type'); return; }
    if (form.originalPrice && form.discountedPrice && parseFloat(form.discountedPrice) >= parseFloat(form.originalPrice)) {
      toast.error('Discounted price must be less than original price'); return;
    }
    setSaving(true);
    try {
      const data: any = {
        ...form,
        featured: Boolean(form.featured),
        status: 'active',
      };
      if (!data.originalPrice) delete data.originalPrice;
      if (!data.discountedPrice) delete data.discountedPrice;
      if (!data.url) delete data.url;
      if (!data.image) delete data.image;
      if (!isBankCardCategory) {
        delete data.bankName;
        delete data.cardTypes;
        delete data.offerType;
        delete data.minimumSpend;
        delete data.maximumBenefit;
      } else {
        if (!data.minimumSpend) delete data.minimumSpend;
        if (!data.maximumBenefit) delete data.maximumBenefit;
      }
      await PromotionAPI.create(data);
      toast.success('Deal created and set live!');
      router.push('/admin/promotions');
    } catch (err: any) {
      toast.error(err.message || 'Failed to create deal.');
    } finally {
      setSaving(false);
    }
  };

  const inputStyle = { width: '100%', padding: '0.75rem 1rem', borderRadius: '0.75rem', border: '1.5px solid var(--border-color)', background: 'var(--card-bg)', color: 'var(--text-primary)', fontSize: '0.9rem', outline: 'none', boxSizing: 'border-box' as const };
  const labelStyle = { display: 'block', fontSize: '0.85rem', fontWeight: 600 as const, marginBottom: '0.4rem', color: 'var(--text-primary)' };

  const daysLeft = form.endDate ? Math.ceil((new Date(form.endDate).getTime() - new Date(form.startDate).getTime()) / 86400000) : 0;

  return (
    <div className="max-w-2xl mx-auto">
      <div className="flex items-center gap-3 mb-6">
        <button onClick={() => router.back()} style={{ width: '36px', height: '36px', borderRadius: '50%', border: '1.5px solid var(--border-color)', background: 'var(--card-bg)', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
          <i className="fas fa-arrow-left"></i>
        </button>
        <div>
          <h1 style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--text-primary)', margin: 0 }}>Quick Add Deal</h1>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', margin: 0 }}>Creates deal as <strong>Active</strong> immediately — no approval needed</p>
        </div>
      </div>

      <form onSubmit={handleSubmit}>
        <div className="promotion-card" style={{ padding: '1.75rem', display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>

          {/* Merchant */}
          <div>
            <label style={labelStyle}>Merchant <span style={{ color: '#ef4444' }}>*</span></label>
            <select style={inputStyle} value={form.merchantId} onChange={e => update('merchantId', e.target.value)} required>
              <option value="">— Select a merchant —</option>
              {merchants.map(m => (
                <option key={m._id} value={m._id}>{m.name}</option>
              ))}
            </select>
          </div>

          {/* Title */}
          <div>
            <label style={labelStyle}>Title <span style={{ color: '#ef4444' }}>*</span></label>
            <input style={inputStyle} value={form.title} onChange={e => update('title', e.target.value)} required placeholder="e.g. 20% Off All Burgers" />
          </div>

          {/* Description */}
          <div>
            <label style={labelStyle}>Description <span style={{ color: '#ef4444' }}>*</span></label>
            <textarea style={{ ...inputStyle, resize: 'vertical', minHeight: '80px' }} value={form.description} onChange={e => update('description', e.target.value)} required placeholder="What does the customer get?" />
          </div>

          {/* Discount + Code */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label style={labelStyle}>{isBankCardCategory ? 'Offer Summary' : 'Discount'} <span style={{ color: '#ef4444' }}>*</span></label>
              <input
                style={inputStyle}
                value={form.discount}
                onChange={e => update('discount', e.target.value)}
                required
                placeholder={isBankCardCategory ? 'e.g. 20% cashback up to Rs1500' : '20%, Rs.500, BOGO'}
              />
              {isBankCardCategory && (
                <p style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', marginTop: '0.3rem' }}>
                  Bank card promotions use this summary instead of a generic deal type.
                </p>
              )}
            </div>
            <div>
              <label style={labelStyle}>Promo Code <span style={{ color: '#ef4444' }}>*</span></label>
              <div style={{ position: 'relative' }}>
                <input style={{ ...inputStyle, paddingRight: '4.5rem', textTransform: 'uppercase' }} value={form.code} onChange={e => update('code', e.target.value.toUpperCase())} required placeholder="SAVE20" />
                <button type="button" onClick={generateCode} style={{ position: 'absolute', right: '0.5rem', top: '50%', transform: 'translateY(-50%)', fontSize: '0.72rem', fontWeight: 600, padding: '0.25rem 0.5rem', borderRadius: '0.375rem', border: '1px solid var(--border-color)', background: 'var(--light-gray)', color: 'var(--text-secondary)', cursor: 'pointer' }}>
                  Auto
                </button>
              </div>
            </div>
          </div>

          {/* Category */}
          <div>
            <label style={labelStyle}>Category</label>
            <select style={inputStyle} value={form.category} onChange={e => update('category', e.target.value)}>
              {PROMOTION_CATEGORIES.map(category => <option key={category.id} value={category.id}>{category.name}</option>)}
            </select>
          </div>

          {isBankCardCategory && (
            <div style={{ padding: '1rem', borderRadius: '1rem', background: 'rgba(15,76,129,0.04)', border: '1px solid rgba(15,76,129,0.14)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', marginBottom: '1rem' }}>
                <div style={{ width: '36px', height: '36px', borderRadius: '0.75rem', background: 'rgba(15,76,129,0.12)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#0f4c81' }}>
                  <i className="fas fa-credit-card"></i>
                </div>
                <div>
                  <div style={{ fontWeight: 800, color: 'var(--text-primary)' }}>Bank Card Offer Details</div>
                  <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>Add the structured fields used by mobile and web card-offer views.</div>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label style={labelStyle}>Bank Name <span style={{ color: '#ef4444' }}>*</span></label>
                  <input style={inputStyle} value={form.bankName} onChange={e => update('bankName', e.target.value)} placeholder="HNB, Sampath, Commercial Bank" />
                </div>
                <div>
                  <label style={labelStyle}>Offer Type <span style={{ color: '#ef4444' }}>*</span></label>
                  <select style={inputStyle} value={form.offerType} onChange={e => update('offerType', e.target.value)}>
                    <option value="">Select offer type</option>
                    {BANK_OFFER_TYPES.map(option => <option key={option.value} value={option.value}>{option.label}</option>)}
                  </select>
                </div>
              </div>

              <div style={{ marginTop: '1rem' }}>
                <label style={labelStyle}>Eligible Card Types <span style={{ color: '#ef4444' }}>*</span></label>
                <div className="flex flex-wrap gap-2">
                  {[
                    { value: 'credit', label: 'Credit' },
                    { value: 'debit', label: 'Debit' },
                    { value: 'prepaid', label: 'Prepaid' },
                  ].map(card => {
                    const selected = form.cardTypes.includes(card.value);
                    return (
                      <button
                        key={card.value}
                        type="button"
                        onClick={() => toggleCardType(card.value)}
                        style={{
                          padding: '0.55rem 0.9rem',
                          borderRadius: '9999px',
                          border: `1.5px solid ${selected ? '#0f4c81' : 'var(--border-color)'}`,
                          background: selected ? '#0f4c81' : 'var(--card-bg)',
                          color: selected ? '#fff' : 'var(--text-primary)',
                          fontWeight: 700,
                          cursor: 'pointer',
                          fontSize: '0.82rem',
                        }}
                      >
                        <i className="fas fa-credit-card" style={{ marginRight: '0.45rem' }}></i>{card.label}
                      </button>
                    );
                  })}
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4" style={{ marginTop: '1rem' }}>
                <div>
                  <label style={labelStyle}>Minimum Spend</label>
                  <input type="number" step="0.01" min="0" style={inputStyle} value={form.minimumSpend} onChange={e => update('minimumSpend', e.target.value)} placeholder="5000" />
                </div>
                <div>
                  <label style={labelStyle}>Maximum Benefit</label>
                  <input type="number" step="0.01" min="0" style={inputStyle} value={form.maximumBenefit} onChange={e => update('maximumBenefit', e.target.value)} placeholder="2500" />
                </div>
              </div>
            </div>
          )}

          {/* Dates */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label style={labelStyle}>Start Date</label>
              <input type="date" style={inputStyle} value={form.startDate} onChange={e => update('startDate', e.target.value)} />
            </div>
            <div>
              <label style={labelStyle}>End Date</label>
              <input type="date" style={inputStyle} value={form.endDate} onChange={e => update('endDate', e.target.value)} min={form.startDate} />
              {daysLeft > 0 && <p style={{ fontSize: '0.75rem', color: '#10b981', marginTop: '0.3rem' }}><i className="fas fa-check-circle mr-1"></i>{daysLeft} days active</p>}
            </div>
          </div>

          {/* Prices */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label style={labelStyle}>Original Price (optional)</label>
              <input type="number" step="0.01" min="0" style={inputStyle} value={form.originalPrice} onChange={e => update('originalPrice', e.target.value)} placeholder="1000.00" />
            </div>
            <div>
              <label style={labelStyle}>Discounted Price (optional)</label>
              <input type="number" step="0.01" min="0" style={inputStyle} value={form.discountedPrice} onChange={e => update('discountedPrice', e.target.value)} placeholder="800.00" />
            </div>
          </div>

          {/* Image URL */}
          <div>
            <label style={labelStyle}>Image URL (optional)</label>
            <input style={inputStyle} value={form.image} onChange={e => update('image', e.target.value)} placeholder="https://example.com/image.jpg" />
          </div>

          {/* Deal URL */}
          <div>
            <label style={labelStyle}>Deal URL (optional)</label>
            <input style={inputStyle} value={form.url} onChange={e => update('url', e.target.value)} placeholder="https://merchant.com/deal" />
          </div>

          {/* Featured */}
          <label style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', cursor: 'pointer', padding: '0.875rem 1rem', borderRadius: '0.75rem', border: `1.5px solid ${form.featured ? 'var(--primary-color)' : 'var(--border-color)'}`, background: form.featured ? 'rgba(99,102,241,0.04)' : 'transparent' }}>
            <input type="checkbox" checked={form.featured} onChange={e => update('featured', e.target.checked)} style={{ width: '18px', height: '18px', accentColor: 'var(--primary-color)', cursor: 'pointer' }} />
            <div>
              <span style={{ fontWeight: 700, fontSize: '0.875rem', color: 'var(--text-primary)' }}>⭐ Feature this deal</span>
              <p style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', margin: 0 }}>Shows on homepage hero section</p>
            </div>
          </label>

          {/* Submit */}
          <div className="flex justify-end gap-3 pt-2">
            <button type="button" onClick={() => router.back()} style={{ padding: '0.7rem 1.5rem', borderRadius: '0.625rem', border: '1.5px solid var(--border-color)', background: 'var(--card-bg)', color: 'var(--text-secondary)', fontWeight: 600, cursor: 'pointer' }}>
              Cancel
            </button>
            <button type="submit" disabled={saving} className="btn btn-primary" style={{ padding: '0.7rem 1.75rem' }}>
              {saving ? <><i className="fas fa-spinner fa-spin"></i> Creating...</> : <><i className="fas fa-bolt"></i> Create & Go Live</>}
            </button>
          </div>
        </div>
      </form>
    </div>
  );
}
