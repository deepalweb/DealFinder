'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import AdminFilterBar from '@/components/admin/AdminFilterBar';
import AdminPageHeader from '@/components/admin/AdminPageHeader';
import AdminStatusChip from '@/components/admin/AdminStatusChip';
import { AdminAPI, PromotionAPI } from '@/lib/api';
import {
  formatAdminDate,
  formatAdminRelativeDays,
  getAdminCategoryLabel,
  getAdminQaMeta,
  getEffectivePromotionStatus,
  getMerchantName,
  getNormalizedAdminCategory,
  getPromotionId,
  matchesAdminSearch,
} from '@/lib/admin';
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
  createdAt?: string;
  updatedAt?: string;
  merchant?: string | { name?: string; status?: string };
  effectiveStatus?: EffectiveStatus;
  merchantState?: string;
  qaFlags?: string[];
  viewCount?: number;
  clickCount?: number;
  favoriteCount?: number;
  ctr?: number;
  daysRemaining?: number;
};

type EffectiveStatus =
  | 'active'
  | 'scheduled'
  | 'rejected'
  | 'admin_paused'
  | 'expired'
  | 'draft';

type EnrichedPromotion = PromotionRecord & {
  effectiveStatus: EffectiveStatus;
  normalizedCategory: string;
  categoryLabel: string;
  qaFlags: string[];
};

const statusOptions: { value: string; label: string }[] = [
  { value: 'all', label: 'All status' },
  { value: 'active', label: 'Active' },
  { value: 'scheduled', label: 'Scheduled' },
  { value: 'rejected', label: 'Rejected' },
  { value: 'admin_paused', label: 'Paused' },
  { value: 'expired', label: 'Expired' },
  { value: 'draft', label: 'Draft' },
];

const bulkActions = [
  { value: 'pause', label: 'Pause selected' },
  { value: 'resume', label: 'Resume selected' },
  { value: 'reject', label: 'Reject selected' },
  { value: 'feature', label: 'Feature selected' },
  { value: 'unfeature', label: 'Remove featured' },
];

function getLatestTimestamp(promotion: PromotionRecord) {
  const value = promotion.updatedAt || promotion.createdAt || promotion.startDate;
  const time = value ? new Date(value).getTime() : 0;
  return Number.isFinite(time) ? time : 0;
}

function AdminMetricTile({
  icon,
  label,
  value,
  tone,
  onClick,
}: {
  icon: string;
  label: string;
  value: number | string;
  tone: string;
  onClick?: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="surface-panel panel-pad"
      style={{
        textAlign: 'left',
        border: '1px solid var(--border-color)',
        cursor: onClick ? 'pointer' : 'default',
        minHeight: 112,
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
        <span
          style={{
            width: 38,
            height: 38,
            borderRadius: '0.8rem',
            display: 'inline-flex',
            alignItems: 'center',
            justifyContent: 'center',
            background: `${tone}18`,
            color: tone,
          }}
        >
          <i className={`fas ${icon}`}></i>
        </span>
        <div>
          <p style={{ margin: 0, color: 'var(--text-secondary)', fontSize: '0.78rem', fontWeight: 700 }}>{label}</p>
          <p style={{ margin: 0, color: 'var(--text-primary)', fontSize: '1.55rem', fontWeight: 850 }}>{value}</p>
        </div>
      </div>
    </button>
  );
}

export default function AdminPromotionsPage() {
  const [promotions, setPromotions] = useState<PromotionRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [reviewOnly, setReviewOnly] = useState(false);
  const [sortMode, setSortMode] = useState('updated_desc');
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [bulkAction, setBulkAction] = useState('pause');
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  const loadPromotions = useCallback(async () => {
    setLoading(true);
    try {
      const response = await AdminAPI.getPromotionsPage({
        limit: 100,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      });
      const arr = Array.isArray(response) ? response : response?.data || [];
      setPromotions(arr);
      setSelectedIds(new Set());
    } catch {
      toast.error('Failed to load promotions.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadPromotions();
  }, [loadPromotions]);

  const enrichedPromotions = useMemo<EnrichedPromotion[]>(
    () =>
      promotions.map((promotion) => ({
        ...promotion,
        effectiveStatus: (promotion.effectiveStatus || getEffectivePromotionStatus(promotion)) as EffectiveStatus,
        normalizedCategory: getNormalizedAdminCategory(promotion.category),
        categoryLabel: getAdminCategoryLabel(promotion.category),
        qaFlags: promotion.qaFlags || [],
      })),
    [promotions]
  );

  const summary = useMemo(() => {
    const active = enrichedPromotions.filter((promotion) => promotion.effectiveStatus === 'active').length;
    const scheduled = enrichedPromotions.filter((promotion) => promotion.effectiveStatus === 'scheduled').length;
    const paused = enrichedPromotions.filter((promotion) => promotion.effectiveStatus === 'admin_paused').length;
    const needsReview = enrichedPromotions.filter((promotion) => promotion.qaFlags.length > 0).length;
    const expiringSoon = enrichedPromotions.filter((promotion) => {
      const days = promotion.daysRemaining;
      return typeof days === 'number' && days >= 0 && days <= 3;
    }).length;

    return { active, scheduled, paused, needsReview, expiringSoon };
  }, [enrichedPromotions]);

  const filtered = useMemo(() => {
    let result = [...enrichedPromotions];

    if (statusFilter !== 'all') {
      result = result.filter((promotion) => promotion.effectiveStatus === statusFilter);
    }

    if (categoryFilter !== 'all') {
      result = result.filter((promotion) => promotion.normalizedCategory === categoryFilter);
    }

    if (reviewOnly) {
      result = result.filter((promotion) => promotion.qaFlags.length > 0);
    }

    if (search.trim()) {
      result = result.filter((promotion) =>
        matchesAdminSearch(search, promotion.title, getMerchantName(promotion.merchant), promotion.categoryLabel, promotion.discount)
      );
    }

    result.sort((a, b) => {
      if (sortMode === 'ending_soon') return (a.daysRemaining ?? 9999) - (b.daysRemaining ?? 9999);
      if (sortMode === 'views_desc') return (b.viewCount ?? 0) - (a.viewCount ?? 0);
      if (sortMode === 'qa_desc') return b.qaFlags.length - a.qaFlags.length;
      if (sortMode === 'title_asc') return (a.title || '').localeCompare(b.title || '');
      return getLatestTimestamp(b) - getLatestTimestamp(a);
    });

    return result;
  }, [categoryFilter, enrichedPromotions, reviewOnly, search, sortMode, statusFilter]);

  const categoryOptions = useMemo(
    () =>
      [...new Set(enrichedPromotions.map((promotion) => promotion.normalizedCategory).filter(Boolean))].sort(),
    [enrichedPromotions]
  );

  const selectedVisibleCount = filtered.filter((promotion) => selectedIds.has(getPromotionId(promotion))).length;
  const allVisibleSelected = filtered.length > 0 && selectedVisibleCount === filtered.length;

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
    setActionLoading(id + 'featured');
    try {
      const updated = await PromotionAPI.update(id, { featured: !promotion.featured });
      setPromotions((prev) => prev.map((entry) => (getPromotionId(entry) === id ? updated : entry)));
      toast.success(promotion.featured ? 'Removed from featured' : 'Marked as featured');
    } catch {
      toast.error('Failed to update.');
    } finally {
      setActionLoading(null);
    }
  };

  const runBulkAction = async () => {
    if (!selectedIds.size) {
      toast.error('Select promotions first.');
      return;
    }
    setActionLoading('bulk');
    try {
      const response = await AdminAPI.runPromotionBulkAction({
        ids: Array.from(selectedIds),
        action: bulkAction,
      });
      toast.success(`${response?.modifiedCount ?? selectedIds.size} promotion(s) updated.`);
      await loadPromotions();
    } catch {
      toast.error('Bulk action failed.');
    } finally {
      setActionLoading(null);
    }
  };

  const handleDelete = async (id: string, title: string) => {
    if (!confirm(`Delete "${title}"? This cannot be undone.`)) return;
    setActionLoading(id + 'delete');
    try {
      await PromotionAPI.delete(id);
      setPromotions((prev) => prev.filter((promotion) => getPromotionId(promotion) !== id));
      setSelectedIds((prev) => {
        const next = new Set(prev);
        next.delete(id);
        return next;
      });
      toast.success('Promotion deleted.');
    } catch {
      toast.error('Failed to delete.');
    } finally {
      setActionLoading(null);
    }
  };

  const toggleRow = (id: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const toggleAllVisible = () => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (allVisibleSelected) {
        filtered.forEach((promotion) => next.delete(getPromotionId(promotion)));
      } else {
        filtered.forEach((promotion) => next.add(getPromotionId(promotion)));
      }
      return next;
    });
  };

  return (
    <div>
      <AdminPageHeader
        title="Promotions"
        subtitle={`${filtered.length} shown from ${enrichedPromotions.length} loaded promotions`}
        actions={
          <button className="btn btn-secondary" onClick={loadPromotions} disabled={loading}>
            <i className="fas fa-rotate"></i>
            Refresh
          </button>
        }
      />

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(170px, 1fr))', gap: '0.9rem', marginBottom: '1.1rem' }}>
        <AdminMetricTile icon="fa-bolt" label="Active" value={summary.active} tone="#059669" onClick={() => setStatusFilter('active')} />
        <AdminMetricTile icon="fa-calendar-day" label="Scheduled" value={summary.scheduled} tone="#6366f1" onClick={() => setStatusFilter('scheduled')} />
        <AdminMetricTile icon="fa-pause" label="Paused" value={summary.paused} tone="#64748b" onClick={() => setStatusFilter('admin_paused')} />
        <AdminMetricTile icon="fa-triangle-exclamation" label="Needs Review" value={summary.needsReview} tone="#d97706" onClick={() => setReviewOnly(true)} />
        <AdminMetricTile icon="fa-hourglass-half" label="Expiring Soon" value={summary.expiringSoon} tone="#ef4444" onClick={() => setSortMode('ending_soon')} />
      </div>

      <AdminFilterBar>
        <div className="input-with-icon toolbar-grow" style={{ maxWidth: '400px' }}>
          <i className="fas fa-search"></i>
          <input
            className="modern-input"
            placeholder="Search title, merchant, discount..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <select className="modern-select" style={{ maxWidth: '175px' }} value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
          {statusOptions.map((option) => (
            <option key={option.value} value={option.value}>{option.label}</option>
          ))}
        </select>
        <select className="modern-select" style={{ maxWidth: '200px' }} value={categoryFilter} onChange={(e) => setCategoryFilter(e.target.value)}>
          <option value="all">All categories</option>
          {categoryOptions.map((categoryId) => (
            <option key={categoryId} value={categoryId}>
              {getAdminCategoryLabel(categoryId)}
            </option>
          ))}
        </select>
        <select className="modern-select" style={{ maxWidth: '170px' }} value={sortMode} onChange={(e) => setSortMode(e.target.value)}>
          <option value="updated_desc">Newest updated</option>
          <option value="ending_soon">Ending soon</option>
          <option value="views_desc">Most viewed</option>
          <option value="qa_desc">Most issues</option>
          <option value="title_asc">Title A-Z</option>
        </select>
        <button
          onClick={() => setReviewOnly((value) => !value)}
          style={{
            padding: '0.62rem 0.9rem',
            borderRadius: '0.8rem',
            border: `1.5px solid ${reviewOnly ? 'rgba(245,158,11,0.38)' : 'var(--border-color)'}`,
            background: reviewOnly ? 'rgba(245,158,11,0.1)' : 'var(--card-bg)',
            color: reviewOnly ? '#b45309' : 'var(--text-secondary)',
            fontSize: '0.82rem',
            fontWeight: 700,
            cursor: 'pointer',
          }}
        >
          <i className="fas fa-clipboard-check"></i> Review only
        </button>
      </AdminFilterBar>

      {selectedIds.size > 0 ? (
        <div className="surface-panel panel-pad" style={{ marginBottom: '1rem', display: 'flex', gap: '0.75rem', alignItems: 'center', flexWrap: 'wrap' }}>
          <span style={{ fontWeight: 800, color: 'var(--text-primary)' }}>{selectedIds.size} selected</span>
          <select className="modern-select" style={{ maxWidth: '190px' }} value={bulkAction} onChange={(e) => setBulkAction(e.target.value)}>
            {bulkActions.map((action) => (
              <option key={action.value} value={action.value}>{action.label}</option>
            ))}
          </select>
          <button className="btn btn-primary" onClick={runBulkAction} disabled={actionLoading === 'bulk'}>
            <i className="fas fa-wand-magic-sparkles"></i>
            Apply
          </button>
          <button className="btn btn-secondary" onClick={() => setSelectedIds(new Set())}>
            Clear
          </button>
        </div>
      ) : null}

      <div className="surface-panel overflow-hidden">
        <div className="overflow-x-auto">
          <table className="data-table">
            <thead>
              <tr>
                <th style={{ width: 42 }}>
                  <input type="checkbox" checked={allVisibleSelected} onChange={toggleAllVisible} aria-label="Select visible promotions" />
                </th>
                {['Promotion', 'Merchant', 'Status', 'Performance', 'Quality', 'Dates', 'Actions'].map((header) => (
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
                    <td colSpan={8} style={{ padding: '0.75rem 1rem' }}>
                      <div className="skeleton" style={{ height: '20px' }}></div>
                    </td>
                  </tr>
                ))
              ) : filtered.length === 0 ? (
                <tr>
                  <td colSpan={8} style={{ padding: '3rem', textAlign: 'center', color: 'var(--text-secondary)' }}>
                    No promotions match the current filters.
                  </td>
                </tr>
              ) : (
                filtered.map((promotion) => {
                  const id = getPromotionId(promotion);
                  const isPaused = promotion.effectiveStatus === 'admin_paused';
                  const isPubliclyVisible = ['active', 'scheduled'].includes(promotion.effectiveStatus);
                  const selected = selectedIds.has(id);

                  return (
                    <tr key={id} style={{ background: selected ? 'rgba(37,99,235,0.045)' : undefined }}>
                      <td>
                        <input type="checkbox" checked={selected} onChange={() => toggleRow(id)} aria-label={`Select ${promotion.title || 'promotion'}`} />
                      </td>
                      <td>
                        <div className="flex items-center gap-3">
                          {promotion.image ? (
                            <span
                              role="img"
                              aria-label={promotion.title || 'Promotion image'}
                              style={{
                                width: 42,
                                height: 42,
                                borderRadius: '0.5rem',
                                flexShrink: 0,
                                backgroundImage: `url(${promotion.image})`,
                                backgroundSize: 'cover',
                                backgroundPosition: 'center',
                              }}
                            />
                          ) : (
                            <span style={{ width: 42, height: 42, borderRadius: '0.5rem', background: 'var(--light-gray)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-secondary)' }}>
                              <i className="fas fa-tag"></i>
                            </span>
                          )}
                          <div style={{ minWidth: 180 }}>
                            <p style={{ fontWeight: 700, fontSize: '0.875rem', color: 'var(--text-primary)', margin: 0 }}>
                              {promotion.title || 'Untitled promotion'}
                            </p>
                            <p style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', margin: 0 }}>
                              {promotion.categoryLabel}
                              {promotion.featured ? ' · Featured' : ''}
                            </p>
                          </div>
                        </div>
                      </td>
                      <td style={{ fontSize: '0.875rem', color: 'var(--text-secondary)' }}>{getMerchantName(promotion.merchant)}</td>
                      <td>
                        <AdminStatusChip status={promotion.effectiveStatus} />
                      </td>
                      <td style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>
                        <strong style={{ color: 'var(--text-primary)' }}>{promotion.viewCount ?? 0}</strong> views
                        <br />
                        {promotion.clickCount ?? 0} clicks · {promotion.favoriteCount ?? 0} saves · {promotion.ctr ?? 0}% CTR
                      </td>
                      <td>
                        {promotion.qaFlags.length ? (
                          <div style={{ display: 'flex', gap: '0.3rem', flexWrap: 'wrap', maxWidth: 230 }}>
                            {promotion.qaFlags.slice(0, 2).map((flag) => {
                              const meta = getAdminQaMeta(flag);
                              return (
                                <span key={flag} className="status-chip" style={{ background: meta.bg, color: meta.color }}>
                                  {meta.label}
                                </span>
                              );
                            })}
                            {promotion.qaFlags.length > 2 ? (
                              <span className="status-chip">+{promotion.qaFlags.length - 2}</span>
                            ) : null}
                          </div>
                        ) : (
                          <span style={{ color: '#059669', fontSize: '0.78rem', fontWeight: 700 }}>Clear</span>
                        )}
                      </td>
                      <td style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', whiteSpace: 'nowrap' }}>
                        Ends {formatAdminDate(promotion.endDate)}
                        <br />
                        {formatAdminRelativeDays(promotion.daysRemaining)}
                      </td>
                      <td style={{ textAlign: 'right' }}>
                        <div className="flex justify-end gap-2 flex-wrap">
                          {isPubliclyVisible ? (
                            <button className="btn btn-secondary" onClick={() => updateStatus(id, 'admin_paused')} disabled={!!actionLoading} style={{ padding: '0.42rem 0.7rem', fontSize: '0.75rem' }}>
                              <i className="fas fa-pause"></i> Pause
                            </button>
                          ) : null}
                          {isPaused ? (
                            <button className="btn btn-secondary" onClick={() => updateStatus(id, 'active')} disabled={!!actionLoading} style={{ padding: '0.42rem 0.7rem', fontSize: '0.75rem', color: '#059669' }}>
                              <i className="fas fa-play"></i> Resume
                            </button>
                          ) : null}
                          <button className="btn btn-secondary" onClick={() => toggleFeatured(promotion)} disabled={!!actionLoading} style={{ padding: '0.42rem 0.7rem', fontSize: '0.75rem', color: promotion.featured ? '#d97706' : 'var(--text-secondary)' }}>
                            <i className={`fas ${promotion.featured ? 'fa-star' : 'fa-star-half-stroke'}`}></i>
                          </button>
                          <button className="btn btn-secondary" onClick={() => handleDelete(id, promotion.title || 'Untitled promotion')} disabled={!!actionLoading} style={{ padding: '0.42rem 0.7rem', fontSize: '0.75rem', color: '#ef4444' }}>
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
