function LoginPage() {
  const { useState } = React;
  const { useNavigate, Link } = ReactRouterDOM;
  const navigate = useNavigate();

  const [formData, setFormData] = useState({ email: '', password: '' });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [googleClientId, setGoogleClientId] = useState(null);

  React.useEffect(() => {
    const userData = localStorage.getItem('dealFinderUser');
    if (userData) {
      const user = JSON.parse(userData);
      navigate(user.role === 'merchant' ? '/merchant/dashboard' : '/');
    }
  }, []);

  React.useEffect(() => {
    fetch('/api/config').then(r => r.json()).then(c => setGoogleClientId(c.GOOGLE_CLIENT_ID)).catch(() => {});
  }, []);

  React.useEffect(() => {
    if (googleClientId && window.google) {
      google.accounts.id.initialize({ client_id: googleClientId, callback: handleGoogleSignIn });
      google.accounts.id.renderButton(document.getElementById('google-signin-button'), { theme: 'outline', size: 'large', width: '100%' });
    }
  }, [googleClientId]);

  const handleChange = e => setFormData({ ...formData, [e.target.name]: e.target.value });

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError(''); setLoading(true);
    try {
      const response = await window.API.Users.login(formData);
      localStorage.setItem('dealFinderUser', JSON.stringify(response));
      window.dispatchEvent(new Event('authChange'));
      navigate(response.role === 'merchant' ? '/merchant/dashboard' : '/');
    } catch {
      setError('Invalid email or password. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleDemoLogin = (e) => {
    e.preventDefault();
    setFormData({ email: 'demo@merchant.com', password: 'demo123' });
    setTimeout(() => document.getElementById('login-form').dispatchEvent(new Event('submit', { cancelable: true, bubbles: true })), 100);
  };

  const handleGoogleSignIn = async (response) => {
    try {
      const res = await window.API.Users.googleSignIn({ token: response.credential });
      localStorage.setItem('dealFinderUser', JSON.stringify(res));
      navigate(res.role === 'merchant' ? '/merchant/dashboard' : '/');
    } catch {
      setError('Google Sign-In failed. Please try again.');
    }
  };

  const inputStyle = (hasError) => ({
    width: '100%', padding: '0.75rem 1rem', borderRadius: '0.625rem', fontSize: '0.95rem',
    border: `1.5px solid ${hasError ? '#ef4444' : 'var(--border-color)'}`,
    background: 'var(--card-bg)', color: 'var(--text-primary)', outline: 'none', boxSizing: 'border-box',
    transition: 'border-color 0.2s'
  });

  return (
    <div className="page-container" style={{display:'flex',alignItems:'center',justifyContent:'center',minHeight:'calc(100vh - 160px)',padding:'2rem 1rem'}}>
      <div className="fade-in" style={{width:'100%',maxWidth:'420px'}}>
        {/* Logo */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center gap-2 mb-2">
            <span style={{background:'linear-gradient(135deg,#6366f1,#f43f5e)',borderRadius:'0.625rem',padding:'0.4rem 0.7rem',color:'#fff',fontSize:'1.1rem',fontWeight:800}}>%</span>
            <span style={{fontSize:'1.4rem',fontWeight:800,color:'var(--text-primary)',letterSpacing:'-0.02em'}}>DealFinder</span>
          </div>
          <h1 style={{fontSize:'1.6rem',fontWeight:800,color:'var(--text-primary)',letterSpacing:'-0.02em',margin:'0.5rem 0 0.25rem'}}>Welcome back</h1>
          <p style={{color:'var(--text-secondary)',fontSize:'0.9rem'}}>Sign in to your account</p>
        </div>

        <div className="promotion-card p-6">
          {error && (
            <div className="flex items-center gap-2 p-3 rounded-lg mb-4" style={{background:'rgba(239,68,68,0.08)',border:'1px solid rgba(239,68,68,0.2)'}}>
              <i className="fas fa-exclamation-circle" style={{color:'#ef4444'}}></i>
              <p style={{color:'#ef4444',margin:0,fontSize:'0.875rem'}}>{error}</p>
            </div>
          )}

          <form id="login-form" onSubmit={handleSubmit}>
            <div className="mb-4">
              <label style={{display:'block',fontSize:'0.85rem',fontWeight:600,marginBottom:'0.4rem',color:'var(--text-primary)'}}>Email Address</label>
              <input type="email" name="email" value={formData.email} onChange={handleChange} style={inputStyle(false)} placeholder="you@example.com" required />
            </div>

            <div className="mb-5">
              <label style={{display:'block',fontSize:'0.85rem',fontWeight:600,marginBottom:'0.4rem',color:'var(--text-primary)'}}>Password</label>
              <div style={{position:'relative'}}>
                <input type={showPassword ? 'text' : 'password'} name="password" value={formData.password} onChange={handleChange} style={{...inputStyle(false),paddingRight:'2.75rem'}} placeholder="••••••••" required />
                <button type="button" onClick={() => setShowPassword(!showPassword)} style={{position:'absolute',right:'0.875rem',top:'50%',transform:'translateY(-50%)',background:'none',border:'none',color:'var(--text-secondary)',cursor:'pointer'}}>
                  <i className={`fas ${showPassword ? 'fa-eye-slash' : 'fa-eye'}`}></i>
                </button>
              </div>
            </div>

            <button type="submit" disabled={loading} className="btn w-full mb-3"
              style={{background:'linear-gradient(135deg,#6366f1,#4f46e5)',color:'#fff',justifyContent:'center',padding:'0.75rem',fontSize:'0.95rem',fontWeight:600,gap:'0.5rem'}}>
              {loading ? <><i className="fas fa-spinner fa-spin"></i> Signing in...</> : 'Sign In'}
            </button>

            <button type="button" onClick={handleDemoLogin} className="btn w-full mb-4"
              style={{background:'rgba(16,185,129,0.1)',color:'#059669',border:'1.5px solid rgba(16,185,129,0.3)',justifyContent:'center',padding:'0.75rem',fontSize:'0.875rem',fontWeight:600}}>
              <i className="fas fa-play-circle mr-2"></i> Try Demo Merchant Account
            </button>

            <div style={{position:'relative',textAlign:'center',marginBottom:'1rem'}}>
              <div style={{position:'absolute',top:'50%',left:0,right:0,height:'1px',background:'var(--border-color)'}}></div>
              <span style={{position:'relative',background:'var(--card-bg)',padding:'0 0.75rem',fontSize:'0.8rem',color:'var(--text-secondary)'}}>or continue with</span>
            </div>

            <div id="google-signin-button" style={{display:'flex',justifyContent:'center'}}></div>
          </form>

          <div className="text-center mt-5" style={{fontSize:'0.875rem',color:'var(--text-secondary)'}}>
            <Link to="/reset-password" style={{color:'var(--primary-color)',textDecoration:'none',fontWeight:500}}>Forgot password?</Link>
            <span style={{margin:'0 0.5rem'}}>·</span>
            <span>No account? </span>
            <Link to="/register" style={{color:'var(--primary-color)',textDecoration:'none',fontWeight:600}}>Sign up</Link>
          </div>
        </div>
      </div>
    </div>
  );
}

window.LoginPage = LoginPage;
