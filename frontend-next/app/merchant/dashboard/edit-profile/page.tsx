'use client';

import { useState, useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { MerchantAPI } from '@/lib/api';
import toast from 'react-hot-toast';

import MapPicker from '@/components/ui/MapPicker';

const TABS = [
  { id: 'basic', icon: 'fa-store', label: 'Basic Info' },
  { id: 'contact', icon: 'fa-phone', label: 'Contact' },
  { id: 'social', icon: 'fa-share-alt', label: 'Social Media' },
  { id: 'branding', icon: 'fa-image', label: 'Branding' },
  { id: 'location', icon: 'fa-map-marker-alt', label: 'Location' },
];

const SOCIAL_PLATFORMS = [
  { key: 'facebook', icon: 'fa-facebook-f', color: '#1877f2', label: 'Facebook', placeholder: 'your.page' },
  { key: 'instagram', icon: 'fa-instagram', color: '#e1306c', label: 'Instagram', placeholder: '@yourhandle' },
  { key: 'twitter', icon: 'fa-twitter', color: '#1da1f2', label: 'Twitter / X', placeholder: '@yourhandle' },
  { key: 'tiktok', icon: 'fa-tiktok', color: '#010101', label: 'TikTok', placeholder: '@yourhandle' },
];

const CATEGORIES = ['fashion','electronics','travel','health','entertainment','home','pets','food','education','other'];

export default function EditProfilePage() {
  const { user } = useAuth();
  const router = useRouter();
  const logoInputRef = useRef<HTMLInputElement>(null);
  const bannerInputRef = useRef<HTMLInputElement>(null);

  const [activeTab, setActiveTab] = useState('basic');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [hasChanges, setHasChanges] = useState(false);
  const [originalData, setOriginalData] = useState<any>(null);

  const [form, setForm] = useState({
    name: '',
    profile: '',
    category: '',
    website: '',
    contactInfo: '',
    contactNumber: '',
    address: '',
    logo: '',
    banner: '',
    socialMedia: { facebook: '', instagram: '', twitter: '', tiktok: '' },
    location: null as { lat: number; lng: number } | null,
  });

  useEffect(() => {
    if (!user) { router.push('/login'); return; }
    if (user.role !== 'merchant') { router.push('/'); return; }
    MerchantAPI.getById(user.merchantId!).then(m => {
      const data = {
        name: m.name || '',
        profile: m.profile || '',
        category: m.category || '',
        website: m.website || '',
        contactInfo: m.contactInfo || '',
        contactNumber: m.contactNumber || '',
        address: m.address || '',
        logo: m.logo || '',
        banner: m.banner || '',
        socialMedia: { facebook: m.socialMedia?.facebook || '', instagram: m.socialMedia?.instagram || '', twitter: m.socialMedia?.twitter || '', tiktok: m.socialMedia?.tiktok || '' },
        location: m.location?.coordinates ? { lat: m.location.coordinates[1], lng: m.location.coordinates[0] } : null,
      };
      setForm(data);
      setOriginalData(data);
    }).catch(() => toast.error('Failed to load profile.')).finally(() => setLoading(false));
  }, [user]);

  // Track unsaved changes
  useEffect(() => {
    if (!originalData) return;
    setHasChanges(JSON.stringify(form) !== JSON.stringify(originalData));
  }, [form, originalData]);

  const updateForm = (key: string, value: any) => setForm(prev => ({ ...prev, [key]: value }));
  const updateSocial = (key: string, value: string) => setForm(prev => ({ ...prev, socialMedia: { ...prev.socialMedia, [key]: value } }));

  const handleImageFile = (file: File, field: 'logo' | 'banner') => {
    if (file.size > 2 * 1024 * 1024) { toast.error('Image must be under 2MB'); return; }
    const reader = new FileReader();
    reader.onloadend = () => updateForm(field, reader.result as string);
    reader.readAsDataURL(file);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.name.trim()) { toast.error('Business name is required'); setActiveTab('basic'); return; }
    setSaving(true);
    try {
      await MerchantAPI.update(user!.merchantId!, {
        ...form,
        location: form.location ? { type: 'Point', coordinates: [form.location.lng, form.location.lat] } : null,
      });
      setOriginalData({ ...form });
      setHasChanges(false);
      toast.success('Profile updated successfully!');
      router.push('/merchant/dashboard');
    } catch (err: any) {
      toast.error(err.message || 'Failed to update profile.');
    } finally {
      setSaving(false);
    }
  };

  const inputStyle = {
    width: '100%', padding: '0.75rem 1rem', borderRadius: '0.75rem',
    border: '1.5px solid var(--border-color)', background: 'var(--card-bg)',
    color: 'var(--text-primary)', fontSize: '0.9rem', outline: 'none',
    boxSizing: 'border-box' as const, transition: 'border-color 0.2s',
  };

  const labelStyle = {
    display: 'block', fontSize: '0.85rem', fontWeight: 600 as const,
    marginBottom: '0.4rem', color: 'var(--text-primary)',
  };

  const hintStyle = { fontSize: '0.75rem', color: 'var(--text-secondary)', marginTop: '0.3rem' };

  const getSafeLogo = (url: string, name: string) =>
    url && (url.startsWith('data:') || url.startsWith('http'))
      ? url : `https://ui-avatars.com/api/?name=${encodeURIComponent(name || 'M')}&background=random&size=300`;

  if (loading) return (
    <div className="max-w-4xl mx-auto px-4 py-8">
      <div className="skeleton mb-4" style={{ height: '40px', width: '200px' }}></div>
      <div className="skeleton-card" style={{ height: '500px' }}></div>
    </div>
  );

  return (
    <div className="max-w-4xl mx-auto px-4 py-8">
      {/* Page Header */}
      <div className="flex items-center justify-between mb-6 flex-wrap gap-3">
        <div className="flex items-center gap-3">
          <button onClick={() => router.push('/merchant/dashboard')}
            style={{ width: '36px', height: '36px', borderRadius: '50%', border: '1.5px solid var(--border-color)', background: 'var(--card-bg)', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
            <i className="fas fa-arrow-left"></i>
          </button>
          <div>
            <h1 style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--text-primary)', margin: 0, letterSpacing: '-0.02em' }}>Edit Store Profile</h1>
            <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', margin: 0 }}>Update your store information and branding</p>
          </div>
        </div>

        {/* Unsaved changes indicator */}
        {hasChanges && (
          <div className="flex items-center gap-2 fade-in" style={{ padding: '0.4rem 0.875rem', borderRadius: '9999px', background: 'rgba(245,158,11,0.1)', border: '1px solid rgba(245,158,11,0.3)' }}>
            <div style={{ width: '6px', height: '6px', borderRadius: '50%', background: '#f59e0b' }}></div>
            <span style={{ fontSize: '0.8rem', fontWeight: 600, color: '#d97706' }}>Unsaved changes</span>
          </div>
        )}
      </div>

      <form onSubmit={handleSubmit}>
        <div className="flex flex-col md:flex-row gap-6">
          {/* Sidebar Tabs */}
          <div style={{ width: '100%', maxWidth: '200px', flexShrink: 0 }}>
            <div className="promotion-card" style={{ padding: '0.5rem' }}>
              {TABS.map(tab => (
                <button key={tab.id} type="button" onClick={() => setActiveTab(tab.id)}
                  style={{
                    display: 'flex', alignItems: 'center', gap: '0.625rem', width: '100%',
                    padding: '0.75rem 1rem', borderRadius: '0.625rem', border: 'none', cursor: 'pointer',
                    fontSize: '0.875rem', fontWeight: 600, textAlign: 'left', transition: 'all 0.15s',
                    background: activeTab === tab.id ? 'linear-gradient(135deg,var(--primary-color),var(--primary-dark))' : 'transparent',
                    color: activeTab === tab.id ? '#fff' : 'var(--text-secondary)',
                    marginBottom: '0.125rem',
                  }}>
                  <i className={`fas ${tab.icon}`} style={{ width: '16px', textAlign: 'center' }}></i>
                  {tab.label}
                </button>
              ))}
            </div>

            {/* Store preview card */}
            <div className="promotion-card mt-4" style={{ padding: '1rem', textAlign: 'center' }}>
              <img src={getSafeLogo(form.logo, form.name)} alt="Logo preview"
                style={{ width: '64px', height: '64px', borderRadius: '50%', objectFit: 'cover', border: '3px solid var(--primary-color)', margin: '0 auto 0.75rem' }}
                onError={(e: any) => { e.target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(form.name || 'M')}&background=random&size=300`; }} />
              <p style={{ fontWeight: 700, fontSize: '0.9rem', color: 'var(--text-primary)', margin: '0 0 0.25rem' }}>{form.name || 'Your Store'}</p>
              <p style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', margin: 0 }}>{form.category || 'Category'}</p>
            </div>
          </div>

          {/* Tab Content */}
          <div style={{ flex: 1 }}>
            <div className="promotion-card" style={{ padding: '1.75rem' }}>

              {/* Basic Info */}
              {activeTab === 'basic' && (
                <div className="fade-in">
                  <h2 style={{ fontSize: '1.1rem', fontWeight: 700, color: 'var(--text-primary)', marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <i className="fas fa-store" style={{ color: 'var(--primary-color)' }}></i> Basic Information
                  </h2>
                  <div className="flex flex-col gap-4">
                    <div>
                      <label style={labelStyle}>Business Name <span style={{ color: '#ef4444' }}>*</span></label>
                      <input style={inputStyle} value={form.name} onChange={e => updateForm('name', e.target.value)} required placeholder="Your Store Name"
                        onFocus={e => (e.target.style.borderColor = 'var(--primary-color)')} onBlur={e => (e.target.style.borderColor = 'var(--border-color)')} />
                    </div>
                    <div>
                      <label style={labelStyle}>Category</label>
                      <select style={inputStyle} value={form.category} onChange={e => updateForm('category', e.target.value)}>
                        <option value="">Select a category</option>
                        {CATEGORIES.map(c => <option key={c} value={c}>{c.charAt(0).toUpperCase() + c.slice(1)}</option>)}
                      </select>
                    </div>
                    <div>
                      <label style={labelStyle}>Store Description</label>
                      <textarea style={{ ...inputStyle, resize: 'vertical', minHeight: '120px' }} value={form.profile} onChange={e => updateForm('profile', e.target.value)}
                        placeholder="Tell customers about your store, what you sell, and what makes you special..."
                        onFocus={e => (e.target.style.borderColor = 'var(--primary-color)')} onBlur={e => (e.target.style.borderColor = 'var(--border-color)')}></textarea>
                      <p style={hintStyle}>{form.profile.length}/500 characters</p>
                    </div>
                    <div>
                      <label style={labelStyle}>Website</label>
                      <div style={{ position: 'relative' }}>
                        <i className="fas fa-globe" style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-secondary)', pointerEvents: 'none' }}></i>
                        <input type="url" style={{ ...inputStyle, paddingLeft: '2.5rem' }} value={form.website} onChange={e => updateForm('website', e.target.value)}
                          placeholder="https://yourstore.com"
                          onFocus={e => (e.target.style.borderColor = 'var(--primary-color)')} onBlur={e => (e.target.style.borderColor = 'var(--border-color)')} />
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* Contact */}
              {activeTab === 'contact' && (
                <div className="fade-in">
                  <h2 style={{ fontSize: '1.1rem', fontWeight: 700, color: 'var(--text-primary)', marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <i className="fas fa-phone" style={{ color: 'var(--primary-color)' }}></i> Contact Information
                  </h2>
                  <div className="flex flex-col gap-4">
                    <div>
                      <label style={labelStyle}>Contact Email</label>
                      <div style={{ position: 'relative' }}>
                        <i className="fas fa-envelope" style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-secondary)', pointerEvents: 'none' }}></i>
                        <input type="email" style={{ ...inputStyle, paddingLeft: '2.5rem' }} value={form.contactInfo} onChange={e => updateForm('contactInfo', e.target.value)}
                          placeholder="contact@yourstore.com"
                          onFocus={e => (e.target.style.borderColor = 'var(--primary-color)')} onBlur={e => (e.target.style.borderColor = 'var(--border-color)')} />
                      </div>
                    </div>
                    <div>
                      <label style={labelStyle}>Phone Number</label>
                      <div style={{ position: 'relative' }}>
                        <i className="fas fa-phone" style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-secondary)', pointerEvents: 'none' }}></i>
                        <input type="tel" style={{ ...inputStyle, paddingLeft: '2.5rem' }} value={form.contactNumber} onChange={e => updateForm('contactNumber', e.target.value)}
                          placeholder="+1 (555) 000-0000"
                          onFocus={e => (e.target.style.borderColor = 'var(--primary-color)')} onBlur={e => (e.target.style.borderColor = 'var(--border-color)')} />
                      </div>
                    </div>
                    <div>
                      <label style={labelStyle}>Store Address</label>
                      <div style={{ position: 'relative' }}>
                        <i className="fas fa-map-marker-alt" style={{ position: 'absolute', left: '1rem', top: '1rem', color: 'var(--text-secondary)', pointerEvents: 'none' }}></i>
                        <textarea style={{ ...inputStyle, paddingLeft: '2.5rem', resize: 'vertical', minHeight: '80px' }} value={form.address} onChange={e => updateForm('address', e.target.value)}
                          placeholder="123 Main Street, City, Country"
                          onFocus={e => (e.target.style.borderColor = 'var(--primary-color)')} onBlur={e => (e.target.style.borderColor = 'var(--border-color)')}></textarea>
                      </div>
                      <p style={hintStyle}>This address will be shown on your store profile</p>
                    </div>
                  </div>
                </div>
              )}

              {/* Social Media */}
              {activeTab === 'social' && (
                <div className="fade-in">
                  <h2 style={{ fontSize: '1.1rem', fontWeight: 700, color: 'var(--text-primary)', marginBottom: '0.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <i className="fas fa-share-alt" style={{ color: 'var(--primary-color)' }}></i> Social Media
                  </h2>
                  <p style={{ ...hintStyle, marginBottom: '1.5rem' }}>Connect your social media accounts to let customers follow you</p>
                  <div className="flex flex-col gap-4">
                    {SOCIAL_PLATFORMS.map(p => (
                      <div key={p.key}>
                        <label style={labelStyle}>{p.label}</label>
                        <div style={{ position: 'relative' }}>
                          <div style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', width: '28px', height: '28px', borderRadius: '50%', background: p.color, display: 'flex', alignItems: 'center', justifyContent: 'center', pointerEvents: 'none' }}>
                            <i className={`fab ${p.icon}`} style={{ color: '#fff', fontSize: '0.75rem' }}></i>
                          </div>
                          <input style={{ ...inputStyle, paddingLeft: '3.25rem' }} value={(form.socialMedia as any)[p.key]}
                            onChange={e => updateSocial(p.key, e.target.value)} placeholder={p.placeholder}
                            onFocus={e => (e.target.style.borderColor = p.color)} onBlur={e => (e.target.style.borderColor = 'var(--border-color)')} />
                        </div>
                        {(form.socialMedia as any)[p.key] && (
                          <p style={{ ...hintStyle, color: 'var(--primary-color)' }}>
                            <i className="fas fa-check-circle mr-1"></i> Connected
                          </p>
                        )}
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Branding */}
              {activeTab === 'branding' && (
                <div className="fade-in">
                  <h2 style={{ fontSize: '1.1rem', fontWeight: 700, color: 'var(--text-primary)', marginBottom: '0.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <i className="fas fa-image" style={{ color: 'var(--primary-color)' }}></i> Branding
                  </h2>
                  <p style={{ ...hintStyle, marginBottom: '1.5rem' }}>Upload your store logo and banner image</p>

                  {/* Logo */}
                  <div style={{ marginBottom: '2rem' }}>
                    <label style={labelStyle}>Store Logo</label>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '1.25rem', padding: '1.25rem', borderRadius: '1rem', border: '2px dashed var(--border-color)', background: 'var(--light-gray)', marginBottom: '0.75rem' }}>
                      <img src={getSafeLogo(form.logo, form.name)} alt="Logo"
                        style={{ width: '72px', height: '72px', borderRadius: '50%', objectFit: 'cover', border: '3px solid var(--primary-color)', flexShrink: 0 }}
                        onError={(e: any) => { e.target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(form.name || 'M')}&background=random&size=300`; }} />
                      <div className="flex-1">
                        <p style={{ fontWeight: 600, fontSize: '0.875rem', color: 'var(--text-primary)', marginBottom: '0.5rem' }}>Upload a logo</p>
                        <p style={hintStyle}>PNG, JPG up to 2MB. Recommended: 400×400px</p>
                        <div className="flex gap-2 mt-3">
                          <button type="button" onClick={() => logoInputRef.current?.click()} className="btn" style={{ fontSize: '0.8rem', padding: '0.4rem 0.875rem', border: '1.5px solid var(--border-color)', background: 'var(--card-bg)', color: 'var(--text-primary)' }}>
                            <i className="fas fa-upload"></i> Upload File
                          </button>
                          {form.logo && <button type="button" onClick={() => updateForm('logo', '')} style={{ fontSize: '0.8rem', padding: '0.4rem 0.875rem', borderRadius: '0.625rem', border: '1.5px solid rgba(239,68,68,0.3)', background: 'rgba(239,68,68,0.06)', color: '#ef4444', cursor: 'pointer' }}>Remove</button>}
                        </div>
                        <input ref={logoInputRef} type="file" accept="image/*" style={{ display: 'none' }} onChange={e => e.target.files?.[0] && handleImageFile(e.target.files[0], 'logo')} />
                      </div>
                    </div>
                    <input style={inputStyle} value={form.logo} onChange={e => updateForm('logo', e.target.value)} placeholder="Or paste image URL: https://..."
                      onFocus={e => (e.target.style.borderColor = 'var(--primary-color)')} onBlur={e => (e.target.style.borderColor = 'var(--border-color)')} />
                    <p style={hintStyle}>You can upload a file or paste a URL</p>
                  </div>

                  {/* Banner */}
                  <div>
                    <label style={labelStyle}>Store Banner</label>
                    <div style={{ borderRadius: '1rem', overflow: 'hidden', border: '2px dashed var(--border-color)', marginBottom: '0.75rem', position: 'relative', minHeight: '140px', background: form.banner ? `url(${form.banner}) center/cover` : 'var(--light-gray)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      {!form.banner && (
                        <div className="text-center" style={{ padding: '2rem' }}>
                          <i className="fas fa-image" style={{ fontSize: '2rem', color: 'var(--text-secondary)', marginBottom: '0.5rem', display: 'block' }}></i>
                          <p style={{ fontSize: '0.875rem', color: 'var(--text-secondary)', margin: 0 }}>No banner set</p>
                        </div>
                      )}
                      {form.banner && <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.3)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}></div>}
                      <div style={{ position: 'absolute', bottom: '0.75rem', right: '0.75rem', display: 'flex', gap: '0.5rem' }}>
                        <button type="button" onClick={() => bannerInputRef.current?.click()} className="btn" style={{ fontSize: '0.8rem', padding: '0.4rem 0.875rem', background: 'rgba(255,255,255,0.9)', color: 'var(--text-primary)', border: 'none' }}>
                          <i className="fas fa-upload"></i> Upload
                        </button>
                        {form.banner && <button type="button" onClick={() => updateForm('banner', '')} style={{ fontSize: '0.8rem', padding: '0.4rem 0.875rem', borderRadius: '0.625rem', background: 'rgba(239,68,68,0.9)', color: '#fff', border: 'none', cursor: 'pointer' }}>Remove</button>}
                      </div>
                      <input ref={bannerInputRef} type="file" accept="image/*" style={{ display: 'none' }} onChange={e => e.target.files?.[0] && handleImageFile(e.target.files[0], 'banner')} />
                    </div>
                    <input style={inputStyle} value={form.banner} onChange={e => updateForm('banner', e.target.value)} placeholder="Or paste banner URL: https://..."
                      onFocus={e => (e.target.style.borderColor = 'var(--primary-color)')} onBlur={e => (e.target.style.borderColor = 'var(--border-color)')} />
                    <p style={hintStyle}>Recommended: 1200×400px. This appears at the top of your store page.</p>
                  </div>
                </div>
              )}

              {/* Location */}
              {activeTab === 'location' && (
                <div className="fade-in">
                  <h2 style={{ fontSize: '1.1rem', fontWeight: 700, color: 'var(--text-primary)', marginBottom: '0.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <i className="fas fa-map-marker-alt" style={{ color: 'var(--primary-color)' }}></i> Store Location
                  </h2>
                  <p style={{ ...hintStyle, marginBottom: '1.25rem' }}>Pin your store on the map so customers can find nearby deals. Click anywhere on the map or drag the marker to set your location.</p>

                  {form.location && (
                    <div style={{ padding: '0.75rem 1rem', borderRadius: '0.75rem', background: 'rgba(16,185,129,0.08)', border: '1px solid rgba(16,185,129,0.2)', marginBottom: '1rem', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                      <span style={{ fontSize: '0.85rem', color: '#059669', fontWeight: 600 }}>
                        <i className="fas fa-check-circle mr-2"></i>
                        {form.location.lat.toFixed(6)}, {form.location.lng.toFixed(6)}
                      </span>
                      <button type="button" onClick={() => updateForm('location', null)}
                        style={{ fontSize: '0.75rem', padding: '0.25rem 0.625rem', borderRadius: '0.375rem', border: '1px solid rgba(239,68,68,0.3)', background: 'rgba(239,68,68,0.06)', color: '#ef4444', cursor: 'pointer' }}>
                        <i className="fas fa-times mr-1"></i>Clear
                      </button>
                    </div>
                  )}

                  <button type="button" onClick={() => {
                    if (!navigator.geolocation) { toast.error('Geolocation not supported'); return; }
                    navigator.geolocation.getCurrentPosition(
                      ({ coords }) => updateForm('location', { lat: coords.latitude, lng: coords.longitude }),
                      () => toast.error('Could not get your location')
                    );
                  }} className="btn" style={{ marginBottom: '1rem', border: '1.5px solid var(--border-color)', background: 'var(--card-bg)', color: 'var(--text-primary)', fontSize: '0.85rem' }}>
                    <i className="fas fa-location-arrow" style={{ color: 'var(--primary-color)' }}></i> Use My Current Location
                  </button>

                  <MapPicker
                    lat={form.location?.lat ?? null}
                    lng={form.location?.lng ?? null}
                    onChange={(lat, lng) => updateForm('location', { lat, lng })}
                    height="360px"
                  />
                  <p style={{ ...hintStyle, marginTop: '0.5rem' }}>Click on the map to place your store marker, or drag it to adjust.</p>
                </div>
              )}
            </div>

            {/* Tab navigation + Save */}
            <div className="flex items-center justify-between mt-4 flex-wrap gap-3">
              <div className="flex gap-2">
                {TABS.findIndex(t => t.id === activeTab) > 0 && (
                  <button type="button" onClick={() => setActiveTab(TABS[TABS.findIndex(t => t.id === activeTab) - 1].id)}
                    className="btn" style={{ border: '1.5px solid var(--border-color)', background: 'var(--card-bg)', color: 'var(--text-secondary)' }}>
                    <i className="fas fa-arrow-left"></i> Previous
                  </button>
                )}
                {TABS.findIndex(t => t.id === activeTab) < TABS.length - 1 && (
                  <button type="button" onClick={() => setActiveTab(TABS[TABS.findIndex(t => t.id === activeTab) + 1].id)}
                    className="btn" style={{ border: '1.5px solid var(--border-color)', background: 'var(--card-bg)', color: 'var(--text-secondary)' }}>
                    Next <i className="fas fa-arrow-right"></i>
                  </button>
                )}
              </div>

              <div className="flex gap-3">
                <button type="button" onClick={() => router.push('/merchant/dashboard')}
                  style={{ padding: '0.6rem 1.25rem', borderRadius: '0.625rem', border: '1.5px solid var(--border-color)', background: 'var(--card-bg)', color: 'var(--text-secondary)', fontWeight: 600, cursor: 'pointer', fontSize: '0.875rem' }}>
                  Cancel
                </button>
                <button type="submit" disabled={saving || !hasChanges} className="btn btn-primary"
                  style={{ opacity: !hasChanges ? 0.6 : 1, cursor: !hasChanges ? 'not-allowed' : 'pointer' }}>
                  {saving ? <><i className="fas fa-spinner fa-spin"></i> Saving...</> : <><i className="fas fa-save"></i> Save Changes</>}
                </button>
              </div>
            </div>
          </div>
        </div>
      </form>
    </div>
  );
}
