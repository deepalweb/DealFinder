'use client';

import { useState, useEffect } from 'react';
import { AdminAPI, PromotionAPI } from '@/lib/api';
import { getPromotionImage } from '@/lib/utils/promotion-image';
import toast from 'react-hot-toast';

const STATUS_STYLES: Record<string, { bg: string; color: string }> = {
  active: { bg: 'rgba(16,185,129,0.1)', color: '#059669' },
  approved: { bg: 'rgba(16,185,129,0.1)', color: '#059669' },
  pending_approval: { bg: 'rgba(245,158,11,0.1)', color: '#d97706' },
  scheduled: { bg: 'rgba(99,102,241,0.1)', color: '#6366f1' },
  rejected: { bg: 'rgba(239,68,68,0.1)', color: '#ef4444' },
  admin_paused: { bg: 'rgba(100,116,139,0.1)', color: '#64748b' },
  expired: { bg: 'rgba(100,116,139,0.1)', color: '#64748b' },
  draft: { bg: 'rgba(100,116,139,0.1)', color: '#64748b' },
};

export default function AdminPromotionsPage() {
  const [promotions, setPromotions] = useState<any[]>([]);
  const [filtered, setFiltered] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  useEffect(() => {
    AdminAPI.getAllPromotions().then(data => {
      const arr = Array.isArray(data) ? data : [];
      setPromotions(arr);
      setFiltered(arr);
    }).catch(() => toast.error('Failed to load promotions.')).finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    let result = [...promotions];
    if (statusFilter !== 'all') result = result.filter(p => p.status === statusFilter);
    if (categoryFilter !== 'all') result = result.filter(p => p.category === categoryFilter);
    if (search) { const t = search.toLowerCase(); result = result.filter(p => p.title?.toLowerCase().includes(t) || (typeof p.merchant === 'object' ? p.merchant?.name : p.merchant)?.toLowerCase().includes(t)); }
    setFiltered(result);
  }, [promotions, search, statusFilter, categoryFilter]);

  const updateStatus = async (id: string, status: string) => {
    setActionLoading(id + status);
    try {
      await PromotionAPI.update(id, { status });
      setPromotions(prev => prev.map(p => (p._id || p.id) === id ? { ...p, status } : p));
      toast.success(`Promotion ${status.replace(/_/g,' ')}`);
    } catch { toast.error('Failed to update status.'); }
    finally { setActionLoading(null); }
  };

  const toggleFeatured = async (p: any) => {
    const id = p._id || p.id;
    try {
      await PromotionAPI.update(id, { featured: !p.featured });
      setPromotions(prev => prev.map(x => (x._id || x.id) === id ? { ...x, featured: !x.featured } : x));
      toast.success(p.featured ? 'Removed from featured' : 'Marked as featured');
    } catch { toast.error('Failed to update.'); }
  };

  const handleDelete = async (id: string, title: string) => {
    if (!confirm(`Delete "${title}"? This cannot be undone.`)) return;
    try { await PromotionAPI.delete(id); setPromotions(prev => prev.filter(p => (p._id || p.id) !== id)); toast.success('Promotion deleted.'); } catch { toast.error('Failed to delete.'); }
  };

  const getMerchantName = (m: any) => typeof m === 'object' ? m?.name : m || '—';
  const fmt = (d: string) => new Date(d).toLocaleDateString('en-US', { month:'short', day:'numeric', year:'numeric' });
  return (
    <div>
      <div className="flex items-center justify-between mb-6 flex-wrap gap-3">
        <div>
          <h1 style={{ fontSize:'1.75rem', fontWeight:800, color:'var(--text-primary)', margin:0, letterSpacing:'-0.02em' }}>Promotions</h1>
          <p style={{ color:'var(--text-secondary)', margin:0, fontSize:'0.875rem' }}>{filtered.length} of {promotions.length} promotions</p>
        </div>
      </div>

      {/* Pending alert */}
      {promotions.filter(p => p.status === 'pending_approval').length > 0 && (
        <div className="surface-panel panel-pad" style={{ marginBottom:'1.25rem', display:'flex', alignItems:'center', gap:'0.75rem', background:'linear-gradient(135deg, rgba(245,158,11,0.1), rgba(249,115,22,0.08))', borderColor:'rgba(245,158,11,0.25)' }}>
          <i className="fas fa-clock" style={{ color:'#f59e0b' }}></i>
          <span style={{ fontSize:'0.875rem', color:'#92400e', fontWeight:500 }}>
            {promotions.filter(p => p.status === 'pending_approval').length} promotion(s) waiting for approval
          </span>
          <button onClick={() => setStatusFilter('pending_approval')} style={{ marginLeft:'auto', fontSize:'0.75rem', fontWeight:700, color:'#92400e', padding:'0.25rem 0.625rem', borderRadius:'0.375rem', background:'rgba(245,158,11,0.15)', border:'none', cursor:'pointer' }}>
            Review Now
          </button>
        </div>
      )}

      {/* Filters */}
      <div className="glass-toolbar mb-5">
        <div className="input-with-icon toolbar-grow" style={{ maxWidth:'400px' }}>
          <i className="fas fa-search"></i>
          <input className="modern-input" placeholder="Search promotions..." value={search} onChange={e => setSearch(e.target.value)} />
        </div>
        <select className="modern-select" style={{ maxWidth:'190px' }} value={statusFilter} onChange={e => setStatusFilter(e.target.value)}>
          <option value="all">All Status</option>
          <option value="active">Active</option>
          <option value="pending_approval">Pending Approval</option>
          <option value="approved">Approved</option>
          <option value="scheduled">Scheduled</option>
          <option value="rejected">Rejected</option>
          <option value="admin_paused">Paused</option>
          <option value="expired">Expired</option>
        </select>
        <select className="modern-select" style={{ maxWidth:'210px' }} value={categoryFilter} onChange={e => setCategoryFilter(e.target.value)}>
          <option value="all">All Categories</option>
          {[...new Set(promotions.map(p => p.category).filter(Boolean))].sort().map(cat => (
            <option key={cat} value={cat}>{cat.charAt(0).toUpperCase() + cat.slice(1).replace(/_/g, ' ')}</option>
          ))}
        </select>
      </div>

      {/* Table */}
      <div className="surface-panel overflow-hidden">
        <div className="overflow-x-auto">
          <table className="data-table">
            <thead><tr>{['Promotion','Merchant','Discount','Status','Dates','Actions'].map(h => (
              <th key={h} style={{ textAlign:h==='Actions'?'right':'left' }}>{h}</th>
            ))}</tr></thead>
            <tbody>
              {loading ? Array.from({ length:5 }).map((_,i) => (
                <tr key={i}><td colSpan={6} style={{ padding:'0.75rem 1rem' }}><div className="skeleton" style={{ height:'20px' }}></div></td></tr>
              )) : filtered.length === 0 ? (
                <tr><td colSpan={6} style={{ padding:'3rem', textAlign:'center', color:'var(--text-secondary)' }}>No promotions found</td></tr>
              ) : filtered.map(p => {
                const id = p._id || p.id;
                return (
                  <tr key={id}>
                    <td>
                      <div className="flex items-center gap-3">
                        <img src={getPromotionImage(p)} alt={p.title} style={{ width:'36px', height:'36px', borderRadius:'0.5rem', objectFit:'cover', flexShrink:0 }} />
                        <div>
                          <p style={{ fontWeight:600, fontSize:'0.875rem', color:'var(--text-primary)', margin:0 }}>{p.title}</p>
                          <p style={{ fontSize:'0.75rem', color:'var(--text-secondary)', margin:0 }}>{p.category}</p>
                        </div>
                      </div>
                    </td>
                    <td style={{ fontSize:'0.875rem', color:'var(--text-secondary)' }}>{getMerchantName(p.merchant)}</td>
                    <td>
                      <span className="discount-badge" style={{ position:'static', fontSize:'0.72rem' }}>{p.discount} OFF</span>
                      {p.featured && <span style={{ display:'block', fontSize:'0.7rem', color:'#d97706', fontWeight:700, marginTop:'0.2rem' }}>⭐ Featured</span>}
                    </td>
                    <td>
                      <span className="status-chip" style={{ background: STATUS_STYLES[p.status]?.bg || 'var(--light-gray)', color: STATUS_STYLES[p.status]?.color || 'var(--text-secondary)' }}>
                        {p.status?.replace(/_/g,' ') || '—'}
                      </span>
                    </td>
                    <td style={{ fontSize:'0.75rem', color:'var(--text-secondary)' }}>
                      {fmt(p.startDate)}<br/>{fmt(p.endDate)}
                    </td>
                    <td style={{ textAlign:'right' }}>
                      <div className="flex justify-end gap-2 flex-wrap">
                        {p.status === 'pending_approval' && (
                          <>
                            <button onClick={() => updateStatus(id, 'approved')} disabled={!!actionLoading} style={{ padding:'0.3rem 0.6rem', borderRadius:'0.5rem', border:'1.5px solid rgba(16,185,129,0.3)', background:'rgba(16,185,129,0.08)', color:'#059669', fontSize:'0.75rem', fontWeight:600, cursor:'pointer' }}>
                              <i className="fas fa-check"></i> Approve
                            </button>
                            <button onClick={() => updateStatus(id, 'rejected')} disabled={!!actionLoading} style={{ padding:'0.3rem 0.6rem', borderRadius:'0.5rem', border:'1.5px solid rgba(239,68,68,0.3)', background:'rgba(239,68,68,0.06)', color:'#ef4444', fontSize:'0.75rem', fontWeight:600, cursor:'pointer' }}>
                              <i className="fas fa-times"></i> Reject
                            </button>
                          </>
                        )}
                        {['active','approved'].includes(p.status) && (
                          <button onClick={() => updateStatus(id, 'admin_paused')} disabled={!!actionLoading} style={{ padding:'0.3rem 0.6rem', borderRadius:'0.5rem', border:'1.5px solid rgba(100,116,139,0.3)', background:'rgba(100,116,139,0.06)', color:'#64748b', fontSize:'0.75rem', fontWeight:600, cursor:'pointer' }}>
                            <i className="fas fa-pause"></i> Pause
                          </button>
                        )}
                        {p.status === 'admin_paused' && (
                          <button onClick={() => updateStatus(id, 'active')} disabled={!!actionLoading} style={{ padding:'0.3rem 0.6rem', borderRadius:'0.5rem', border:'1.5px solid rgba(16,185,129,0.3)', background:'rgba(16,185,129,0.08)', color:'#059669', fontSize:'0.75rem', fontWeight:600, cursor:'pointer' }}>
                            <i className="fas fa-play"></i> Resume
                          </button>
                        )}
                        <button onClick={() => toggleFeatured(p)} style={{ padding:'0.3rem 0.6rem', borderRadius:'0.5rem', border:`1.5px solid ${p.featured ? 'rgba(245,158,11,0.3)' : 'var(--border-color)'}`, background: p.featured ? 'rgba(245,158,11,0.08)' : 'var(--card-bg)', color: p.featured ? '#d97706' : 'var(--text-secondary)', fontSize:'0.75rem', fontWeight:600, cursor:'pointer' }}>
                          {p.featured ? '⭐' : '☆'}
                        </button>
                        <button onClick={() => handleDelete(id, p.title)} style={{ padding:'0.3rem 0.6rem', borderRadius:'0.5rem', border:'1.5px solid rgba(239,68,68,0.3)', background:'rgba(239,68,68,0.06)', color:'#ef4444', fontSize:'0.75rem', fontWeight:600, cursor:'pointer' }}>
                          <i className="fas fa-trash-alt"></i>
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
