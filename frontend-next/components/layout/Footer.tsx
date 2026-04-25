'use client';

import Link from 'next/link';

const socialLinks = [
  { href: '#', icon: 'fab fa-facebook-f', label: 'Facebook' },
  { href: '#', icon: 'fab fa-instagram', label: 'Instagram' },
  { href: '#', icon: 'fab fa-tiktok', label: 'TikTok' },
];

export default function Footer() {
  return (
    <footer
      style={{
        marginTop: '4rem',
        color: '#dbe4ee',
        background:
          'radial-gradient(circle at top left, rgba(37,99,235,0.28), transparent 26%), radial-gradient(circle at top right, rgba(56,189,248,0.22), transparent 28%), radial-gradient(circle at bottom right, rgba(245,158,11,0.16), transparent 24%), linear-gradient(180deg, #0f172a 0%, #111827 100%)',
      }}
    >
      <div className="max-w-7xl mx-auto px-4" style={{ paddingTop: '3.5rem', paddingBottom: '1.4rem' }}>
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
            gap: '1.5rem',
            marginBottom: '2.5rem',
          }}
        >
          <section
            style={{
              padding: '1.4rem',
              borderRadius: '1.25rem',
              background: 'rgba(255,255,255,0.05)',
              border: '1px solid rgba(255,255,255,0.08)',
            }}
          >
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1rem' }}>
              <span
                style={{
                  width: '2.4rem',
                  height: '2.4rem',
                  borderRadius: '0.85rem',
                  display: 'inline-flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  background: 'var(--primary-gradient)',
                  color: '#fff',
                  fontWeight: 900,
                }}
              >
                %
              </span>
              <div>
                <div style={{ fontWeight: 900, fontSize: '1.05rem', color: '#fff' }}>DealFinder</div>
                <div style={{ fontSize: '0.8rem', color: '#9fb3c8' }}>Deals, nearby offers, and smarter browsing</div>
              </div>
            </div>

            <p style={{ margin: 0, marginBottom: '1rem', lineHeight: 1.7, color: '#b8c7d8', fontSize: '0.92rem' }}>
              Find current promotions faster, compare nearby options, and keep your shopping flow focused instead of scattered.
            </p>

            <div className="grid grid-cols-1 gap-2" style={{ fontSize: '0.88rem' }}>
              <a href="mailto:support@dealfinder.com" style={{ color: '#dbe4ee', textDecoration: 'none', display: 'inline-flex', alignItems: 'center', gap: '0.55rem' }}>
                <i className="fas fa-envelope" style={{ color: '#f59e0b' }}></i>
                support@dealfinder.com
              </a>
              <a href="tel:+94760846996" style={{ color: '#dbe4ee', textDecoration: 'none', display: 'inline-flex', alignItems: 'center', gap: '0.55rem' }}>
                <i className="fas fa-phone" style={{ color: '#22c55e' }}></i>
                +94 760 846 996
              </a>
            </div>
          </section>

          <section>
            <div style={{ fontWeight: 800, color: '#fff', marginBottom: '1rem', fontSize: '0.92rem', textTransform: 'uppercase' }}>
              Discover
            </div>
            <div className="grid grid-cols-1 gap-3">
              {[
                ['/', 'Home'],
                ['/categories/all', 'All Deals'],
                ['/nearby', 'Nearby Offers'],
                ['/merchants', 'Stores'],
                ['/favorites', 'Saved Deals'],
              ].map(([href, label]) => (
                <Link key={href} href={href} style={{ color: '#b8c7d8', textDecoration: 'none', fontWeight: 600 }}>
                  {label}
                </Link>
              ))}
            </div>
          </section>

          <section>
            <div style={{ fontWeight: 800, color: '#fff', marginBottom: '1rem', fontSize: '0.92rem', textTransform: 'uppercase' }}>
              Company
            </div>
            <div className="grid grid-cols-1 gap-3">
              {[
                ['/about', 'About DealFinder'],
                ['/contact', 'Contact'],
                ['/privacy', 'Privacy'],
                ['/register', 'Create Account'],
                ['/login', 'Sign In'],
              ].map(([href, label]) => (
                <Link key={href} href={href} style={{ color: '#b8c7d8', textDecoration: 'none', fontWeight: 600 }}>
                  {label}
                </Link>
              ))}
            </div>
          </section>

          <section
            style={{
              padding: '1.4rem',
              borderRadius: '1.25rem',
              background: 'linear-gradient(135deg, rgba(37,99,235,0.2), rgba(56,189,248,0.16), rgba(245,158,11,0.18))',
              border: '1px solid rgba(255,255,255,0.08)',
            }}
          >
            <div style={{ fontWeight: 800, color: '#fff', marginBottom: '0.7rem', fontSize: '1rem' }}>Stay in the loop</div>
            <p style={{ margin: 0, marginBottom: '1rem', lineHeight: 1.7, color: '#d7e3f0', fontSize: '0.9rem' }}>
              Save the offers you care about and check back for the latest featured promotions and nearby picks.
            </p>
            <div className="flex flex-wrap gap-2">
              <Link
                href="/register"
                className="btn"
                style={{
                  background: '#fff',
                  color: '#0f172a',
                  fontWeight: 800,
                  padding: '0.85rem 1rem',
                }}
              >
                Create Free Account
              </Link>
              <Link
                href="/categories/all"
                className="btn"
                style={{
                  background: 'rgba(255,255,255,0.08)',
                  color: '#fff',
                  border: '1px solid rgba(255,255,255,0.14)',
                  padding: '0.85rem 1rem',
                }}
              >
                Browse Deals
              </Link>
            </div>
          </section>
        </div>

        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            gap: '1rem',
            flexWrap: 'wrap',
            alignItems: 'center',
            paddingTop: '1.25rem',
            borderTop: '1px solid rgba(255,255,255,0.08)',
          }}
        >
          <div style={{ color: '#8ca0b5', fontSize: '0.82rem' }}>
            Copyright {new Date().getFullYear()} DealFinder. Built for cleaner deal discovery.
          </div>
          <div className="flex items-center gap-2">
            {socialLinks.map((social) => (
              <a
                key={social.label}
                href={social.href}
                aria-label={social.label}
                className="social-icon"
                style={{
                  background: 'rgba(255,255,255,0.06)',
                  color: '#fff',
                  borderColor: 'rgba(255,255,255,0.12)',
                }}
              >
                <i className={social.icon}></i>
              </a>
            ))}
          </div>
        </div>
      </div>
    </footer>
  );
}
