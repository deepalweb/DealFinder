'use client';
import { useState } from 'react';
import Link from 'next/link';
import { buildApiUrl } from '@/lib/config/api';
import toast from 'react-hot-toast';

export default function ResetPasswordPage() {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [sent, setSent] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault(); setLoading(true);
    try {
      await fetch(buildApiUrl('users/reset-password'), { method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({ email }) });
      setSent(true); toast.success('Reset link sent if email exists.');
    } catch { toast.error('Failed to send reset email.'); } finally { setLoading(false); }
  };

  return (
    <div style={{ display:'flex', alignItems:'center', justifyContent:'center', minHeight:'calc(100vh - 160px)', padding:'2rem 1rem' }}>
      <div className="fade-in" style={{ width:'100%', maxWidth:'420px' }}>
        <div className="text-center mb-8">
          <h1 style={{ fontSize:'1.6rem', fontWeight:800, color:'var(--text-primary)', marginBottom:'0.25rem' }}>Reset Password</h1>
          <p style={{ color:'var(--text-secondary)', fontSize:'0.9rem' }}>Enter your email to receive a reset link</p>
        </div>
        <div className="promotion-card" style={{ padding:'1.5rem' }}>
          {sent ? (
            <div className="text-center py-4">
              <div style={{ fontSize:'3rem', marginBottom:'1rem' }}>📧</div>
              <h3 style={{ fontWeight:700, marginBottom:'0.5rem', color:'var(--text-primary)' }}>Check your email</h3>
              <p style={{ color:'var(--text-secondary)', fontSize:'0.875rem', marginBottom:'1.5rem' }}>If your email is registered, you&apos;ll receive a reset link shortly.</p>
              <Link href="/login" className="btn btn-primary">Back to Login</Link>
            </div>
          ) : (
            <form onSubmit={handleSubmit}>
              <div style={{ marginBottom:'1.25rem' }}>
                <label style={{ display:'block', fontSize:'0.85rem', fontWeight:600, marginBottom:'0.4rem', color:'var(--text-primary)' }}>Email Address</label>
                <input type="email" value={email} onChange={e=>setEmail(e.target.value)} required placeholder="you@example.com"
                  style={{ width:'100%', padding:'0.75rem 1rem', borderRadius:'0.625rem', border:'1.5px solid var(--border-color)', background:'var(--card-bg)', color:'var(--text-primary)', fontSize:'0.9rem', outline:'none', boxSizing:'border-box' }} />
              </div>
              <button type="submit" disabled={loading} className="btn btn-primary" style={{ width:'100%', justifyContent:'center', padding:'0.75rem' }}>
                {loading ? <><i className="fas fa-spinner fa-spin"></i> Sending...</> : 'Send Reset Link'}
              </button>
              <p className="text-center mt-4" style={{ fontSize:'0.875rem', color:'var(--text-secondary)' }}>
                Remember your password? <Link href="/login" style={{ color:'var(--primary-color)', fontWeight:600, textDecoration:'none' }}>Sign in</Link>
              </p>
            </form>
          )}
        </div>
      </div>
    </div>
  );
}
