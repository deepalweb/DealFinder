'use client';

import { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import Script from 'next/script';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { UserAPI } from '@/lib/api';
import toast from 'react-hot-toast';

export default function RegisterPage() {
  const router = useRouter();
  const { login } = useAuth();
  const [formData, setFormData] = useState({ name: '', email: '', password: '', confirmPassword: '', role: 'user', businessName: '' });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const getPasswordStrength = (pwd: string) => {
    if (!pwd) return null;
    let score = 0;
    if (pwd.length >= 8) score++;
    if (pwd.length >= 12) score++;
    if (/[A-Z]/.test(pwd)) score++;
    if (/[0-9]/.test(pwd)) score++;
    if (/[^A-Za-z0-9]/.test(pwd)) score++;
    if (score <= 1) return { label: 'Weak', color: '#ef4444', width: '25%' };
    if (score <= 2) return { label: 'Fair', color: '#f97316', width: '50%' };
    if (score <= 3) return { label: 'Good', color: '#eab308', width: '75%' };
    return { label: 'Strong', color: '#22c55e', width: '100%' };
  };
  const strength = getPasswordStrength(formData.password);

  const validate = () => {
    const e: Record<string, string> = {};
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

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;
    setLoading(true);
    try {
      const res = await UserAPI.register({ name: formData.name, email: formData.email, password: formData.password, role: formData.role, businessName: formData.role === 'merchant' ? formData.businessName : undefined });
      login(res);
      toast.success('Account created successfully!');
      router.push(res.role === 'merchant' ? '/merchant/dashboard' : '/');
    } catch (err: any) {
      toast.error(err.message || 'Registration failed. Email may already be in use.');
    } finally {
      setLoading(false);
    }
  };

  const inputStyle = (hasError: boolean) => ({
    borderColor: hasError ? '#ef4444' : undefined,
  });

  return (
    <div className="auth-shell">
      <div className="auth-card wide fade-in">
        <div className="text-center mb-6">
          <Link href="/" className="brand-mark" style={{ marginBottom: '1rem' }}>
            <span className="brand-badge">%</span>
            <span style={{ fontSize: '1.4rem', fontWeight: 800, color: 'var(--text-primary)', letterSpacing: '-0.02em' }}>DealFinder</span>
          </Link>
          <h1 style={{ fontSize: '1.6rem', fontWeight: 800, color: 'var(--text-primary)', letterSpacing: '-0.02em', margin: '0.5rem 0 0.25rem' }}>Create your account</h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>Join thousands of deal hunters</p>
        </div>

        <div className="auth-panel">
          <form onSubmit={handleSubmit}>
            {/* Account Type */}
            <div style={{ marginBottom: '1rem' }}>
              <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 600, marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Account Type</label>
              <div style={{ display: 'flex', gap: '0.75rem' }}>
                {[['user', 'fa-user', 'Regular User'], ['merchant', 'fa-store', 'Merchant']].map(([val, icon, label]) => (
                  <button key={val} type="button" onClick={() => setFormData({ ...formData, role: val })}
                    style={{ flex: 1, padding: '0.8rem', borderRadius: '0.95rem', cursor: 'pointer', border: `1px solid ${formData.role === val ? 'rgba(37,99,235,0.35)' : 'rgba(148,163,184,0.22)'}`, background: formData.role === val ? 'linear-gradient(135deg, rgba(37,99,235,0.12), rgba(56,189,248,0.08))' : 'rgba(255,255,255,0.72)', color: formData.role === val ? 'var(--primary-color)' : 'var(--text-secondary)', fontWeight: 600, fontSize: '0.85rem', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.4rem' }}>
                    <i className={`fas ${icon}`}></i> {label}
                  </button>
                ))}
              </div>
            </div>

            {[
              { name: 'name', label: 'Full Name', type: 'text', placeholder: 'John Doe' },
              { name: 'email', label: 'Email Address', type: 'email', placeholder: 'you@example.com' },
            ].map(f => (
              <div key={f.name} style={{ marginBottom: '0.875rem' }}>
                <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 600, marginBottom: '0.4rem', color: 'var(--text-primary)' }}>{f.label}</label>
                <input type={f.type} value={(formData as any)[f.name]} onChange={e => setFormData({ ...formData, [f.name]: e.target.value })} className="modern-input" style={inputStyle(!!errors[f.name])} placeholder={f.placeholder} />
                {errors[f.name] && <p style={{ color: '#ef4444', fontSize: '0.75rem', marginTop: '0.25rem' }}>{errors[f.name]}</p>}
              </div>
            ))}

            <div style={{ marginBottom: '0.875rem' }}>
              <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 600, marginBottom: '0.4rem', color: 'var(--text-primary)' }}>Password</label>
              <div style={{ position: 'relative' }}>
                <input type={showPassword ? 'text' : 'password'} value={formData.password} onChange={e => setFormData({ ...formData, password: e.target.value })} className="modern-input" style={{ ...inputStyle(!!errors.password), paddingRight: '2.75rem' }} placeholder="Min. 8 characters" />
                <button type="button" onClick={() => setShowPassword(!showPassword)} style={{ position: 'absolute', right: '0.875rem', top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer' }}>
                  <i className={`fas ${showPassword ? 'fa-eye-slash' : 'fa-eye'}`}></i>
                </button>
              </div>
              {errors.password && <p style={{ color: '#ef4444', fontSize: '0.75rem', marginTop: '0.25rem' }}>{errors.password}</p>}
              {strength && !errors.password && (
                <div style={{ marginTop: '0.5rem' }}>
                  <div style={{ height: '4px', borderRadius: '9999px', background: 'var(--border-color)', overflow: 'hidden' }}>
                    <div style={{ height: '100%', width: strength.width, background: strength.color, borderRadius: '9999px', transition: 'all 0.3s' }} />
                  </div>
                  <p style={{ fontSize: '0.72rem', color: strength.color, marginTop: '0.25rem', fontWeight: 600 }}>{strength.label} password</p>
                </div>
              )}
            </div>

            <div style={{ marginBottom: '0.875rem' }}>
              <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 600, marginBottom: '0.4rem', color: 'var(--text-primary)' }}>Confirm Password</label>
              <input type="password" value={formData.confirmPassword} onChange={e => setFormData({ ...formData, confirmPassword: e.target.value })} className="modern-input" style={inputStyle(!!errors.confirmPassword)} placeholder="••••••••" />
              {errors.confirmPassword && <p style={{ color: '#ef4444', fontSize: '0.75rem', marginTop: '0.25rem' }}>{errors.confirmPassword}</p>}
            </div>

            {formData.role === 'merchant' && (
              <div className="fade-in" style={{ marginBottom: '0.875rem' }}>
                <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 600, marginBottom: '0.4rem', color: 'var(--text-primary)' }}>Business Name</label>
                <input type="text" value={formData.businessName} onChange={e => setFormData({ ...formData, businessName: e.target.value })} className="modern-input" style={inputStyle(!!errors.businessName)} placeholder="Your Store Name" />
                {errors.businessName && <p style={{ color: '#ef4444', fontSize: '0.75rem', marginTop: '0.25rem' }}>{errors.businessName}</p>}
              </div>
            )}

            <button type="submit" disabled={loading} className="btn btn-primary"
              style={{ width: '100%', justifyContent: 'center', padding: '0.75rem', fontSize: '0.95rem', marginTop: '0.5rem' }}>
              {loading ? <><i className="fas fa-spinner fa-spin"></i> Creating account...</> : 'Create Account'}
            </button>
          </form>

          <p className="text-center mt-4" style={{ fontSize: '0.875rem', color: 'var(--text-secondary)' }}>
            Already have an account? <Link href="/login" style={{ color: 'var(--primary-color)', fontWeight: 600, textDecoration: 'none' }}>Sign in</Link>
          </p>
        </div>
      </div>
    </div>
  );
}
