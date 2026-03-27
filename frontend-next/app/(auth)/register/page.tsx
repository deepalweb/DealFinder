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
    width: '100%', padding: '0.75rem 1rem', borderRadius: '0.625rem', fontSize: '0.9rem',
    border: `1.5px solid ${hasError ? '#ef4444' : 'var(--border-color)'}`,
    background: 'var(--card-bg)', color: 'var(--text-primary)', outline: 'none', boxSizing: 'border-box' as const,
  });

  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: 'calc(100vh - 160px)', padding: '2rem 1rem' }}>
      <div className="fade-in" style={{ width: '100%', maxWidth: '460px' }}>
        <div className="text-center mb-6">
          <Link href="/" style={{ display: 'inline-flex', alignItems: 'center', gap: '0.5rem', textDecoration: 'none', marginBottom: '1rem' }}>
            <span style={{ background: 'linear-gradient(135deg,#6366f1,#f43f5e)', borderRadius: '0.625rem', padding: '0.4rem 0.7rem', color: '#fff', fontSize: '1.1rem', fontWeight: 800 }}>%</span>
            <span style={{ fontSize: '1.4rem', fontWeight: 800, color: 'var(--text-primary)', letterSpacing: '-0.02em' }}>DealFinder</span>
          </Link>
          <h1 style={{ fontSize: '1.6rem', fontWeight: 800, color: 'var(--text-primary)', letterSpacing: '-0.02em', margin: '0.5rem 0 0.25rem' }}>Create your account</h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>Join thousands of deal hunters</p>
        </div>

        <div className="promotion-card" style={{ padding: '1.5rem' }}>
          <form onSubmit={handleSubmit}>
            {/* Account Type */}
            <div style={{ marginBottom: '1rem' }}>
              <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 600, marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Account Type</label>
              <div style={{ display: 'flex', gap: '0.75rem' }}>
                {[['user', 'fa-user', 'Regular User'], ['merchant', 'fa-store', 'Merchant']].map(([val, icon, label]) => (
                  <button key={val} type="button" onClick={() => setFormData({ ...formData, role: val })}
                    style={{ flex: 1, padding: '0.625rem', borderRadius: '0.625rem', cursor: 'pointer', border: `1.5px solid ${formData.role === val ? 'var(--primary-color)' : 'var(--border-color)'}`, background: formData.role === val ? 'rgba(99,102,241,0.08)' : 'var(--card-bg)', color: formData.role === val ? 'var(--primary-color)' : 'var(--text-secondary)', fontWeight: 600, fontSize: '0.85rem', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.4rem' }}>
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
                <input type={f.type} value={(formData as any)[f.name]} onChange={e => setFormData({ ...formData, [f.name]: e.target.value })} style={inputStyle(!!errors[f.name])} placeholder={f.placeholder} />
                {errors[f.name] && <p style={{ color: '#ef4444', fontSize: '0.75rem', marginTop: '0.25rem' }}>{errors[f.name]}</p>}
              </div>
            ))}

            <div style={{ marginBottom: '0.875rem' }}>
              <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 600, marginBottom: '0.4rem', color: 'var(--text-primary)' }}>Password</label>
              <div style={{ position: 'relative' }}>
                <input type={showPassword ? 'text' : 'password'} value={formData.password} onChange={e => setFormData({ ...formData, password: e.target.value })} style={{ ...inputStyle(!!errors.password), paddingRight: '2.75rem' }} placeholder="Min. 8 characters" />
                <button type="button" onClick={() => setShowPassword(!showPassword)} style={{ position: 'absolute', right: '0.875rem', top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer' }}>
                  <i className={`fas ${showPassword ? 'fa-eye-slash' : 'fa-eye'}`}></i>
                </button>
              </div>
              {errors.password && <p style={{ color: '#ef4444', fontSize: '0.75rem', marginTop: '0.25rem' }}>{errors.password}</p>}
            </div>

            <div style={{ marginBottom: '0.875rem' }}>
              <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 600, marginBottom: '0.4rem', color: 'var(--text-primary)' }}>Confirm Password</label>
              <input type="password" value={formData.confirmPassword} onChange={e => setFormData({ ...formData, confirmPassword: e.target.value })} style={inputStyle(!!errors.confirmPassword)} placeholder="••••••••" />
              {errors.confirmPassword && <p style={{ color: '#ef4444', fontSize: '0.75rem', marginTop: '0.25rem' }}>{errors.confirmPassword}</p>}
            </div>

            {formData.role === 'merchant' && (
              <div className="fade-in" style={{ marginBottom: '0.875rem' }}>
                <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 600, marginBottom: '0.4rem', color: 'var(--text-primary)' }}>Business Name</label>
                <input type="text" value={formData.businessName} onChange={e => setFormData({ ...formData, businessName: e.target.value })} style={inputStyle(!!errors.businessName)} placeholder="Your Store Name" />
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
