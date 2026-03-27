export default function AboutPage() {
  return (
    <div className="max-w-3xl mx-auto px-4 py-12">
      <h1 style={{ fontSize:'2rem', fontWeight:800, color:'var(--text-primary)', marginBottom:'1rem' }}>About DealFinder</h1>
      <p style={{ color:'var(--text-secondary)', lineHeight:1.8, marginBottom:'1rem' }}>DealFinder is your one-stop destination for discovering the best discounts, promotions, and deals from your favorite stores and brands.</p>
      <p style={{ color:'var(--text-secondary)', lineHeight:1.8, marginBottom:'1rem' }}>Our mission is to help shoppers save money by connecting them with merchants who offer exclusive deals and promotions.</p>
      <h2 style={{ fontSize:'1.25rem', fontWeight:700, color:'var(--text-primary)', margin:'2rem 0 0.75rem' }}>For Shoppers</h2>
      <p style={{ color:'var(--text-secondary)', lineHeight:1.8 }}>Browse thousands of deals, save your favorites, get notified about nearby promotions, and never miss a great offer again.</p>
      <h2 style={{ fontSize:'1.25rem', fontWeight:700, color:'var(--text-primary)', margin:'2rem 0 0.75rem' }}>For Merchants</h2>
      <p style={{ color:'var(--text-secondary)', lineHeight:1.8 }}>Create and manage your promotions, reach new customers, and grow your business with our merchant dashboard.</p>
    </div>
  );
}
