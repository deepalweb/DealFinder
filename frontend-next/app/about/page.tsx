import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'About DealFinder',
  description:
    'Learn how DealFinder helps shoppers discover better deals and helps merchants reach the right customers in Sri Lanka.',
  alternates: {
    canonical: '/about',
  },
};

export default function AboutPage() {
  return (
    <div className="page-shell compact">
      <div className="page-header">
        <div>
          <div className="page-eyebrow"><i className="fas fa-circle-info"></i> About</div>
          <h1 className="page-title">Built to make deal hunting feel clear and fast.</h1>
          <p className="page-subtitle">
            DealFinder brings featured offers, nearby promotions, and newest price drops into one sharper experience for shoppers and merchants.
          </p>
        </div>
      </div>

      <div className="surface-panel panel-pad">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <h2 style={{ fontSize: '1.2rem', fontWeight: 800, color: 'var(--text-primary)', margin: '0 0 0.8rem' }}>What we do</h2>
            <p style={{ color: 'var(--text-secondary)', lineHeight: 1.8, marginBottom: '1rem' }}>
              DealFinder is your one-stop destination for discovering the best discounts, promotions, and limited-time offers from the stores people already shop with.
            </p>
            <p style={{ color: 'var(--text-secondary)', lineHeight: 1.8, margin: 0 }}>
              Our goal is simple: help shoppers save faster while giving merchants a cleaner way to reach the right customers.
            </p>
          </div>

          <div className="grid gap-4">
            <div className="stat-tile">
              <div className="page-eyebrow" style={{ marginBottom: '0.8rem' }}><i className="fas fa-bag-shopping"></i> For Shoppers</div>
              <p style={{ color: 'var(--text-secondary)', lineHeight: 1.7, margin: 0 }}>
                Browse real deals, save favorites, check nearby offers, and move from discovery to decision without the usual noise.
              </p>
            </div>
            <div className="stat-tile">
              <div className="page-eyebrow" style={{ marginBottom: '0.8rem' }}><i className="fas fa-store"></i> For Merchants</div>
              <p style={{ color: 'var(--text-secondary)', lineHeight: 1.7, margin: 0 }}>
                Publish promotions, manage visibility, and attract new customers with a dashboard that keeps campaigns simple to run.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
