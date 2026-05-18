'use client';

import { Suspense, useEffect, useMemo, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { BankOfferAPI } from '@/lib/api';
import { PROMOTION_CATEGORIES } from '@/lib/categories';
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

const APPLICABLE_CATEGORIES = PROMOTION_CATEGORIES.filter((category) => category.id !== 'bank_cards');

function AdminBankOfferForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const editId = searchParams.get('edit');
  const [saving, setSaving] = useState(false);

  const today = new Date().toISOString().split('T')[0];
  const nextMonth = new Date();
  nextMonth.setMonth(nextMonth.getMonth() + 1);

  const [form, setForm] = useState({
    title: '',
    description: '',
    discount: '',
    code: '',
    bankName: '',
    offerType: '',
    cardTypes: [] as string[],
    applicableCategories: [] as string[],
    startDate: today,
    endDate: nextMonth.toISOString().split('T')[0],
    minimumSpend: '',
    maximumBenefit: '',
    image: '',
    url: '',
    termsAndConditions: '',
    featured: false,
    priority: '0',
  });

  useEffect(() => {
    if (!editId) return;
    BankOfferAPI.getById(editId)
      .then((offer) => {
        const formatDate = (value?: string) => value ? new Date(value).toISOString().split('T')[0] : today;
        setForm({
          title: offer.title || '',
          description: offer.description || '',
          discount: offer.discount || '',
          code: offer.code || '',
          bankName: offer.bankName || '',
          offerType: offer.offerType || '',
          cardTypes: Array.isArray(offer.cardTypes) ? offer.cardTypes : [],
          applicableCategories: Array.isArray(offer.applicableCategories) ? offer.applicableCategories : [],
          startDate: formatDate(offer.startDate),
          endDate: formatDate(offer.endDate),
          minimumSpend: offer.minimumSpend?.toString() || '',
          maximumBenefit: offer.maximumBenefit?.toString() || '',
          image: offer.image || '',
          url: offer.url || '',
          termsAndConditions: offer.termsAndConditions || '',
          featured: !!offer.featured,
          priority: typeof offer.priority === 'number' ? String(offer.priority) : '0',
        });
      })
      .catch(() => toast.error('Failed to load bank offer.'));
  }, [editId, today]);

  const update = (key: string, value: any) => setForm((prev) => ({ ...prev, [key]: value }));
  const toggleCardType = (value: string) =>
    setForm((prev) => ({
      ...prev,
      cardTypes: prev.cardTypes.includes(value)
        ? prev.cardTypes.filter((entry) => entry !== value)
        : [...prev.cardTypes, value],
    }));
  const toggleCategory = (value: string) =>
    setForm((prev) => ({
      ...prev,
      applicableCategories: prev.applicableCategories.includes(value)
        ? prev.applicableCategories.filter((entry) => entry !== value)
        : [...prev.applicableCategories, value],
    }));

  const daysLeft = useMemo(
    () => Math.ceil((new Date(form.endDate).getTime() - new Date(form.startDate).getTime()) / 86400000),
    [form.endDate, form.startDate]
  );

  const generateCode = () => {
    const code = (form.title.split(' ').map((word) => word[0]).join('').toUpperCase() || 'BANK') + Math.floor(Math.random() * 90 + 10);
    update('code', code);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.title.trim()) return toast.error('Title is required');
    if (!form.description.trim()) return toast.error('Description is required');
    if (!form.discount.trim()) return toast.error('Offer summary is required');
    if (!form.code.trim()) return toast.error('Promo code is required');
    if (!form.bankName.trim()) return toast.error('Bank name is required');
    if (!form.offerType) return toast.error('Offer type is required');
    if (form.cardTypes.length === 0) return toast.error('Select at least one card type');

    setSaving(true);
    try {
      const payload: any = {
        ...form,
        code: form.code.trim().toUpperCase(),
        priority: parseInt(form.priority || '0', 10) || 0,
        featured: Boolean(form.featured),
      };
      if (!payload.minimumSpend) delete payload.minimumSpend;
      if (!payload.maximumBenefit) delete payload.maximumBenefit;
      if (!payload.image) delete payload.image;
      if (!payload.url) delete payload.url;
      if (!payload.termsAndConditions) delete payload.termsAndConditions;

      if (editId) {
        await BankOfferAPI.update(editId, payload);
        toast.success('Bank offer updated!');
      } else {
        await BankOfferAPI.create(payload);
        toast.success('Bank offer created!');
      }
      router.push('/admin/bank-offers');
    } catch (error: any) {
      toast.error(error.message || 'Failed to save bank offer.');
    } finally {
      setSaving(false);
    }
  };

  const inputStyle = { width: '100%', padding: '0.75rem 1rem', borderRadius: '0.75rem', border: '1.5px solid var(--border-color)', background: 'var(--card-bg)', color: 'var(--text-primary)', fontSize: '0.9rem', outline: 'none', boxSizing: 'border-box' as const };
  const labelStyle = { display: 'block', fontSize: '0.85rem', fontWeight: 600 as const, marginBottom: '0.4rem', color: 'var(--text-primary)' };

  return (
    <div className="max-w-3xl mx-auto">
      <div className="flex items-center gap-3 mb-6">
        <button onClick={() => router.push('/admin/bank-offers')} style={{ width: '36px', height: '36px', borderRadius: '50%', border: '1.5px solid var(--border-color)', background: 'var(--card-bg)', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
          <i className="fas fa-arrow-left"></i>
        </button>
        <div>
          <h1 style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--text-primary)', margin: 0 }}>{editId ? 'Edit Bank Offer' : 'New Bank Offer'}</h1>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', margin: 0 }}>Platform-managed bank card campaign, separate from merchant promotions</p>
        </div>
      </div>

      <form onSubmit={handleSubmit}>
        <div className="promotion-card" style={{ padding: '1.75rem', display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          <div>
            <label style={labelStyle}>Title <span style={{ color: '#ef4444' }}>*</span></label>
            <input style={inputStyle} value={form.title} onChange={(e) => update('title', e.target.value)} required placeholder="e.g. HNB 20% Cashback at Dining Partners" />
          </div>

          <div>
            <label style={labelStyle}>Description <span style={{ color: '#ef4444' }}>*</span></label>
            <textarea style={{ ...inputStyle, resize: 'vertical', minHeight: '90px' }} value={form.description} onChange={(e) => update('description', e.target.value)} required placeholder="Describe how the bank offer works..." />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label style={labelStyle}>Offer Summary <span style={{ color: '#ef4444' }}>*</span></label>
              <input style={inputStyle} value={form.discount} onChange={(e) => update('discount', e.target.value)} required placeholder="e.g. 20% cashback up to Rs1500" />
            </div>
            <div>
              <label style={labelStyle}>Promo Code <span style={{ color: '#ef4444' }}>*</span></label>
              <div style={{ position: 'relative' }}>
                <input style={{ ...inputStyle, paddingRight: '4.5rem', textTransform: 'uppercase' }} value={form.code} onChange={(e) => update('code', e.target.value.toUpperCase())} required placeholder="HNB20" />
                <button type="button" onClick={generateCode} style={{ position: 'absolute', right: '0.5rem', top: '50%', transform: 'translateY(-50%)', fontSize: '0.72rem', fontWeight: 600, padding: '0.25rem 0.5rem', borderRadius: '0.375rem', border: '1px solid var(--border-color)', background: 'var(--light-gray)', color: 'var(--text-secondary)', cursor: 'pointer' }}>
                  Auto
                </button>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label style={labelStyle}>Bank Name <span style={{ color: '#ef4444' }}>*</span></label>
              <input style={inputStyle} value={form.bankName} onChange={(e) => update('bankName', e.target.value)} required placeholder="HNB, Sampath, Commercial Bank" />
            </div>
            <div>
              <label style={labelStyle}>Offer Type <span style={{ color: '#ef4444' }}>*</span></label>
              <select style={inputStyle} value={form.offerType} onChange={(e) => update('offerType', e.target.value)} required>
                <option value="">Select offer type</option>
                {BANK_OFFER_TYPES.map((option) => <option key={option.value} value={option.value}>{option.label}</option>)}
              </select>
            </div>
          </div>

          <div>
            <label style={labelStyle}>Eligible Card Types <span style={{ color: '#ef4444' }}>*</span></label>
            <div className="flex flex-wrap gap-2">
              {[
                { value: 'credit', label: 'Credit' },
                { value: 'debit', label: 'Debit' },
                { value: 'prepaid', label: 'Prepaid' },
              ].map((card) => {
                const selected = form.cardTypes.includes(card.value);
                return (
                  <button
                    key={card.value}
                    type="button"
                    onClick={() => toggleCardType(card.value)}
                    style={{ padding: '0.55rem 0.9rem', borderRadius: '9999px', border: `1.5px solid ${selected ? '#0f4c81' : 'var(--border-color)'}`, background: selected ? '#0f4c81' : 'var(--card-bg)', color: selected ? '#fff' : 'var(--text-primary)', fontWeight: 700, cursor: 'pointer', fontSize: '0.82rem' }}
                  >
                    <i className="fas fa-credit-card" style={{ marginRight: '0.45rem' }}></i>{card.label}
                  </button>
                );
              })}
            </div>
          </div>

          <div>
            <label style={labelStyle}>Applicable Categories</label>
            <div className="flex flex-wrap gap-2">
              {APPLICABLE_CATEGORIES.map((category) => {
                const selected = form.applicableCategories.includes(category.id);
                return (
                  <button
                    key={category.id}
                    type="button"
                    onClick={() => toggleCategory(category.id)}
                    style={{ padding: '0.45rem 0.8rem', borderRadius: '9999px', border: `1px solid ${selected ? 'var(--primary-color)' : 'var(--border-color)'}`, background: selected ? 'rgba(37,99,235,0.08)' : 'var(--card-bg)', color: 'var(--text-primary)', cursor: 'pointer', fontSize: '0.8rem' }}
                  >
                    {category.name}
                  </button>
                );
              })}
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label style={labelStyle}>Minimum Spend</label>
              <input type="number" step="0.01" min="0" style={inputStyle} value={form.minimumSpend} onChange={(e) => update('minimumSpend', e.target.value)} placeholder="5000" />
            </div>
            <div>
              <label style={labelStyle}>Maximum Benefit</label>
              <input type="number" step="0.01" min="0" style={inputStyle} value={form.maximumBenefit} onChange={(e) => update('maximumBenefit', e.target.value)} placeholder="1500" />
            </div>
            <div>
              <label style={labelStyle}>Priority</label>
              <input type="number" step="1" style={inputStyle} value={form.priority} onChange={(e) => update('priority', e.target.value)} placeholder="0" />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label style={labelStyle}>Start Date</label>
              <input type="date" style={inputStyle} value={form.startDate} onChange={(e) => update('startDate', e.target.value)} />
            </div>
            <div>
              <label style={labelStyle}>End Date</label>
              <input type="date" style={inputStyle} value={form.endDate} onChange={(e) => update('endDate', e.target.value)} min={form.startDate} />
              {daysLeft > 0 && <p style={{ fontSize: '0.75rem', color: '#10b981', marginTop: '0.3rem' }}>{daysLeft} days active</p>}
            </div>
          </div>

          <div>
            <label style={labelStyle}>Terms & Conditions</label>
            <textarea style={{ ...inputStyle, resize: 'vertical', minHeight: '100px' }} value={form.termsAndConditions} onChange={(e) => update('termsAndConditions', e.target.value)} placeholder="Add any bank-specific terms, exclusions, and redemption rules." />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label style={labelStyle}>Image URL</label>
              <input style={inputStyle} value={form.image} onChange={(e) => update('image', e.target.value)} placeholder="https://example.com/bank-offer.jpg" />
            </div>
            <div>
              <label style={labelStyle}>Landing URL</label>
              <input style={inputStyle} value={form.url} onChange={(e) => update('url', e.target.value)} placeholder="https://bank.example.com/offer" />
            </div>
          </div>

          <label style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', cursor: 'pointer', padding: '0.875rem 1rem', borderRadius: '0.75rem', border: `1.5px solid ${form.featured ? 'var(--primary-color)' : 'var(--border-color)'}`, background: form.featured ? 'rgba(99,102,241,0.04)' : 'transparent' }}>
            <input type="checkbox" checked={form.featured} onChange={(e) => update('featured', e.target.checked)} style={{ width: '18px', height: '18px', accentColor: 'var(--primary-color)', cursor: 'pointer' }} />
            <div>
              <span style={{ fontWeight: 700, fontSize: '0.875rem', color: 'var(--text-primary)' }}>⭐ Feature this bank offer</span>
              <p style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', margin: 0 }}>Highlights this campaign in platform-managed surfaces</p>
            </div>
          </label>

          <div className="flex justify-end gap-3 pt-2">
            <button type="button" onClick={() => router.push('/admin/bank-offers')} style={{ padding: '0.7rem 1.5rem', borderRadius: '0.625rem', border: '1.5px solid var(--border-color)', background: 'var(--card-bg)', color: 'var(--text-secondary)', fontWeight: 600, cursor: 'pointer' }}>
              Cancel
            </button>
            <button type="submit" disabled={saving} className="btn btn-primary" style={{ padding: '0.7rem 1.75rem' }}>
              {saving ? <><i className="fas fa-spinner fa-spin"></i> Saving...</> : <><i className="fas fa-credit-card"></i> {editId ? 'Update Bank Offer' : 'Create Bank Offer'}</>}
            </button>
          </div>
        </div>
      </form>
    </div>
  );
}

export default function AdminBankOfferNewPage() {
  return (
    <Suspense fallback={<div className="max-w-3xl mx-auto"><div className="skeleton-card" style={{ height: '520px' }}></div></div>}>
      <AdminBankOfferForm />
    </Suspense>
  );
}
