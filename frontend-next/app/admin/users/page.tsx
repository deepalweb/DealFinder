'use client';

import { useState, useEffect } from 'react';
import { UserAPI } from '@/lib/api';
import toast from 'react-hot-toast';

const ROLE_COLORS: Record<string, { bg: string; color: string }> = {
  admin: { bg: 'rgba(239,68,68,0.1)', color: '#ef4444' },
  merchant: { bg: 'rgba(99,102,241,0.1)', color: '#6366f1' },
  user: { bg: 'rgba(16,185,129,0.1)', color: '#10b981' },
};

export default function AdminUsersPage() {
  const [users, setUsers] = useState<any[]>([]);
  const [filtered, setFiltered] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('all');
  const [editUser, setEditUser] = useState<any>(null);
  const [editRole, setEditRole] = useState('');
  const [saving, setSaving] = useState(false);

  const fetchUsers = () => {
    setLoading(true);
    UserAPI.getAll().then(data => { setUsers(data); setFiltered(data); }).catch(() => toast.error('Failed to load users.')).finally(() => setLoading(false));
  };

  useEffect(() => { fetchUsers(); }, []);

  useEffect(() => {
    let result = [...users];
    if (roleFilter !== 'all') result = result.filter(u => u.role === roleFilter);
    if (search) { const t = search.toLowerCase(); result = result.filter(u => u.name?.toLowerCase().includes(t) || u.email?.toLowerCase().includes(t)); }
    setFiltered(result);
  }, [users, search, roleFilter]);

  const handleDelete = async (id: string, name: string) => {
    if (!confirm(`Delete user "${name}"? This cannot be undone.`)) return;
    try { await UserAPI.delete(id); setUsers(prev => prev.filter(u => u._id !== id)); toast.success('User deleted.'); } catch { toast.error('Failed to delete user.'); }
  };

  const handleEditSave = async () => {
    if (!editUser) return;
    setSaving(true);
    try { await UserAPI.updateProfile(editUser._id, { role: editRole }); setUsers(prev => prev.map(u => u._id === editUser._id ? { ...u, role: editRole } : u)); setEditUser(null); toast.success('User updated.'); } catch { toast.error('Failed to update user.'); } finally { setSaving(false); }
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6 flex-wrap gap-3">
        <div>
          <h1 style={{ fontSize:'1.75rem', fontWeight:800, color:'var(--text-primary)', margin:0, letterSpacing:'-0.02em' }}>Users</h1>
          <p style={{ color:'var(--text-secondary)', margin:0, fontSize:'0.875rem' }}>{filtered.length} of {users.length} users</p>
        </div>
      </div>

      {/* Filters */}
      <div className="glass-toolbar mb-5">
        <div className="input-with-icon toolbar-grow" style={{ maxWidth:'400px' }}>
          <i className="fas fa-search"></i>
          <input className="modern-input" placeholder="Search by name or email..." value={search} onChange={e => setSearch(e.target.value)} />
        </div>
        <select className="modern-select" style={{ maxWidth:'180px' }} value={roleFilter} onChange={e => setRoleFilter(e.target.value)}>
          <option value="all">All Roles</option>
          <option value="user">Users</option>
          <option value="merchant">Merchants</option>
          <option value="admin">Admins</option>
        </select>
      </div>

      {/* Table */}
      <div className="surface-panel overflow-hidden">
        <div className="overflow-x-auto">
          <table className="data-table">
            <thead><tr>{['User','Email','Role','Joined','Actions'].map(h => (
              <th key={h} style={{ textAlign:h==='Actions'?'right':'left' }}>{h}</th>
            ))}</tr></thead>
            <tbody>
              {loading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i}><td colSpan={5} style={{ padding:'0.75rem 1rem' }}><div className="skeleton" style={{ height:'20px' }}></div></td></tr>
                ))
              ) : filtered.length === 0 ? (
                <tr><td colSpan={5} style={{ padding:'3rem', textAlign:'center', color:'var(--text-secondary)' }}>No users found</td></tr>
              ) : filtered.map(u => (
                <tr key={u._id}>
                  <td>
                    <div className="flex items-center gap-3">
                      <div style={{ width:'36px', height:'36px', borderRadius:'50%', background:'var(--primary-gradient)', display:'flex', alignItems:'center', justifyContent:'center', color:'#fff', fontWeight:700, fontSize:'0.8rem', flexShrink:0 }}>
                        {u.name?.charAt(0).toUpperCase()}
                      </div>
                      <span style={{ fontWeight:600, fontSize:'0.875rem', color:'var(--text-primary)' }}>{u.name}</span>
                    </div>
                  </td>
                  <td style={{ fontSize:'0.875rem', color:'var(--text-secondary)' }}>{u.email}</td>
                  <td>
                    <span className="status-chip" style={{ background: ROLE_COLORS[u.role]?.bg || 'var(--light-gray)', color: ROLE_COLORS[u.role]?.color || 'var(--text-secondary)' }}>
                      {u.role}
                    </span>
                  </td>
                  <td style={{ fontSize:'0.8rem', color:'var(--text-secondary)' }}>
                    {u.createdAt ? new Date(u.createdAt).toLocaleDateString('en-US', { month:'short', day:'numeric', year:'numeric' }) : '—'}
                  </td>
                  <td style={{ textAlign:'right' }}>
                    <div className="flex justify-end gap-2">
                      <button onClick={() => { setEditUser(u); setEditRole(u.role); }} style={{ padding:'0.3rem 0.75rem', borderRadius:'0.5rem', border:'1.5px solid var(--border-color)', background:'var(--card-bg)', color:'var(--primary-color)', fontSize:'0.8rem', fontWeight:600, cursor:'pointer' }}>
                        <i className="fas fa-edit"></i> Edit
                      </button>
                      {u.role !== 'admin' && (
                        <button onClick={() => handleDelete(u._id, u.name)} style={{ padding:'0.3rem 0.75rem', borderRadius:'0.5rem', border:'1.5px solid rgba(239,68,68,0.3)', background:'rgba(239,68,68,0.06)', color:'#ef4444', fontSize:'0.8rem', fontWeight:600, cursor:'pointer' }}>
                          <i className="fas fa-trash-alt"></i>
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Edit Modal */}
      {editUser && (
        <div style={{ position:'fixed', inset:0, background:'rgba(0,0,0,0.6)', display:'flex', alignItems:'center', justifyContent:'center', zIndex:50, backdropFilter:'blur(4px)' }}>
          <div className="surface-panel panel-pad" style={{ width:'100%', maxWidth:'400px', boxShadow:'0 24px 64px rgba(0,0,0,0.3)' }}>
            <h3 style={{ fontWeight:800, fontSize:'1.1rem', color:'var(--text-primary)', marginBottom:'1.25rem' }}>Edit User Role</h3>
            <div style={{ padding:'0.875rem', borderRadius:'0.75rem', background:'var(--light-gray)', marginBottom:'1.25rem' }}>
              <p style={{ fontWeight:600, fontSize:'0.875rem', color:'var(--text-primary)', margin:0 }}>{editUser.name}</p>
              <p style={{ fontSize:'0.8rem', color:'var(--text-secondary)', margin:'0.2rem 0 0' }}>{editUser.email}</p>
            </div>
            <label style={{ display:'block', fontSize:'0.85rem', fontWeight:600, marginBottom:'0.4rem', color:'var(--text-primary)' }}>Role</label>
            <select value={editRole} onChange={e => setEditRole(e.target.value)} className="modern-select" style={{ width:'100%', marginBottom:'1.25rem', boxSizing:'border-box' as const }}>
              <option value="user">User</option>
              <option value="merchant">Merchant</option>
              <option value="admin">Admin</option>
            </select>
            <div className="flex justify-end gap-3">
              <button onClick={() => setEditUser(null)} style={{ padding:'0.6rem 1.25rem', borderRadius:'0.625rem', border:'1.5px solid var(--border-color)', background:'var(--card-bg)', color:'var(--text-secondary)', fontWeight:600, cursor:'pointer', fontSize:'0.875rem' }}>Cancel</button>
              <button onClick={handleEditSave} disabled={saving} className="btn btn-primary">
                {saving ? <><i className="fas fa-spinner fa-spin"></i> Saving...</> : 'Save Changes'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
