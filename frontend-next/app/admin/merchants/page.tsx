'use client';

import { useEffect, useMemo, useState } from 'react';
import AdminFilterBar from '@/components/admin/AdminFilterBar';
import AdminPageHeader from '@/components/admin/AdminPageHeader';
import AdminStatusChip from '@/components/admin/AdminStatusChip';
import { MerchantAPI } from '@/lib/api';
import { matchesAdminSearch } from '@/lib/admin';
import toast from 'react-hot-toast';

type MerchantRecord = {
  _id: string;
  name?: string;
  logo?: string;
  contactInfo?: string;
  address?: string;
  status?: string;
  promotions?: unknown[];
  activeDeals?: number;
  promotionCount?: number;
  createdAt?: string;
  updatedAt?: string;
};

function getDealCount(merchant: MerchantRecord) {
  if (typeof merchant.activeDeals === 'number') return merchant.activeDeals;
  if (typeof merchant.promotionCount === 'number') return merchant.promotionCount;
  return Array.isArray(merchant.promotions) ? merchant.promotions.length : 0;
}

function getSafeLogo(logo?: string, name?: string) {
  if (logo && (logo.startsWith('data:') || logo.startsWith('http'))) return logo;
  return `https://ui-avatars.com/api/?name=${encodeURIComponent(name || 'M')}&background=random&size=100`;
}

function latestMerchantTime(merchant: MerchantRecord) {
  const raw = merchant.updatedAt || merchant.createdAt;
  const time = raw ? new Date(raw).getTime() : 0;
  return Number.isFinite(time) ? time : 0;
}

function MerchantMetric({
  label,
  value,
  icon,
  tone,
  onClick,
}: {
  label: string;
  value: number;
  icon: string;
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
        minHeight: 104,
        cursor: onClick ? 'pointer' : 'default',
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
          <p style={{ margin: 0, color: 'var(--text-primary)', fontSize: '1.5rem', fontWeight: 850 }}>{value}</p>
        </div>
      </div>
    </button>
  );
}

export default function AdminMerchantsPage() {
  const [merchants, setMerchants] = useState<MerchantRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [dormantOnly, setDormantOnly] = useState(false);
  const [sortMode, setSortMode] = useState('pending_first');
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  const loadMerchants = async () => {
    setLoading(true);
    try {
      const data = await MerchantAPI.getAll();
      setMerchants(Array.isArray(data) ? data : []);
    } catch {
      toast.error('Failed to load merchants.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadMerchants();
  }, []);

  const summary = useMemo(() => {
    const pending = merchants.filter((merchant) => merchant.status === 'pending_approval').length;
    const approved = merchants.filter((merchant) => ['approved', 'active'].includes(merchant.status || 'active')).length;
    const suspended = merchants.filter((merchant) => merchant.status === 'suspended').length;
    const dormant = merchants.filter((merchant) => getDealCount(merchant) === 0).length;
    return { pending, approved, suspended, dormant };
  }, [merchants]);

  const filtered = useMemo(() => {
    let result = [...merchants];

    if (statusFilter !== 'all') {
      result = result.filter((merchant) => (merchant.status || 'active') === statusFilter);
    }
    if (dormantOnly) {
      result = result.filter((merchant) => getDealCount(merchant) === 0);
    }
    if (search.trim()) {
      result = result.filter((merchant) => matchesAdminSearch(search, merchant.name, merchant.contactInfo, merchant.address));
    }

    result.sort((a, b) => {
      if (sortMode === 'deals_desc') return getDealCount(b) - getDealCount(a);
      if (sortMode === 'dormant_first') return getDealCount(a) - getDealCount(b);
      if (sortMode === 'name_asc') return (a.name || '').localeCompare(b.name || '');
      if (sortMode === 'recent') return latestMerchantTime(b) - latestMerchantTime(a);

      const aPending = a.status === 'pending_approval' ? 1 : 0;
      const bPending = b.status === 'pending_approval' ? 1 : 0;
      if (aPending !== bPending) return bPending - aPending;
      return latestMerchantTime(b) - latestMerchantTime(a);
    });

    return result;
  }, [dormantOnly, merchants, search, sortMode, statusFilter]);

  const pendingQueue = useMemo(
    () => merchants.filter((merchant) => merchant.status === 'pending_approval').slice(0, 4),
    [merchants]
  );

  const updateStatus = async (id: string, status: string) => {
    setActionLoading(id + status);
    try {
      await MerchantAPI.update(id, { status });
      setMerchants((prev) => prev.map((merchant) => (merchant._id === id ? { ...merchant, status } : merchant)));
      toast.success(`Merchant ${status.replace(/_/g, ' ')}`);
    } catch {
      toast.error('Failed to update status.');
    } finally {
      setActionLoading(null);
    }
  };

  const handleDelete = async (id: string, name?: string) => {
    if (!confirm(`Delete merchant "${name || 'Unknown merchant'}"? This cannot be undone.`)) return;
    setActionLoading(id + 'delete');
    try {
      await MerchantAPI.delete(id);
      setMerchants((prev) => prev.filter((merchant) => merchant._id !== id));
      toast.success('Merchant deleted.');
    } catch {
      toast.error('Failed to delete.');
    } finally {
      setActionLoading(null);
    }
  };

  return (
    <div>
      <AdminPageHeader
        title="Merchants"
        subtitle={`${filtered.length} shown from ${merchants.length} merchants`}
        actions={
          <button className="btn btn-secondary" onClick={loadMerchants} disabled={loading}>
            <i className="fas fa-rotate"></i>
            Refresh
          </button>
        }
      />

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '0.9rem', marginBottom: '1.1rem' }}>
        <MerchantMetric label="Pending approval" value={summary.pending} icon="fa-clock" tone="#d97706" onClick={() => setStatusFilter('pending_approval')} />
        <MerchantMetric label="Active merchants" value={summary.approved} icon="fa-store" tone="#059669" onClick={() => setStatusFilter('all')} />
        <MerchantMetric label="Suspended" value={summary.suspended} icon="fa-ban" tone="#64748b" onClick={() => setStatusFilter('suspended')} />
        <MerchantMetric label="Dormant stores" value={summary.dormant} icon="fa-moon" tone="#ef4444" onClick={() => setDormantOnly(true)} />
      </div>

      {pendingQueue.length > 0 ? (
        <div className="surface-panel panel-pad" style={{ marginBottom: '1.15rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', gap: '1rem', alignItems: 'center', marginBottom: '0.9rem', flexWrap: 'wrap' }}>
            <div>
              <h2 style={{ margin: 0, fontSize: '1rem', fontWeight: 800, color: 'var(--text-primary)' }}>Approval queue</h2>
              <p style={{ margin: 0, color: 'var(--text-secondary)', fontSize: '0.82rem' }}>Review merchants waiting to go live.</p>
            </div>
            <button
              type="button"
              onClick={() => {
                setStatusFilter('pending_approval');
                setSortMode('pending_first');
              }}
              style={{ border: 'none', background: 'rgba(245,158,11,0.12)', color: '#92400e', borderRadius: '0.7rem', padding: '0.45rem 0.75rem', fontWeight: 800, cursor: 'pointer' }}
            >
              Show all pending
            </button>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '0.75rem' }}>
            {pendingQueue.map((merchant) => (
              <div key={merchant._id} style={{ border: '1px solid rgba(245,158,11,0.22)', borderRadius: '1rem', padding: '0.85rem', background: 'rgba(245,158,11,0.055)' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.7rem', marginBottom: '0.7rem' }}>
                  <span
                    role="img"
                    aria-label={merchant.name || 'Merchant'}
                    style={{
                      width: 38,
                      height: 38,
                      borderRadius: '50%',
                      border: '1px solid var(--border-color)',
                      backgroundImage: `url(${getSafeLogo(merchant.logo, merchant.name)})`,
                      backgroundSize: 'cover',
                      backgroundPosition: 'center',
                    }}
                  />
                  <div>
                    <p style={{ margin: 0, fontWeight: 800, color: 'var(--text-primary)' }}>{merchant.name || 'Unnamed merchant'}</p>
                    <p style={{ margin: 0, fontSize: '0.74rem', color: 'var(--text-secondary)' }}>{merchant.contactInfo || 'No contact'}</p>
                  </div>
                </div>
                <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                  <button className="btn btn-secondary" onClick={() => updateStatus(merchant._id, 'approved')} disabled={!!actionLoading} style={{ padding: '0.42rem 0.7rem', fontSize: '0.75rem', color: '#059669' }}>
                    <i className="fas fa-check"></i> Approve
                  </button>
                  <button className="btn btn-secondary" onClick={() => updateStatus(merchant._id, 'rejected')} disabled={!!actionLoading} style={{ padding: '0.42rem 0.7rem', fontSize: '0.75rem', color: '#ef4444' }}>
                    <i className="fas fa-xmark"></i> Reject
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      ) : null}

      <AdminFilterBar>
        <div className="input-with-icon toolbar-grow" style={{ maxWidth: '400px' }}>
          <i className="fas fa-search"></i>
          <input className="modern-input" placeholder="Search merchants..." value={search} onChange={(e) => setSearch(e.target.value)} />
        </div>
        <select className="modern-select" style={{ maxWidth: '190px' }} value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
          <option value="all">All status</option>
          <option value="active">Active</option>
          <option value="pending_approval">Pending approval</option>
          <option value="approved">Approved</option>
          <option value="rejected">Rejected</option>
          <option value="suspended">Suspended</option>
        </select>
        <select className="modern-select" style={{ maxWidth: '180px' }} value={sortMode} onChange={(e) => setSortMode(e.target.value)}>
          <option value="pending_first">Pending first</option>
          <option value="recent">Recently updated</option>
          <option value="deals_desc">Most active deals</option>
          <option value="dormant_first">Dormant first</option>
          <option value="name_asc">Name A-Z</option>
        </select>
        <button
          onClick={() => setDormantOnly((value) => !value)}
          style={{
            padding: '0.62rem 0.9rem',
            borderRadius: '0.8rem',
            border: `1.5px solid ${dormantOnly ? 'rgba(239,68,68,0.4)' : 'var(--border-color)'}`,
            background: dormantOnly ? 'rgba(239,68,68,0.08)' : 'var(--card-bg)',
            color: dormantOnly ? '#ef4444' : 'var(--text-secondary)',
            fontSize: '0.82rem',
            fontWeight: 700,
            cursor: 'pointer',
            whiteSpace: 'nowrap',
          }}
        >
          <i className="fas fa-moon"></i> Dormant only
        </button>
      </AdminFilterBar>

      <div className="surface-panel overflow-hidden">
        <div className="overflow-x-auto">
          <table className="data-table">
            <thead>
              <tr>
                {['Merchant', 'Contact', 'Deals', 'Status', 'Signals', 'Actions'].map((header) => (
                  <th key={header} style={{ textAlign: header === 'Actions' ? 'right' : 'left' }}>{header}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {loading ? (
                Array.from({ length: 5 }).map((_, index) => (
                  <tr key={index}>
                    <td colSpan={6} style={{ padding: '0.75rem 1rem' }}><div className="skeleton" style={{ height: '20px' }}></div></td>
                  </tr>
                ))
              ) : filtered.length === 0 ? (
                <tr><td colSpan={6} style={{ padding: '3rem', textAlign: 'center', color: 'var(--text-secondary)' }}>No merchants found</td></tr>
              ) : (
                filtered.map((merchant) => {
                  const dealCount = getDealCount(merchant);
                  const status = merchant.status || 'active';

                  return (
                    <tr key={merchant._id}>
                      <td>
                        <div className="flex items-center gap-3">
                          <span
                            role="img"
                            aria-label={merchant.name || 'Merchant'}
                            style={{
                              width: 40,
                              height: 40,
                              borderRadius: '50%',
                              flexShrink: 0,
                              border: '1px solid var(--border-color)',
                              backgroundImage: `url(${getSafeLogo(merchant.logo, merchant.name)})`,
                              backgroundSize: 'cover',
                              backgroundPosition: 'center',
                            }}
                          />
                          <div>
                            <p style={{ fontWeight: 700, fontSize: '0.875rem', color: 'var(--text-primary)', margin: 0 }}>{merchant.name || 'Unnamed merchant'}</p>
                            <p style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', margin: 0 }}>{merchant.address || 'No address added'}</p>
                          </div>
                        </div>
                      </td>
                      <td style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>{merchant.contactInfo || 'No contact'}</td>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                          <span style={{ fontSize: '0.95rem', fontWeight: 800, color: dealCount > 0 ? 'var(--text-primary)' : '#94a3b8' }}>{dealCount}</span>
                          <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>deal{dealCount !== 1 ? 's' : ''}</span>
                        </div>
                      </td>
                      <td><AdminStatusChip status={status} /></td>
                      <td>
                        <div style={{ display: 'flex', gap: '0.35rem', flexWrap: 'wrap' }}>
                          {dealCount === 0 ? <span className="status-chip" style={{ background: 'rgba(239,68,68,0.08)', color: '#ef4444' }}>Dormant</span> : null}
                          {status === 'pending_approval' ? <span className="status-chip" style={{ background: 'rgba(245,158,11,0.12)', color: '#92400e' }}>Needs approval</span> : null}
                          {status === 'approved' && dealCount > 0 ? <span className="status-chip" style={{ background: 'rgba(16,185,129,0.1)', color: '#059669' }}>Ready</span> : null}
                        </div>
                      </td>
                      <td style={{ textAlign: 'right' }}>
                        <div className="flex justify-end gap-2 flex-wrap">
                          {status === 'pending_approval' ? (
                            <>
                              <button className="btn btn-secondary" onClick={() => updateStatus(merchant._id, 'approved')} disabled={actionLoading === merchant._id + 'approved'} style={{ padding: '0.42rem 0.7rem', fontSize: '0.75rem', color: '#059669' }}>
                                <i className="fas fa-check"></i> Approve
                              </button>
                              <button className="btn btn-secondary" onClick={() => updateStatus(merchant._id, 'rejected')} disabled={actionLoading === merchant._id + 'rejected'} style={{ padding: '0.42rem 0.7rem', fontSize: '0.75rem', color: '#ef4444' }}>
                                <i className="fas fa-times"></i> Reject
                              </button>
                            </>
                          ) : null}
                          {['active', 'approved'].includes(status) ? (
                            <button className="btn btn-secondary" onClick={() => updateStatus(merchant._id, 'suspended')} disabled={!!actionLoading} style={{ padding: '0.42rem 0.7rem', fontSize: '0.75rem' }}>
                              <i className="fas fa-ban"></i> Suspend
                            </button>
                          ) : null}
                          {['suspended', 'rejected'].includes(status) ? (
                            <button className="btn btn-secondary" onClick={() => updateStatus(merchant._id, 'active')} disabled={!!actionLoading} style={{ padding: '0.42rem 0.7rem', fontSize: '0.75rem', color: '#059669' }}>
                              <i className="fas fa-undo"></i> Reactivate
                            </button>
                          ) : null}
                          <button className="btn btn-secondary" onClick={() => handleDelete(merchant._id, merchant.name)} disabled={!!actionLoading} style={{ padding: '0.42rem 0.7rem', fontSize: '0.75rem', color: '#ef4444' }}>
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
