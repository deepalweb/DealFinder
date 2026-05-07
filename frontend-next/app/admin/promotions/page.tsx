'use client';

import { useEffect, useMemo, useState } from 'react';
import { usePathname, useRouter, useSearchParams } from 'next/navigation';
import AdminFilterBar from '@/components/admin/AdminFilterBar';
import AdminPageHeader from '@/components/admin/AdminPageHeader';
import AdminStatusChip from '@/components/admin/AdminStatusChip';
import { AdminAPI, PromotionAPI } from '@/lib/api';
import {
  formatAdminDate,
  formatAdminRelativeDays,
  getAdminCategoryLabel,
  getAdminQaMeta,
  getMerchantName,
  getPromotionId,
} from '@/lib/admin';
import toast from 'react-hot-toast';

type MerchantInfo = {
  _id?: string;
  name?: string;
  status?: string;
  logo?: string;
  contactInfo?: string;
  category?: string;
};

type PromotionRecord = {
  _id?: string;
  id?: string;
  title?: string;
  discount?: string;
  category?: string;
  image?: string;
  featured?: boolean;
  status?: string;
  effectiveStatus?: string;
  startDate?: string;
  endDate?: string;
  createdAt?: string;
  merchant?: string | MerchantInfo;
  merchantState?: string;
  commentCount?: number;
  ratingsCount?: number;
  averageRating?: number;
  favoriteCount?: number;
  clickCount?: number;
  viewCount?: number;
  ctr?: number;
  ageDays?: number;
  daysRemaining?: number;
  qaFlags?: string[];
  qaCount?: number;
  comments?: { text?: string; createdAt?: string }[];
  ratings?: { value?: number; createdAt?: string }[];
  url?: string;
  description?: string;
  code?: string;
};

type FiltersResponse = {
  categories: string[];
  merchants: MerchantInfo[];
  merchantStates: string[];
};

type PromotionPageResponse = {
  data: PromotionRecord[];
  totalCount: number;
  totalPages: number;
  currentPage: number;
  pageSize: number;
};

const PAGE_SIZE_OPTIONS = [10, 20, 50];

const SORT_OPTIONS = [
  { value: 'createdAt', label: 'Newest' },
  { value: 'endDate', label: 'Ending soon' },
  { value: 'clickCount', label: 'Most clicks' },
  { value: 'viewCount', label: 'Most views' },
  { value: 'favoriteCount', label: 'Most favorites' },
  { value: 'ctr', label: 'Best CTR' },
  { value: 'qaCount', label: 'Most issues' },
];

const DEFAULT_COLUMNS = {
  merchant: true,
  performance: true,
  quality: true,
  dates: true,
  actions: true,
};

function buildQueryString(searchParams: URLSearchParams, updates: Record<string, string | null>) {
  const next = new URLSearchParams(searchParams.toString());
  Object.entries(updates).forEach(([key, value]) => {
    if (!value || value === 'all') next.delete(key);
    else next.set(key, value);
  });
  return next.toString();
}

function SortHeader({
  label,
  sortKey,
  activeSort,
  activeOrder,
  onToggle,
  align = 'left',
}: {
  label: string;
  sortKey?: string;
  activeSort: string;
  activeOrder: string;
  onToggle: (sortKey: string) => void;
  align?: 'left' | 'right' | 'center';
}) {
  const isActive = sortKey && activeSort === sortKey;
  return (
    <th style={{ textAlign: align }}>
      {sortKey ? (
        <button
          onClick={() => onToggle(sortKey)}
          style={{
            border: 'none',
            background: 'transparent',
            cursor: 'pointer',
            color: 'inherit',
            fontWeight: 700,
            display: 'inline-flex',
            alignItems: 'center',
            gap: '0.35rem',
            padding: 0,
          }}
        >
          {label}
          <span style={{ opacity: isActive ? 1 : 0.45 }}>
            <i className={`fas ${isActive && activeOrder === 'asc' ? 'fa-arrow-up' : 'fa-arrow-down'}`}></i>
          </span>
        </button>
      ) : (
        label
      )}
    </th>
  );
}

function FilterChip({ label, onRemove }: { label: string; onRemove: () => void }) {
  return (
    <button
      onClick={onRemove}
      style={{
        border: '1px solid rgba(99,102,241,0.18)',
        background: 'rgba(99,102,241,0.08)',
        color: '#4f46e5',
        fontSize: '0.75rem',
        fontWeight: 700,
        borderRadius: '999px',
        padding: '0.35rem 0.7rem',
        cursor: 'pointer',
      }}
    >
      {label} ×
    </button>
  );
}

function MetricPill({ label, value, accent }: { label: string; value: string | number; accent?: string }) {
  return (
    <div
      style={{
        border: '1px solid rgba(148,163,184,0.16)',
        background: 'rgba(255,255,255,0.72)',
        borderRadius: '0.85rem',
        padding: '0.45rem 0.6rem',
        minWidth: '72px',
      }}
    >
      <div style={{ fontSize: '0.68rem', color: 'var(--text-secondary)', fontWeight: 700 }}>{label}</div>
      <div style={{ fontSize: '0.88rem', color: accent || 'var(--text-primary)', fontWeight: 800 }}>{value}</div>
    </div>
  );
}

export default function AdminPromotionsPage() {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  const [filtersData, setFiltersData] = useState<FiltersResponse | null>(null);
  const [response, setResponse] = useState<PromotionPageResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [drawerPromotion, setDrawerPromotion] = useState<PromotionRecord | null>(null);
  const [columns, setColumns] = useState(DEFAULT_COLUMNS);

  const query = useMemo(
    () => ({
      q: searchParams.get('q') || '',
      status: searchParams.get('status') || 'all',
      category: searchParams.get('category') || 'all',
      featured: searchParams.get('featured') || 'all',
      merchantId: searchParams.get('merchantId') || 'all',
      merchantState: searchParams.get('merchantState') || 'all',
      dateFrom: searchParams.get('dateFrom') || '',
      dateTo: searchParams.get('dateTo') || '',
      createdFrom: searchParams.get('createdFrom') || '',
      createdTo: searchParams.get('createdTo') || '',
      sortBy: searchParams.get('sortBy') || 'createdAt',
      sortOrder: searchParams.get('sortOrder') || 'desc',
      page: Number(searchParams.get('page') || '1'),
      limit: Number(searchParams.get('limit') || '20'),
    }),
    [searchParams]
  );

  const promotions = response?.data || [];
  const totalCount = response?.totalCount || 0;
  const totalPages = response?.totalPages || 1;
  const currentPage = response?.currentPage || 1;
  const pageSize = response?.pageSize || query.limit;

  useEffect(() => {
    Promise.all([
      AdminAPI.getPromotionsPage({
        ...query,
        merchantId: query.merchantId === 'all' ? '' : query.merchantId,
      }),
      filtersData ? Promise.resolve(filtersData) : AdminAPI.getPromotionFilters(),
    ])
      .then(([pageData, filterMeta]) => {
        setResponse(pageData);
        setFiltersData(filterMeta);
      })
      .catch(() => toast.error('Failed to load promotions.'))
      .finally(() => setLoading(false));
  }, [query, filtersData]);

  useEffect(() => {
    setSelectedIds((prev) => prev.filter((id) => promotions.some((promotion) => getPromotionId(promotion) === id)));
  }, [promotions]);

  const updateQuery = (updates: Record<string, string | null>) => {
    const qs = buildQueryString(searchParams, updates);
    router.replace(qs ? `${pathname}?${qs}` : pathname);
  };

  const pendingCount = useMemo(
    () => promotions.filter((promotion) => promotion.effectiveStatus === 'pending_approval').length,
    [promotions]
  );

  const activeFilterChips = useMemo(() => {
    const chips: { key: string; label: string; clear: Record<string, string | null> }[] = [];
    if (query.q) chips.push({ key: 'q', label: `Search: ${query.q}`, clear: { q: null, page: '1' } });
    if (query.status !== 'all') chips.push({ key: 'status', label: `Status: ${query.status.replace(/_/g, ' ')}`, clear: { status: null, page: '1' } });
    if (query.category !== 'all') chips.push({ key: 'category', label: `Category: ${getAdminCategoryLabel(query.category)}`, clear: { category: null, page: '1' } });
    if (query.featured !== 'all') chips.push({ key: 'featured', label: query.featured === 'true' ? 'Featured only' : 'Non-featured only', clear: { featured: null, page: '1' } });
    if (query.merchantId !== 'all') {
      const merchant = filtersData?.merchants.find((entry) => entry._id === query.merchantId);
      chips.push({ key: 'merchantId', label: `Merchant: ${merchant?.name || 'Selected'}`, clear: { merchantId: null, page: '1' } });
    }
    if (query.merchantState !== 'all') chips.push({ key: 'merchantState', label: `Merchant state: ${query.merchantState.replace(/_/g, ' ')}`, clear: { merchantState: null, page: '1' } });
    if (query.dateFrom || query.dateTo) chips.push({ key: 'dateRange', label: `Deal window: ${query.dateFrom || '...'} to ${query.dateTo || '...'}`, clear: { dateFrom: null, dateTo: null, page: '1' } });
    if (query.createdFrom || query.createdTo) chips.push({ key: 'createdRange', label: `Created: ${query.createdFrom || '...'} to ${query.createdTo || '...'}`, clear: { createdFrom: null, createdTo: null, page: '1' } });
    return chips;
  }, [filtersData?.merchants, query]);

  const allOnPageSelected = promotions.length > 0 && promotions.every((promotion) => selectedIds.includes(getPromotionId(promotion)));

  const refreshPage = async () => {
    setLoading(true);
    try {
      const pageData = await AdminAPI.getPromotionsPage({
        ...query,
        merchantId: query.merchantId === 'all' ? '' : query.merchantId,
      });
      setResponse(pageData);
    } catch {
      toast.error('Failed to refresh promotions.');
    } finally {
      setLoading(false);
    }
  };

  const updateSinglePromotion = async (id: string, payload: Record<string, unknown>, successMessage: string) => {
    setActionLoading(id);
    try {
      await PromotionAPI.update(id, payload);
      toast.success(successMessage);
      await refreshPage();
    } catch {
      toast.error('Failed to update promotion.');
    } finally {
      setActionLoading(null);
    }
  };

  const runBulkAction = async (action: string, value?: string) => {
    if (!selectedIds.length) {
      toast.error('Select at least one promotion first.');
      return;
    }

    setActionLoading(`bulk-${action}`);
    try {
      const result = await AdminAPI.runPromotionBulkAction({ ids: selectedIds, action, value });
      toast.success(`${result.modifiedCount || 0} promotion(s) updated.`);
      setSelectedIds([]);
      await refreshPage();
    } catch {
      toast.error('Bulk action failed.');
    } finally {
      setActionLoading(null);
    }
  };

  const exportCsv = async () => {
    try {
      const exportData = await AdminAPI.getPromotionsPage({
        ...query,
        merchantId: query.merchantId === 'all' ? '' : query.merchantId,
        page: 1,
        limit: 1000,
      });

      const rows = (exportData.data || []).map((promotion: PromotionRecord) => ({
        title: promotion.title || '',
        merchant: getMerchantName(promotion.merchant),
        status: promotion.effectiveStatus || '',
        category: getAdminCategoryLabel(promotion.category),
        featured: promotion.featured ? 'Yes' : 'No',
        views: promotion.viewCount || 0,
        clicks: promotion.clickCount || 0,
        ctr: promotion.ctr || 0,
        favorites: promotion.favoriteCount || 0,
        comments: promotion.commentCount || 0,
        rating: promotion.averageRating || 0,
        issues: (promotion.qaFlags || []).join('|'),
        startDate: promotion.startDate || '',
        endDate: promotion.endDate || '',
      }));

      const headers = Object.keys(rows[0] || {
        title: '',
        merchant: '',
        status: '',
        category: '',
        featured: '',
        views: '',
        clicks: '',
        ctr: '',
        favorites: '',
        comments: '',
        rating: '',
        issues: '',
        startDate: '',
        endDate: '',
      });

      const csv = [
        headers.join(','),
        ...rows.map((row: Record<string, string | number>) =>
          headers
            .map((header) => `"${String(row[header] ?? '').replace(/"/g, '""')}"`)
            .join(',')
        ),
      ].join('\n');

      const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = 'admin-promotions-export.csv';
      link.click();
      URL.revokeObjectURL(url);
    } catch {
      toast.error('Failed to export promotions.');
    }
  };

  const toggleSort = (sortKey: string) => {
    const nextOrder = query.sortBy === sortKey && query.sortOrder === 'desc' ? 'asc' : 'desc';
    updateQuery({ sortBy: sortKey, sortOrder: nextOrder, page: '1' });
  };

  const toggleColumn = (key: keyof typeof DEFAULT_COLUMNS) => {
    setColumns((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  return (
    <div>
      <AdminPageHeader
        title="Promotions"
        subtitle={`${totalCount} promotion${totalCount === 1 ? '' : 's'} matched${activeFilterChips.length ? ' your filters' : ''}`}
        actions={
          <div className="flex gap-2 flex-wrap">
            <button className="modern-button secondary-button" onClick={exportCsv}>
              <i className="fas fa-file-export"></i> Export CSV
            </button>
            <button className="modern-button secondary-button" onClick={refreshPage}>
              <i className="fas fa-rotate"></i> Refresh
            </button>
          </div>
        }
      />

      {pendingCount > 0 && (
        <div
          className="surface-panel panel-pad"
          style={{
            marginBottom: '1rem',
            display: 'flex',
            alignItems: 'center',
            gap: '0.75rem',
            flexWrap: 'wrap',
            background: 'linear-gradient(135deg, rgba(245,158,11,0.1), rgba(249,115,22,0.08))',
            borderColor: 'rgba(245,158,11,0.25)',
          }}
        >
          <i className="fas fa-clock" style={{ color: '#f59e0b' }}></i>
          <span style={{ fontSize: '0.875rem', color: '#92400e', fontWeight: 500 }}>
            {pendingCount} promotion{pendingCount === 1 ? '' : 's'} on this page waiting for approval
          </span>
          <button className="modern-button secondary-button" onClick={() => updateQuery({ status: 'pending_approval', page: '1' })}>
            Review Pending
          </button>
        </div>
      )}

      <AdminFilterBar>
        <div className="input-with-icon toolbar-grow" style={{ maxWidth: '320px' }}>
          <i className="fas fa-search"></i>
          <input
            className="modern-input"
            placeholder="Search title, merchant, category..."
            value={query.q}
            onChange={(e) => updateQuery({ q: e.target.value, page: '1' })}
          />
        </div>
        <select className="modern-select" value={query.status} onChange={(e) => updateQuery({ status: e.target.value, page: '1' })}>
          <option value="all">All statuses</option>
          <option value="active">Active</option>
          <option value="pending_approval">Pending approval</option>
          <option value="scheduled">Scheduled</option>
          <option value="rejected">Rejected</option>
          <option value="admin_paused">Paused</option>
          <option value="expired">Expired</option>
          <option value="draft">Draft</option>
        </select>
        <select className="modern-select" value={query.category} onChange={(e) => updateQuery({ category: e.target.value, page: '1' })}>
          <option value="all">All categories</option>
          {(filtersData?.categories || []).map((category) => (
            <option key={category} value={category}>
              {getAdminCategoryLabel(category)}
            </option>
          ))}
        </select>
        <select className="modern-select" value={query.merchantId} onChange={(e) => updateQuery({ merchantId: e.target.value, page: '1' })}>
          <option value="all">All merchants</option>
          {(filtersData?.merchants || []).map((merchant) => (
            <option key={merchant._id} value={merchant._id}>
              {merchant.name}
            </option>
          ))}
        </select>
        <select className="modern-select" value={query.merchantState} onChange={(e) => updateQuery({ merchantState: e.target.value, page: '1' })}>
          <option value="all">Any merchant state</option>
          {(filtersData?.merchantStates || []).map((state) => (
            <option key={state} value={state}>
              {state.replace(/_/g, ' ')}
            </option>
          ))}
        </select>
        <select className="modern-select" value={query.featured} onChange={(e) => updateQuery({ featured: e.target.value, page: '1' })}>
          <option value="all">Featured + non-featured</option>
          <option value="true">Featured only</option>
          <option value="false">Non-featured only</option>
        </select>
        <select className="modern-select" value={query.sortBy} onChange={(e) => updateQuery({ sortBy: e.target.value, page: '1' })}>
          {SORT_OPTIONS.map((option) => (
            <option key={option.value} value={option.value}>
              Sort: {option.label}
            </option>
          ))}
        </select>
        <select className="modern-select" value={String(query.limit)} onChange={(e) => updateQuery({ limit: e.target.value, page: '1' })}>
          {PAGE_SIZE_OPTIONS.map((size) => (
            <option key={size} value={String(size)}>
              {size} / page
            </option>
          ))}
        </select>
      </AdminFilterBar>

      <AdminFilterBar>
        <input className="modern-input" type="date" value={query.dateFrom} onChange={(e) => updateQuery({ dateFrom: e.target.value || null, page: '1' })} />
        <input className="modern-input" type="date" value={query.dateTo} onChange={(e) => updateQuery({ dateTo: e.target.value || null, page: '1' })} />
        <input className="modern-input" type="date" value={query.createdFrom} onChange={(e) => updateQuery({ createdFrom: e.target.value || null, page: '1' })} />
        <input className="modern-input" type="date" value={query.createdTo} onChange={(e) => updateQuery({ createdTo: e.target.value || null, page: '1' })} />
        <button className="modern-button secondary-button" onClick={() => updateQuery({ dateFrom: null, dateTo: null, createdFrom: null, createdTo: null, page: '1' })}>
          Clear Dates
        </button>
        <div className="flex gap-2 ml-auto flex-wrap">
          {Object.entries(columns).map(([key, enabled]) => (
            <button key={key} className="modern-button secondary-button" onClick={() => toggleColumn(key as keyof typeof DEFAULT_COLUMNS)}>
              <i className={`fas ${enabled ? 'fa-eye' : 'fa-eye-slash'}`}></i> {key}
            </button>
          ))}
        </div>
      </AdminFilterBar>

      {activeFilterChips.length > 0 && (
        <div className="flex gap-2 flex-wrap" style={{ marginBottom: '1rem' }}>
          {activeFilterChips.map((chip) => (
            <FilterChip key={chip.key} label={chip.label} onRemove={() => updateQuery(chip.clear)} />
          ))}
          <button className="modern-button secondary-button" onClick={() => router.replace(pathname)}>
            Clear all
          </button>
        </div>
      )}

      <div
        className="surface-panel panel-pad"
        style={{ marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.75rem', flexWrap: 'wrap' }}
      >
        <strong style={{ fontSize: '0.85rem', color: 'var(--text-primary)' }}>
          {selectedIds.length} selected
        </strong>
        <button className="modern-button secondary-button" disabled={!selectedIds.length || !!actionLoading} onClick={() => runBulkAction('approve')}>
          Approve
        </button>
        <button className="modern-button secondary-button" disabled={!selectedIds.length || !!actionLoading} onClick={() => runBulkAction('reject')}>
          Reject
        </button>
        <button className="modern-button secondary-button" disabled={!selectedIds.length || !!actionLoading} onClick={() => runBulkAction('pause')}>
          Pause
        </button>
        <button className="modern-button secondary-button" disabled={!selectedIds.length || !!actionLoading} onClick={() => runBulkAction('feature')}>
          Feature
        </button>
        <button className="modern-button secondary-button" disabled={!selectedIds.length || !!actionLoading} onClick={() => runBulkAction('unfeature')}>
          Unfeature
        </button>
        <select
          className="modern-select"
          defaultValue=""
          disabled={!selectedIds.length || !!actionLoading}
          onChange={(e) => {
            if (!e.target.value) return;
            runBulkAction('set_category', e.target.value);
            e.target.value = '';
          }}
        >
          <option value="">Fix category...</option>
          {(filtersData?.categories || []).map((category) => (
            <option key={category} value={category}>
              {getAdminCategoryLabel(category)}
            </option>
          ))}
        </select>
        {!!selectedIds.length && (
          <button className="modern-button secondary-button" onClick={() => setSelectedIds([])}>
            Clear selection
          </button>
        )}
      </div>

      <div className="surface-panel overflow-hidden">
        <div className="overflow-x-auto">
          <table className="data-table">
            <thead>
              <tr>
                <th style={{ width: '36px' }}>
                  <input
                    type="checkbox"
                    checked={allOnPageSelected}
                    onChange={() =>
                      setSelectedIds(allOnPageSelected ? [] : promotions.map((promotion) => getPromotionId(promotion)))
                    }
                  />
                </th>
                <SortHeader label="Promotion" sortKey="title" activeSort={query.sortBy} activeOrder={query.sortOrder} onToggle={toggleSort} />
                {columns.merchant && <SortHeader label="Merchant" sortKey="merchant" activeSort={query.sortBy} activeOrder={query.sortOrder} onToggle={toggleSort} />}
                {columns.performance && <SortHeader label="Performance" sortKey="clickCount" activeSort={query.sortBy} activeOrder={query.sortOrder} onToggle={toggleSort} />}
                {columns.quality && <SortHeader label="Quality" sortKey="qaCount" activeSort={query.sortBy} activeOrder={query.sortOrder} onToggle={toggleSort} />}
                {columns.dates && <SortHeader label="Dates" sortKey="endDate" activeSort={query.sortBy} activeOrder={query.sortOrder} onToggle={toggleSort} />}
                {columns.actions && <SortHeader label="Actions" activeSort={query.sortBy} activeOrder={query.sortOrder} onToggle={toggleSort} align="right" />}
              </tr>
            </thead>
            <tbody>
              {loading ? (
                Array.from({ length: 6 }).map((_, index) => (
                  <tr key={index}>
                    <td colSpan={1 + Object.values(columns).filter(Boolean).length} style={{ padding: '0.75rem 1rem' }}>
                      <div className="skeleton" style={{ height: '22px' }}></div>
                    </td>
                  </tr>
                ))
              ) : promotions.length === 0 ? (
                <tr>
                  <td colSpan={1 + Object.values(columns).filter(Boolean).length} style={{ padding: '3rem', textAlign: 'center' }}>
                    <div style={{ maxWidth: '420px', margin: '0 auto' }}>
                      <div style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--text-primary)', marginBottom: '0.4rem' }}>
                        No promotions match this view
                      </div>
                      <div style={{ color: 'var(--text-secondary)', fontSize: '0.9rem', marginBottom: '1rem' }}>
                        Try clearing filters or widening the date window to find more promotions.
                      </div>
                      <button className="modern-button secondary-button" onClick={() => router.replace(pathname)}>
                        Reset filters
                      </button>
                    </div>
                  </td>
                </tr>
              ) : (
                promotions.map((promotion) => {
                  const id = getPromotionId(promotion);
                  const qaFlags = promotion.qaFlags || [];
                  const busy = !!actionLoading;
                  const isPending = promotion.effectiveStatus === 'pending_approval';
                  const canPause = ['active', 'scheduled'].includes(promotion.effectiveStatus || '');
                  const canResume = promotion.effectiveStatus === 'admin_paused';

                  return (
                    <tr key={id}>
                      <td>
                        <input
                          type="checkbox"
                          checked={selectedIds.includes(id)}
                          onChange={() =>
                            setSelectedIds((prev) =>
                              prev.includes(id) ? prev.filter((entry) => entry !== id) : [...prev, id]
                            )
                          }
                        />
                      </td>
                      <td>
                        <div className="flex items-start gap-3">
                          {promotion.image ? (
                            <img
                              src={promotion.image}
                              alt={promotion.title}
                              style={{ width: '42px', height: '42px', borderRadius: '0.7rem', objectFit: 'cover', flexShrink: 0 }}
                            />
                          ) : (
                            <div style={{ width: '42px', height: '42px', borderRadius: '0.7rem', background: 'rgba(148,163,184,0.16)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-secondary)', flexShrink: 0 }}>
                              <i className="fas fa-image"></i>
                            </div>
                          )}
                          <div style={{ minWidth: 0 }}>
                            <button
                              onClick={() => setDrawerPromotion(promotion)}
                              style={{ border: 'none', background: 'transparent', padding: 0, textAlign: 'left', cursor: 'pointer' }}
                            >
                              <div style={{ fontWeight: 700, fontSize: '0.9rem', color: 'var(--text-primary)' }}>{promotion.title || 'Untitled promotion'}</div>
                            </button>
                            <div style={{ color: 'var(--text-secondary)', fontSize: '0.75rem', marginTop: '0.15rem' }}>
                              {getAdminCategoryLabel(promotion.category)}{promotion.featured ? ' · Featured' : ''}
                            </div>
                            <div className="flex gap-2 flex-wrap" style={{ marginTop: '0.45rem' }}>
                              <AdminStatusChip status={promotion.effectiveStatus || promotion.status || 'draft'} />
                              {promotion.featured ? (
                                <span style={{ background: 'rgba(245,158,11,0.12)', color: '#d97706', borderRadius: '999px', padding: '0.2rem 0.55rem', fontSize: '0.68rem', fontWeight: 700 }}>
                                  Featured
                                </span>
                              ) : null}
                            </div>
                          </div>
                        </div>
                      </td>
                      {columns.merchant && (
                        <td>
                          <div style={{ fontSize: '0.86rem', color: 'var(--text-primary)', fontWeight: 700 }}>
                            {getMerchantName(promotion.merchant)}
                          </div>
                          <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', marginTop: '0.15rem' }}>
                            {(promotion.merchantState || 'unknown').replace(/_/g, ' ')}
                          </div>
                        </td>
                      )}
                      {columns.performance && (
                        <td>
                          <div className="flex gap-2 flex-wrap">
                            <MetricPill label="Views" value={promotion.viewCount || 0} />
                            <MetricPill label="Clicks" value={promotion.clickCount || 0} />
                            <MetricPill label="CTR" value={`${promotion.ctr || 0}%`} accent="#0f766e" />
                            <MetricPill label="Favs" value={promotion.favoriteCount || 0} />
                            <MetricPill label="Rating" value={promotion.averageRating || 0} accent="#a16207" />
                          </div>
                          <div style={{ fontSize: '0.72rem', color: 'var(--text-secondary)', marginTop: '0.45rem' }}>
                            {promotion.commentCount || 0} comments · {promotion.ratingsCount || 0} ratings
                          </div>
                        </td>
                      )}
                      {columns.quality && (
                        <td>
                          {qaFlags.length === 0 ? (
                            <span style={{ background: 'rgba(16,185,129,0.1)', color: '#059669', borderRadius: '999px', padding: '0.25rem 0.6rem', fontSize: '0.72rem', fontWeight: 700 }}>
                              Looks good
                            </span>
                          ) : (
                            <div className="flex gap-2 flex-wrap">
                              {qaFlags.slice(0, 3).map((flag) => {
                                const meta = getAdminQaMeta(flag);
                                return (
                                  <span
                                    key={flag}
                                    style={{
                                      background: meta.bg,
                                      color: meta.color,
                                      borderRadius: '999px',
                                      padding: '0.25rem 0.6rem',
                                      fontSize: '0.72rem',
                                      fontWeight: 700,
                                    }}
                                  >
                                    {meta.label}
                                  </span>
                                );
                              })}
                              {qaFlags.length > 3 && (
                                <span style={{ color: 'var(--text-secondary)', fontSize: '0.72rem', fontWeight: 700 }}>
                                  +{qaFlags.length - 3} more
                                </span>
                              )}
                            </div>
                          )}
                        </td>
                      )}
                      {columns.dates && (
                        <td style={{ fontSize: '0.78rem', color: 'var(--text-secondary)' }}>
                          <div>Starts {formatAdminDate(promotion.startDate)}</div>
                          <div>Ends {formatAdminDate(promotion.endDate)}</div>
                          <div style={{ marginTop: '0.35rem', color: promotion.daysRemaining !== undefined && promotion.daysRemaining < 0 ? '#ef4444' : 'var(--text-secondary)', fontWeight: 700 }}>
                            {formatAdminRelativeDays(promotion.daysRemaining)}
                          </div>
                          <div style={{ fontSize: '0.7rem', marginTop: '0.15rem' }}>Age: {promotion.ageDays || 0}d</div>
                        </td>
                      )}
                      {columns.actions && (
                        <td style={{ textAlign: 'right' }}>
                          <div className="flex justify-end gap-2 flex-wrap">
                            <button className="modern-button secondary-button" onClick={() => setDrawerPromotion(promotion)}>
                              Inspect
                            </button>
                            {isPending && (
                              <>
                                <button disabled={busy} className="modern-button secondary-button" onClick={() => updateSinglePromotion(id, { status: 'approved' }, 'Promotion approved.')}>
                                  Approve
                                </button>
                                <button disabled={busy} className="modern-button secondary-button" onClick={() => updateSinglePromotion(id, { status: 'rejected' }, 'Promotion rejected.')}>
                                  Reject
                                </button>
                              </>
                            )}
                            {canPause && (
                              <button disabled={busy} className="modern-button secondary-button" onClick={() => updateSinglePromotion(id, { status: 'admin_paused' }, 'Promotion paused.')}>
                                Pause
                              </button>
                            )}
                            {canResume && (
                              <button disabled={busy} className="modern-button secondary-button" onClick={() => updateSinglePromotion(id, { status: 'active' }, 'Promotion resumed.')}>
                                Resume
                              </button>
                            )}
                            <button disabled={busy} className="modern-button secondary-button" onClick={() => updateSinglePromotion(id, { featured: !promotion.featured }, promotion.featured ? 'Removed from featured.' : 'Marked as featured.')}>
                              {promotion.featured ? 'Unfeature' : 'Feature'}
                            </button>
                          </div>
                        </td>
                      )}
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      <div className="flex items-center justify-between flex-wrap gap-3" style={{ marginTop: '1rem' }}>
        <div style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>
          Showing {(currentPage - 1) * pageSize + (promotions.length ? 1 : 0)}-{(currentPage - 1) * pageSize + promotions.length} of {totalCount}
        </div>
        <div className="flex gap-2">
          <button className="modern-button secondary-button" disabled={currentPage <= 1} onClick={() => updateQuery({ page: String(currentPage - 1) })}>
            Previous
          </button>
          <div style={{ alignSelf: 'center', fontSize: '0.85rem', color: 'var(--text-secondary)' }}>
            Page {currentPage} of {totalPages}
          </div>
          <button className="modern-button secondary-button" disabled={currentPage >= totalPages} onClick={() => updateQuery({ page: String(currentPage + 1) })}>
            Next
          </button>
        </div>
      </div>

      {drawerPromotion && (
        <div
          onClick={() => setDrawerPromotion(null)}
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(15,23,42,0.45)',
            zIndex: 60,
            display: 'flex',
            justifyContent: 'flex-end',
          }}
        >
          <div
            onClick={(e) => e.stopPropagation()}
            style={{
              width: 'min(540px, 100vw)',
              height: '100vh',
              overflowY: 'auto',
              background: 'linear-gradient(180deg, #ffffff, #f8fafc)',
              padding: '1.25rem',
              boxShadow: '-24px 0 60px rgba(15,23,42,0.18)',
            }}
          >
            <div className="flex items-start justify-between gap-3" style={{ marginBottom: '1rem' }}>
              <div>
                <div style={{ fontSize: '1.2rem', fontWeight: 900, color: 'var(--text-primary)' }}>{drawerPromotion.title || 'Untitled promotion'}</div>
                <div style={{ color: 'var(--text-secondary)', fontSize: '0.85rem', marginTop: '0.25rem' }}>
                  {getMerchantName(drawerPromotion.merchant)} · {getAdminCategoryLabel(drawerPromotion.category)}
                </div>
              </div>
              <button className="modern-button secondary-button" onClick={() => setDrawerPromotion(null)}>
                Close
              </button>
            </div>

            <div className="flex gap-2 flex-wrap" style={{ marginBottom: '1rem' }}>
              <AdminStatusChip status={drawerPromotion.effectiveStatus || drawerPromotion.status || 'draft'} />
              {drawerPromotion.featured && (
                <span style={{ background: 'rgba(245,158,11,0.12)', color: '#d97706', borderRadius: '999px', padding: '0.25rem 0.6rem', fontSize: '0.72rem', fontWeight: 700 }}>
                  Featured
                </span>
              )}
              {(drawerPromotion.qaFlags || []).map((flag) => {
                const meta = getAdminQaMeta(flag);
                return (
                  <span key={flag} style={{ background: meta.bg, color: meta.color, borderRadius: '999px', padding: '0.25rem 0.6rem', fontSize: '0.72rem', fontWeight: 700 }}>
                    {meta.label}
                  </span>
                );
              })}
            </div>

            {drawerPromotion.image && (
              <img
                src={drawerPromotion.image}
                alt={drawerPromotion.title}
                style={{ width: '100%', height: '220px', objectFit: 'cover', borderRadius: '1rem', marginBottom: '1rem' }}
              />
            )}

            <div className="grid grid-cols-2 gap-3" style={{ marginBottom: '1rem' }}>
              <MetricPill label="Views" value={drawerPromotion.viewCount || 0} />
              <MetricPill label="Clicks" value={drawerPromotion.clickCount || 0} />
              <MetricPill label="CTR" value={`${drawerPromotion.ctr || 0}%`} accent="#0f766e" />
              <MetricPill label="Favorites" value={drawerPromotion.favoriteCount || 0} />
              <MetricPill label="Comments" value={drawerPromotion.commentCount || 0} />
              <MetricPill label="Avg rating" value={drawerPromotion.averageRating || 0} accent="#a16207" />
            </div>

            <div className="surface-panel panel-pad" style={{ marginBottom: '1rem' }}>
              <div style={{ fontWeight: 800, color: 'var(--text-primary)', marginBottom: '0.65rem' }}>Promotion Summary</div>
              <div style={{ color: 'var(--text-secondary)', fontSize: '0.9rem', lineHeight: 1.6 }}>
                {drawerPromotion.description || 'No description available.'}
              </div>
              <div className="grid grid-cols-2 gap-3" style={{ marginTop: '0.85rem' }}>
                <div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', fontWeight: 700 }}>Discount</div>
                  <div style={{ fontSize: '0.9rem', color: 'var(--text-primary)', fontWeight: 700 }}>{drawerPromotion.discount || '—'}</div>
                </div>
                <div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', fontWeight: 700 }}>Code</div>
                  <div style={{ fontSize: '0.9rem', color: 'var(--text-primary)', fontWeight: 700 }}>{drawerPromotion.code || '—'}</div>
                </div>
                <div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', fontWeight: 700 }}>Start</div>
                  <div style={{ fontSize: '0.9rem', color: 'var(--text-primary)', fontWeight: 700 }}>{formatAdminDate(drawerPromotion.startDate)}</div>
                </div>
                <div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', fontWeight: 700 }}>End</div>
                  <div style={{ fontSize: '0.9rem', color: 'var(--text-primary)', fontWeight: 700 }}>{formatAdminDate(drawerPromotion.endDate)}</div>
                </div>
              </div>
            </div>

            <div className="surface-panel panel-pad" style={{ marginBottom: '1rem' }}>
              <div style={{ fontWeight: 800, color: 'var(--text-primary)', marginBottom: '0.65rem' }}>Merchant Snapshot</div>
              <div style={{ fontSize: '0.95rem', fontWeight: 700, color: 'var(--text-primary)' }}>
                {getMerchantName(drawerPromotion.merchant)}
              </div>
              <div style={{ fontSize: '0.82rem', color: 'var(--text-secondary)', marginTop: '0.25rem' }}>
                Merchant state: {(drawerPromotion.merchantState || 'unknown').replace(/_/g, ' ')}
              </div>
              {typeof drawerPromotion.merchant === 'object' && drawerPromotion.merchant && (
                <div style={{ fontSize: '0.82rem', color: 'var(--text-secondary)', marginTop: '0.25rem' }}>
                  Contact: {(drawerPromotion.merchant as MerchantInfo)?.contactInfo || '—'}
                </div>
              )}
            </div>

            <div className="surface-panel panel-pad">
              <div style={{ fontWeight: 800, color: 'var(--text-primary)', marginBottom: '0.65rem' }}>Quick Actions</div>
              <div className="flex gap-2 flex-wrap">
                <button className="modern-button secondary-button" onClick={() => updateSinglePromotion(getPromotionId(drawerPromotion), { featured: !drawerPromotion.featured }, drawerPromotion.featured ? 'Removed from featured.' : 'Marked as featured.')}>
                  {drawerPromotion.featured ? 'Unfeature' : 'Feature'}
                </button>
                <button className="modern-button secondary-button" onClick={() => updateSinglePromotion(getPromotionId(drawerPromotion), { status: 'approved' }, 'Promotion approved.')}>
                  Approve
                </button>
                <button className="modern-button secondary-button" onClick={() => updateSinglePromotion(getPromotionId(drawerPromotion), { status: 'admin_paused' }, 'Promotion paused.')}>
                  Pause
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
