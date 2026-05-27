'use client';

import Link from 'next/link';
import { useLanguage } from '@/contexts/LanguageContext';

const socialLinks = [
  { href: '#', icon: 'fab fa-facebook-f', label: 'Facebook' },
  { href: '#', icon: 'fab fa-instagram', label: 'Instagram' },
  { href: '#', icon: 'fab fa-tiktok', label: 'TikTok' },
];

export default function Footer() {
  const { language } = useLanguage();

  const footerCopy = {
    tagline: language === 'en' ? 'Find the best deals near you — instantly' : language === 'si' ? 'ඔබ අසල හොඳම deals — ක්ෂණිකව' : 'உங்களுக்கு அருகிலுள்ள சிறந்த deals — உடனே',
    description:
      language === 'en'
        ? 'Fast, smart, and local-first deal discovery built for shoppers in Sri Lanka.'
        : language === 'si'
          ? 'ශ්‍රී ලංකාවේ shoppers සඳහා වේගවත්, smart, local-first deal discovery platform එකක්.'
          : 'இலங்கை shoppers க்காக உருவாக்கப்பட்ட வேகமான, smart, local-first deal discovery platform.',
    discover: language === 'en' ? 'Discover' : language === 'si' ? 'සොයාගන්න' : 'கண்டறியுங்கள்',
    company: language === 'en' ? 'Company' : language === 'si' ? 'සමාගම' : 'நிறுவனம்',
    stay: language === 'en' ? 'Stay in the loop' : language === 'si' ? 'නිතර updates ලබාගන්න' : 'புதிய updates அறியுங்கள்',
    stayBody:
      language === 'en'
        ? 'Save offers, track urgency, and come back to the best local deals before they disappear.'
        : language === 'si'
          ? 'Offers save කරන්න, urgency track කරන්න, disappear වෙන්න කලින් හොඳම local deals වෙත නැවත එන්න.'
          : 'Offers ஐ save செய்து, urgency ஐ track செய்து, மறைவதற்கு முன் சிறந்த local deals ஐ மீண்டும் பாருங்கள்.',
    saveOffers: language === 'en' ? 'Save Offers' : language === 'si' ? 'Offers Save කරන්න' : 'Offers Save செய்யுங்கள்',
    viewNearby: language === 'en' ? 'View Nearby' : language === 'si' ? 'Nearby බලන්න' : 'Nearby பாருங்கள்',
    copyright:
      language === 'en'
        ? 'Fast local savings, without the clutter.'
        : language === 'si'
          ? 'අතිරික්ත නැති local savings.'
          : 'அதிர்ச்சியில்லா local savings.',
  };

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
                <div style={{ fontSize: '0.8rem', color: '#9fb3c8' }}>{footerCopy.tagline}</div>
              </div>
            </div>

            <p style={{ margin: 0, marginBottom: '1rem', lineHeight: 1.7, color: '#b8c7d8', fontSize: '0.92rem' }}>
              {footerCopy.description}
            </p>

            <div className="grid grid-cols-1 gap-2" style={{ fontSize: '0.88rem' }}>
              <a href="mailto:support@dealfinderapp.lk" style={{ color: '#dbe4ee', textDecoration: 'none', display: 'inline-flex', alignItems: 'center', gap: '0.55rem' }}>
                <i className="fas fa-envelope" style={{ color: '#f59e0b' }}></i>
                support@dealfinderapp.lk
              </a>
              <a href="tel:+94760846996" style={{ color: '#dbe4ee', textDecoration: 'none', display: 'inline-flex', alignItems: 'center', gap: '0.55rem' }}>
                <i className="fas fa-phone" style={{ color: '#22c55e' }}></i>
                +94 760 846 996
              </a>
            </div>
          </section>

          <section>
            <div style={{ fontWeight: 800, color: '#fff', marginBottom: '1rem', fontSize: '0.92rem', textTransform: 'uppercase' }}>
              {footerCopy.discover}
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
              {footerCopy.company}
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
            <div style={{ fontWeight: 800, color: '#fff', marginBottom: '0.7rem', fontSize: '1rem' }}>{footerCopy.stay}</div>
            <p style={{ margin: 0, marginBottom: '1rem', lineHeight: 1.7, color: '#d7e3f0', fontSize: '0.9rem' }}>
              {footerCopy.stayBody}
            </p>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.625rem' }}>
              <Link
                href="/register"
                className="btn"
                style={{
                  background: '#fff',
                  color: '#0f172a',
                  fontWeight: 800,
                  padding: '0.85rem 1rem',
                  textAlign: 'center',
                }}
              >
                {footerCopy.saveOffers}
              </Link>
              <Link
                href="/categories/all"
                className="btn"
                style={{
                  background: 'rgba(255,255,255,0.08)',
                  color: '#fff',
                  border: '1px solid rgba(255,255,255,0.14)',
                  padding: '0.85rem 1rem',
                  textAlign: 'center',
                }}
              >
                {footerCopy.viewNearby}
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
            Copyright {new Date().getFullYear()} DealFinder. {footerCopy.copyright}
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
