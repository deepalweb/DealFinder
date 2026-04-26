'use client';

import { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { MerchantAPI } from '@/lib/api';
import SkeletonCard from '@/components/ui/SkeletonCard';
import HeroSection from '@/components/ui/HeroSection';

type Merchant = {
  _id?: string;
  id?: string;
  name?: string;
  description?: string;
  category?: string;
  logo?: string;
  activeDeals?: number;
  followers?: number;
  website?: string;
};

const CATEGORIES = [
  { id: 'all', name: 'All Stores', icon: 'fa-layer-group' },
  { id: 'fashion', name: 'Fashion', icon: 'fa-shirt' },
  { id: 'electronics', name: 'Electronics', icon: 'fa-laptop' },
  { id: 'food', name: 'Food', icon: 'fa-utensils' },
  { id: 'travel', name: 'Travel', icon: 'fa-plane' },
  { id: 'health', name: 'Health', icon: 'fa-heart-pulse' },
  { id: 'entertainment', name: 'Entertainment', icon: 'fa-gamepad' },
  { id: 'home', name: 'Home', icon: 'fa-house' },
];

const SORT_OPTIONS = [
  { id: 'most-deals', label: 'Most Deals' },
  { id: 'most-followed', label: 'Most Followed' },
  { id: 'a-z', label: 'Name A-Z' },
];

const CAT_ICONS: Record<string, string> = {
  fashion: 'fa-shirt',
  electronics: 'fa-laptop',
  travel: 'fa-plane',
  health: 'fa-heart-pulse',
  entertainment: 'fa-gamepad',
  home: 'fa-house',
  pets: 'fa-paw',
  food: 'fa-utensils',
};

function getMerchantId(merchant: Merchant) {
  return merchant._id || merchant.id || '';
}

function getSafeLogo(logo?: string, name?: string) {
  if (logo && (logo.startsWith('data:image') || logo.startsWith('http'))) return logo;
  return `https://ui-avatars.com/api/?name=${encodeURIComponent(name || 'M')}&background=random&size=300`;
}

function getCategoryLabel(category?: string) {
  if (!category) return 'Other';
  return category.charAt(0).toUpperCase() + category.slice(1);
}

export default function MerchantsPage() {
  const [merchants, setMerchants] = useState<Merchant[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCat, setSelectedCat] = useState('all');
  const [sortBy, setSortBy] = useState('most-deals');

  useEffect(() => {
    MerchantAPI.getAll()
      .then((data) => setMerchants(Array.isArray(data) ? data : []))
      .finally(() => setLoading(false));
  }, []);

  const categoryCounts = useMemo(() => {
    const counts = new Map<string, number>();

    for (const merchant of merchants) {
      const key = merchant.category || 'other';
      counts.set(key, (counts.get(key) || 0) + 1);
    }

    return counts;
  }, [merchants]);

  const filtered = useMemo(() => {
    let result = [...merchants];

    if (selectedCat !== 'all') {
      result = result.filter((merchant) => merchant.category === selectedCat);
    }

    if (searchTerm.trim()) {
      const term = searchTerm.trim().toLowerCase();
      result = result.filter((merchant) =>
        merchant.name?.toLowerCase().includes(term) ||
        merchant.description?.toLowerCase().includes(term) ||
        merchant.category?.toLowerCase().includes(term)
      );
    }

    if (sortBy === 'most-deals') {
      result.sort((a, b) => (b.activeDeals || 0) - (a.activeDeals || 0));
    } else if (sortBy === 'most-followed') {
      result.sort((a, b) => (b.followers || 0) - (a.followers || 0));
    } else if (sortBy === 'a-z') {
      result.sort((a, b) => (a.name || '').localeCompare(b.name || ''));
    }

    return result;
  }, [merchants, searchTerm, selectedCat, sortBy]);

  const spotlightMerchants = useMemo(
    () => [...merchants].sort((a, b) => ((b.activeDeals || 0) + (b.followers || 0) / 100) - ((a.activeDeals || 0) + (a.followers || 0) / 100)).slice(0, 3),
    [merchants]
  );

  const stats = useMemo(() => {
    const totalDeals = merchants.reduce((sum, merchant) => sum + (merchant.activeDeals || 0), 0);
    const totalFollowers = merchants.reduce((sum, merchant) => sum + (merchant.followers || 0), 0);

    return [
      { label: 'Stores', value: merchants.length },
      { label: 'Active deals', value: totalDeals },
      { label: 'Followers', value: totalFollowers.toLocaleString() },
    ];
  }, [merchants]);

  return (
    <div>
      <HeroSection
        icon="fa-store"
        title="Stores Worth"
        titleAccent="Checking First"
        subtitle="Find the merchants with the strongest live offers, clearer category signals, and faster paths to the deals that matter."
        bgImage="https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1600&auto=format&fit=crop&q=60"
        gradient="linear-gradient(135deg, rgba(8,17,33,0.96) 0%, rgba(29,78,216,0.9) 54%, rgba(245,158,11,0.8) 100%)"
        minHeight="320px"
      >
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))',
            gap: '0.85rem',
            maxWidth: '48rem',
            margin: '0 auto 1rem',
          }}
        >
          {stats.map((stat) => (
            <div
              key={stat.label}
              style={{
                padding: '0.9rem 1rem',
                borderRadius: '1rem',
                background: 'rgba(255,255,255,0.12)',
                border: '1px solid rgba(255,255,255,0.16)',
                backdropFilter: 'blur(10px)',
              }}
            >
              <div style={{ fontSize: '1.35rem', fontWeight: 900 }}>{loading ? '--' : stat.value}</div>
              <div style={{ fontSize: '0.82rem', opacity: 0.82 }}>{stat.label}</div>
            </div>
          ))}
        </div>

        <div style={{ position: 'relative', maxWidth: '540px', margin: '0 auto' }}>
          <i
            className="fas fa-search"
            style={{
              position: 'absolute',
              left: '1.1rem',
              top: '50%',
              transform: 'translateY(-50%)',
              color: 'rgba(255,255,255,0.7)',
              pointerEvents: 'none',
            }}
          ></i>
          <input
            type="text"
            placeholder="Search stores, categories, or merchant types..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            style={{
              width: '100%',
              padding: '0.95rem 3rem',
              border: '2px solid rgba(255,255,255,0.25)',
              borderRadius: '9999px',
              fontSize: '1rem',
              background: 'rgba(255,255,255,0.14)',
              color: '#fff',
              backdropFilter: 'blur(8px)',
              outline: 'none',
              boxSizing: 'border-box',
            }}
          />
          {searchTerm ? (
            <button
              onClick={() => setSearchTerm('')}
              style={{
                position: 'absolute',
                right: '1.1rem',
                top: '50%',
                transform: 'translateY(-50%)',
                background: 'none',
                border: 'none',
                color: 'rgba(255,255,255,0.7)',
                cursor: 'pointer',
              }}
            >
              <i className="fas fa-times"></i>
            </button>
          ) : null}
        </div>
      </HeroSection>

      <div className="max-w-7xl mx-auto px-4" style={{ marginTop: '-2rem', position: 'relative', zIndex: 2 }}>
        <div
          className="surface-panel panel-pad"
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
            gap: '1rem',
          }}
        >
          <div>
            <div className="page-eyebrow">
              <i className="fas fa-store"></i>
              Store discovery
            </div>
            <div style={{ marginTop: '0.9rem', fontSize: '1.15rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              {loading ? 'Loading stores...' : `${filtered.length} store${filtered.length === 1 ? '' : 's'} in view`}
            </div>
            <p style={{ margin: '0.45rem 0 0', color: 'var(--text-secondary)', lineHeight: 1.6 }}>
              Filter by category, rank by deal density or audience, and jump into merchants that are active right now.
            </p>
          </div>
          <div className="stat-tile" style={{ padding: '1rem 1.1rem' }}>
            <div style={{ fontSize: '0.8rem', fontWeight: 700, textTransform: 'uppercase', color: 'var(--primary-color)' }}>
              Leading category
            </div>
            <div style={{ marginTop: '0.35rem', fontSize: '1.35rem', fontWeight: 800 }}>
              {loading ? '--' : selectedCat === 'all' ? 'All stores' : getCategoryLabel(selectedCat)}
            </div>
            <div style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
              {loading ? '--' : selectedCat === 'all' ? 'Every merchant category visible' : `${categoryCounts.get(selectedCat) || 0} stores in this category`}
            </div>
          </div>
          <div className="stat-tile" style={{ padding: '1rem 1.1rem' }}>
            <div style={{ fontSize: '0.8rem', fontWeight: 700, textTransform: 'uppercase', color: 'var(--highlight-color)' }}>
              Sorting by
            </div>
            <div style={{ marginTop: '0.35rem', fontSize: '1.35rem', fontWeight: 800 }}>
              {SORT_OPTIONS.find((option) => option.id === sortBy)?.label || 'Most Deals'}
            </div>
            <div style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
              Bring the most useful merchants to the top first
            </div>
          </div>
        </div>
      </div>

      <div className="page-shell">
        <div className="surface-panel panel-pad" style={{ marginBottom: '1.5rem' }}>
          <div className="glass-toolbar">
            <div className="toolbar-grow input-with-icon" style={{ minWidth: 0 }}>
              <i className="fas fa-search"></i>
              <input
                type="text"
                placeholder="Search stores, descriptions, or categories"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="modern-input"
              />
            </div>
            <div style={{ minWidth: '180px', flex: '0 1 220px' }}>
              <select value={sortBy} onChange={(e) => setSortBy(e.target.value)} className="modern-select">
                {SORT_OPTIONS.map((option) => (
                  <option key={option.id} value={option.id}>
                    {option.label}
                  </option>
                ))}
              </select>
            </div>
            <button
              onClick={() => {
                setSearchTerm('');
                setSelectedCat('all');
                setSortBy('most-deals');
              }}
              className="btn"
              style={{
                background: 'transparent',
                color: 'var(--text-secondary)',
                border: '1px solid var(--border-color)',
                padding: '0.8rem 1rem',
              }}
            >
              <i className="fas fa-rotate-left"></i>
              Reset
            </button>
          </div>

          <div
            style={{
              display: 'flex',
              flexWrap: 'wrap',
              gap: '0.6rem',
              marginTop: '1rem',
              alignItems: 'center',
            }}
          >
            <span style={{ fontSize: '0.82rem', color: 'var(--text-secondary)', fontWeight: 700, textTransform: 'uppercase' }}>
              Active filters
            </span>
            <span className="status-chip" style={{ background: 'rgba(37,99,235,0.08)', color: 'var(--primary-color)' }}>
              <i className="fas fa-layer-group"></i>
              {selectedCat === 'all' ? 'All stores' : getCategoryLabel(selectedCat)}
            </span>
            <span className="status-chip" style={{ background: 'rgba(245,158,11,0.1)', color: 'var(--warning-color)' }}>
              <i className="fas fa-arrow-down-wide-short"></i>
              {SORT_OPTIONS.find((option) => option.id === sortBy)?.label}
            </span>
            {searchTerm ? (
              <span className="status-chip" style={{ background: 'rgba(37,99,235,0.08)', color: 'var(--primary-color)' }}>
                <i className="fas fa-search"></i>
                {searchTerm}
              </span>
            ) : null}
          </div>
        </div>

        <div className="flex gap-2 overflow-x-auto pb-2 mb-8" style={{ scrollbarWidth: 'none' }}>
          {CATEGORIES.map((cat) => (
            <button
              key={cat.id}
              onClick={() => setSelectedCat(cat.id)}
              className={`category-item ${selectedCat === cat.id ? 'active' : ''}`}
              style={{ flexShrink: 0 }}
            >
              <i className={`fas ${cat.icon}`}></i>
              {cat.name}
              <span
                style={{
                  marginLeft: '0.2rem',
                  padding: '0.15rem 0.45rem',
                  borderRadius: '999px',
                  background: selectedCat === cat.id ? 'rgba(255,255,255,0.2)' : 'rgba(37,99,235,0.08)',
                  color: selectedCat === cat.id ? '#fff' : 'var(--primary-color)',
                  fontSize: '0.72rem',
                  fontWeight: 700,
                }}
              >
                {cat.id === 'all' ? merchants.length : categoryCounts.get(cat.id) || 0}
              </span>
            </button>
          ))}
        </div>

        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
            {Array.from({ length: 6 }).map((_, i) => <SkeletonCard key={i} />)}
          </div>
        ) : filtered.length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon"><i className="fas fa-store-slash"></i></div>
            <h2 style={{ fontWeight: 800, marginBottom: '0.5rem', color: 'var(--text-primary)' }}>No stores found</h2>
            <p style={{ color: 'var(--text-secondary)', maxWidth: '34rem', margin: '0 auto 1.2rem', lineHeight: 1.7 }}>
              Try a broader search or jump back to all categories. The goal here is to make good merchants easier to spot, not hide them.
            </p>
            <button
              onClick={() => {
                setSearchTerm('');
                setSelectedCat('all');
                setSortBy('most-deals');
              }}
              className="btn btn-primary"
            >
              Reset Store Filters
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-10">
            {spotlightMerchants.length > 0 ? (
              <section>
                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'end',
                    gap: '1rem',
                    marginBottom: '1.4rem',
                    flexWrap: 'wrap',
                  }}
                >
                  <div>
                    <div style={{ color: 'var(--highlight-color)', fontSize: '0.82rem', fontWeight: 800, textTransform: 'uppercase' }}>
                      Spotlight
                    </div>
                    <h2 className="section-title" style={{ marginBottom: 0 }}>
                      <i className="fas fa-star" style={{ color: 'var(--highlight-color)' }}></i>
                      Stores Getting Attention
                    </h2>
                  </div>
                  <div style={{ color: 'var(--text-secondary)', fontSize: '0.92rem' }}>
                    Strong deal activity and follower momentum
                  </div>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                  {spotlightMerchants.map((merchant, index) => (
                    <Link
                      key={getMerchantId(merchant)}
                      href={`/merchants/${getMerchantId(merchant)}`}
                      className="surface-panel panel-pad"
                      style={{ textDecoration: 'none', color: 'inherit' }}
                    >
                      <div className="page-eyebrow" style={{ marginBottom: '1rem' }}>
                        <i className="fas fa-ranking-star"></i>
                        Top {index + 1}
                      </div>
                      <div className="flex items-center gap-3 mb-3">
                        <div style={{ width: '64px', height: '64px', position: 'relative', flexShrink: 0 }}>
                          <Image
                          src={getSafeLogo(merchant.logo, merchant.name)}
                          alt={merchant.name || 'Merchant logo'}
                          fill
                          sizes="64px"
                          style={{ borderRadius: '1rem', objectFit: 'cover', border: '2px solid var(--border-color)' }}
                        />
                        </div>
                        <div>
                          <h3 style={{ fontWeight: 800, fontSize: '1.02rem', color: 'var(--text-primary)', margin: 0 }}>
                            {merchant.name}
                          </h3>
                          <div style={{ fontSize: '0.82rem', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '0.35rem', marginTop: '0.35rem', flexWrap: 'wrap' }}>
                            <i className={`fas ${CAT_ICONS[merchant.category || ''] || 'fa-store'}`}></i>
                            <span>{getCategoryLabel(merchant.category)}</span>
                          </div>
                        </div>
                      </div>
                      <p style={{ fontSize: '0.88rem', color: 'var(--text-secondary)', lineHeight: 1.6, margin: 0 }}>
                        {merchant.description || `${merchant.name} is running live offers worth checking right now.`}
                      </p>
                      <div className="grid grid-cols-2 gap-3" style={{ marginTop: '1rem' }}>
                        <div className="stat-tile" style={{ padding: '0.9rem' }}>
                          <div style={{ fontSize: '1.15rem', fontWeight: 900 }}>{merchant.activeDeals || 0}</div>
                          <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>Active deals</div>
                        </div>
                        <div className="stat-tile" style={{ padding: '0.9rem' }}>
                          <div style={{ fontSize: '1.15rem', fontWeight: 900 }}>{typeof merchant.followers === 'number' ? merchant.followers.toLocaleString() : '0'}</div>
                          <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>Followers</div>
                        </div>
                      </div>
                    </Link>
                  ))}
                </div>
              </section>
            ) : null}

            <section>
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'end',
                  gap: '1rem',
                  marginBottom: '1.4rem',
                  flexWrap: 'wrap',
                }}
              >
                <div>
                  <div style={{ color: 'var(--primary-color)', fontSize: '0.82rem', fontWeight: 800, textTransform: 'uppercase' }}>
                    Store directory
                  </div>
                  <h2 className="section-title" style={{ marginBottom: 0 }}>
                    <i className="fas fa-store"></i>
                    Browse All Matching Stores
                  </h2>
                </div>
                <div style={{ color: 'var(--text-secondary)', fontSize: '0.92rem' }}>
                  {filtered.length} store{filtered.length === 1 ? '' : 's'} after filters
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
                {filtered.map((merchant) => (
                  <div key={getMerchantId(merchant)} className="promotion-card fade-in" style={{ padding: '1.25rem' }}>
                    <div className="flex items-start gap-3 mb-3">
                      <div style={{ width: '60px', height: '60px', position: 'relative', flexShrink: 0 }}>
                        <Image
                        src={getSafeLogo(merchant.logo, merchant.name)}
                        alt={merchant.name || 'Merchant logo'}
                        fill
                        sizes="60px"
                        style={{ borderRadius: '1rem', objectFit: 'cover', border: '2px solid var(--border-color)' }}
                      />
                      </div>
                      <div style={{ minWidth: 0 }}>
                        <h2 style={{ fontWeight: 800, fontSize: '1rem', color: 'var(--text-primary)', margin: 0 }}>
                          {merchant.name}
                        </h2>
                        <div style={{ fontSize: '0.82rem', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '0.35rem', marginTop: '0.35rem', flexWrap: 'wrap' }}>
                          <i className={`fas ${CAT_ICONS[merchant.category || ''] || 'fa-store'}`}></i>
                          <span>{getCategoryLabel(merchant.category)}</span>
                          <span>•</span>
                          <span>{typeof merchant.followers === 'number' ? merchant.followers.toLocaleString() : '0'} followers</span>
                        </div>
                      </div>
                    </div>

                    <p style={{ fontSize: '0.86rem', color: 'var(--text-secondary)', marginBottom: '1rem', lineHeight: 1.6 }}>
                      {merchant.description || `${merchant.name} offers live deals worth comparing.`}
                    </p>

                    <div className="grid grid-cols-2 gap-3" style={{ marginBottom: '1rem' }}>
                      <div style={{ borderRadius: '0.95rem', padding: '0.85rem', background: 'rgba(37,99,235,0.06)', border: '1px solid rgba(37,99,235,0.12)' }}>
                        <div style={{ fontSize: '1.05rem', fontWeight: 800, color: 'var(--text-primary)' }}>{merchant.activeDeals || 0}</div>
                        <div style={{ fontSize: '0.78rem', color: 'var(--text-secondary)' }}>Active deals</div>
                      </div>
                      <div style={{ borderRadius: '0.95rem', padding: '0.85rem', background: 'rgba(245,158,11,0.08)', border: '1px solid rgba(245,158,11,0.14)' }}>
                        <div style={{ fontSize: '1.05rem', fontWeight: 800, color: 'var(--text-primary)' }}>{typeof merchant.followers === 'number' ? merchant.followers.toLocaleString() : '0'}</div>
                        <div style={{ fontSize: '0.78rem', color: 'var(--text-secondary)' }}>Followers</div>
                      </div>
                    </div>

                    <div className="flex items-center justify-between gap-3 flex-wrap">
                      <span className="status-chip" style={{ background: 'rgba(22,163,74,0.12)', color: 'var(--success-color)' }}>
                        <i className="fas fa-bolt"></i>
                        {merchant.activeDeals || 0} live offers
                      </span>
                      <div className="flex gap-2">
                        {merchant.website && merchant.website !== '#' ? (
                          <a
                            href={merchant.website}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="btn"
                            style={{
                              fontSize: '0.8rem',
                              padding: '0.5rem 0.9rem',
                              background: 'var(--card-bg)',
                              color: 'var(--text-primary)',
                              border: '1px solid var(--border-color)',
                              textDecoration: 'none',
                            }}
                          >
                            <i className="fas fa-arrow-up-right-from-square"></i>
                            Site
                          </a>
                        ) : null}
                        <Link
                          href={`/merchants/${getMerchantId(merchant)}`}
                          className="btn btn-primary"
                          style={{ fontSize: '0.8rem', padding: '0.5rem 1rem' }}
                        >
                          Visit Store
                        </Link>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </section>
          </div>
        )}
      </div>
    </div>
  );
}
