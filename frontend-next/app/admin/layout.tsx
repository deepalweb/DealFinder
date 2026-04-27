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
  { href: '/admin/sections', icon: 'fa-layer-group', label: 'Sections' },
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
    <div className="admin-shell" style={{ marginTop:'-1px' }}>
      {/* Sidebar */}
      <aside className="admin-sidebar hidden md:flex">
        <div style={{ padding:'1.5rem 1.25rem', borderBottom:'1px solid rgba(255,255,255,0.08)' }}>
          <Link href="/" className="brand-mark">
            <span className="brand-badge">%</span>
            <span style={{ color:'#fff', fontWeight:800, fontSize:'1rem', letterSpacing:'-0.02em' }}>DealFinder</span>
          </Link>
          <div style={{ marginTop:'0.8rem', padding:'0.35rem 0.65rem', borderRadius:'9999px', background:'rgba(56,189,248,0.16)', display:'inline-flex', alignItems:'center', gap:'0.35rem', border:'1px solid rgba(96,165,250,0.18)' }}>
            <i className="fas fa-shield-alt" style={{ color:'#7dd3fc', fontSize:'0.7rem' }}></i>
            <span style={{ color:'#dbeafe', fontSize:'0.72rem', fontWeight:700 }}>Admin Panel</span>
          </div>
        </div>

        <nav style={{ flex:1, padding:'1rem 0.75rem', display:'flex', flexDirection:'column', gap:'0.25rem' }}>
          {NAV.map(item => (
            <Link key={item.href} href={item.href} className={`admin-nav-link ${pathname===item.href ? 'active' : ''}`}>
              <i className={`fas ${item.icon}`} style={{ width:'16px', textAlign:'center' }}></i>
              {item.label}
            </Link>
          ))}
          {/* Quick Add */}
          <Link href="/admin/promotions/new" style={{ display:'flex', alignItems:'center', gap:'0.75rem', padding:'0.85rem 1rem', borderRadius:'0.95rem', textDecoration:'none', fontSize:'0.875rem', fontWeight:700, marginTop:'0.5rem', background:'var(--primary-gradient)', color:'#fff', boxShadow:'0 16px 30px rgba(37,99,235,0.25)' }}>
            <i className="fas fa-bolt" style={{ width:'16px', textAlign:'center' }}></i>
            Quick Add Deal
          </Link>
        </nav>

        <div style={{ padding:'1rem 1.25rem', borderTop:'1px solid rgba(255,255,255,0.08)' }}>
          <div style={{ display:'flex', alignItems:'center', gap:'0.75rem', marginBottom:'0.75rem' }}>
            <div style={{ width:'36px', height:'36px', borderRadius:'50%', background:'var(--primary-gradient)', display:'flex', alignItems:'center', justifyContent:'center', color:'#fff', fontWeight:700, fontSize:'0.875rem', flexShrink:0 }}>
              {user.name.charAt(0).toUpperCase()}
            </div>
            <div style={{ minWidth:0 }}>
              <p style={{ color:'#fff', fontWeight:600, fontSize:'0.8rem', margin:0, overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap' }}>{user.name}</p>
              <p style={{ color:'rgba(255,255,255,0.5)', fontSize:'0.72rem', margin:0 }}>Administrator</p>
            </div>
          </div>
          <button onClick={logout} style={{ width:'100%', padding:'0.65rem', borderRadius:'0.85rem', border:'1px solid rgba(255,255,255,0.12)', background:'rgba(255,255,255,0.06)', color:'rgba(255,255,255,0.75)', fontSize:'0.8rem', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', gap:'0.5rem' }}>
            <i className="fas fa-sign-out-alt"></i> Logout
          </button>
        </div>
      </aside>

      {/* Main */}
      <div style={{ flex:1, display:'flex', flexDirection:'column', minWidth:0 }}>
        {/* Mobile topbar */}
        <div className="md:hidden" style={{ padding:'1rem', background:'var(--glass-gradient)', borderBottom:'1px solid var(--border-color)', display:'flex', alignItems:'center', justifyContent:'space-between' }}>
          <span style={{ fontWeight:800, color:'var(--text-primary)' }}>Admin Panel</span>
          <div className="flex gap-2">
            {NAV.map(item => (
              <Link key={item.href} href={item.href} style={{ padding:'0.45rem 0.65rem', borderRadius:'0.75rem', fontSize:'0.75rem', textDecoration:'none', background: pathname===item.href ? 'var(--primary-gradient)' : 'rgba(255,255,255,0.72)', color: pathname===item.href ? '#fff' : 'var(--text-secondary)' }}>
                <i className={`fas ${item.icon}`}></i>
              </Link>
            ))}
          </div>
        </div>
        <main className="admin-main" style={{ overflowY:'auto' }}>{children}</main>
      </div>
    </div>
  );
}
