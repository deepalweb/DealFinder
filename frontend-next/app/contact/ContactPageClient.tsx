'use client';

import { useState } from 'react';
import toast from 'react-hot-toast';

export default function ContactPageClient() {
  const [form, setForm] = useState({ name:'', email:'', message:'' });
  const handleSubmit = (e: React.FormEvent) => { e.preventDefault(); toast.success('Message sent! We\'ll get back to you soon.'); setForm({ name:'', email:'', message:'' }); };
  return (
    <div className="page-shell compact">
      <div className="page-header">
        <div>
          <div className="page-eyebrow"><i className="fas fa-envelope"></i> Contact</div>
          <h1 className="page-title">Let&apos;s keep the conversation easy.</h1>
          <p className="page-subtitle">Questions, partnership ideas, bug reports, or product feedback all belong here.</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-[0.95fr_1.05fr] gap-6">
        <div className="surface-panel panel-pad" style={{ display:'flex', flexDirection:'column', gap:'0.9rem' }}>
          <div className="page-eyebrow" style={{ width: 'fit-content' }}><i className="fas fa-headset"></i> Reach us</div>
          <h2 style={{ fontSize:'1.3rem', fontWeight:800, color:'var(--text-primary)', margin:'0 0 0.2rem' }}>We usually reply quickly.</h2>
          <p style={{ color:'var(--text-secondary)', lineHeight:1.7, margin:'0 0 0.5rem' }}>
            The fastest path is email, but you can also call if the matter is urgent.
          </p>

          <div className="stat-tile">
            <div style={{ display:'flex', alignItems:'center', gap:'0.75rem', color:'var(--text-primary)' }}>
              <i className="fas fa-envelope" style={{ color:'var(--primary-color)', width:'1.25rem' }}></i>
              <a href="mailto:support@dealfinderapp.lk" style={{ color:'var(--text-primary)', textDecoration:'none' }}>support@dealfinderapp.lk</a>
            </div>
          </div>
          <div className="stat-tile">
            <div style={{ display:'flex', alignItems:'center', gap:'0.75rem', color:'var(--text-primary)' }}>
              <i className="fas fa-phone" style={{ color:'var(--primary-color)', width:'1.25rem' }}></i>
              <a href="tel:+94760846996" style={{ color:'var(--text-primary)', textDecoration:'none' }}>+94 760 846 996</a>
            </div>
          </div>
        </div>

        <div className="surface-panel panel-pad">
          <div className="page-eyebrow" style={{ width: 'fit-content', marginBottom: '1rem' }}><i className="fas fa-paper-plane"></i> Send message</div>
          <form onSubmit={handleSubmit}>
            <div style={{ marginBottom:'1rem' }}><label style={{ display:'block', fontSize:'0.85rem', fontWeight:600, marginBottom:'0.45rem', color:'var(--text-primary)' }}>Name</label><input className="modern-input" value={form.name} onChange={e=>setForm({...form,name:e.target.value})} required /></div>
            <div style={{ marginBottom:'1rem' }}><label style={{ display:'block', fontSize:'0.85rem', fontWeight:600, marginBottom:'0.45rem', color:'var(--text-primary)' }}>Email</label><input type="email" className="modern-input" value={form.email} onChange={e=>setForm({...form,email:e.target.value})} required /></div>
            <div style={{ marginBottom:'1.25rem' }}><label style={{ display:'block', fontSize:'0.85rem', fontWeight:600, marginBottom:'0.45rem', color:'var(--text-primary)' }}>Message</label><textarea className="modern-textarea" style={{ resize:'vertical', minHeight:'160px' }} value={form.message} onChange={e=>setForm({...form,message:e.target.value})} required></textarea></div>
            <button type="submit" className="btn btn-primary"><i className="fas fa-paper-plane"></i> Send Message</button>
          </form>
        </div>
      </div>
    </div>
  );
}
