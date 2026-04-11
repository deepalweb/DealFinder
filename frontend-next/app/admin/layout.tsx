'use client';

import { useEffect } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';

const NAV = [
  { href: '/admin/dashboard', icon: 'fa-chart-line', label: 'Dashboard' },
  { href: '/admin/users', icon: 'fa-users', label: 'Users' },
  { href: '/admin/merchants', icon: 'fa-store', label: 'Merchants' },
  { href: '/admin/promotions', icon: 'fa-tags', label: 'Promotions' },
];

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const { user, loading, logout } = useAuth();
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    if (!loading && (!user || user.role !== 'admin')) router.push('/');
  }, [user, loading]);

  if (loading || !user || user.role !== 'admin') return (
    <div style={{ display:'flex', alignItems:'center', justifyContent:'center', minHeight:'100vh' }}>
      <div className="skeleton-card" style={{ width:'200px', height:'80px' }}></div>
    </div>
  );

  return (
    <div style={{ display:'flex', minHeight:'100vh', background:'var(--body-bg)', marginTop:'-1px' }}>
      {/* Sidebar */}
      <aside className="hidden md:flex" style={{ width:'240px', background:'linear-gradient(180deg,#0f172a 0%,#1e1b4b 100%)', flexShrink:0, position:'sticky', top:0, height:'100vh', flexDirection:'column' }}>
        <div style={{ padding:'1.5rem 1.25rem', borderBottom:'1px solid rgba(255,255,255,0.08)' }}>
          <Link href="/" style={{ display:'flex', alignItems:'center', gap:'0.5rem', textDecoration:'none' }}>
            <span style={{ background:'linear-gradient(135deg,#6366f1,#f43f5e)', borderRadius:'0.5rem', padding:'0.25rem 0.5rem', color:'#fff', fontSize:'0.9rem', fontWeight:800 }}>%</span>
            <span style={{ color:'#fff', fontWeight:800, fontSize:'1rem', letterSpacing:'-0.02em' }}>DealFinder</span>
          </Link>
          <div style={{ marginTop:'0.5rem', padding:'0.25rem 0.5rem', borderRadius:'0.375rem', background:'rgba(239,68,68,0.15)', display:'inline-flex', alignItems:'center', gap:'0.35rem' }}>
            <i className="fas fa-shield-alt" style={{ color:'#ef4444', fontSize:'0.7rem' }}></i>
            <span style={{ color:'#fca5a5', fontSize:'0.72rem', fontWeight:700 }}>Admin Panel</span>
          </div>
        </div>

        <nav style={{ flex:1, padding:'1rem 0.75rem', display:'flex', flexDirection:'column', gap:'0.25rem' }}>
          {NAV.map(item => (
            <Link key={item.href} href={item.href} style={{ display:'flex', alignItems:'center', gap:'0.75rem', padding:'0.75rem 1rem', borderRadius:'0.625rem', textDecoration:'none', fontSize:'0.875rem', fontWeight:600, transition:'all 0.15s', background: pathname===item.href ? 'rgba(99,102,241,0.2)' : 'transparent', color: pathname===item.href ? '#a5b4fc' : 'rgba(255,255,255,0.6)', borderLeft: pathname===item.href ? '3px solid #6366f1' : '3px solid transparent' }}>
              <i className={`fas ${item.icon}`} style={{ width:'16px', textAlign:'center' }}></i>
              {item.label}
            </Link>
          ))}
          {/* Quick Add */}
          <Link href="/admin/promotions/new" style={{ display:'flex', alignItems:'center', gap:'0.75rem', padding:'0.75rem 1rem', borderRadius:'0.625rem', textDecoration:'none', fontSize:'0.875rem', fontWeight:700, marginTop:'0.5rem', background:'linear-gradient(135deg,#6366f1,#f43f5e)', color:'#fff', boxShadow:'0 4px 12px rgba(99,102,241,0.4)' }}>
            <i className="fas fa-bolt" style={{ width:'16px', textAlign:'center' }}></i>
            Quick Add Deal
          </Link>
        </nav>

        <div style={{ padding:'1rem 1.25rem', borderTop:'1px solid rgba(255,255,255,0.08)' }}>
          <div style={{ display:'flex', alignItems:'center', gap:'0.75rem', marginBottom:'0.75rem' }}>
            <div style={{ width:'36px', height:'36px', borderRadius:'50%', background:'linear-gradient(135deg,#6366f1,#f43f5e)', display:'flex', alignItems:'center', justifyContent:'center', color:'#fff', fontWeight:700, fontSize:'0.875rem', flexShrink:0 }}>
              {user.name.charAt(0).toUpperCase()}
            </div>
            <div style={{ minWidth:0 }}>
              <p style={{ color:'#fff', fontWeight:600, fontSize:'0.8rem', margin:0, overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap' }}>{user.name}</p>
              <p style={{ color:'rgba(255,255,255,0.5)', fontSize:'0.72rem', margin:0 }}>Administrator</p>
            </div>
          </div>
          <button onClick={logout} style={{ width:'100%', padding:'0.5rem', borderRadius:'0.5rem', border:'1px solid rgba(255,255,255,0.1)', background:'rgba(255,255,255,0.05)', color:'rgba(255,255,255,0.6)', fontSize:'0.8rem', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', gap:'0.5rem' }}>
            <i className="fas fa-sign-out-alt"></i> Logout
          </button>
        </div>
      </aside>

      {/* Main */}
      <div style={{ flex:1, display:'flex', flexDirection:'column', minWidth:0 }}>
        {/* Mobile topbar */}
        <div className="md:hidden" style={{ padding:'1rem', background:'var(--card-bg)', borderBottom:'1px solid var(--border-color)', display:'flex', alignItems:'center', justifyContent:'space-between' }}>
          <span style={{ fontWeight:800, color:'var(--text-primary)' }}>Admin Panel</span>
          <div className="flex gap-2">
            {NAV.map(item => (
              <Link key={item.href} href={item.href} style={{ padding:'0.4rem 0.6rem', borderRadius:'0.5rem', fontSize:'0.75rem', textDecoration:'none', background: pathname===item.href ? 'var(--primary-color)' : 'var(--light-gray)', color: pathname===item.href ? '#fff' : 'var(--text-secondary)' }}>
                <i className={`fas ${item.icon}`}></i>
              </Link>
            ))}
          </div>
        </div>
        <main style={{ flex:1, padding:'2rem', overflowY:'auto' }}>{children}</main>
      </div>
    </div>
  );
}
