'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { UserAPI } from '@/lib/api';
import toast from 'react-hot-toast';

export default function LoginPage() {
  const router = useRouter();
  const { user, login } = useAuth();
  const [formData, setFormData] = useState({ email: '', password: '' });
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  useEffect(() => {
    if (user) router.push(user.role === 'merchant' ? '/merchant/dashboard' : '/');
  }, [user]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      const res = await UserAPI.login(formData);
      login(res);
      toast.success(`Welcome back, ${res.name}!`);
      router.push(res.role === 'merchant' ? '/merchant/dashboard' : '/');
    } catch (err: any) {
      toast.error(err.message || 'Invalid email or password.');
    } finally {
      setLoading(false);
    }
  };

  const inputStyle = {
    width: '100%', padding: '0.75rem 1rem', borderRadius: '0.625rem', fontSize: '0.9rem',
    border: '1.5px solid var(--border-color)', background: 'var(--card-bg)',
    color: 'var(--text-primary)', outline: 'none', boxSizing: 'border-box' as const,
  };

  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: 'calc(100vh - 160px)', padding: '2rem 1rem' }}>
      <div className="fade-in" style={{ width: '100%', maxWidth: '420px' }}>
        <div className="text-center mb-8">
          <Link href="/" style={{ display: 'inline-flex', alignItems: 'center', gap: '0.5rem', textDecoration: 'none', marginBottom: '1rem' }}>
            <span style={{ background: 'linear-gradient(135deg,#6366f1,#f43f5e)', borderRadius: '0.625rem', padding: '0.4rem 0.7rem', color: '#fff', fontSize: '1.1rem', fontWeight: 800 }}>%</span>
            <span style={{ fontSize: '1.4rem', fontWeight: 800, color: 'var(--text-primary)', letterSpacing: '-0.02em' }}>DealFinder</span>
          </Link>
          <h1 style={{ fontSize: '1.6rem', fontWeight: 800, color: 'var(--text-primary)', letterSpacing: '-0.02em', margin: '0.5rem 0 0.25rem' }}>Welcome back</h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>Sign in to your account</p>
        </div>

        <div className="promotion-card" style={{ padding: '1.5rem' }}>
          <form onSubmit={handleSubmit}>
            <div style={{ marginBottom: '1rem' }}>
              <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 600, marginBottom: '0.4rem', color: 'var(--text-primary)' }}>Email Address</label>
              <input type="email" value={formData.email} onChange={e => setFormData({ ...formData, email: e.target.value })}
                style={inputStyle} placeholder="you@example.com" required />
            </div>

            <div style={{ marginBottom: '1.25rem' }}>
              <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 600, marginBottom: '0.4rem', color: 'var(--text-primary)' }}>Password</label>
              <div style={{ position: 'relative' }}>
                <input type={showPassword ? 'text' : 'password'} value={formData.password}
                  onChange={e => setFormData({ ...formData, password: e.target.value })}
                  style={{ ...inputStyle, paddingRight: '2.75rem' }} placeholder="••••••••" required />
                <button type="button" onClick={() => setShowPassword(!showPassword)}
                  style={{ position: 'absolute', right: '0.875rem', top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer' }}>
                  <i className={`fas ${showPassword ? 'fa-eye-slash' : 'fa-eye'}`}></i>
                </button>
              </div>
            </div>

            <button type="submit" disabled={loading} className="btn btn-primary w-full"
              style={{ justifyContent: 'center', padding: '0.75rem', fontSize: '0.95rem', width: '100%', marginBottom: '0.75rem' }}>
              {loading ? <><i className="fas fa-spinner fa-spin"></i> Signing in...</> : 'Sign In'}
            </button>

            <button type="button" onClick={() => { setFormData({ email: 'demo@merchant.com', password: 'demo123' }); }}
              style={{ width: '100%', padding: '0.75rem', borderRadius: '0.625rem', border: '1.5px solid rgba(16,185,129,0.3)', background: 'rgba(16,185,129,0.08)', color: '#059669', fontWeight: 600, cursor: 'pointer', fontSize: '0.875rem', marginBottom: '1rem' }}>
              <i className="fas fa-play-circle mr-2"></i> Fill Demo Merchant Credentials
            </button>

            <div style={{ position: 'relative', textAlign: 'center', marginBottom: '1rem' }}>
              <div style={{ position: 'absolute', top: '50%', left: 0, right: 0, height: '1px', background: 'var(--border-color)' }}></div>
              <span style={{ position: 'relative', background: 'var(--card-bg)', padding: '0 0.75rem', fontSize: '0.8rem', color: 'var(--text-secondary)' }}>or</span>
            </div>

            <div id="google-signin-button" style={{ display: 'flex', justifyContent: 'center' }}></div>
          </form>

          <div className="text-center mt-5" style={{ fontSize: '0.875rem', color: 'var(--text-secondary)' }}>
            <Link href="/reset-password" style={{ color: 'var(--primary-color)', textDecoration: 'none', fontWeight: 500 }}>Forgot password?</Link>
            <span style={{ margin: '0 0.5rem' }}>·</span>
            <span>No account? </span>
            <Link href="/register" style={{ color: 'var(--primary-color)', textDecoration: 'none', fontWeight: 600 }}>Sign up</Link>
          </div>
        </div>
      </div>
    </div>
  );
}
