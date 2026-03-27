'use client';

import Link from 'next/link';

export default function Footer() {
  return (
    <footer style={{ background: 'linear-gradient(135deg, #0f172a 0%, #1e1b4b 100%)', color: '#e2e8f0', padding: '3rem 0 1.5rem', marginTop: '4rem' }}>
      <div className="max-w-7xl mx-auto px-4">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8 mb-8">
          <div>
            <h3 style={{ fontWeight: 800, fontSize: '1.1rem', color: '#fff', marginBottom: '0.75rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <span style={{ background: 'linear-gradient(135deg,#6366f1,#f43f5e)', borderRadius: '0.375rem', padding: '0.2rem 0.4rem', fontSize: '0.875rem' }}>%</span>
              DealFinder
            </h3>
            <p style={{ fontSize: '0.875rem', color: '#94a3b8', lineHeight: 1.6, marginBottom: '1rem' }}>
              Your destination for the best discounts and promotions from your favorite brands.
            </p>
            <div className="flex gap-2">
              {[['fab fa-facebook-f','#1877f2'],['fab fa-twitter','#1da1f2'],['fab fa-instagram','linear-gradient(135deg,#833ab4,#fd1d1d,#fcb045)'],['fab fa-tiktok','#010101']].map(([icon, bg]) => (
                <a key={icon} href="#" className="social-icon" style={{ background: bg as string, borderColor: 'transparent', color: '#fff' }}>
                  <i className={icon as string}></i>
                </a>
              ))}
            </div>
          </div>

          <div>
            <h3 style={{ fontWeight: 700, fontSize: '0.9rem', color: '#fff', marginBottom: '0.875rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Categories</h3>
            {['fashion','electronics','travel','food','health'].map(cat => (
              <Link key={cat} href={`/categories/${cat}`} className="footer-link" style={{ display: 'block', color: '#94a3b8', fontSize: '0.875rem', marginBottom: '0.4rem', textDecoration: 'none', transition: 'color 0.2s' }}
                onMouseEnter={e => (e.currentTarget.style.color = '#fff')}
                onMouseLeave={e => (e.currentTarget.style.color = '#94a3b8')}>
                {cat.charAt(0).toUpperCase() + cat.slice(1)}
              </Link>
            ))}
          </div>

          <div>
            <h3 style={{ fontWeight: 700, fontSize: '0.9rem', color: '#fff', marginBottom: '0.875rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Quick Links</h3>
            {[['/', 'Home'],['/categories/all','All Deals'],['/merchants','Stores'],['/about','About Us'],['/contact','Contact'],['/privacy','Privacy Policy']].map(([href, label]) => (
              <Link key={href} href={href} style={{ display: 'block', color: '#94a3b8', fontSize: '0.875rem', marginBottom: '0.4rem', textDecoration: 'none', transition: 'color 0.2s' }}
                onMouseEnter={e => (e.currentTarget.style.color = '#fff')}
                onMouseLeave={e => (e.currentTarget.style.color = '#94a3b8')}>
                {label}
              </Link>
            ))}
          </div>

          <div>
            <h3 style={{ fontWeight: 700, fontSize: '0.9rem', color: '#fff', marginBottom: '0.875rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Newsletter</h3>
            <p style={{ fontSize: '0.875rem', color: '#94a3b8', marginBottom: '0.875rem' }}>Subscribe for the latest deals and promotions.</p>
            <form className="flex flex-col gap-2" onSubmit={e => e.preventDefault()}>
              <input type="email" placeholder="Your email address" required
                style={{ padding: '0.625rem 0.875rem', borderRadius: '0.5rem', border: '1px solid rgba(255,255,255,0.12)', background: 'rgba(255,255,255,0.06)', color: '#fff', fontSize: '0.875rem', outline: 'none' }} />
              <button type="submit" className="btn btn-primary" style={{ justifyContent: 'center' }}>
                <i className="fas fa-paper-plane"></i> Subscribe
              </button>
            </form>
          </div>
        </div>

        <div style={{ borderTop: '1px solid rgba(255,255,255,0.08)', paddingTop: '1.5rem', textAlign: 'center', fontSize: '0.8rem', color: '#64748b' }}>
          <i className="far fa-copyright"></i> {new Date().getFullYear()} DealFinder. All rights reserved.
        </div>
      </div>
    </footer>
  );
}
