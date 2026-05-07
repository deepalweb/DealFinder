'use client';

import { useEffect, useMemo, useState } from 'react';
import { AdminAPI, PromotionAPI } from '@/lib/api';
import { getCategoryLabel, normalizeCategoryId } from '@/lib/categories';
import toast from 'react-hot-toast';

type PromotionRecord = {
  _id?: string;
  id?: string;
  title?: string;
  discount?: string;
  category?: string;
  image?: string;
  featured?: boolean;
  status?: string;
  startDate?: string;
  endDate?: string;
  merchant?: string | { name?: string };
};

type EffectiveStatus =
  | 'active'
  | 'pending_approval'
  | 'scheduled'
  | 'rejected'
  | 'admin_paused'
  | 'expired'
  | 'draft';

type EnrichedPromotion = PromotionRecord & {
  effectiveStatus: EffectiveStatus;
  normalizedCategory: string;
  categoryLabel: string;
};

const STATUS_STYLES: Record<string, { bg: string; color: string }> = {
  active: { bg: 'rgba(16,185,129,0.1)', color: '#059669' },
  pending_approval: { bg: 'rgba(245,158,11,0.1)', color: '#d97706' },
  scheduled: { bg: 'rgba(99,102,241,0.1)', color: '#6366f1' },
  rejected: { bg: 'rgba(239,68,68,0.1)', color: '#ef4444' },
  admin_paused: { bg: 'rgba(100,116,139,0.1)', color: '#64748b' },
  expired: { bg: 'rgba(100,116,139,0.1)', color: '#64748b' },
  draft: { bg: 'rgba(100,116,139,0.1)', color: '#64748b' },
};

function getPromotionId(promotion: PromotionRecord) {
  return promotion._id || promotion.id || '';
}

function getMerchantName(merchant: PromotionRecord['merchant']) {
  return typeof merchant === 'object' ? merchant?.name || '—' : merchant || '—';
}

function getEffectiveStatus(promotion: PromotionRecord): EffectiveStatus {
  const rawStatus = promotion.status || 'draft';
  if (['pending_approval', 'rejected', 'admin_paused', 'draft'].includes(rawStatus)) {
    return rawStatus as EffectiveStatus;
  }

  const now = new Date();
  const startDate = promotion.startDate ? new Date(promotion.startDate) : null;
  const endDate = promotion.endDate ? new Date(promotion.endDate) : null;

  if (endDate && !Number.isNaN(endDate.getTime()) && endDate < now) {
    return 'expired';
  }

  if (startDate && !Number.isNaN(startDate.getTime()) && startDate > now) {
    return 'scheduled';
  }

  return 'active';
}

function formatDate(value?: string) {
  if (!value) return '—';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '—';
  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}

export default function AdminPromotionsPage() {
  const [promotions, setPromotions] = useState<PromotionRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  useEffect(() => {
    AdminAPI.getAllPromotions()
      .then((data) => {
        const arr = Array.isArray(data) ? data : [];
        setPromotions(arr);
      })
      .catch(() => toast.error('Failed to load promotions.'))
      .finally(() => setLoading(false));
  }, []);

  const enrichedPromotions = useMemo<EnrichedPromotion[]>(
    () =>
      promotions.map((promotion) => ({
        ...promotion,
        effectiveStatus: getEffectiveStatus(promotion),
        normalizedCategory: normalizeCategoryId(promotion.category),
        categoryLabel: getCategoryLabel(promotion.category),
      })),
    [promotions]
  );

  const filtered = useMemo(() => {
    let result = [...enrichedPromotions];

    if (statusFilter !== 'all') {
      result = result.filter((promotion) => promotion.effectiveStatus === statusFilter);
    }

    if (categoryFilter !== 'all') {
      result = result.filter((promotion) => promotion.normalizedCategory === categoryFilter);
    }

    if (search.trim()) {
      const term = search.trim().toLowerCase();
      result = result.filter((promotion) => {
        const merchantName = getMerchantName(promotion.merchant).toLowerCase();
        return (
          promotion.title?.toLowerCase().includes(term) ||
          merchantName.includes(term) ||
          promotion.categoryLabel.toLowerCase().includes(term)
        );
      });
    }

    return result;
  }, [categoryFilter, enrichedPromotions, search, statusFilter]);

  const pendingCount = useMemo(
    () => enrichedPromotions.filter((promotion) => promotion.effectiveStatus === 'pending_approval').length,
    [enrichedPromotions]
  );

  const categoryOptions = useMemo(
    () =>
      [...new Set(enrichedPromotions.map((promotion) => promotion.normalizedCategory).filter(Boolean))].sort(),
    [enrichedPromotions]
  );

  const updateStatus = async (id: string, status: string) => {
    setActionLoading(id + status);
    try {
      const updated = await PromotionAPI.update(id, { status });
      setPromotions((prev) => prev.map((promotion) => (getPromotionId(promotion) === id ? updated : promotion)));
      toast.success(`Promotion ${status.replace(/_/g, ' ')}`);
    } catch {
      toast.error('Failed to update status.');
    } finally {
      setActionLoading(null);
    }
  };

  const toggleFeatured = async (promotion: EnrichedPromotion) => {
    const id = getPromotionId(promotion);
    try {
      const updated = await PromotionAPI.update(id, { featured: !promotion.featured });
      setPromotions((prev) => prev.map((entry) => (getPromotionId(entry) === id ? updated : entry)));
      toast.success(promotion.featured ? 'Removed from featured' : 'Marked as featured');
    } catch {
      toast.error('Failed to update.');
    }
  };

  const handleDelete = async (id: string, title: string) => {
    if (!confirm(`Delete "${title}"? This cannot be undone.`)) return;
    try {
      await PromotionAPI.delete(id);
      setPromotions((prev) => prev.filter((promotion) => getPromotionId(promotion) !== id));
      toast.success('Promotion deleted.');
    } catch {
      toast.error('Failed to delete.');
    }
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6 flex-wrap gap-3">
        <div>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 800, color: 'var(--text-primary)', margin: 0, letterSpacing: '-0.02em' }}>
            Promotions
          </h1>
          <p style={{ color: 'var(--text-secondary)', margin: 0, fontSize: '0.875rem' }}>
            {filtered.length} of {enrichedPromotions.length} promotions
          </p>
        </div>
      </div>

      {pendingCount > 0 && (
        <div
          className="surface-panel panel-pad"
          style={{
            marginBottom: '1.25rem',
            display: 'flex',
            alignItems: 'center',
            gap: '0.75rem',
            background: 'linear-gradient(135deg, rgba(245,158,11,0.1), rgba(249,115,22,0.08))',
            borderColor: 'rgba(245,158,11,0.25)',
          }}
        >
          <i className="fas fa-clock" style={{ color: '#f59e0b' }}></i>
          <span style={{ fontSize: '0.875rem', color: '#92400e', fontWeight: 500 }}>
            {pendingCount} promotion(s) waiting for approval
          </span>
          <button
            onClick={() => setStatusFilter('pending_approval')}
            style={{
              marginLeft: 'auto',
              fontSize: '0.75rem',
              fontWeight: 700,
              color: '#92400e',
              padding: '0.25rem 0.625rem',
              borderRadius: '0.375rem',
              background: 'rgba(245,158,11,0.15)',
              border: 'none',
              cursor: 'pointer',
            }}
          >
            Review Now
          </button>
        </div>
      )}

      <div className="glass-toolbar mb-5">
        <div className="input-with-icon toolbar-grow" style={{ maxWidth: '400px' }}>
          <i className="fas fa-search"></i>
          <input
            className="modern-input"
            placeholder="Search promotions..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <select className="modern-select" style={{ maxWidth: '190px' }} value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
          <option value="all">All Status</option>
          <option value="active">Active</option>
          <option value="pending_approval">Pending Approval</option>
          <option value="scheduled">Scheduled</option>
          <option value="rejected">Rejected</option>
          <option value="admin_paused">Paused</option>
          <option value="expired">Expired</option>
          <option value="draft">Draft</option>
        </select>
        <select className="modern-select" style={{ maxWidth: '210px' }} value={categoryFilter} onChange={(e) => setCategoryFilter(e.target.value)}>
          <option value="all">All Categories</option>
          {categoryOptions.map((categoryId) => (
            <option key={categoryId} value={categoryId}>
              {getCategoryLabel(categoryId)}
            </option>
          ))}
        </select>
      </div>

      <div className="surface-panel overflow-hidden">
        <div className="overflow-x-auto">
          <table className="data-table">
            <thead>
              <tr>
                {['Promotion', 'Merchant', 'Discount', 'Status', 'Dates', 'Actions'].map((header) => (
                  <th key={header} style={{ textAlign: header === 'Actions' ? 'right' : 'left' }}>
                    {header}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {loading ? (
                Array.from({ length: 5 }).map((_, index) => (
                  <tr key={index}>
                    <td colSpan={6} style={{ padding: '0.75rem 1rem' }}>
                      <div className="skeleton" style={{ height: '20px' }}></div>
                    </td>
                  </tr>
                ))
              ) : filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} style={{ padding: '3rem', textAlign: 'center', color: 'var(--text-secondary)' }}>
                    No promotions found
                  </td>
                </tr>
              ) : (
                filtered.map((promotion) => {
                  const id = getPromotionId(promotion);
                  const isPaused = promotion.effectiveStatus === 'admin_paused';
                  const isPending = promotion.effectiveStatus === 'pending_approval';
                  const isPubliclyVisible = ['active', 'scheduled'].includes(promotion.effectiveStatus);

                  return (
                    <tr key={id}>
                      <td>
                        <div className="flex items-center gap-3">
                          {promotion.image ? (
                            <img
                              src={promotion.image}
                              alt={promotion.title}
                              style={{ width: '36px', height: '36px', borderRadius: '0.5rem', objectFit: 'cover', flexShrink: 0 }}
                            />
                          ) : null}
                          <div>
                            <p style={{ fontWeight: 600, fontSize: '0.875rem', color: 'var(--text-primary)', margin: 0 }}>
                              {promotion.title}
                            </p>
                            <p style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', margin: 0 }}>
                              {promotion.categoryLabel}
                            </p>
                          </div>
                        </div>
                      </td>
                      <td style={{ fontSize: '0.875rem', color: 'var(--text-secondary)' }}>{getMerchantName(promotion.merchant)}</td>
                      <td>
                        <span className="discount-badge" style={{ position: 'static', fontSize: '0.72rem' }}>
                          {promotion.discount || '—'}
                          {promotion.discount ? ' OFF' : ''}
                        </span>
                        {promotion.featured ? (
                          <span style={{ display: 'block', fontSize: '0.7rem', color: '#d97706', fontWeight: 700, marginTop: '0.2rem' }}>
                            ⭐ Featured
                          </span>
                        ) : null}
                      </td>
                      <td>
                        <span
                          className="status-chip"
                          style={{
                            background: STATUS_STYLES[promotion.effectiveStatus]?.bg || 'var(--light-gray)',
                            color: STATUS_STYLES[promotion.effectiveStatus]?.color || 'var(--text-secondary)',
                          }}
                        >
                          {promotion.effectiveStatus.replace(/_/g, ' ')}
                        </span>
                      </td>
                      <td style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>
                        {formatDate(promotion.startDate)}
                        <br />
                        {formatDate(promotion.endDate)}
                      </td>
                      <td style={{ textAlign: 'right' }}>
                        <div className="flex justify-end gap-2 flex-wrap">
                          {isPending ? (
                            <>
                              <button
                                onClick={() => updateStatus(id, 'approved')}
                                disabled={!!actionLoading}
                                style={{
                                  padding: '0.3rem 0.6rem',
                                  borderRadius: '0.5rem',
                                  border: '1.5px solid rgba(16,185,129,0.3)',
                                  background: 'rgba(16,185,129,0.08)',
                                  color: '#059669',
                                  fontSize: '0.75rem',
                                  fontWeight: 600,
                                  cursor: 'pointer',
                                }}
                              >
                                <i className="fas fa-check"></i> Approve
                              </button>
                              <button
                                onClick={() => updateStatus(id, 'rejected')}
                                disabled={!!actionLoading}
                                style={{
                                  padding: '0.3rem 0.6rem',
                                  borderRadius: '0.5rem',
                                  border: '1.5px solid rgba(239,68,68,0.3)',
                                  background: 'rgba(239,68,68,0.06)',
                                  color: '#ef4444',
                                  fontSize: '0.75rem',
                                  fontWeight: 600,
                                  cursor: 'pointer',
                                }}
                              >
                                <i className="fas fa-times"></i> Reject
                              </button>
                            </>
                          ) : null}
                          {isPubliclyVisible ? (
                            <button
                              onClick={() => updateStatus(id, 'admin_paused')}
                              disabled={!!actionLoading}
                              style={{
                                padding: '0.3rem 0.6rem',
                                borderRadius: '0.5rem',
                                border: '1.5px solid rgba(100,116,139,0.3)',
                                background: 'rgba(100,116,139,0.06)',
                                color: '#64748b',
                                fontSize: '0.75rem',
                                fontWeight: 600,
                                cursor: 'pointer',
                              }}
                            >
                              <i className="fas fa-pause"></i> Pause
                            </button>
                          ) : null}
                          {isPaused ? (
                            <button
                              onClick={() => updateStatus(id, 'active')}
                              disabled={!!actionLoading}
                              style={{
                                padding: '0.3rem 0.6rem',
                                borderRadius: '0.5rem',
                                border: '1.5px solid rgba(16,185,129,0.3)',
                                background: 'rgba(16,185,129,0.08)',
                                color: '#059669',
                                fontSize: '0.75rem',
                                fontWeight: 600,
                                cursor: 'pointer',
                              }}
                            >
                              <i className="fas fa-play"></i> Resume
                            </button>
                          ) : null}
                          <button
                            onClick={() => toggleFeatured(promotion)}
                            style={{
                              padding: '0.3rem 0.6rem',
                              borderRadius: '0.5rem',
                              border: `1.5px solid ${promotion.featured ? 'rgba(245,158,11,0.3)' : 'var(--border-color)'}`,
                              background: promotion.featured ? 'rgba(245,158,11,0.08)' : 'var(--card-bg)',
                              color: promotion.featured ? '#d97706' : 'var(--text-secondary)',
                              fontSize: '0.75rem',
                              fontWeight: 600,
                              cursor: 'pointer',
                            }}
                          >
                            {promotion.featured ? '⭐' : '☆'}
                          </button>
                          <button
                            onClick={() => handleDelete(id, promotion.title || 'Untitled promotion')}
                            style={{
                              padding: '0.3rem 0.6rem',
                              borderRadius: '0.5rem',
                              border: '1.5px solid rgba(239,68,68,0.3)',
                              background: 'rgba(239,68,68,0.06)',
                              color: '#ef4444',
                              fontSize: '0.75rem',
                              fontWeight: 600,
                              cursor: 'pointer',
                            }}
                          >
                            <i className="fas fa-trash-alt"></i>
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
