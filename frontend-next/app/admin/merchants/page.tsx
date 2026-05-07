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
  status?: string;
  promotions?: unknown[];
  activeDeals?: number;
};

export default function AdminMerchantsPage() {
  const [merchants, setMerchants] = useState<MerchantRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [dormantOnly, setDormantOnly] = useState(false);
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  useEffect(() => {
    MerchantAPI.getAll().then(setMerchants).catch(() => toast.error('Failed to load merchants.')).finally(() => setLoading(false));
  }, []);

  const getDealCount = (merchant: MerchantRecord) =>
    typeof merchant.activeDeals === 'number'
      ? merchant.activeDeals
      : Array.isArray(merchant.promotions)
        ? merchant.promotions.length
        : 0;

  const filtered = useMemo(() => {
    let result = [...merchants];
    if (statusFilter !== 'all') result = result.filter((merchant) => merchant.status === statusFilter);
    if (dormantOnly) result = result.filter((merchant) => getDealCount(merchant) === 0);
    if (search.trim()) result = result.filter((merchant) => matchesAdminSearch(search, merchant.name, merchant.contactInfo));
    return result;
  }, [dormantOnly, merchants, search, statusFilter]);

  const updateStatus = async (id: string, status: string) => {
    setActionLoading(id + status);
    try {
      await MerchantAPI.update(id, { status });
      setMerchants(prev => prev.map(m => m._id === id ? { ...m, status } : m));
      toast.success(`Merchant ${status.replace('_', ' ')}`);
    } catch { toast.error('Failed to update status.'); }
    finally { setActionLoading(null); }
  };

  const handleDelete = async (id: string, name?: string) => {
    if (!confirm(`Delete merchant "${name || 'Unknown merchant'}"? This cannot be undone.`)) return;
    try { await MerchantAPI.delete(id); setMerchants(prev => prev.filter(m => m._id !== id)); toast.success('Merchant deleted.'); } catch { toast.error('Failed to delete.'); }
  };

  const getSafeLogo = (logo?: string, name?: string) => (logo && (logo.startsWith('data:') || logo.startsWith('http'))) ? logo : `https://ui-avatars.com/api/?name=${encodeURIComponent(name || 'M')}&background=random&size=100`;
  return (
    <div>
      <AdminPageHeader title="Merchants" subtitle={`${filtered.length} of ${merchants.length} merchants`} />

      {/* Pending alert */}
      {merchants.filter(m => m.status === 'pending_approval').length > 0 && (
        <div className="surface-panel panel-pad" style={{ marginBottom:'1.25rem', display:'flex', alignItems:'center', gap:'0.75rem', background:'linear-gradient(135deg, rgba(245,158,11,0.1), rgba(249,115,22,0.08))', borderColor:'rgba(245,158,11,0.25)' }}>
          <i className="fas fa-clock" style={{ color:'#f59e0b' }}></i>
          <span style={{ fontSize:'0.875rem', color:'#92400e', fontWeight:500 }}>
            {merchants.filter(m => m.status === 'pending_approval').length} merchant(s) waiting for approval
          </span>
          <button onClick={() => setStatusFilter('pending_approval')} style={{ marginLeft:'auto', fontSize:'0.75rem', fontWeight:700, color:'#92400e', padding:'0.25rem 0.625rem', borderRadius:'0.375rem', background:'rgba(245,158,11,0.15)', border:'none', cursor:'pointer' }}>
            Review Now
          </button>
        </div>
      )}

      <AdminFilterBar>
        <div className="input-with-icon toolbar-grow" style={{ maxWidth:'400px' }}>
          <i className="fas fa-search"></i>
          <input className="modern-input" placeholder="Search merchants..." value={search} onChange={e => setSearch(e.target.value)} />
        </div>
        <select className="modern-select" style={{ maxWidth:'190px' }} value={statusFilter} onChange={e => setStatusFilter(e.target.value)}>
          <option value="all">All Status</option>
          <option value="active">Active</option>
          <option value="pending_approval">Pending Approval</option>
          <option value="approved">Approved</option>
          <option value="rejected">Rejected</option>
          <option value="suspended">Suspended</option>
        </select>
        <button onClick={() => setDormantOnly(d => !d)} style={{ padding:'0.5rem 0.875rem', borderRadius:'0.625rem', border:`1.5px solid ${dormantOnly ? 'rgba(239,68,68,0.4)' : 'var(--border-color)'}`, background: dormantOnly ? 'rgba(239,68,68,0.08)' : 'var(--card-bg)', color: dormantOnly ? '#ef4444' : 'var(--text-secondary)', fontSize:'0.875rem', fontWeight:600, cursor:'pointer', whiteSpace:'nowrap' }}>
          <i className="fas fa-moon mr-1"></i> Dormant only {dormantOnly && `(${filtered.length})`}
        </button>
      </AdminFilterBar>

      <div className="surface-panel overflow-hidden">
        <div className="overflow-x-auto">
          <table className="data-table">
            <thead><tr>{['Merchant','Deals','Status','Actions'].map(h => (
              <th key={h} style={{ textAlign:h==='Actions'?'right':'left' }}>{h}</th>
            ))}</tr></thead>
            <tbody>
              {loading ? Array.from({ length:5 }).map((_,i) => (
                <tr key={i}><td colSpan={4} style={{ padding:'0.75rem 1rem' }}><div className="skeleton" style={{ height:'20px' }}></div></td></tr>
              )) : filtered.length === 0 ? (
                <tr><td colSpan={4} style={{ padding:'3rem', textAlign:'center', color:'var(--text-secondary)' }}>No merchants found</td></tr>
              ) : filtered.map(m => (
                <tr key={m._id}>
                  <td>
                    <div className="flex items-center gap-3">
                      <img src={getSafeLogo(m.logo, m.name)} alt={m.name} style={{ width:'36px', height:'36px', borderRadius:'50%', objectFit:'cover', flexShrink:0, border:'1px solid var(--border-color)' }}
                        onError={(e:any) => { e.target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(m.name || 'M')}&background=random&size=100`; }} />
                      <div>
                        <p style={{ fontWeight:600, fontSize:'0.875rem', color:'var(--text-primary)', margin:0 }}>{m.name}</p>
                        <p style={{ fontSize:'0.75rem', color:'var(--text-secondary)', margin:0 }}>{m.contactInfo || '—'}</p>
                      </div>
                    </div>
                  </td>
                  <td>
                    <div style={{ display:'flex', alignItems:'center', gap:'0.4rem' }}>
                      <span style={{ fontSize:'0.875rem', fontWeight:700, color: getDealCount(m) > 0 ? 'var(--text-primary)' : '#94a3b8' }}>
                        {getDealCount(m)}
                      </span>
                      <span style={{ fontSize:'0.75rem', color:'var(--text-secondary)' }}>deal{getDealCount(m) !== 1 ? 's' : ''}</span>
                      {getDealCount(m) === 0 && (
                        <span style={{ fontSize:'0.7rem', color:'#ef4444', fontWeight:600, background:'rgba(239,68,68,0.08)', padding:'0.15rem 0.4rem', borderRadius:'9999px' }}>dormant</span>
                      )}
                    </div>
                  </td>
                  <td>
                    <AdminStatusChip status={m.status || 'active'} />
                  </td>
                  <td style={{ textAlign:'right' }}>
                    <div className="flex justify-end gap-2 flex-wrap">
                      {m.status === 'pending_approval' && (
                        <>
                          <button onClick={() => updateStatus(m._id, 'approved')} disabled={actionLoading === m._id+'approved'} style={{ padding:'0.3rem 0.75rem', borderRadius:'0.5rem', border:'1.5px solid rgba(16,185,129,0.3)', background:'rgba(16,185,129,0.08)', color:'#059669', fontSize:'0.8rem', fontWeight:600, cursor:'pointer' }}>
                            <i className="fas fa-check"></i> Approve
                          </button>
                          <button onClick={() => updateStatus(m._id, 'rejected')} disabled={actionLoading === m._id+'rejected'} style={{ padding:'0.3rem 0.75rem', borderRadius:'0.5rem', border:'1.5px solid rgba(239,68,68,0.3)', background:'rgba(239,68,68,0.06)', color:'#ef4444', fontSize:'0.8rem', fontWeight:600, cursor:'pointer' }}>
                            <i className="fas fa-times"></i> Reject
                          </button>
                        </>
                      )}
                      {m.status === 'active' && (
                        <button onClick={() => updateStatus(m._id, 'suspended')} style={{ padding:'0.3rem 0.75rem', borderRadius:'0.5rem', border:'1.5px solid rgba(100,116,139,0.3)', background:'rgba(100,116,139,0.06)', color:'#64748b', fontSize:'0.8rem', fontWeight:600, cursor:'pointer' }}>
                          <i className="fas fa-ban"></i> Suspend
                        </button>
                      )}
                      {(m.status === 'suspended' || m.status === 'rejected') && (
                        <button onClick={() => updateStatus(m._id, 'active')} style={{ padding:'0.3rem 0.75rem', borderRadius:'0.5rem', border:'1.5px solid rgba(16,185,129,0.3)', background:'rgba(16,185,129,0.08)', color:'#059669', fontSize:'0.8rem', fontWeight:600, cursor:'pointer' }}>
                          <i className="fas fa-undo"></i> Reactivate
                        </button>
                      )}
                      <button onClick={() => handleDelete(m._id, m.name)} style={{ padding:'0.3rem 0.75rem', borderRadius:'0.5rem', border:'1.5px solid rgba(239,68,68,0.3)', background:'rgba(239,68,68,0.06)', color:'#ef4444', fontSize:'0.8rem', fontWeight:600, cursor:'pointer' }}>
                        <i className="fas fa-trash-alt"></i>
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
