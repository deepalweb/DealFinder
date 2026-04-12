'use client';

import { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import NotificationBell from '@/components/ui/NotificationBell';

export default function Header() {
  const pathname = usePathname();
  const { user, logout } = useAuth();
  const [menuOpen, setMenuOpen] = useState(false);
  const [userMenuOpen, setUserMenuOpen] = useState(false);
  const [isDark, setIsDark] = useState(false);
  const [mounted, setMounted] = useState(false);
  const userMenuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setMounted(true);
    const saved = localStorage.getItem('df-theme');
    if (saved === 'dark') {
      document.documentElement.setAttribute('data-theme', 'dark');
      setIsDark(true);
    }
  }, []);

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (userMenuRef.current && !userMenuRef.current.contains(e.target as Node)) setUserMenuOpen(false);
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  const toggleDark = () => {
    const next = !isDark;
    setIsDark(next);
    document.documentElement.setAttribute('data-theme', next ? 'dark' : 'light');
    localStorage.setItem('df-theme', next ? 'dark' : 'light');
  };

  const isActive = (path: string) => pathname === path;

  const navLinks = [
    { href: '/', icon: 'fa-home', label: 'Home' },
    { href: '/categories/all', icon: 'fa-tags', label: 'All Deals' },
    { href: '/merchants', icon: 'fa-store', label: 'Stores' },
    { href: '/favorites', icon: 'fa-heart', label: 'Favorites' },
    { href: '/nearby', icon: 'fa-map-marker-alt', label: 'Nearby' },
  ];

  const getSafeImage = (url?: string, name?: string) => {
    if (url && (url.startsWith('data:image') || url.startsWith('http'))) return url;
    return `https://ui-avatars.com/api/?name=${encodeURIComponent(name || 'U')}&background=random&size=100`;
  };

  const userMenuItems = user ? [
    { href: '/profile', icon: 'fa-user', label: 'My Profile' },
    { href: '/favorites', icon: 'fa-heart', label: 'My Favorites' },
    ...(user.role === 'merchant' ? [{ href: '/merchant/dashboard', icon: 'fa-store', label: 'Dashboard' }] : []),
    ...(user.role === 'admin' ? [{ href: '/admin/dashboard', icon: 'fa-shield-alt', label: 'Admin' }] : []),
  ] : [];

  return (
    <header style={{ backgroundColor: 'var(--header-bg)', backdropFilter: 'blur(16px)', boxShadow: '0 1px 0 var(--border-color)', position: 'sticky', top: 0, zIndex: 100 }}>
      <div className="max-w-7xl mx-auto px-4 py-3">
        <div className="flex items-center justify-between">

          {/* Logo */}
          <Link href="/" className="flex items-center gap-2 font-extrabold text-xl"
            style={{ color: 'var(--primary-color)', letterSpacing: '-0.03em', textDecoration: 'none' }}>
            <span style={{ background: 'linear-gradient(135deg,#6366f1,#f43f5e)', borderRadius: '0.5rem', padding: '0.25rem 0.5rem', color: '#fff', fontSize: '1rem' }}>%</span>
            DealFinder
          </Link>

          {/* Desktop Nav */}
          <nav className="hidden md:flex items-center gap-1">
            {navLinks.map(({ href, icon, label }) => (
              <Link key={href} href={href} style={{ color: isActive(href) ? 'var(--primary-color)' : 'var(--text-secondary)', background: isActive(href) ? 'rgba(99,102,241,0.1)' : 'transparent', padding: '0.4rem 0.75rem', borderRadius: '0.5rem', fontSize: '0.9rem', fontWeight: 500, textDecoration: 'none', transition: 'all 0.2s', display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                <i className={`fas ${icon}`}></i> {label}
              </Link>
            ))}
          </nav>

          {/* Right side */}
          <div className="flex items-center gap-2">

            {/* Notification Bell */}
            {mounted && user && <NotificationBell />}

            {/* Dark mode toggle — only after mount */}
            {mounted && (
              <button onClick={toggleDark} title={isDark ? 'Light mode' : 'Dark mode'}
                style={{ width: '2.25rem', height: '2.25rem', borderRadius: '50%', border: '1.5px solid var(--border-color)', background: 'var(--card-bg)', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', transition: 'all 0.2s', fontSize: '1rem' }}>
                <i className={`fas ${isDark ? 'fa-sun' : 'fa-moon'}`}></i>
              </button>
            )}

            {/* User menu — only after mount */}
            {mounted && (
              <>
                {user ? (
                  <div className="hidden md:block relative" ref={userMenuRef}>
                    <button onClick={() => setUserMenuOpen(!userMenuOpen)}
                      className="flex items-center gap-2" style={{ background: 'none', border: 'none', cursor: 'pointer' }}>
                      <span style={{ fontSize: '0.875rem', fontWeight: 500, color: 'var(--text-primary)' }}>{user.name}</span>
                      <div style={{ width: '36px', height: '36px', borderRadius: '50%', overflow: 'hidden', border: '2px solid var(--primary-color)' }}>
                        <img src={getSafeImage(user.profilePicture, user.name)} alt="Profile" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                      </div>
                    </button>
                    {userMenuOpen && (
                      <div style={{ position: 'absolute', right: 0, top: '110%', width: '220px', background: 'var(--card-bg)', borderRadius: '0.875rem', boxShadow: '0 8px 32px rgba(0,0,0,0.15)', border: '1px solid var(--border-color)', overflow: 'hidden', zIndex: 50 }}>
                        <div style={{ padding: '0.875rem 1rem', borderBottom: '1px solid var(--border-color)' }}>
                          <p style={{ fontWeight: 700, margin: 0, fontSize: '0.875rem', color: 'var(--text-primary)' }}>{user.name}</p>
                          <p style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', margin: 0 }}>{user.email}</p>
                        </div>
                        {userMenuItems.map(item => (
                          <Link key={item.href} href={item.href} onClick={() => setUserMenuOpen(false)}
                            style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.625rem 1rem', fontSize: '0.875rem', color: 'var(--text-primary)', textDecoration: 'none' }}
                            onMouseEnter={e => (e.currentTarget.style.background = 'var(--light-gray)')}
                            onMouseLeave={e => (e.currentTarget.style.background = 'transparent')}>
                            <i className={`fas ${item.icon}`} style={{ width: '16px', color: 'var(--primary-color)' }}></i> {item.label}
                          </Link>
                        ))}
                        <hr style={{ margin: '0.25rem 0', border: 'none', borderTop: '1px solid var(--border-color)' }} />
                        <button onClick={() => { setUserMenuOpen(false); logout(); }}
                          style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.625rem 1rem', fontSize: '0.875rem', color: '#ef4444', background: 'none', border: 'none', cursor: 'pointer', width: '100%' }}>
                          <i className="fas fa-sign-out-alt" style={{ width: '16px' }}></i> Logout
                        </button>
                      </div>
                    )}
                  </div>
                ) : (
                  <div className="hidden md:flex items-center gap-2">
                    <Link href="/login" style={{ fontSize: '0.875rem', fontWeight: 500, color: 'var(--text-secondary)', textDecoration: 'none' }}>Login</Link>
                    <Link href="/register" className="btn btn-primary" style={{ fontSize: '0.8rem', padding: '0.4rem 0.875rem' }}>Sign Up</Link>
                  </div>
                )}
              </>
            )}

            {/* Mobile menu button */}
            <button className="md:hidden" onClick={() => setMenuOpen(!menuOpen)}
              style={{ width: '2.25rem', height: '2.25rem', borderRadius: '50%', border: '1.5px solid var(--border-color)', background: 'var(--card-bg)', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
              <i className={`fas ${menuOpen ? 'fa-times' : 'fa-bars'}`}></i>
            </button>
          </div>
        </div>

        {/* Mobile menu */}
        {menuOpen && (
          <div className="md:hidden mt-3 pb-3" style={{ borderTop: '1px solid var(--border-color)', paddingTop: '0.75rem' }}>
            <nav className="flex flex-col gap-1">
              {navLinks.map(({ href, icon, label }) => (
                <Link key={href} href={href} onClick={() => setMenuOpen(false)}
                  style={{ color: isActive(href) ? 'var(--primary-color)' : 'var(--text-secondary)', padding: '0.5rem 0.75rem', borderRadius: '0.5rem', fontSize: '0.9rem', fontWeight: 500, textDecoration: 'none', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <i className={`fas ${icon}`}></i> {label}
                </Link>
              ))}
              {mounted && user ? (
                <>
                  <Link href="/profile" onClick={() => setMenuOpen(false)} style={{ color: 'var(--text-secondary)', padding: '0.5rem 0.75rem', borderRadius: '0.5rem', fontSize: '0.9rem', fontWeight: 500, textDecoration: 'none', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <i className="fas fa-user"></i> Profile
                  </Link>
                  <button onClick={() => { setMenuOpen(false); logout(); }} style={{ color: '#ef4444', padding: '0.5rem 0.75rem', borderRadius: '0.5rem', fontSize: '0.9rem', fontWeight: 500, background: 'none', border: 'none', cursor: 'pointer', textAlign: 'left', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <i className="fas fa-sign-out-alt"></i> Logout
                  </button>
                </>
              ) : (
                <div className="flex gap-2 pt-2">
                  <Link href="/login" onClick={() => setMenuOpen(false)} className="btn" style={{ flex: 1, justifyContent: 'center', border: '1.5px solid var(--border-color)', background: 'var(--card-bg)', color: 'var(--text-primary)' }}>Login</Link>
                  <Link href="/register" onClick={() => setMenuOpen(false)} className="btn btn-primary" style={{ flex: 1, justifyContent: 'center' }}>Sign Up</Link>
                </div>
              )}
            </nav>
          </div>
        )}
      </div>
    </header>
  );
}
