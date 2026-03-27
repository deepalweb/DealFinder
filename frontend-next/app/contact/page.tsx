'use client';
import { useState } from 'react';
import toast from 'react-hot-toast';

export default function ContactPage() {
  const [form, setForm] = useState({ name:'', email:'', message:'' });
  const handleSubmit = (e: React.FormEvent) => { e.preventDefault(); toast.success('Message sent! We\'ll get back to you soon.'); setForm({ name:'', email:'', message:'' }); };
  const inputStyle = { width:'100%', padding:'0.75rem 1rem', borderRadius:'0.625rem', border:'1.5px solid var(--border-color)', background:'var(--card-bg)', color:'var(--text-primary)', fontSize:'0.9rem', outline:'none', boxSizing:'border-box' as const };
  return (
    <div className="max-w-2xl mx-auto px-4 py-12">
      <h1 style={{ fontSize:'2rem', fontWeight:800, color:'var(--text-primary)', marginBottom:'0.5rem' }}>Contact Us</h1>
      <p style={{ color:'var(--text-secondary)', marginBottom:'2rem' }}>Have a question or feedback? We&apos;d love to hear from you.</p>
      <div className="promotion-card" style={{ padding:'1.5rem' }}>
        <form onSubmit={handleSubmit}>
          <div style={{ marginBottom:'1rem' }}><label style={{ display:'block', fontSize:'0.85rem', fontWeight:600, marginBottom:'0.4rem', color:'var(--text-primary)' }}>Name</label><input style={inputStyle} value={form.name} onChange={e=>setForm({...form,name:e.target.value})} required /></div>
          <div style={{ marginBottom:'1rem' }}><label style={{ display:'block', fontSize:'0.85rem', fontWeight:600, marginBottom:'0.4rem', color:'var(--text-primary)' }}>Email</label><input type="email" style={inputStyle} value={form.email} onChange={e=>setForm({...form,email:e.target.value})} required /></div>
          <div style={{ marginBottom:'1.5rem' }}><label style={{ display:'block', fontSize:'0.85rem', fontWeight:600, marginBottom:'0.4rem', color:'var(--text-primary)' }}>Message</label><textarea style={{...inputStyle,resize:'vertical'}} value={form.message} onChange={e=>setForm({...form,message:e.target.value})} rows={5} required></textarea></div>
          <button type="submit" className="btn btn-primary"><i className="fas fa-paper-plane"></i> Send Message</button>
        </form>
      </div>
    </div>
  );
}
