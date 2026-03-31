'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { PromotionAPI } from '@/lib/api';
import PromotionCard from '@/components/ui/PromotionCard';
import SkeletonCard from '@/components/ui/SkeletonCard';

import HeroSection from '@/components/ui/HeroSection';

const CATEGORIES = [
  { id: 'all', name: 'All Deals', icon: 'fa-th-large' },
  { id: 'fashion', name: 'Fashion', icon: 'fa-tshirt' },
  { id: 'electronics', name: 'Electronics', icon: 'fa-laptop' },
  { id: 'food', name: 'Food', icon: 'fa-utensils' },
  { id: 'travel', name: 'Travel', icon: 'fa-plane' },
  { id: 'health', name: 'Health', icon: 'fa-heart-pulse' },
  { id: 'entertainment', name: 'Entertainment', icon: 'fa-gamepad' },
  { id: 'home', name: 'Home', icon: 'fa-home' },
];

export default function CategoryPage() {
  const { categoryId } = useParams<{ categoryId: string }>();
  const router = useRouter();
  const [promotions, setPromotions] = useState<any[]>([]);
  const [filtered, setFiltered] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState('newest');
  const [activeOnly, setActiveOnly] = useState(true);

  const currentCat = CATEGORIES.find(c => c.id === categoryId) || { name: 'All Deals', icon: 'fa-tag' };

  useEffect(() => {
    PromotionAPI.getAll().then(data => {
      setPromotions(data);
    }).finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    let result = [...promotions];
    if (categoryId !== 'all') result = result.filter(p => p.category === categoryId);
    if (activeOnly) result = result.filter(p => new Date(p.endDate) >= new Date());
    if (searchTerm) {
      const t = searchTerm.toLowerCase();
      result = result.filter(p => p.title?.toLowerCase().includes(t) || p.description?.toLowerCase().includes(t));
    }
    if (sortBy === 'newest') result.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
    else if (sortBy === 'ending-soon') result.sort((a, b) => new Date(a.endDate).getTime() - new Date(b.endDate).getTime());
    setFiltered(result);
  }, [promotions, categoryId, searchTerm, sortBy, activeOnly]);

  return (
    <div>
      <HeroSection
        icon={currentCat.icon}
        title={currentCat.name}
        subtitle={loading ? 'Loading...' : `${filtered.length} deals found`}
      />

      <div className="max-w-7xl mx-auto px-4 py-8">
        {/* Category pills */}
        <div className="flex gap-2 overflow-x-auto pb-2 mb-6" style={{ scrollbarWidth: 'none' }}>
          {CATEGORIES.map(cat => (
            <button key={cat.id} onClick={() => router.push(`/categories/${cat.id}`)}
              className={`category-item ${categoryId === cat.id ? 'active' : ''}`} style={{ flexShrink: 0 }}>
              <i className={`fas ${cat.icon}`}></i> {cat.name}
            </button>
          ))}
        </div>

        {/* Filters */}
        <div className="flex flex-col md:flex-row md:items-center gap-3 mb-6">
          <div style={{ position: 'relative', flex: 1, maxWidth: '400px' }}>
            <i className="fas fa-search" style={{ position: 'absolute', left: '0.875rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-secondary)', pointerEvents: 'none' }}></i>
            <input type="text" placeholder="Search deals..." value={searchTerm} onChange={e => setSearchTerm(e.target.value)}
              style={{ width: '100%', padding: '0.625rem 2.5rem', border: '1.5px solid var(--border-color)', borderRadius: '9999px', background: 'var(--card-bg)', color: 'var(--text-primary)', fontSize: '0.875rem', outline: 'none', boxSizing: 'border-box' }} />
            {searchTerm && <button onClick={() => setSearchTerm('')} style={{ position: 'absolute', right: '0.875rem', top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer' }}><i className="fas fa-times"></i></button>}
          </div>
          <div className="flex items-center gap-3">
            <select value={sortBy} onChange={e => setSortBy(e.target.value)}
              style={{ padding: '0.5rem 0.875rem', border: '1.5px solid var(--border-color)', borderRadius: '0.5rem', background: 'var(--card-bg)', color: 'var(--text-primary)', fontSize: '0.85rem', cursor: 'pointer' }}>
              <option value="newest">Newest</option>
              <option value="ending-soon">Ending Soon</option>
            </select>
            <button onClick={() => setActiveOnly(!activeOnly)}
              style={{ padding: '0.5rem 0.875rem', borderRadius: '0.5rem', fontSize: '0.85rem', fontWeight: 600, cursor: 'pointer', border: '1.5px solid', borderColor: activeOnly ? 'var(--primary-color)' : 'var(--border-color)', background: activeOnly ? 'rgba(99,102,241,0.08)' : 'var(--card-bg)', color: activeOnly ? 'var(--primary-color)' : 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
              <i className={`fas ${activeOnly ? 'fa-toggle-on' : 'fa-toggle-off'}`}></i> Active only
            </button>
          </div>
        </div>

        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {Array.from({ length: 8 }).map((_, i) => <SkeletonCard key={i} />)}
          </div>
        ) : filtered.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {filtered.map(p => <PromotionCard key={p._id || p.id} promotion={p} />)}
          </div>
        ) : (
          <div className="text-center py-16">
            <div style={{ fontSize: '3rem', marginBottom: '1rem' }}>🔍</div>
            <h2 style={{ fontWeight: 700, marginBottom: '0.5rem' }}>No deals found</h2>
            <p style={{ color: 'var(--text-secondary)', marginBottom: '1.5rem' }}>{searchTerm ? 'Try different keywords' : 'No active deals in this category'}</p>
            {activeOnly && <button className="btn btn-primary" onClick={() => setActiveOnly(false)}>Show Expired Deals</button>}
          </div>
        )}
      </div>
    </div>
  );
}
