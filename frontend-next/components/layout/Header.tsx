'use client';

import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { usePathname, useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import NotificationBell from '@/components/ui/NotificationBell';

export default function Header() {
  const pathname = usePathname();
  const router = useRouter();
  const { user, logout, loading } = useAuth();
  const [menuOpen, setMenuOpen] = useState(false);
  const [userMenuOpen, setUserMenuOpen] = useState(false);
  const [isDark, setIsDark] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const userMenuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const saved = localStorage.getItem('df-theme');
    if (saved === 'dark') {
      document.documentElement.setAttribute('data-theme', 'dark');
    }
  }, []);

  useEffect(() => {
    const handler = (event: MouseEvent) => {
      if (userMenuRef.current && !userMenuRef.current.contains(event.target as Node)) {
        setUserMenuOpen(false);
      }
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

  const isActive = (href: string) => {
    if (href === '/') return pathname === '/';
    return pathname === href || pathname.startsWith(`${href}/`);
  };

  const navLinks = [
    { href: '/categories/all', icon: 'fa-tags', label: 'Categories' },
    { href: '/nearby', icon: 'fa-location-dot', label: 'Nearby Deals' },
    { href: '/merchants', icon: 'fa-store', label: 'Businesses' },
  ];

  const getSafeImage = (url?: string, name?: string) => {
    if (url && (url.startsWith('data:image') || url.startsWith('http'))) return url;
    return `https://ui-avatars.com/api/?name=${encodeURIComponent(name || 'U')}&background=random&size=100`;
  };

  const submitSearch = () => {
    const trimmed = searchQuery.trim();
    setMenuOpen(false);
    setUserMenuOpen(false);
    router.push(trimmed ? `/categories/all?q=${encodeURIComponent(trimmed)}` : '/categories/all');
  };

  const userMenuItems = user
    ? [
        { href: '/profile', icon: 'fa-user', label: 'My Profile' },
        { href: '/favorites', icon: 'fa-heart', label: 'Saved Deals' },
        ...(user.role === 'merchant' ? [{ href: '/merchant/dashboard', icon: 'fa-chart-line', label: 'Merchant Dashboard' }] : []),
        ...(user.role === 'admin' ? [{ href: '/admin/dashboard', icon: 'fa-shield-halved', label: 'Admin Console' }] : []),
      ]
    : [];

  return (
    <header
      style={{
        position: 'sticky',
        top: 0,
        zIndex: 100,
        background: 'color-mix(in srgb, var(--header-bg) 94%, transparent)',
        backdropFilter: 'blur(18px)',
        borderBottom: '1px solid color-mix(in srgb, var(--border-color) 78%, transparent)',
        boxShadow: '0 12px 28px rgba(15, 23, 42, 0.08)',
      }}
    >
      <div className="max-w-7xl mx-auto px-4 py-3">
        <div className="flex items-center justify-between gap-6">
          {/* LEFT: Logo + Brand */}
          <Link
            href="/"
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '0.65rem',
              textDecoration: 'none',
              flexShrink: 0,
            }}
          >
            <span
              style={{
                width: '2.4rem',
                height: '2.4rem',
                borderRadius: '0.7rem',
                display: 'inline-flex',
                alignItems: 'center',
                justifyContent: 'center',
                background: 'var(--primary-gradient)',
                color: '#fff',
                fontWeight: 900,
                fontSize: '1.2rem',
                boxShadow: '0 8px 16px rgba(37,99,235,0.2)',
              }}
            >
              %
            </span>
            <span>
              <span
                style={{
                  display: 'block',
                  fontSize: '1.05rem',
                  fontWeight: 800,
                  letterSpacing: '-0.02em',
                  color: 'var(--text-primary)',
                  lineHeight: 1.2,
                }}
              >
                DealFinder
              </span>
              <span
                className="hidden sm:block"
                style={{
                  fontSize: '0.7rem',
                  color: 'var(--text-secondary)',
                  whiteSpace: 'nowrap',
                  fontWeight: 500,
                }}
              >
                Sri Lanka Deals
              </span>
            </span>
          </Link>

          {/* CENTER: Large Search Bar */}
          <div className="hidden md:flex" style={{ flex: 1, minWidth: 0, maxWidth: '600px' }}>
            <div
              style={{
                width: '100%',
                display: 'flex',
                alignItems: 'center',
                gap: '0.75rem',
                padding: '0.6rem 0.7rem 0.6rem 1.1rem',
                borderRadius: '999px',
                background: 'var(--card-bg)',
                border: '2px solid var(--border-color)',
                boxShadow: '0 4px 12px rgba(0,0,0,0.08)',
                transition: 'all 0.2s ease',
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.borderColor = 'var(--primary-color)';
                e.currentTarget.style.boxShadow = '0 6px 20px rgba(37,99,235,0.15)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.borderColor = 'var(--border-color)';
                e.currentTarget.style.boxShadow = '0 4px 12px rgba(0,0,0,0.08)';
              }}
            >
              <i className="fas fa-search" style={{ color: 'var(--text-secondary)', fontSize: '1rem' }}></i>
              <input
                type="text"
                value={searchQuery}
                onChange={(event) => setSearchQuery(event.target.value)}
                onKeyDown={(event) => {
                  if (event.key === 'Enter') submitSearch();
                }}
                placeholder="Search restaurants, hotels, bank offers…"
                style={{
                  flex: 1,
                  minWidth: 0,
                  border: 'none',
                  outline: 'none',
                  background: 'transparent',
                  color: 'var(--text-primary)',
                  fontSize: '0.95rem',
                  fontWeight: 500,
                }}
              />
              <button
                onClick={submitSearch}
                className="btn btn-primary"
                style={{ 
                  padding: '0.65rem 1.2rem', 
                  borderRadius: '999px',
                  fontSize: '0.9rem',
                  fontWeight: 700,
                }}
              >
                Search
              </button>
            </div>
          </div>

          {/* RIGHT: Desktop Navigation */}
          <div className="hidden lg:flex items-center gap-1">
            <nav className="flex items-center gap-1">
              {navLinks.map(({ href, icon, label }) => {
                const active = isActive(href);
                return (
                  <Link
                    key={href}
                    href={href}
                    onClick={() => {
                      setMenuOpen(false);
                      setUserMenuOpen(false);
                    }}
                    style={{
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '0.5rem',
                      padding: '0.65rem 0.9rem',
                      borderRadius: '0.6rem',
                      textDecoration: 'none',
                      fontSize: '0.88rem',
                      fontWeight: 600,
                      color: active ? 'var(--primary-color)' : 'var(--text-secondary)',
                      background: active ? 'rgba(37,99,235,0.1)' : 'transparent',
                      transition: 'all 0.2s ease',
                    }}
                    onMouseEnter={(e) => {
                      if (!active) {
                        e.currentTarget.style.background = 'var(--light-gray)';
                        e.currentTarget.style.color = 'var(--text-primary)';
                      }
                    }}
                    onMouseLeave={(e) => {
                      if (!active) {
                        e.currentTarget.style.background = 'transparent';
                        e.currentTarget.style.color = 'var(--text-secondary)';
                      }
                    }}
                  >
                    <i className={`fas ${icon}`} style={{ fontSize: '0.9rem' }}></i>
                    {label}
                  </Link>
                );
              })}
            </nav>

          </div>

          {/* RIGHT: User Actions */}
          <div className="flex items-center gap-2">
            {!loading && user ? <NotificationBell /> : null}

            {!loading && user ? (
                <div className="hidden md:block relative" ref={userMenuRef}>
                  <button
                    onClick={() => setUserMenuOpen(!userMenuOpen)}
                    style={{
                      border: '1px solid var(--border-color)',
                      background: 'var(--card-bg)',
                      borderRadius: '999px',
                      padding: '0.35rem 0.45rem 0.35rem 0.85rem',
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '0.75rem',
                      cursor: 'pointer',
                      boxShadow: 'var(--box-shadow)',
                    }}
                  >
                    <span style={{ textAlign: 'right' }}>
                      <span style={{ display: 'block', fontSize: '0.86rem', fontWeight: 700, color: 'var(--text-primary)' }}>
                        {user.name}
                      </span>
                      <span style={{ display: 'block', fontSize: '0.73rem', color: 'var(--text-secondary)' }}>
                        {user.role === 'merchant' ? 'Merchant account' : user.role === 'admin' ? 'Admin account' : 'Member'}
                      </span>
                    </span>
                    <span
                      style={{
                        width: '2.25rem',
                        height: '2.25rem',
                        position: 'relative',
                        borderRadius: '999px',
                        overflow: 'hidden',
                        border: '2px solid rgba(37,99,235,0.16)',
                        flexShrink: 0,
                      }}
                    >
                      <Image
                        src={getSafeImage(user.profilePicture, user.name)}
                        alt="Profile"
                        fill
                        sizes="36px"
                        style={{ objectFit: 'cover' }}
                      />
                    </span>
                  </button>

                  {userMenuOpen && (
                    <div
                      style={{
                        position: 'absolute',
                        right: 0,
                        top: 'calc(100% + 0.7rem)',
                        width: '250px',
                        background: 'var(--card-bg)',
                        borderRadius: '1rem',
                        boxShadow: '0 20px 40px rgba(15,23,42,0.16)',
                        border: '1px solid var(--border-color)',
                        overflow: 'hidden',
                      }}
                    >
                      <div
                        style={{
                          padding: '1rem',
                          background: 'linear-gradient(135deg, rgba(37,99,235,0.08), rgba(245,158,11,0.08))',
                          borderBottom: '1px solid var(--border-color)',
                        }}
                      >
                        <div style={{ fontWeight: 800, color: 'var(--text-primary)' }}>{user.name}</div>
                        <div style={{ fontSize: '0.78rem', color: 'var(--text-secondary)' }}>{user.email}</div>
                      </div>

                      <div style={{ padding: '0.5rem' }}>
                        {userMenuItems.map((item) => (
                          <Link
                            key={item.href}
                            href={item.href}
                            onClick={() => setUserMenuOpen(false)}
                            style={{
                              display: 'flex',
                              alignItems: 'center',
                              gap: '0.65rem',
                              padding: '0.8rem',
                              borderRadius: '0.8rem',
                              textDecoration: 'none',
                              color: 'var(--text-primary)',
                              fontSize: '0.9rem',
                              fontWeight: 600,
                            }}
                            onMouseEnter={(event) => {
                              event.currentTarget.style.background = 'var(--light-gray)';
                            }}
                            onMouseLeave={(event) => {
                              event.currentTarget.style.background = 'transparent';
                            }}
                          >
                            <i className={`fas ${item.icon}`} style={{ width: '1rem', color: 'var(--primary-color)' }}></i>
                            {item.label}
                          </Link>
                        ))}
                        <button
                          onClick={() => logout()}
                          style={{
                            marginTop: '0.25rem',
                            width: '100%',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.65rem',
                            padding: '0.8rem',
                            borderRadius: '0.8rem',
                            border: 'none',
                            background: 'transparent',
                            color: 'var(--danger-color)',
                            fontSize: '0.9rem',
                            fontWeight: 700,
                            cursor: 'pointer',
                          }}
                        >
                          <i className="fas fa-right-from-bracket" style={{ width: '1rem' }}></i>
                          Logout
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              ) : !loading ? (
                <div className="hidden md:flex items-center gap-2">
                  <Link
                    href="/login"
                    onClick={() => setMenuOpen(false)}
                    style={{
                      padding: '0.65rem 1rem',
                      borderRadius: '0.6rem',
                      textDecoration: 'none',
                      color: 'var(--text-primary)',
                      fontWeight: 600,
                      fontSize: '0.88rem',
                      transition: 'all 0.2s ease',
                    }}
                    onMouseEnter={(e) => {
                      e.currentTarget.style.background = 'var(--light-gray)';
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.background = 'transparent';
                    }}
                  >
                    Login
                  </Link>
                  <Link
                    href="/register"
                    onClick={() => setMenuOpen(false)}
                    className="btn"
                    style={{
                      background: 'var(--primary-gradient)',
                      color: '#fff',
                      padding: '0.65rem 1.2rem',
                      borderRadius: '0.6rem',
                      boxShadow: '0 4px 12px rgba(37,99,235,0.25)',
                      fontWeight: 700,
                      fontSize: '0.88rem',
                    }}
                  >
                    <i className="fas fa-mobile-screen-button" style={{ marginRight: '0.5rem' }}></i>
                    Download App
                  </Link>
                </div>
              ) : null}

            {/* Mobile: Download + Hamburger */}
            <Link
              href="/register"
              className="md:hidden btn"
              style={{
                background: 'var(--primary-gradient)',
                color: '#fff',
                padding: '0.6rem 0.8rem',
                borderRadius: '0.6rem',
                fontSize: '0.85rem',
                fontWeight: 700,
                textDecoration: 'none',
                display: 'inline-flex',
                alignItems: 'center',
                gap: '0.4rem',
              }}
            >
              <i className="fas fa-download"></i>
            </Link>

            <button
              className="md:hidden"
              onClick={() => setMenuOpen(!menuOpen)}
              style={{
                width: '2.4rem',
                height: '2.4rem',
                borderRadius: '0.6rem',
                border: '1px solid var(--border-color)',
                background: 'var(--card-bg)',
                color: 'var(--text-secondary)',
                display: 'inline-flex',
                alignItems: 'center',
                justifyContent: 'center',
                cursor: 'pointer',
                fontSize: '1.1rem',
              }}
            >
              <i className={`fas ${menuOpen ? 'fa-times' : 'fa-bars'}`}></i>
            </button>
          </div>
        </div>

        {menuOpen && (
          <div
            className="md:hidden"
            style={{
              marginTop: '1rem',
              padding: '1rem',
              borderRadius: '1rem',
              background: 'var(--card-bg)',
              border: '1px solid var(--border-color)',
              boxShadow: '0 8px 24px rgba(0,0,0,0.1)',
            }}
          >
            {/* Mobile Search Bar */}
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.6rem',
                padding: '0.7rem 1rem',
                borderRadius: '0.8rem',
                background: 'var(--light-gray)',
                marginBottom: '1rem',
                border: '1px solid var(--border-color)',
              }}
            >
              <i className="fas fa-search" style={{ color: 'var(--text-secondary)' }}></i>
              <input
                type="text"
                value={searchQuery}
                onChange={(event) => setSearchQuery(event.target.value)}
                onKeyDown={(event) => {
                  if (event.key === 'Enter') submitSearch();
                }}
                placeholder="Search restaurants, hotels…"
                style={{
                  flex: 1,
                  minWidth: 0,
                  border: 'none',
                  outline: 'none',
                  background: 'transparent',
                  color: 'var(--text-primary)',
                  fontSize: '0.9rem',
                }}
              />
              <button
                onClick={submitSearch}
                className="btn btn-primary"
                style={{ padding: '0.6rem 1rem', fontSize: '0.85rem' }}
              >
                Go
              </button>
            </div>

            <nav className="grid grid-cols-1 gap-2 mb-4">
              {navLinks.map(({ href, icon, label }) => {
                const active = isActive(href);
                return (
                  <Link
                    key={href}
                    href={href}
                    onClick={() => setMenuOpen(false)}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.7rem',
                      padding: '0.85rem 1rem',
                      borderRadius: '0.8rem',
                      textDecoration: 'none',
                      fontWeight: 600,
                      fontSize: '0.9rem',
                      color: active ? 'var(--primary-color)' : 'var(--text-primary)',
                      background: active ? 'rgba(37,99,235,0.1)' : 'var(--light-gray)',
                    }}
                  >
                    <i className={`fas ${icon}`}></i>
                    {label}
                  </Link>
                );
              })}
            </nav>

            <div
              style={{
                paddingTop: '1rem',
                borderTop: '1px solid var(--border-color)',
              }}
            >

              {!loading && user ? (
                <div className="grid grid-cols-1 gap-2">
                  {userMenuItems.map((item) => (
                    <Link
                      key={item.href}
                      href={item.href}
                      onClick={() => setMenuOpen(false)}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '0.7rem',
                        padding: '0.9rem 1rem',
                        borderRadius: '0.9rem',
                        background: 'var(--light-gray)',
                        color: 'var(--text-primary)',
                        textDecoration: 'none',
                        fontWeight: 700,
                      }}
                    >
                      <i className={`fas ${item.icon}`} style={{ color: 'var(--primary-color)' }}></i>
                      {item.label}
                    </Link>
                  ))}
                  <button
                    onClick={() => logout()}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.7rem',
                      padding: '0.9rem 1rem',
                      borderRadius: '0.9rem',
                      border: 'none',
                      background: 'rgba(239,68,68,0.08)',
                      color: 'var(--danger-color)',
                      fontWeight: 800,
                      cursor: 'pointer',
                    }}
                  >
                    <i className="fas fa-right-from-bracket"></i>
                    Logout
                  </button>
                </div>
              ) : !loading ? (
                <div className="grid grid-cols-2 gap-2">
                  <Link
                    href="/login"
                    onClick={() => setMenuOpen(false)}
                    className="btn"
                    style={{
                      justifyContent: 'center',
                      background: 'var(--light-gray)',
                      color: 'var(--text-primary)',
                      padding: '0.9rem 1rem',
                    }}
                  >
                    Login
                  </Link>
                  <Link
                    href="/register"
                    onClick={() => setMenuOpen(false)}
                    className="btn"
                    style={{
                      justifyContent: 'center',
                      background: 'var(--primary-gradient)',
                      color: '#fff',
                      padding: '0.9rem 1rem',
                    }}
                  >
                    Grab Deals
                  </Link>
                </div>
              ) : null}
            </div>
          </div>
        )}
      </div>
    </header>
  );
}
