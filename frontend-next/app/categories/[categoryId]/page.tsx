'use client';

import { useEffect, useMemo, useState } from 'react';
import { useParams, useRouter, useSearchParams } from 'next/navigation';
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

const SORT_OPTIONS = [
  { id: 'newest', label: 'Newest' },
  { id: 'ending-soon', label: 'Ending Soon' },
  { id: 'highest-discount', label: 'Biggest Discount' },
  { id: 'merchant', label: 'Merchant A-Z' },
];

type Promotion = {
  _id?: string;
  id?: string;
  title?: string;
  description?: string;
  category?: string;
  endDate?: string;
  createdAt?: string;
  discount?: string | number;
  featured?: boolean;
  merchant?: string | { name?: string };
};

function getMerchantName(promotion: Promotion) {
  return typeof promotion.merchant === 'object' ? promotion.merchant?.name || 'Unknown Merchant' : promotion.merchant || 'Unknown Merchant';
}

function getDiscountValue(discount: Promotion['discount']) {
  const numeric = Number.parseFloat(String(discount ?? '').replace(/[^\d.]/g, ''));
  return Number.isFinite(numeric) ? numeric : 0;
}

function getDateValue(value?: string) {
  if (!value) return 0;
  const time = new Date(value).getTime();
  return Number.isFinite(time) ? time : 0;
}

export default function CategoryPage() {
  const { categoryId } = useParams<{ categoryId: string }>();
  const router = useRouter();
  const searchParams = useSearchParams();
  const [promotions, setPromotions] = useState<Promotion[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState(() => searchParams.get('q') || '');
  const [sortBy, setSortBy] = useState('newest');
  const [activeOnly, setActiveOnly] = useState(true);
  const [currentTimestamp] = useState(() => Date.now());

  const currentCat = CATEGORIES.find(c => c.id === categoryId) || { name: 'All Deals', icon: 'fa-tag' };
  const categoryCounts = useMemo(() => {
    const counts = new Map<string, number>();

    for (const promotion of promotions) {
      const key = promotion.category || 'other';
      counts.set(key, (counts.get(key) || 0) + 1);
    }

    return counts;
  }, [promotions]);

  const quickStats = useMemo(() => {
    const liveDeals = promotions.filter((promotion) => getDateValue(promotion.endDate) >= currentTimestamp);
    const visibleDeals = categoryId === 'all'
      ? liveDeals
      : liveDeals.filter((promotion) => promotion.category === categoryId);
    const merchantCount = new Set(visibleDeals.map((promotion) => getMerchantName(promotion))).size;
    const featuredCount = visibleDeals.filter((promotion) => promotion.featured).length;
    const endingSoonCount = visibleDeals.filter((promotion) => {
      const timeLeft = getDateValue(promotion.endDate) - currentTimestamp;
      return timeLeft >= 0 && timeLeft <= 3 * 24 * 60 * 60 * 1000;
    }).length;

    return [
      { label: 'Live deals', value: visibleDeals.length },
      { label: 'Merchants', value: merchantCount },
      { label: 'Featured', value: featuredCount },
      { label: 'Ending soon', value: endingSoonCount },
    ];
  }, [categoryId, currentTimestamp, promotions]);

  useEffect(() => {
    PromotionAPI.getAll().then(data => {
      setPromotions(data);
    }).finally(() => setLoading(false));
  }, []);

  const filtered = useMemo(() => {
    let result = [...promotions];
    if (categoryId !== 'all') result = result.filter(p => p.category === categoryId);
    if (activeOnly) result = result.filter(p => getDateValue(p.endDate) >= currentTimestamp);
    if (searchTerm) {
      const t = searchTerm.toLowerCase();
      result = result.filter(p =>
        p.title?.toLowerCase().includes(t) ||
        p.description?.toLowerCase().includes(t) ||
        getMerchantName(p).toLowerCase().includes(t)
      );
    }
    if (sortBy === 'newest') result.sort((a, b) => getDateValue(b.createdAt) - getDateValue(a.createdAt));
    else if (sortBy === 'ending-soon') result.sort((a, b) => getDateValue(a.endDate) - getDateValue(b.endDate));
    else if (sortBy === 'highest-discount') result.sort((a, b) => getDiscountValue(b.discount) - getDiscountValue(a.discount));
    else if (sortBy === 'merchant') result.sort((a, b) => getMerchantName(a).localeCompare(getMerchantName(b)));
    return result;
  }, [promotions, categoryId, searchTerm, sortBy, activeOnly, currentTimestamp]);

  const featuredVisible = filtered.filter((promotion) => promotion.featured).length;
  const showingLabel = loading
    ? 'Loading deals...'
    : `${filtered.length} result${filtered.length === 1 ? '' : 's'}${searchTerm ? ` for "${searchTerm}"` : ''}`;

  return (
    <div>
      <HeroSection
        icon={currentCat.icon}
        title={currentCat.name}
        subtitle={categoryId === 'all'
          ? 'Browse the full marketplace with better sorting, quicker scanning, and fewer dead ends.'
          : `Explore ${currentCat.name.toLowerCase()} offers with live filters and faster comparison.`}
        gradient="linear-gradient(135deg, rgba(8,17,33,0.96) 0%, rgba(29,78,216,0.92) 48%, rgba(245,158,11,0.82) 100%)"
        bgImage="https://images.unsplash.com/photo-1481437156560-3205f6a55735?auto=format&fit=crop&w=1600&q=80"
        minHeight="320px"
      >
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(140px, 1fr))',
            gap: '0.85rem',
            maxWidth: '54rem',
            margin: '0 auto',
          }}
        >
          {quickStats.map((stat) => (
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
              <div style={{ fontSize: '1.4rem', fontWeight: 800 }}>{loading ? '--' : stat.value}</div>
              <div style={{ fontSize: '0.82rem', opacity: 0.82 }}>{stat.label}</div>
            </div>
          ))}
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
              <i className="fas fa-compass"></i>
              Browse smarter
            </div>
            <div style={{ marginTop: '0.9rem', fontSize: '1.15rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              {showingLabel}
            </div>
            <p style={{ margin: '0.45rem 0 0', color: 'var(--text-secondary)', lineHeight: 1.6 }}>
              Sort by urgency, discount, or merchant and keep expired offers out of the way until you need them.
            </p>
          </div>
          <div className="stat-tile" style={{ padding: '1rem 1.1rem' }}>
            <div style={{ fontSize: '0.8rem', fontWeight: 700, textTransform: 'uppercase', color: 'var(--primary-color)' }}>
              Visible now
            </div>
            <div style={{ marginTop: '0.35rem', fontSize: '1.6rem', fontWeight: 800 }}>
              {loading ? '--' : filtered.length}
            </div>
            <div style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
              {activeOnly ? 'Active offers only' : 'Active and expired offers'}
            </div>
          </div>
          <div className="stat-tile" style={{ padding: '1rem 1.1rem' }}>
            <div style={{ fontSize: '0.8rem', fontWeight: 700, textTransform: 'uppercase', color: 'var(--highlight-color)' }}>
              Featured in view
            </div>
            <div style={{ marginTop: '0.35rem', fontSize: '1.6rem', fontWeight: 800 }}>
              {loading ? '--' : featuredVisible}
            </div>
            <div style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
              Highlighted deals inside the current result set
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 py-8">
        <div className="flex gap-2 overflow-x-auto pb-2 mb-6" style={{ scrollbarWidth: 'none' }}>
          {CATEGORIES.map(cat => (
            <button
              key={cat.id}
              onClick={() => router.push(`/categories/${cat.id}`)}
              className={`category-item ${categoryId === cat.id ? 'active' : ''}`}
              style={{ flexShrink: 0 }}
            >
              <i className={`fas ${cat.icon}`}></i>
              {cat.name}
              <span
                style={{
                  marginLeft: '0.2rem',
                  padding: '0.15rem 0.45rem',
                  borderRadius: '999px',
                  background: categoryId === cat.id ? 'rgba(255,255,255,0.2)' : 'rgba(37,99,235,0.08)',
                  color: categoryId === cat.id ? '#fff' : 'var(--primary-color)',
                  fontSize: '0.72rem',
                  fontWeight: 700,
                }}
              >
                {cat.id === 'all' ? promotions.length : categoryCounts.get(cat.id) || 0}
              </span>
            </button>
          ))}
        </div>

        <div className="surface-panel panel-pad" style={{ marginBottom: '1.5rem' }}>
          <div className="glass-toolbar">
            <div className="toolbar-grow input-with-icon" style={{ minWidth: 0 }}>
              <i className="fas fa-search"></i>
              <input
                type="text"
                placeholder="Search deals, descriptions, or merchants"
                value={searchTerm}
                onChange={e => setSearchTerm(e.target.value)}
                className="modern-input"
              />
              {searchTerm ? (
                <button
                  onClick={() => setSearchTerm('')}
                  aria-label="Clear search"
                  style={{
                    position: 'absolute',
                    right: '0.9rem',
                    top: '50%',
                    transform: 'translateY(-50%)',
                    width: '2rem',
                    height: '2rem',
                    borderRadius: '999px',
                    border: '1px solid rgba(148,163,184,0.2)',
                    background: 'rgba(255,255,255,0.9)',
                    color: 'var(--text-secondary)',
                    cursor: 'pointer',
                  }}
                >
                  <i className="fas fa-times"></i>
                </button>
              ) : null}
            </div>
            <div style={{ minWidth: '180px', flex: '0 1 220px' }}>
              <select value={sortBy} onChange={e => setSortBy(e.target.value)} className="modern-select">
                {SORT_OPTIONS.map((option) => (
                  <option key={option.id} value={option.id}>
                    {option.label}
                  </option>
                ))}
              </select>
            </div>
            <button
              onClick={() => setActiveOnly(!activeOnly)}
              className="btn"
              style={{
                background: activeOnly ? 'var(--primary-gradient)' : 'var(--card-bg)',
                color: activeOnly ? '#fff' : 'var(--text-primary)',
                border: activeOnly ? 'none' : '1px solid var(--border-color)',
                padding: '0.8rem 1rem',
              }}
            >
              <i className={`fas ${activeOnly ? 'fa-toggle-on' : 'fa-toggle-off'}`}></i>
              {activeOnly ? 'Live Only' : 'Include Expired'}
            </button>
            <button
              onClick={() => {
                setSearchTerm('');
                setSortBy('newest');
                setActiveOnly(true);
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
              {currentCat.name}
            </span>
            <span className="status-chip" style={{ background: 'rgba(245,158,11,0.1)', color: 'var(--warning-color)' }}>
              <i className="fas fa-arrow-down-wide-short"></i>
              {SORT_OPTIONS.find((option) => option.id === sortBy)?.label}
            </span>
            <span className="status-chip" style={{ background: activeOnly ? 'rgba(22,163,74,0.12)' : 'rgba(107,114,128,0.12)', color: activeOnly ? 'var(--success-color)' : 'var(--text-secondary)' }}>
              <i className={`fas ${activeOnly ? 'fa-bolt' : 'fa-clock-rotate-left'}`}></i>
              {activeOnly ? 'Live deals only' : 'Expired included'}
            </span>
            {searchTerm ? (
              <span className="status-chip" style={{ background: 'rgba(37,99,235,0.08)', color: 'var(--primary-color)' }}>
                <i className="fas fa-search"></i>
                {searchTerm}
              </span>
            ) : null}
          </div>
        </div>

        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {Array.from({ length: 8 }).map((_, i) => <SkeletonCard key={i} />)}
          </div>
        ) : filtered.length > 0 ? (
          <>
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'end',
                gap: '1rem',
                flexWrap: 'wrap',
                marginBottom: '1.25rem',
              }}
            >
              <div>
                <div style={{ color: 'var(--primary-color)', fontSize: '0.82rem', fontWeight: 700, textTransform: 'uppercase' }}>
                  Results
                </div>
                <h2 className="section-title" style={{ marginBottom: 0 }}>
                  <i className="fas fa-table-cells-large"></i>
                  {showingLabel}
                </h2>
              </div>
              <div style={{ color: 'var(--text-secondary)', fontSize: '0.92rem' }}>
                Sorted by {SORT_OPTIONS.find((option) => option.id === sortBy)?.label?.toLowerCase()}
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              {filtered.map(p => <PromotionCard key={p._id || p.id} promotion={p} />)}
            </div>
          </>
        ) : (
          <div className="empty-state">
            <div className="empty-icon">
              <i className="fas fa-search"></i>
            </div>
            <h2 style={{ fontWeight: 800, marginBottom: '0.5rem' }}>No deals match this view</h2>
            <p style={{ color: 'var(--text-secondary)', marginBottom: '1.25rem', maxWidth: '34rem', marginInline: 'auto', lineHeight: 1.7 }}>
              {searchTerm
                ? `Nothing matched "${searchTerm}" in ${currentCat.name}. Try a broader keyword or switch the sort and status filters.`
                : activeOnly
                  ? `There are no live deals to show in ${currentCat.name} right now.`
                  : `There are no deals to show in ${currentCat.name} right now.`}
            </p>
            <div className="flex justify-center gap-3 flex-wrap">
              <button
                className="btn"
                onClick={() => {
                  setSearchTerm('');
                  setSortBy('newest');
                }}
                style={{
                  background: 'var(--card-bg)',
                  color: 'var(--text-primary)',
                  border: '1px solid var(--border-color)',
                }}
              >
                Reset Filters
              </button>
              {activeOnly && (
                <button className="btn btn-primary" onClick={() => setActiveOnly(false)}>
                  Show Expired Deals
                </button>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
