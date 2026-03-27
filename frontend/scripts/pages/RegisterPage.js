function RegisterPage() {
  const { useState } = React;
  const { useNavigate, Link } = ReactRouterDOM;
  const navigate = useNavigate();

  const [formData, setFormData] = useState({
    name: '', email: '', password: '', confirmPassword: '',
    role: 'user', businessName: '', notifications: true
  });
  const [errors, setErrors] = useState({});
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData({ ...formData, [name]: type === 'checkbox' ? checked : value });
    if (errors[name]) setErrors({ ...errors, [name]: '' });
  };

  const validate = () => {
    const e = {};
    if (!formData.name.trim()) e.name = 'Name is required';
    if (!formData.email.trim()) e.email = 'Email is required';
    else if (!/\S+@\S+\.\S+/.test(formData.email)) e.email = 'Invalid email';
    if (!formData.password) e.password = 'Password is required';
    else if (formData.password.length < 8) e.password = 'Minimum 8 characters';
    if (formData.password !== formData.confirmPassword) e.confirmPassword = 'Passwords do not match';
    if (formData.role === 'merchant' && !formData.businessName.trim()) e.businessName = 'Business name is required';
    setErrors(e);
    return Object.keys(e).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validate()) return;
    setLoading(true);
    try {
      const response = await window.API.Users.register({
        name: formData.name, email: formData.email, password: formData.password,
        role: formData.role, businessName: formData.role === 'merchant' ? formData.businessName : undefined
      });
      localStorage.setItem('dealFinderUser', JSON.stringify(response));
      navigate(response.role === 'merchant' ? '/merchant/dashboard' : '/');
    } catch {
      setErrors({ form: 'Registration failed. This email may already be in use.' });
    } finally {
      setLoading(false);
    }
  };

  const inputStyle = (hasError) => ({
    width: '100%', padding: '0.75rem 1rem', borderRadius: '0.625rem', fontSize: '0.9rem',
    border: `1.5px solid ${hasError ? '#ef4444' : 'var(--border-color)'}`,
    background: 'var(--card-bg)', color: 'var(--text-primary)', outline: 'none', boxSizing: 'border-box'
  });

  return (
    <div className="page-container" style={{display:'flex',alignItems:'center',justifyContent:'center',minHeight:'calc(100vh - 160px)',padding:'2rem 1rem'}}>
      <div className="fade-in" style={{width:'100%',maxWidth:'460px'}}>
        {/* Logo */}
        <div className="text-center mb-6">
          <div className="inline-flex items-center gap-2 mb-2">
            <span style={{background:'linear-gradient(135deg,#6366f1,#f43f5e)',borderRadius:'0.625rem',padding:'0.4rem 0.7rem',color:'#fff',fontSize:'1.1rem',fontWeight:800}}>%</span>
            <span style={{fontSize:'1.4rem',fontWeight:800,color:'var(--text-primary)',letterSpacing:'-0.02em'}}>DealFinder</span>
          </div>
          <h1 style={{fontSize:'1.6rem',fontWeight:800,color:'var(--text-primary)',letterSpacing:'-0.02em',margin:'0.5rem 0 0.25rem'}}>Create your account</h1>
          <p style={{color:'var(--text-secondary)',fontSize:'0.9rem'}}>Join thousands of deal hunters</p>
        </div>

        <div className="promotion-card p-6">
          {errors.form && (
            <div className="flex items-center gap-2 p-3 rounded-lg mb-4" style={{background:'rgba(239,68,68,0.08)',border:'1px solid rgba(239,68,68,0.2)'}}>
              <i className="fas fa-exclamation-circle" style={{color:'#ef4444'}}></i>
              <p style={{color:'#ef4444',margin:0,fontSize:'0.875rem'}}>{errors.form}</p>
            </div>
          )}

          <form onSubmit={handleSubmit}>
            {/* Account Type */}
            <div className="mb-4">
              <label style={{display:'block',fontSize:'0.85rem',fontWeight:600,marginBottom:'0.5rem',color:'var(--text-primary)'}}>Account Type</label>
              <div className="flex gap-3">
                {[['user','fa-user','Regular User'],['merchant','fa-store','Merchant']].map(([val, icon, label]) => (
                  <button key={val} type="button" onClick={() => setFormData({...formData, role: val})}
                    style={{
                      flex:1, padding:'0.625rem', borderRadius:'0.625rem', cursor:'pointer',
                      border: `1.5px solid ${formData.role === val ? 'var(--primary-color)' : 'var(--border-color)'}`,
                      background: formData.role === val ? 'rgba(99,102,241,0.08)' : 'var(--card-bg)',
                      color: formData.role === val ? 'var(--primary-color)' : 'var(--text-secondary)',
                      fontWeight: 600, fontSize:'0.85rem', display:'flex', alignItems:'center', justifyContent:'center', gap:'0.4rem'
                    }}>
                    <i className={`fas ${icon}`}></i> {label}
                  </button>
                ))}
              </div>
            </div>

            <div className="mb-3">
              <label style={{display:'block',fontSize:'0.85rem',fontWeight:600,marginBottom:'0.4rem',color:'var(--text-primary)'}}>Full Name</label>
              <input type="text" name="name" value={formData.name} onChange={handleChange} style={inputStyle(errors.name)} placeholder="John Doe" />
              {errors.name && <p style={{color:'#ef4444',fontSize:'0.75rem',marginTop:'0.25rem'}}>{errors.name}</p>}
            </div>

            <div className="mb-3">
              <label style={{display:'block',fontSize:'0.85rem',fontWeight:600,marginBottom:'0.4rem',color:'var(--text-primary)'}}>Email Address</label>
              <input type="email" name="email" value={formData.email} onChange={handleChange} style={inputStyle(errors.email)} placeholder="you@example.com" />
              {errors.email && <p style={{color:'#ef4444',fontSize:'0.75rem',marginTop:'0.25rem'}}>{errors.email}</p>}
            </div>

            <div className="mb-3">
              <label style={{display:'block',fontSize:'0.85rem',fontWeight:600,marginBottom:'0.4rem',color:'var(--text-primary)'}}>Password</label>
              <div style={{position:'relative'}}>
                <input type={showPassword ? 'text' : 'password'} name="password" value={formData.password} onChange={handleChange} style={{...inputStyle(errors.password),paddingRight:'2.75rem'}} placeholder="Min. 8 characters" />
                <button type="button" onClick={() => setShowPassword(!showPassword)} style={{position:'absolute',right:'0.875rem',top:'50%',transform:'translateY(-50%)',background:'none',border:'none',color:'var(--text-secondary)',cursor:'pointer'}}>
                  <i className={`fas ${showPassword ? 'fa-eye-slash' : 'fa-eye'}`}></i>
                </button>
              </div>
              {errors.password && <p style={{color:'#ef4444',fontSize:'0.75rem',marginTop:'0.25rem'}}>{errors.password}</p>}
            </div>

            <div className="mb-3">
              <label style={{display:'block',fontSize:'0.85rem',fontWeight:600,marginBottom:'0.4rem',color:'var(--text-primary)'}}>Confirm Password</label>
              <input type="password" name="confirmPassword" value={formData.confirmPassword} onChange={handleChange} style={inputStyle(errors.confirmPassword)} placeholder="••••••••" />
              {errors.confirmPassword && <p style={{color:'#ef4444',fontSize:'0.75rem',marginTop:'0.25rem'}}>{errors.confirmPassword}</p>}
            </div>

            {formData.role === 'merchant' && (
              <div className="mb-3 fade-in">
                <label style={{display:'block',fontSize:'0.85rem',fontWeight:600,marginBottom:'0.4rem',color:'var(--text-primary)'}}>Business Name</label>
                <input type="text" name="businessName" value={formData.businessName} onChange={handleChange} style={inputStyle(errors.businessName)} placeholder="Your Store Name" />
                {errors.businessName && <p style={{color:'#ef4444',fontSize:'0.75rem',marginTop:'0.25rem'}}>{errors.businessName}</p>}
              </div>
            )}

            <div className="flex items-center gap-2 mb-5 mt-2">
              <input type="checkbox" id="notifications" name="notifications" checked={formData.notifications} onChange={handleChange}
                style={{width:'16px',height:'16px',accentColor:'var(--primary-color)',cursor:'pointer'}} />
              <label htmlFor="notifications" style={{fontSize:'0.825rem',color:'var(--text-secondary)',cursor:'pointer'}}>
                Receive deal notifications and updates
              </label>
            </div>

            <button type="submit" disabled={loading} className="btn w-full"
              style={{background:'linear-gradient(135deg,#6366f1,#4f46e5)',color:'#fff',justifyContent:'center',padding:'0.75rem',fontSize:'0.95rem',fontWeight:600,gap:'0.5rem'}}>
              {loading ? <><i className="fas fa-spinner fa-spin"></i> Creating account...</> : 'Create Account'}
            </button>
          </form>

          <p className="text-center mt-4" style={{fontSize:'0.875rem',color:'var(--text-secondary)'}}>
            Already have an account? <Link to="/login" style={{color:'var(--primary-color)',fontWeight:600,textDecoration:'none'}}>Sign in</Link>
          </p>
        </div>
      </div>
    </div>
  );
}

window.RegisterPage = RegisterPage;
