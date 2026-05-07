'use client';

import { useEffect, useMemo, useState } from 'react';
import AdminFilterBar from '@/components/admin/AdminFilterBar';
import AdminPageHeader from '@/components/admin/AdminPageHeader';
import AdminStatusChip from '@/components/admin/AdminStatusChip';
import { UserAPI } from '@/lib/api';
import { formatAdminDate, matchesAdminSearch } from '@/lib/admin';
import toast from 'react-hot-toast';

type UserRecord = {
  _id: string;
  name?: string;
  email?: string;
  role?: string;
  createdAt?: string;
};

export default function AdminUsersPage() {
  const [users, setUsers] = useState<UserRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('all');
  const [editUser, setEditUser] = useState<UserRecord | null>(null);
  const [editRole, setEditRole] = useState('');
  const [saving, setSaving] = useState(false);

  const fetchUsers = () => {
    setLoading(true);
    UserAPI.getAll().then(setUsers).catch(() => toast.error('Failed to load users.')).finally(() => setLoading(false));
  };

  useEffect(() => { fetchUsers(); }, []);

  const filtered = useMemo(() => {
    let result = [...users];
    if (roleFilter !== 'all') result = result.filter((user) => user.role === roleFilter);
    if (search.trim()) {
      result = result.filter((user) => matchesAdminSearch(search, user.name, user.email));
    }
    return result;
  }, [roleFilter, search, users]);

  const handleDelete = async (id: string, name?: string) => {
    if (!confirm(`Delete user "${name || 'Unknown user'}"? This cannot be undone.`)) return;
    try { await UserAPI.delete(id); setUsers(prev => prev.filter(u => u._id !== id)); toast.success('User deleted.'); } catch { toast.error('Failed to delete user.'); }
  };

  const handleEditSave = async () => {
    if (!editUser) return;
    setSaving(true);
    try { await UserAPI.updateProfile(editUser._id, { role: editRole }); setUsers(prev => prev.map(u => u._id === editUser._id ? { ...u, role: editRole } : u)); setEditUser(null); toast.success('User updated.'); } catch { toast.error('Failed to update user.'); } finally { setSaving(false); }
  };

  return (
    <div>
      <AdminPageHeader title="Users" subtitle={`${filtered.length} of ${users.length} users`} />

      <AdminFilterBar>
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
      </AdminFilterBar>

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
                    <AdminStatusChip status={u.role} />
                  </td>
                  <td style={{ fontSize:'0.8rem', color:'var(--text-secondary)' }}>
                    {formatAdminDate(u.createdAt)}
                  </td>
                  <td style={{ textAlign:'right' }}>
                    <div className="flex justify-end gap-2">
                      <button onClick={() => { setEditUser(u); setEditRole(u.role || 'user'); }} style={{ padding:'0.3rem 0.75rem', borderRadius:'0.5rem', border:'1.5px solid var(--border-color)', background:'var(--card-bg)', color:'var(--primary-color)', fontSize:'0.8rem', fontWeight:600, cursor:'pointer' }}>
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
