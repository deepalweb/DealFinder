'use client';

import { useState, useEffect } from 'react';
import { MerchantAPI } from '@/lib/api';
import toast from 'react-hot-toast';

const STATUS_STYLES: Record<string, { bg: string; color: string }> = {
  active: { bg: 'rgba(16,185,129,0.1)', color: '#059669' },
  pending_approval: { bg: 'rgba(245,158,11,0.1)', color: '#d97706' },
  approved: { bg: 'rgba(16,185,129,0.1)', color: '#059669' },
  rejected: { bg: 'rgba(239,68,68,0.1)', color: '#ef4444' },
  suspended: { bg: 'rgba(100,116,139,0.1)', color: '#64748b' },
  needs_review: { bg: 'rgba(99,102,241,0.1)', color: '#6366f1' },
};

export default function AdminMerchantsPage() {
  const [merchants, setMerchants] = useState<any[]>([]);
  const [filtered, setFiltered] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  useEffect(() => {
    MerchantAPI.getAll().then(data => { setMerchants(data); setFiltered(data); }).catch(() => toast.error('Failed to load merchants.')).finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    let result = [...merchants];
    if (statusFilter !== 'all') result = result.filter(m => m.status === statusFilter);
    if (search) { const t = search.toLowerCase(); result = result.filter(m => m.name?.toLowerCase().includes(t)); }
    setFiltered(result);
  }, [merchants, search, statusFilter]);

  const updateStatus = async (id: string, status: string) => {
    setActionLoading(id + status);
    try {
      await MerchantAPI.update(id, { status });
      setMerchants(prev => prev.map(m => m._id === id ? { ...m, status } : m));
      toast.success(`Merchant ${status.replace('_', ' ')}`);
    } catch { toast.error('Failed to update status.'); }
    finally { setActionLoading(null); }
  };

  const handleDelete = async (id: string, name: string) => {
    if (!confirm(`Delete merchant "${name}"? This cannot be undone.`)) return;
    try { await MerchantAPI.delete(id); setMerchants(prev => prev.filter(m => m._id !== id)); toast.success('Merchant deleted.'); } catch { toast.error('Failed to delete.'); }
  };

  const getSafeLogo = (logo: string, name: string) => (logo && (logo.startsWith('data:') || logo.startsWith('http'))) ? logo : `https://ui-avatars.com/api/?name=${encodeURIComponent(name || 'M')}&background=random&size=100`;
  const inputStyle = { padding:'0.5rem 0.875rem', borderRadius:'0.625rem', border:'1.5px solid var(--border-color)', background:'var(--card-bg)', color:'var(--text-primary)', fontSize:'0.875rem', outline:'none' };

  return (
    <div>
      <div className="flex items-center justify-between mb-6 flex-wrap gap-3">
        <div>
          <h1 style={{ fontSize:'1.75rem', fontWeight:800, color:'var(--text-primary)', margin:0, letterSpacing:'-0.02em' }}>Merchants</h1>
          <p style={{ color:'var(--text-secondary)', margin:0, fontSize:'0.875rem' }}>{filtered.length} of {merchants.length} merchants</p>
        </div>
      </div>

      {/* Pending alert */}
      {merchants.filter(m => m.status === 'pending_approval').length > 0 && (
        <div style={{ padding:'0.875rem 1.25rem', borderRadius:'0.875rem', background:'rgba(245,158,11,0.08)', border:'1px solid rgba(245,158,11,0.25)', marginBottom:'1.25rem', display:'flex', alignItems:'center', gap:'0.75rem' }}>
          <i className="fas fa-clock" style={{ color:'#f59e0b' }}></i>
          <span style={{ fontSize:'0.875rem', color:'#92400e', fontWeight:500 }}>
            {merchants.filter(m => m.status === 'pending_approval').length} merchant(s) waiting for approval
          </span>
          <button onClick={() => setStatusFilter('pending_approval')} style={{ marginLeft:'auto', fontSize:'0.75rem', fontWeight:700, color:'#92400e', padding:'0.25rem 0.625rem', borderRadius:'0.375rem', background:'rgba(245,158,11,0.15)', border:'none', cursor:'pointer' }}>
            Review Now
          </button>
        </div>
      )}

      {/* Filters */}
      <div className="flex flex-col md:flex-row gap-3 mb-5">
        <div style={{ position:'relative', flex:1, maxWidth:'400px' }}>
          <i className="fas fa-search" style={{ position:'absolute', left:'0.875rem', top:'50%', transform:'translateY(-50%)', color:'var(--text-secondary)', pointerEvents:'none' }}></i>
          <input style={{ ...inputStyle, width:'100%', paddingLeft:'2.5rem', boxSizing:'border-box' }} placeholder="Search merchants..." value={search} onChange={e => setSearch(e.target.value)} />
        </div>
        <select style={inputStyle} value={statusFilter} onChange={e => setStatusFilter(e.target.value)}>
          <option value="all">All Status</option>
          <option value="active">Active</option>
          <option value="pending_approval">Pending Approval</option>
          <option value="approved">Approved</option>
          <option value="rejected">Rejected</option>
          <option value="suspended">Suspended</option>
        </select>
      </div>

      {/* Table */}
      <div className="promotion-card overflow-hidden">
        <div className="overflow-x-auto">
          <table style={{ width:'100%', borderCollapse:'collapse' }}>
            <thead>
              <tr style={{ background:'var(--light-gray)', borderBottom:'1.5px solid var(--border-color)' }}>
                {['Merchant','Category','Status','Actions'].map(h => (
                  <th key={h} style={{ padding:'0.75rem 1rem', textAlign:h==='Actions'?'right':'left', fontSize:'0.75rem', fontWeight:700, color:'var(--text-secondary)', textTransform:'uppercase', letterSpacing:'0.05em' }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {loading ? Array.from({ length:5 }).map((_,i) => (
                <tr key={i}><td colSpan={4} style={{ padding:'0.75rem 1rem' }}><div className="skeleton" style={{ height:'20px' }}></div></td></tr>
              )) : filtered.length === 0 ? (
                <tr><td colSpan={4} style={{ padding:'3rem', textAlign:'center', color:'var(--text-secondary)' }}>No merchants found</td></tr>
              ) : filtered.map(m => (
                <tr key={m._id} style={{ borderBottom:'1px solid var(--border-color)' }}
                  onMouseEnter={e => (e.currentTarget.style.background = 'var(--light-gray)')}
                  onMouseLeave={e => (e.currentTarget.style.background = 'transparent')}>
                  <td style={{ padding:'0.75rem 1rem' }}>
                    <div className="flex items-center gap-3">
                      <img src={getSafeLogo(m.logo, m.name)} alt={m.name} style={{ width:'36px', height:'36px', borderRadius:'50%', objectFit:'cover', flexShrink:0, border:'1px solid var(--border-color)' }}
                        onError={(e:any) => { e.target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(m.name)}&background=random&size=100`; }} />
                      <div>
                        <p style={{ fontWeight:600, fontSize:'0.875rem', color:'var(--text-primary)', margin:0 }}>{m.name}</p>
                        <p style={{ fontSize:'0.75rem', color:'var(--text-secondary)', margin:0 }}>{m.contactInfo || '—'}</p>
                      </div>
                    </div>
                  </td>
                  <td style={{ padding:'0.75rem 1rem', fontSize:'0.875rem', color:'var(--text-secondary)', textTransform:'capitalize' }}>{m.category || '—'}</td>
                  <td style={{ padding:'0.75rem 1rem' }}>
                    <span style={{ padding:'0.2rem 0.6rem', borderRadius:'9999px', fontSize:'0.75rem', fontWeight:700, background: STATUS_STYLES[m.status]?.bg || 'var(--light-gray)', color: STATUS_STYLES[m.status]?.color || 'var(--text-secondary)' }}>
                      {m.status?.replace(/_/g,' ') || 'active'}
                    </span>
                  </td>
                  <td style={{ padding:'0.75rem 1rem', textAlign:'right' }}>
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
