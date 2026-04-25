'use client';

import { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { UserAPI } from '@/lib/api';
import toast from 'react-hot-toast';

declare global {
  interface Window { google: any; }
}

export default function LoginPage() {
  const router = useRouter();
  const { user, login } = useAuth();
  const [formData, setFormData] = useState({ email: '', password: '' });
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [googleReady, setGoogleReady] = useState(false);
  const googleBtnRef = useRef<HTMLDivElement>(null);
  const googleClientIdRef = useRef<string | null>(null);

  useEffect(() => {
    if (user) router.push(user.role === 'merchant' ? '/merchant/dashboard' : user.role === 'admin' ? '/admin/dashboard' : '/');
  }, [user]);

  // Step 1: Fetch client ID
  useEffect(() => {
    const configUrl = window.location.hostname === 'localhost' ? 'http://localhost:8080/api/config' : '/api/config';
    fetch(configUrl)
      .then(r => r.json())
      .then(c => { googleClientIdRef.current = c.GOOGLE_CLIENT_ID; tryInitGoogle(); })
      .catch(() => {});
  }, []);

  // Step 2: Load GSI script dynamically
  useEffect(() => {
    if (document.getElementById('google-gsi-script')) { tryInitGoogle(); return; }
    const script = document.createElement('script');
    script.id = 'google-gsi-script';
    script.src = 'https://accounts.google.com/gsi/client';
    script.async = true;
    script.defer = true;
    script.onload = () => tryInitGoogle();
    document.head.appendChild(script);
  }, []);

  // Step 3: Poll until google object, clientId, and ref are all ready
  const googleInitialized = useRef(false);
  const tryInitGoogle = () => {
    if (googleInitialized.current) return;
    let attempts = 0;
    const interval = setInterval(() => {
      attempts++;
      if (attempts > 20) { clearInterval(interval); return; }
      if (window.google && googleClientIdRef.current && googleBtnRef.current) {
        clearInterval(interval);
        if (googleInitialized.current) return;
        googleInitialized.current = true;
        try {
          window.google.accounts.id.initialize({
            client_id: googleClientIdRef.current,
            callback: handleGoogleCallback,
            auto_select: false,
          });
          window.google.accounts.id.renderButton(googleBtnRef.current, {
            theme: 'outline',
            size: 'large',
            width: 360,
            text: 'signin_with',
            shape: 'rectangular',
          });
          setGoogleReady(true);
        } catch (e) {
          console.warn('Google init error:', e);
        }
      }
    }, 300);
  };

  const handleGoogleCallback = async (response: any) => {
    try {
      const res = await UserAPI.googleSignIn({ token: response.credential });
      login(res);
      toast.success(`Welcome, ${res.name}!`);
      router.push(res.role === 'merchant' ? '/merchant/dashboard' : res.role === 'admin' ? '/admin/dashboard' : '/');
    } catch (err: any) {
      toast.error(err.message || 'Google Sign-In failed.');
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      const res = await UserAPI.login(formData);
      login(res);
      toast.success(`Welcome back, ${res.name}!`);
      router.push(res.role === 'merchant' ? '/merchant/dashboard' : res.role === 'admin' ? '/admin/dashboard' : '/');
    } catch (err: any) {
      toast.error(err.message || 'Invalid email or password.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-shell">
      <div className="auth-card fade-in">

        {/* Logo */}
        <div className="text-center mb-8">
          <Link href="/" className="brand-mark" style={{ marginBottom: '1rem' }}>
            <span className="brand-badge">%</span>
            <span style={{ fontSize: '1.4rem', fontWeight: 800, color: 'var(--text-primary)', letterSpacing: '-0.02em' }}>DealFinder</span>
          </Link>
          <h1 style={{ fontSize: '1.6rem', fontWeight: 800, color: 'var(--text-primary)', letterSpacing: '-0.02em', margin: '0.5rem 0 0.25rem' }}>Welcome back</h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>Sign in to your account</p>
        </div>

        <div className="auth-panel">

          {/* Google Sign-In */}
          <div style={{ marginBottom: '1.25rem' }}>
            {/* Outer div managed by React - never modified */}
            <div style={{ width: '100%', minHeight: '44px', position: 'relative' }}>
              {/* Placeholder - hidden once Google renders */}
              {!googleReady && (
                <div style={{ width: '100%', height: '44px', borderRadius: '0.9rem', background: 'rgba(255,255,255,0.82)', border: '1px solid rgba(148,163,184,0.22)', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.75rem', color: 'var(--text-secondary)', fontSize: '0.875rem' }}>
                  <i className="fab fa-google" style={{ fontSize: '1rem' }}></i>
                  Sign in with Google
                </div>
              )}
              {/* Google renders into this div - kept empty by React */}
              <div
                ref={googleBtnRef}
                style={{ position: googleReady ? 'static' : 'absolute', top: 0, left: 0, width: '100%', opacity: googleReady ? 1 : 0 }}
              ></div>
            </div>
          </div>

          {/* Divider */}
          <div style={{ position: 'relative', textAlign: 'center', marginBottom: '1.25rem' }}>
            <div style={{ position: 'absolute', top: '50%', left: 0, right: 0, height: '1px', background: 'var(--border-color)' }}></div>
            <span style={{ position: 'relative', background: 'var(--card-bg)', padding: '0 0.75rem', fontSize: '0.8rem', color: 'var(--text-secondary)' }}>or sign in with email</span>
          </div>

          {/* Email/Password Form */}
          <form onSubmit={handleSubmit}>
            <div style={{ marginBottom: '1rem' }}>
              <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 600, marginBottom: '0.4rem', color: 'var(--text-primary)' }}>Email Address</label>
              <input type="email" value={formData.email} onChange={e => setFormData({ ...formData, email: e.target.value })}
                className="modern-input" placeholder="you@example.com" required autoComplete="email" />
            </div>

            <div style={{ marginBottom: '1.25rem' }}>
              <div className="flex items-center justify-between" style={{ marginBottom: '0.4rem' }}>
                <label style={{ fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-primary)' }}>Password</label>
                <Link href="/reset-password" style={{ fontSize: '0.8rem', color: 'var(--primary-color)', textDecoration: 'none' }}>Forgot password?</Link>
              </div>
              <div style={{ position: 'relative' }}>
                <input type={showPassword ? 'text' : 'password'} value={formData.password}
                  onChange={e => setFormData({ ...formData, password: e.target.value })}
                  className="modern-input" style={{ paddingRight: '2.75rem' }} placeholder="••••••••" required autoComplete="current-password" />
                <button type="button" onClick={() => setShowPassword(!showPassword)}
                  style={{ position: 'absolute', right: '0.875rem', top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer' }}>
                  <i className={`fas ${showPassword ? 'fa-eye-slash' : 'fa-eye'}`}></i>
                </button>
              </div>
            </div>

            <button type="submit" disabled={loading} className="btn btn-primary"
              style={{ justifyContent: 'center', padding: '0.75rem', fontSize: '0.95rem', width: '100%', marginBottom: '1rem' }}>
              {loading ? <><i className="fas fa-spinner fa-spin"></i> Signing in...</> : 'Sign In'}
            </button>
          </form>

          {/* Demo accounts */}
          <div style={{ borderTop: '1px solid var(--border-color)', paddingTop: '1rem' }}>
            <p style={{ fontSize: '0.72rem', color: 'var(--text-secondary)', textAlign: 'center', marginBottom: '0.625rem', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Quick Demo Access</p>
            <div className="flex gap-2">
              {[
                { label: 'Merchant', icon: 'fa-store', email: 'jane@example.com', pass: 'password123', color: '#059669', bg: 'rgba(16,185,129,0.06)', border: 'rgba(16,185,129,0.3)' },
                { label: 'User', icon: 'fa-user', email: 'john@example.com', pass: 'password123', color: 'var(--primary-color)', bg: 'rgba(99,102,241,0.06)', border: 'rgba(99,102,241,0.3)' },
              ].map(d => (
                <button key={d.label} type="button"
                  onClick={() => setFormData({ email: d.email, password: d.pass })}
                  style={{ flex: 1, padding: '0.6rem 0.35rem', borderRadius: '0.9rem', border: `1px solid ${d.border}`, background: d.bg, color: d.color, fontWeight: 600, cursor: 'pointer', fontSize: '0.78rem', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.35rem' }}>
                  <i className={`fas ${d.icon}`}></i> {d.label}
                </button>
              ))}
            </div>
          </div>

          <p className="text-center mt-4" style={{ fontSize: '0.875rem', color: 'var(--text-secondary)' }}>
            No account? <Link href="/register" style={{ color: 'var(--primary-color)', textDecoration: 'none', fontWeight: 600 }}>Sign up</Link>
          </p>
        </div>
      </div>
    </div>
  );
}
