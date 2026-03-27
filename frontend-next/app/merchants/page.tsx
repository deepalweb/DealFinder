'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { MerchantAPI } from '@/lib/api';
import SkeletonCard from '@/components/ui/SkeletonCard';

const CATEGORIES = [
  { id: 'all', name: 'All', icon: 'fa-th-large' },
  { id: 'fashion', name: 'Fashion', icon: 'fa-tshirt' },
  { id: 'electronics', name: 'Electronics', icon: 'fa-laptop' },
  { id: 'food', name: 'Food', icon: 'fa-utensils' },
  { id: 'travel', name: 'Travel', icon: 'fa-plane' },
  { id: 'health', name: 'Health', icon: 'fa-heart-pulse' },
  { id: 'entertainment', name: 'Entertainment', icon: 'fa-gamepad' },
  { id: 'home', name: 'Home', icon: 'fa-home' },
];

const CAT_ICONS: Record<string, string> = { fashion: 'fa-tshirt', electronics: 'fa-laptop', travel: 'fa-plane', health: 'fa-heart-pulse', entertainment: 'fa-gamepad', home: 'fa-home', pets: 'fa-paw', food: 'fa-utensils' };

export default function MerchantsPage() {
  const [merchants, setMerchants] = useState<any[]>([]);
  const [filtered, setFiltered] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCat, setSelectedCat] = useState('all');

  useEffect(() => {
    MerchantAPI.getAll().then(data => { setMerchants(data); setFiltered(data); }).finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    let result = [...merchants];
    if (selectedCat !== 'all') result = result.filter(m => m.category === selectedCat);
    if (searchTerm) { const t = searchTerm.toLowerCase(); result = result.filter(m => m.name?.toLowerCase().includes(t) || m.description?.toLowerCase().includes(t)); }
    setFiltered(result);
  }, [merchants, searchTerm, selectedCat]);

  const getSafeLogo = (logo: string, name: string) => {
    if (logo && (logo.startsWith('data:image') || logo.startsWith('http'))) return logo;
    return `https://ui-avatars.com/api/?name=${encodeURIComponent(name || 'M')}&background=random&size=300`;
  };

  return (
    <div>
      <div style={{ background: 'linear-gradient(135deg, #6366f1 0%, #8b5cf6 50%, #f43f5e 100%)', padding: '4rem 0 3rem' }}>
        <div className="max-w-7xl mx-auto px-4 text-center text-white">
          <div className="inline-flex items-center gap-2 mb-4" style={{ background: 'rgba(255,255,255,0.2)', borderRadius: '9999px', padding: '0.375rem 1rem', fontSize: '0.875rem', fontWeight: 500 }}>
            <i className="fas fa-store"></i> {merchants.length} stores available
          </div>
          <h1 style={{ fontSize: 'clamp(2rem,5vw,3.5rem)', fontWeight: 800, letterSpacing: '-0.03em', lineHeight: 1.1, marginBottom: '1rem' }}>Discover Your<br />Favorite Stores</h1>
          <p style={{ fontSize: '1.1rem', opacity: 0.9, maxWidth: '480px', margin: '0 auto 2rem' }}>Follow merchants to get personalized deal recommendations.</p>
          <div style={{ position: 'relative', maxWidth: '520px', margin: '0 auto' }}>
            <i className="fas fa-search" style={{ position: 'absolute', left: '1.1rem', top: '50%', transform: 'translateY(-50%)', color: 'rgba(255,255,255,0.7)', pointerEvents: 'none' }}></i>
            <input type="text" placeholder="Search stores..." value={searchTerm} onChange={e => setSearchTerm(e.target.value)}
              style={{ width: '100%', padding: '0.875rem 3rem', border: '2px solid rgba(255,255,255,0.3)', borderRadius: '9999px', fontSize: '1rem', background: 'rgba(255,255,255,0.15)', color: '#fff', backdropFilter: 'blur(8px)', outline: 'none', boxSizing: 'border-box' }} />
            {searchTerm && <button onClick={() => setSearchTerm('')} style={{ position: 'absolute', right: '1.1rem', top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', color: 'rgba(255,255,255,0.7)', cursor: 'pointer' }}><i className="fas fa-times"></i></button>}
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 py-8">
        <div className="flex gap-2 overflow-x-auto pb-2 mb-8" style={{ scrollbarWidth: 'none' }}>
          {CATEGORIES.map(cat => (
            <button key={cat.id} onClick={() => setSelectedCat(cat.id)} className={`category-item ${selectedCat === cat.id ? 'active' : ''}`} style={{ flexShrink: 0 }}>
              <i className={`fas ${cat.icon}`}></i> {cat.name}
            </button>
          ))}
        </div>

        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {Array.from({ length: 6 }).map((_, i) => <SkeletonCard key={i} />)}
          </div>
        ) : filtered.length === 0 ? (
          <div className="text-center py-16">
            <div style={{ fontSize: '3rem', marginBottom: '1rem' }}>🏪</div>
            <h2 style={{ fontWeight: 700, marginBottom: '0.5rem' }}>No stores found</h2>
            <p style={{ color: 'var(--text-secondary)' }}>Try a different search or category</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filtered.map(m => (
              <div key={m._id || m.id} className="promotion-card fade-in" style={{ padding: '1.25rem' }}>
                <div className="flex items-center gap-3 mb-3">
                  <img src={getSafeLogo(m.logo, m.name)} alt={m.name} style={{ width: '56px', height: '56px', borderRadius: '50%', objectFit: 'cover', border: '2px solid var(--border-color)', flexShrink: 0 }}
                    onError={(e: any) => { e.target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(m.name)}&background=random&size=300`; }} />
                  <div>
                    <h2 style={{ fontWeight: 700, fontSize: '1rem', color: 'var(--text-primary)', margin: 0 }}>{m.name}</h2>
                    <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                      <i className={`fas ${CAT_ICONS[m.category] || 'fa-store'}`}></i>
                      <span>{m.category ? m.category.charAt(0).toUpperCase() + m.category.slice(1) : 'Other'}</span>
                      <span>•</span>
                      <span>{typeof m.followers === 'number' ? m.followers.toLocaleString() : '0'} followers</span>
                    </div>
                  </div>
                </div>
                <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', marginBottom: '1rem', lineHeight: 1.5 }}>{m.description || `${m.name} offers great deals.`}</p>
                <div className="flex items-center justify-between">
                  <span style={{ fontSize: '0.8rem', fontWeight: 600, color: 'var(--primary-color)' }}><i className="fas fa-tag mr-1"></i>{m.activeDeals || 0} active deals</span>
                  <Link href={`/merchants/${m._id || m.id}`} className="btn btn-primary" style={{ fontSize: '0.8rem', padding: '0.4rem 1rem' }}>Visit Store</Link>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
