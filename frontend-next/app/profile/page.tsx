'use client';
import { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { UserAPI } from '@/lib/api';
import toast from 'react-hot-toast';

export default function ProfilePage() {
  const { user, logout, updateUser } = useAuth();
  const router = useRouter();
  const avatarInputRef = useRef<HTMLInputElement>(null);
  const [activeTab, setActiveTab] = useState('profile');
  const [saving, setSaving] = useState(false);
  const [favorites, setFavorites] = useState<any[]>([]);
  const [following, setFollowing] = useState<any[]>([]);
  const [form, setForm] = useState({ name: '', profilePicture: '' });
  const [pwForm, setPwForm] = useState({ currentPassword: '', newPassword: '', confirmPassword: '' });
  const [notifications, setNotifications] = useState({ email: true, expiringDeals: true, favoriteStores: true, recommendations: true });

  useEffect(() => {
    if (!user) { router.push('/login'); return; }
    setForm({ name: user.name || '', profilePicture: user.profilePicture || '' });
    UserAPI.getFavorites(user._id).then(setFavorites).catch(() => {});
    try { setFollowing(JSON.parse(localStorage.getItem('dealFinderFollowing') || '[]')); } catch {}
  }, [user]);

  const handleProfileSave = async (e: React.FormEvent) => {
    e.preventDefault(); setSaving(true);
    try { const updated = await UserAPI.updateProfile(user!._id, { name: form.name, profilePicture: form.profilePicture }); updateUser(updated); toast.success('Profile updated!'); } catch { toast.error('Failed to update profile.'); } finally { setSaving(false); }
  };

  const handleAvatarFile = (file: File) => {
    if (file.size > 5 * 1024 * 1024) { toast.error('Image must be under 5MB'); return; }
    const reader = new FileReader();
    reader.onloadend = () => setForm(prev => ({ ...prev, profilePicture: reader.result as string }));
    reader.readAsDataURL(file);
  };

  const handlePasswordSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (pwForm.newPassword !== pwForm.confirmPassword) { toast.error('Passwords do not match.'); return; }
    setSaving(true);
    try { await UserAPI.changePassword(user!._id, { currentPassword: pwForm.currentPassword, newPassword: pwForm.newPassword }); setPwForm({ currentPassword:'', newPassword:'', confirmPassword:'' }); toast.success('Password updated!'); } catch { toast.error('Failed to update password.'); } finally { setSaving(false); }
  };

  const handleUnfollow = (id: string) => { const updated = following.filter(m => m.id !== id); setFollowing(updated); localStorage.setItem('dealFinderFollowing', JSON.stringify(updated)); };

  const getSafeImage = (url?: string, name?: string) => (url && (url.startsWith('data:') || url.startsWith('http'))) ? url : `https://ui-avatars.com/api/?name=${encodeURIComponent(name||'U')}&background=random&size=100`;

  const TABS = [{ id:'profile', icon:'fa-user-circle', label:'Profile' },{ id:'security', icon:'fa-lock', label:'Security' },{ id:'notifications', icon:'fa-bell', label:'Notifications' },{ id:'favorites', icon:'fa-heart', label:`Favorites (${favorites.length})` },{ id:'following', icon:'fa-store', label:`Following (${following.length})` }];

  if (!user) return null;

  return (
    <div className="page-shell">
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        {/* Sidebar */}
        <div>
          <div className="surface-panel panel-pad">
            <div className="flex flex-col items-center mb-5 text-center">
              <div style={{ width:'72px', height:'72px', borderRadius:'50%', overflow:'hidden', border:'3px solid var(--primary-color)', marginBottom:'0.75rem', boxShadow:'0 16px 28px rgba(37,99,235,0.18)' }}>
                <img src={getSafeImage(form.profilePicture, user.name)} alt="Profile" style={{ width:'100%', height:'100%', objectFit:'cover' }} />
              </div>
              <h2 style={{ fontWeight:700, fontSize:'1rem', color:'var(--text-primary)', margin:0 }}>{user.name}</h2>
              <p style={{ fontSize:'0.8rem', color:'var(--text-secondary)', margin:'0.2rem 0' }}>{user.email}</p>
              {user.role === 'merchant' && <span style={{ fontSize:'0.7rem', fontWeight:600, padding:'0.2rem 0.6rem', borderRadius:'9999px', background:'rgba(99,102,241,0.1)', color:'var(--primary-color)', marginTop:'0.25rem' }}>Merchant</span>}
            </div>
            <nav className="flex flex-col gap-1">
              {TABS.map(t => (
                <button key={t.id} onClick={() => setActiveTab(t.id)} style={{ display:'flex', alignItems:'center', gap:'0.6rem', padding:'0.75rem 0.9rem', borderRadius:'0.95rem', border:'1px solid transparent', cursor:'pointer', fontSize:'0.875rem', fontWeight:500, textAlign:'left', background:activeTab===t.id?'var(--primary-gradient)':'transparent', color:activeTab===t.id?'#fff':'var(--text-secondary)', boxShadow: activeTab===t.id ? '0 16px 28px rgba(37,99,235,0.2)' : 'none' }}>
                  <i className={`fas ${t.icon}`} style={{ width:'16px' }}></i> {t.label}
                </button>
              ))}
              {user.role === 'merchant' && <button onClick={() => router.push('/merchant/dashboard')} style={{ display:'flex', alignItems:'center', gap:'0.6rem', padding:'0.6rem 0.875rem', borderRadius:'0.625rem', border:'none', cursor:'pointer', fontSize:'0.875rem', fontWeight:500, background:'transparent', color:'var(--text-secondary)' }}><i className="fas fa-chart-line" style={{ width:'16px' }}></i> Dashboard</button>}
              <hr style={{ border:'none', borderTop:'1px solid var(--border-color)', margin:'0.5rem 0' }} />
              <button onClick={logout} style={{ display:'flex', alignItems:'center', gap:'0.6rem', padding:'0.6rem 0.875rem', borderRadius:'0.625rem', border:'none', cursor:'pointer', fontSize:'0.875rem', fontWeight:500, background:'transparent', color:'#ef4444' }}><i className="fas fa-sign-out-alt" style={{ width:'16px' }}></i> Logout</button>
            </nav>
          </div>
        </div>

        {/* Main */}
        <div className="md:col-span-3">
          <div className="surface-panel panel-pad">
            {activeTab === 'profile' && (
              <div>
                <h2 style={{ fontSize:'1.25rem', fontWeight:800, marginBottom:'1.5rem', color:'var(--text-primary)' }}>Profile Settings</h2>
                <form onSubmit={handleProfileSave}>
                  {/* Profile Picture Upload */}
                  <div className="flex items-center gap-5 mb-5 p-4 rounded-xl" style={{ background:'rgba(255,255,255,0.72)', border:'1px solid rgba(148,163,184,0.16)' }}>
                    <div style={{ position:'relative', flexShrink:0 }}>
                      <img src={getSafeImage(form.profilePicture, user.name)} alt="Avatar"
                        style={{ width:'80px', height:'80px', borderRadius:'50%', objectFit:'cover', border:'3px solid var(--primary-color)' }} />
                      <button type="button" onClick={() => avatarInputRef.current?.click()}
                        style={{ position:'absolute', bottom:0, right:0, width:'26px', height:'26px', borderRadius:'50%', background:'var(--primary-color)', border:'2px solid var(--card-bg)', color:'#fff', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', fontSize:'0.65rem' }}>
                        <i className="fas fa-camera"></i>
                      </button>
                      <input ref={avatarInputRef} type="file" accept="image/*" style={{ display:'none' }}
                        onChange={e => e.target.files?.[0] && handleAvatarFile(e.target.files[0])} />
                    </div>
                    <div className="flex-1">
                      <p style={{ fontSize:'0.875rem', fontWeight:700, color:'var(--text-primary)', margin:'0 0 0.25rem' }}>Profile Picture</p>
                      <p style={{ fontSize:'0.75rem', color:'var(--text-secondary)', margin:'0 0 0.625rem' }}>JPG, PNG up to 5MB</p>
                      <div className="flex gap-2 flex-wrap">
                        <button type="button" onClick={() => avatarInputRef.current?.click()}
                          className="btn" style={{ fontSize:'0.78rem', padding:'0.35rem 0.75rem', border:'1.5px solid var(--border-color)', background:'var(--card-bg)', color:'var(--text-primary)' }}>
                          <i className="fas fa-upload"></i> Upload Photo
                        </button>
                        {form.profilePicture && (
                          <button type="button" onClick={() => setForm(prev => ({ ...prev, profilePicture: '' }))}
                            style={{ fontSize:'0.78rem', padding:'0.35rem 0.75rem', borderRadius:'0.625rem', border:'1.5px solid rgba(239,68,68,0.3)', background:'rgba(239,68,68,0.06)', color:'#ef4444', cursor:'pointer' }}>
                            <i className="fas fa-trash"></i> Remove
                          </button>
                        )}
                      </div>
                      <input className="modern-input" style={{ marginTop:'0.625rem', fontSize:'0.8rem' }}
                        value={form.profilePicture.startsWith('data:') ? '' : form.profilePicture}
                        onChange={e => setForm({ ...form, profilePicture: e.target.value })}
                        placeholder="Or paste image URL: https://..." />
                    </div>
                  </div>
                  <div style={{ marginBottom:'1rem' }}><label style={{ display:'block', fontSize:'0.85rem', fontWeight:600, marginBottom:'0.4rem', color:'var(--text-primary)' }}>Full Name</label><input className="modern-input" value={form.name} onChange={e=>setForm({...form,name:e.target.value})} required /></div>
                  <div style={{ marginBottom:'1.5rem' }}><label style={{ display:'block', fontSize:'0.85rem', fontWeight:600, marginBottom:'0.4rem', color:'var(--text-primary)' }}>Email</label><input className="modern-input" style={{opacity:0.6,cursor:'not-allowed'}} value={user.email} disabled /><p style={{ fontSize:'0.75rem', color:'var(--text-secondary)', marginTop:'0.25rem' }}>Email cannot be changed</p></div>
                  <button type="submit" disabled={saving} className="btn btn-primary"><i className="fas fa-save"></i> {saving ? 'Saving...' : 'Save Changes'}</button>
                </form>
              </div>
            )}
            {activeTab === 'security' && (
              <div>
                <h2 style={{ fontSize:'1.25rem', fontWeight:800, marginBottom:'1.5rem', color:'var(--text-primary)' }}>Change Password</h2>
                <form onSubmit={handlePasswordSave}>
                  {[['currentPassword','Current Password'],['newPassword','New Password'],['confirmPassword','Confirm New Password']].map(([k,l]) => (
                    <div key={k} style={{ marginBottom:'1rem' }}><label style={{ display:'block', fontSize:'0.85rem', fontWeight:600, marginBottom:'0.4rem', color:'var(--text-primary)' }}>{l}</label><input type="password" className="modern-input" value={(pwForm as any)[k]} onChange={e=>setPwForm({...pwForm,[k]:e.target.value})} required /></div>
                  ))}
                  <button type="submit" disabled={saving} className="btn btn-primary"><i className="fas fa-lock"></i> {saving ? 'Updating...' : 'Update Password'}</button>
                </form>
              </div>
            )}
            {activeTab === 'notifications' && (
              <div>
                <h2 style={{ fontSize:'1.25rem', fontWeight:800, marginBottom:'1.5rem', color:'var(--text-primary)' }}>Notification Preferences</h2>
                <div className="flex flex-col gap-3 mb-5">
                  {Object.keys(notifications).map(k => (
                    <label key={k} style={{ display:'flex', alignItems:'center', gap:'0.75rem', padding:'0.95rem', borderRadius:'1rem', border:'1px solid rgba(148,163,184,0.16)', cursor:'pointer', background:'rgba(255,255,255,0.72)' }}>
                      <input type="checkbox" checked={(notifications as any)[k]} onChange={e=>setNotifications({...notifications,[k]:e.target.checked})} style={{ width:'16px', height:'16px', accentColor:'var(--primary-color)', cursor:'pointer' }} />
                      <span style={{ fontSize:'0.875rem', fontWeight:500, color:'var(--text-primary)' }}>{k.replace(/([A-Z])/g,' $1').replace(/^./,s=>s.toUpperCase())}</span>
                    </label>
                  ))}
                </div>
                <button className="btn btn-primary" onClick={() => toast.success('Preferences saved!')}>Save Preferences</button>
              </div>
            )}
            {activeTab === 'favorites' && (
              <div>
                <h2 style={{ fontSize:'1.25rem', fontWeight:800, marginBottom:'1.5rem', color:'var(--text-primary)' }}>My Favorite Deals</h2>
                {favorites.length === 0 ? <div className="text-center py-12"><div style={{ fontSize:'2.5rem', marginBottom:'0.75rem' }}>💔</div><p style={{ color:'var(--text-secondary)' }}>No favorites yet.</p><Link href="/categories/all" className="btn btn-primary mt-3" style={{ display:'inline-flex' }}>Browse Deals</Link></div> : (
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {favorites.map((p:any) => (
                      <div key={p._id||p.id} style={{ border:'1px solid rgba(148,163,184,0.16)', borderRadius:'1rem', padding:'0.95rem', display:'flex', gap:'0.875rem', alignItems:'center', background:'rgba(255,255,255,0.72)' }}>
                        {p.image && <img src={p.image} alt={p.title} style={{ width:'52px', height:'52px', borderRadius:'0.5rem', objectFit:'cover', flexShrink:0 }} />}
                        <div className="flex-1" style={{ minWidth:0 }}>
                          <p style={{ fontWeight:600, fontSize:'0.875rem', color:'var(--text-primary)', margin:0, overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap' }}>{p.title}</p>
                          <p style={{ fontSize:'0.75rem', color:'var(--primary-color)', margin:'0.1rem 0', fontWeight:600 }}>{p.discount} OFF</p>
                        </div>
                        <button onClick={() => router.push(`/deal/${p._id||p.id}`)} className="btn btn-primary" style={{ fontSize:'0.75rem', padding:'0.3rem 0.6rem' }}>View</button>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}
            {activeTab === 'following' && (
              <div>
                <h2 style={{ fontSize:'1.25rem', fontWeight:800, marginBottom:'1.5rem', color:'var(--text-primary)' }}>Stores You Follow</h2>
                {following.length === 0 ? <div className="text-center py-12"><div style={{ fontSize:'2.5rem', marginBottom:'0.75rem' }}>🏪</div><p style={{ color:'var(--text-secondary)' }}>Not following any stores yet.</p><Link href="/merchants" className="btn btn-primary mt-3" style={{ display:'inline-flex' }}>Browse Stores</Link></div> : (
                  <div className="flex flex-col gap-3">
                    {following.map((m:any) => (
                      <div key={m.id} style={{ border:'1px solid rgba(148,163,184,0.16)', borderRadius:'1rem', padding:'0.95rem', display:'flex', alignItems:'center', gap:'0.875rem', background:'rgba(255,255,255,0.72)' }}>
                        <img src={`https://ui-avatars.com/api/?name=${encodeURIComponent(m.name)}&background=random&size=100`} alt={m.name} style={{ width:'44px', height:'44px', borderRadius:'50%', objectFit:'cover', flexShrink:0 }} />
                        <div className="flex-1"><p style={{ fontWeight:600, fontSize:'0.875rem', color:'var(--text-primary)', margin:0 }}>{m.name}</p>{m.category && <p style={{ fontSize:'0.75rem', color:'var(--text-secondary)', margin:0 }}>{m.category}</p>}</div>
                        <div className="flex gap-2">
                          <Link href={`/merchants/${m.id}`} className="btn btn-primary" style={{ fontSize:'0.75rem', padding:'0.3rem 0.6rem' }}>Visit</Link>
                          <button onClick={() => handleUnfollow(m.id)} style={{ padding:'0.3rem 0.6rem', borderRadius:'0.5rem', border:'1.5px solid var(--border-color)', background:'var(--card-bg)', color:'var(--text-secondary)', fontSize:'0.75rem', cursor:'pointer' }}>Unfollow</button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
