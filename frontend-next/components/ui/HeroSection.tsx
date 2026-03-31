interface HeroProps {
  title: string;
  titleAccent?: string;
  subtitle?: string;
  icon?: string;
  gradient?: string;
  bgImage?: string;
  children?: React.ReactNode;
  minHeight?: string;
}

export default function HeroSection({
  title,
  titleAccent,
  subtitle,
  icon,
  gradient = 'linear-gradient(135deg, rgba(99,102,241,0.92) 0%, rgba(139,92,246,0.88) 50%, rgba(244,63,94,0.85) 100%)',
  bgImage = 'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=1600&auto=format&fit=crop&q=60',
  children,
  minHeight = '220px',
}: HeroProps) {
  return (
    <div style={{ position: 'relative', padding: '4rem 0 3rem', overflow: 'hidden', minHeight, display: 'flex', alignItems: 'center', background: '#1e1b4b' }}>
      {/* Background image */}
      <div style={{ position: 'absolute', inset: 0, backgroundImage: `url(${bgImage})`, backgroundSize: 'cover', backgroundPosition: 'center', opacity: 0.12 }} />
      {/* Gradient overlay */}
      <div style={{ position: 'absolute', inset: 0, background: gradient }} />
      {/* Decorative blobs */}
      <div style={{ position: 'absolute', top: '-60px', right: '-60px', width: '260px', height: '260px', borderRadius: '50%', background: 'rgba(255,255,255,0.05)', pointerEvents: 'none' }} />
      <div style={{ position: 'absolute', bottom: '-40px', left: '-40px', width: '180px', height: '180px', borderRadius: '50%', background: 'rgba(255,255,255,0.04)', pointerEvents: 'none' }} />

      <div className="max-w-7xl mx-auto px-4 text-center text-white w-full" style={{ position: 'relative', zIndex: 1 }}>
        {icon && (
          <div style={{ width: '56px', height: '56px', background: 'rgba(255,255,255,0.15)', borderRadius: '1rem', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '1.5rem', margin: '0 auto 1rem', backdropFilter: 'blur(8px)', border: '1px solid rgba(255,255,255,0.2)' }}>
            <i className={`fas ${icon}`}></i>
          </div>
        )}
        <h1 style={{ fontSize: 'clamp(1.75rem, 5vw, 3rem)', fontWeight: 900, letterSpacing: '-0.03em', lineHeight: 1.1, marginBottom: '0.75rem', textShadow: '0 2px 20px rgba(0,0,0,0.3)' }}>
          {title}
          {titleAccent && (
            <><br /><span style={{ background: 'linear-gradient(135deg, #fbbf24, #f97316)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>{titleAccent}</span></>
          )}
        </h1>
        {subtitle && <p style={{ opacity: 0.9, fontSize: '1rem', maxWidth: '480px', margin: '0 auto 1.5rem', lineHeight: 1.6 }}>{subtitle}</p>}
        {children}
      </div>
    </div>
  );
}
