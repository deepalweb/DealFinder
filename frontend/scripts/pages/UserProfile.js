function UserProfile() {
  const { useState, useEffect } = React;
  const { useNavigate, Link } = ReactRouterDOM;
  const navigate = useNavigate();

  const [user, setUser] = useState(null);
  const [activeTab, setActiveTab] = useState('profile');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [savedPromotions, setSavedPromotions] = useState([]);
  const [followedMerchants, setFollowedMerchants] = useState([]);
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');
  const [formData, setFormData] = useState({
    name: '', email: '', profilePicture: '',
    currentPassword: '', newPassword: '', confirmPassword: '',
    notifications: { email: true, expiringDeals: true, favoriteStores: true, recommendations: true }
  });

  useEffect(() => {
    try {
      const userData = localStorage.getItem('dealFinderUser');
      if (!userData) { navigate('/login'); return; }
      const u = JSON.parse(userData);
      setUser(u);
      setFormData(prev => ({
        ...prev, name: u.name || '', email: u.email || '', profilePicture: u.profilePicture || '',
        notifications: { ...prev.notifications, ...(u.preferences?.notifications || {}) }
      }));
      setLoading(false);
      if (u._id) {
        window.API.Users.getFavorites(u._id).then(f => setSavedPromotions(f.map(p => ({ ...p, id: p.id || p._id })))).catch(() => {});
      }
      try {
        const following = JSON.parse(localStorage.getItem('dealFinderFollowing') || '[]');
        setFollowedMerchants(following.map(m => ({ ...m, id: m.id || m._id })));
      } catch {}
    } catch {
      setError('Failed to load profile.');
      setLoading(false);
    }
  }, [navigate]);

  const showAlert = (msg, type = 'success') => {
    if (type === 'success') { setSuccess(msg); setError(''); }
    else { setError(msg); setSuccess(''); }
    setTimeout(() => { setSuccess(''); setError(''); }, 4000);
  };

  const handleProfileSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      const updated = await window.API.Users.updateProfile(user._id, {
        name: formData.name, profilePicture: formData.profilePicture,
        preferences: { notifications: formData.notifications }
      });
      const newUser = { ...user, ...updated, profilePicture: formData.profilePicture };
      localStorage.setItem('dealFinderUser', JSON.stringify(newUser));
      setUser(newUser);
      window.dispatchEvent(new Event('authChange'));
      showAlert('Profile updated successfully!');
    } catch { showAlert('Failed to update profile.', 'error'); }
    setSaving(false);
  };

  const handlePasswordSubmit = async (e) => {
    e.preventDefault();
    if (formData.newPassword !== formData.confirmPassword) { showAlert('Passwords do not match.', 'error'); return; }
    setSaving(true);
    try {
      await window.API.Users.changePassword(user._id, { currentPassword: formData.currentPassword, newPassword: formData.newPassword });
      setFormData(prev => ({ ...prev, currentPassword: '', newPassword: '', confirmPassword: '' }));
      showAlert('Password updated successfully!');
    } catch { showAlert('Failed to update password. Check your current password.', 'error'); }
    setSaving(false);
  };

  const handleUnfollow = (merchantId) => {
    const updated = followedMerchants.filter(m => m.id !== merchantId);
    setFollowedMerchants(updated);
    localStorage.setItem('dealFinderFollowing', JSON.stringify(updated));
  };

  const handleRemoveFavorite = async (promotionId) => {
    try {
      await window.API.Users.removeFavorite(user._id, promotionId);
      setSavedPromotions(prev => prev.filter(p => p.id !== promotionId));
    } catch {}
  };

  function getSafeImage(url, name) {
    if (url && (url.startsWith('data:image') || url.startsWith('http'))) return url;
    return `https://ui-avatars.com/api/?name=${encodeURIComponent(name || 'U')}&background=random&size=100`;
  }

  const inputStyle = {
    width:'100%', padding:'0.7rem 1rem', borderRadius:'0.625rem', fontSize:'0.9rem',
    border:'1.5px solid var(--border-color)', background:'var(--card-bg)', color:'var(--text-primary)',
    outline:'none', boxSizing:'border-box', transition:'border-color 0.2s'
  };

  const tabs = [
    { id:'profile', icon:'fa-user-circle', label:'Profile' },
    { id:'security', icon:'fa-lock', label:'Security' },
    { id:'notifications', icon:'fa-bell', label:'Notifications' },
    { id:'favorites', icon:'fa-heart', label:`Favorites (${savedPromotions.length})` },
    { id:'following', icon:'fa-store', label:`Following (${followedMerchants.length})` },
  ];

  if (loading) return (
    <div className="page-container">
      <div className="container py-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
          <div className="skeleton-card p-6" style={{height:'320px'}}></div>
          <div className="md:col-span-3 skeleton-card p-6" style={{height:'320px'}}></div>
        </div>
      </div>
    </div>
  );

  if (!user) return null;

  return (
    <div className="page-container">
      <div className="container py-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">

          {/* Sidebar */}
          <div className="md:col-span-1">
            <div className="promotion-card p-5">
              <div className="flex flex-col items-center mb-5 text-center">
                <div style={{width:'72px',height:'72px',borderRadius:'50%',overflow:'hidden',border:'3px solid var(--primary-color)',marginBottom:'0.75rem'}}>
                  <img src={getSafeImage(formData.profilePicture, user.name)} alt="Profile" style={{width:'100%',height:'100%',objectFit:'cover'}}
                    onError={e => { e.target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(user.name)}&background=random&size=100`; }} />
                </div>
                <h2 style={{fontWeight:700,fontSize:'1rem',color:'var(--text-primary)',margin:0}}>{user.name}</h2>
                <p style={{fontSize:'0.8rem',color:'var(--text-secondary)',margin:'0.2rem 0'}}>{user.email}</p>
                {user.role === 'merchant' && (
                  <span style={{fontSize:'0.7rem',fontWeight:600,padding:'0.2rem 0.6rem',borderRadius:'9999px',background:'rgba(99,102,241,0.1)',color:'var(--primary-color)',marginTop:'0.25rem'}}>
                    Merchant
                  </span>
                )}
              </div>

              <nav className="flex flex-col gap-1">
                {tabs.map(t => (
                  <button key={t.id} onClick={() => setActiveTab(t.id)}
                    style={{
                      display:'flex', alignItems:'center', gap:'0.6rem', padding:'0.6rem 0.875rem',
                      borderRadius:'0.625rem', border:'none', cursor:'pointer', fontSize:'0.875rem', fontWeight:500,
                      textAlign:'left', transition:'all 0.15s',
                      background: activeTab === t.id ? 'linear-gradient(135deg,var(--primary-color),var(--primary-dark))' : 'transparent',
                      color: activeTab === t.id ? '#fff' : 'var(--text-secondary)'
                    }}>
                    <i className={`fas ${t.icon}`} style={{width:'16px'}}></i> {t.label}
                  </button>
                ))}
                {user.role === 'merchant' && (
                  <button onClick={() => navigate('/merchant/dashboard')}
                    style={{display:'flex',alignItems:'center',gap:'0.6rem',padding:'0.6rem 0.875rem',borderRadius:'0.625rem',border:'none',cursor:'pointer',fontSize:'0.875rem',fontWeight:500,background:'transparent',color:'var(--text-secondary)'}}>
                    <i className="fas fa-chart-line" style={{width:'16px'}}></i> Dashboard
                  </button>
                )}
                <hr style={{border:'none',borderTop:'1px solid var(--border-color)',margin:'0.5rem 0'}} />
                <button onClick={() => { localStorage.removeItem('dealFinderUser'); navigate('/login'); }}
                  style={{display:'flex',alignItems:'center',gap:'0.6rem',padding:'0.6rem 0.875rem',borderRadius:'0.625rem',border:'none',cursor:'pointer',fontSize:'0.875rem',fontWeight:500,background:'transparent',color:'#ef4444'}}>
                  <i className="fas fa-sign-out-alt" style={{width:'16px'}}></i> Logout
                </button>
              </nav>
            </div>
          </div>

          {/* Main */}
          <div className="md:col-span-3">
            <div className="promotion-card p-6">
              {success && (
                <div className="flex items-center gap-2 p-3 rounded-lg mb-4" style={{background:'rgba(16,185,129,0.08)',border:'1px solid rgba(16,185,129,0.2)'}}>
                  <i className="fas fa-check-circle" style={{color:'#10b981'}}></i>
                  <p style={{color:'#059669',margin:0,fontSize:'0.875rem'}}>{success}</p>
                </div>
              )}
              {error && (
                <div className="flex items-center gap-2 p-3 rounded-lg mb-4" style={{background:'rgba(239,68,68,0.08)',border:'1px solid rgba(239,68,68,0.2)'}}>
                  <i className="fas fa-exclamation-circle" style={{color:'#ef4444'}}></i>
                  <p style={{color:'#ef4444',margin:0,fontSize:'0.875rem'}}>{error}</p>
                </div>
              )}

              {/* Profile Tab */}
              {activeTab === 'profile' && (
                <div>
                  <h2 style={{fontSize:'1.25rem',fontWeight:800,marginBottom:'1.5rem',color:'var(--text-primary)'}}>Profile Settings</h2>
                  <form onSubmit={handleProfileSubmit}>
                    {/* Avatar */}
                    <div className="flex items-center gap-4 mb-5 p-4 rounded-xl" style={{background:'var(--light-gray)',border:'1px solid var(--border-color)'}}>
                      <img src={getSafeImage(formData.profilePicture, user.name)} alt="Avatar" style={{width:'56px',height:'56px',borderRadius:'50%',objectFit:'cover',border:'2px solid var(--primary-color)'}} />
                      <div className="flex-1">
                        <p style={{fontSize:'0.85rem',fontWeight:600,marginBottom:'0.25rem',color:'var(--text-primary)'}}>Profile Picture</p>
                        <input type="file" accept="image/jpeg,image/png,image/gif"
                          onChange={e => {
                            const file = e.target.files[0];
                            if (!file) return;
                            if (file.size > 2 * 1024 * 1024) { showAlert('Max file size is 2MB.', 'error'); return; }
                            const reader = new FileReader();
                            reader.onloadend = () => setFormData(prev => ({ ...prev, profilePicture: reader.result }));
                            reader.readAsDataURL(file);
                          }}
                          style={{fontSize:'0.8rem',color:'var(--text-secondary)'}}
                        />
                      </div>
                    </div>

                    <div className="mb-4">
                      <label style={{display:'block',fontSize:'0.85rem',fontWeight:600,marginBottom:'0.4rem',color:'var(--text-primary)'}}>Full Name</label>
                      <input type="text" name="name" value={formData.name} onChange={e => setFormData({...formData, name: e.target.value})} style={inputStyle} required />
                    </div>
                    <div className="mb-5">
                      <label style={{display:'block',fontSize:'0.85rem',fontWeight:600,marginBottom:'0.4rem',color:'var(--text-primary)'}}>Email Address</label>
                      <input type="email" value={formData.email} style={{...inputStyle,opacity:0.6,cursor:'not-allowed'}} disabled />
                      <p style={{fontSize:'0.75rem',color:'var(--text-secondary)',marginTop:'0.25rem'}}>Email cannot be changed</p>
                    </div>
                    <button type="submit" disabled={saving} className="btn btn-primary" style={{gap:'0.5rem'}}>
                      {saving ? <><i className="fas fa-spinner fa-spin"></i> Saving...</> : <><i className="fas fa-save"></i> Save Changes</>}
                    </button>
                  </form>
                </div>
              )}

              {/* Security Tab */}
              {activeTab === 'security' && (
                <div>
                  <h2 style={{fontSize:'1.25rem',fontWeight:800,marginBottom:'1.5rem',color:'var(--text-primary)'}}>Change Password</h2>
                  <form onSubmit={handlePasswordSubmit}>
                    {['currentPassword','newPassword','confirmPassword'].map((field, i) => (
                      <div key={field} className="mb-4">
                        <label style={{display:'block',fontSize:'0.85rem',fontWeight:600,marginBottom:'0.4rem',color:'var(--text-primary)'}}>
                          {['Current Password','New Password','Confirm New Password'][i]}
                        </label>
                        <input type="password" value={formData[field]} onChange={e => setFormData({...formData, [field]: e.target.value})} style={inputStyle} required />
                      </div>
                    ))}
                    <button type="submit" disabled={saving} className="btn btn-primary" style={{gap:'0.5rem'}}>
                      {saving ? <><i className="fas fa-spinner fa-spin"></i> Updating...</> : <><i className="fas fa-lock"></i> Update Password</>}
                    </button>
                  </form>
                </div>
              )}

              {/* Notifications Tab */}
              {activeTab === 'notifications' && (
                <div>
                  <h2 style={{fontSize:'1.25rem',fontWeight:800,marginBottom:'1.5rem',color:'var(--text-primary)'}}>Notification Preferences</h2>
                  <form onSubmit={handleProfileSubmit}>
                    <div className="flex flex-col gap-3 mb-5">
                      {Object.keys(formData.notifications).map(key => (
                        <label key={key} style={{display:'flex',alignItems:'center',gap:'0.75rem',padding:'0.875rem',borderRadius:'0.75rem',border:'1.5px solid var(--border-color)',cursor:'pointer',background:'var(--card-bg)'}}>
                          <input type="checkbox" checked={formData.notifications[key]}
                            onChange={e => setFormData(prev => ({ ...prev, notifications: { ...prev.notifications, [key]: e.target.checked } }))}
                            style={{width:'16px',height:'16px',accentColor:'var(--primary-color)',cursor:'pointer'}} />
                          <span style={{fontSize:'0.875rem',fontWeight:500,color:'var(--text-primary)'}}>
                            {key.replace(/([A-Z])/g, ' $1').replace(/^./, s => s.toUpperCase())}
                          </span>
                        </label>
                      ))}
                    </div>
                    <button type="submit" disabled={saving} className="btn btn-primary" style={{gap:'0.5rem'}}>
                      {saving ? <><i className="fas fa-spinner fa-spin"></i> Saving...</> : 'Save Preferences'}
                    </button>
                  </form>
                </div>
              )}

              {/* Favorites Tab */}
              {activeTab === 'favorites' && (
                <div>
                  <h2 style={{fontSize:'1.25rem',fontWeight:800,marginBottom:'1.5rem',color:'var(--text-primary)'}}>My Favorite Deals</h2>
                  {savedPromotions.length === 0 ? (
                    <div className="text-center py-12">
                      <div style={{fontSize:'2.5rem',marginBottom:'0.75rem'}}>💔</div>
                      <p style={{color:'var(--text-secondary)'}}>No favorites yet.</p>
                      <Link to="/categories/all" className="btn btn-primary mt-3" style={{display:'inline-flex',gap:'0.5rem'}}>Browse Deals</Link>
                    </div>
                  ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {savedPromotions.map(p => (
                        <div key={p.id} style={{border:'1.5px solid var(--border-color)',borderRadius:'0.875rem',padding:'0.875rem',display:'flex',gap:'0.875rem',alignItems:'center',background:'var(--card-bg)'}}>
                          {p.image && <img src={p.image} alt={p.title} style={{width:'52px',height:'52px',borderRadius:'0.5rem',objectFit:'cover',flexShrink:0}} />}
                          <div className="flex-1" style={{minWidth:0}}>
                            <p style={{fontWeight:600,fontSize:'0.875rem',color:'var(--text-primary)',margin:0,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{p.title}</p>
                            <p style={{fontSize:'0.75rem',color:'var(--primary-color)',margin:'0.1rem 0',fontWeight:600}}>{p.discount} OFF</p>
                          </div>
                          <div className="flex gap-2">
                            <button onClick={() => navigate(`/deal/${p.id}`)} className="btn btn-primary" style={{fontSize:'0.75rem',padding:'0.3rem 0.6rem'}}>View</button>
                            <button onClick={() => handleRemoveFavorite(p.id)} style={{background:'none',border:'1.5px solid var(--border-color)',borderRadius:'0.5rem',padding:'0.3rem 0.6rem',cursor:'pointer',color:'#ef4444',fontSize:'0.75rem'}}>
                              <i className="fas fa-trash"></i>
                            </button>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              )}

              {/* Following Tab */}
              {activeTab === 'following' && (
                <div>
                  <h2 style={{fontSize:'1.25rem',fontWeight:800,marginBottom:'1.5rem',color:'var(--text-primary)'}}>Stores You Follow</h2>
                  {followedMerchants.length === 0 ? (
                    <div className="text-center py-12">
                      <div style={{fontSize:'2.5rem',marginBottom:'0.75rem'}}>🏪</div>
                      <p style={{color:'var(--text-secondary)'}}>You're not following any stores yet.</p>
                      <Link to="/merchants" className="btn btn-primary mt-3" style={{display:'inline-flex',gap:'0.5rem'}}>Browse Stores</Link>
                    </div>
                  ) : (
                    <div className="flex flex-col gap-3">
                      {followedMerchants.map(m => (
                        <div key={m.id} style={{border:'1.5px solid var(--border-color)',borderRadius:'0.875rem',padding:'0.875rem',display:'flex',alignItems:'center',gap:'0.875rem',background:'var(--card-bg)'}}>
                          <img src={`https://ui-avatars.com/api/?name=${encodeURIComponent(m.name)}&background=random&size=100`} alt={m.name} style={{width:'44px',height:'44px',borderRadius:'50%',objectFit:'cover',flexShrink:0}} />
                          <div className="flex-1">
                            <p style={{fontWeight:600,fontSize:'0.875rem',color:'var(--text-primary)',margin:0}}>{m.name}</p>
                            {m.category && <p style={{fontSize:'0.75rem',color:'var(--text-secondary)',margin:0}}>{m.category}</p>}
                          </div>
                          <div className="flex gap-2">
                            <Link to={`/merchants/${m.id}`} className="btn btn-primary" style={{fontSize:'0.75rem',padding:'0.3rem 0.6rem'}}>Visit</Link>
                            <button onClick={() => handleUnfollow(m.id)} style={{background:'none',border:'1.5px solid var(--border-color)',borderRadius:'0.5rem',padding:'0.3rem 0.6rem',cursor:'pointer',color:'var(--text-secondary)',fontSize:'0.75rem'}}>
                              Unfollow
                            </button>
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
    </div>
  );
}

window.UserProfile = UserProfile;
