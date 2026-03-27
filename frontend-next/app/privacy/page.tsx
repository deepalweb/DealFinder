export default function PrivacyPage() {
  return (
    <div className="max-w-3xl mx-auto px-4 py-12">
      <h1 style={{ fontSize:'2rem', fontWeight:800, color:'var(--text-primary)', marginBottom:'1rem' }}>Privacy Policy</h1>
      <p style={{ color:'var(--text-secondary)', lineHeight:1.8, marginBottom:'1rem' }}>Last updated: {new Date().toLocaleDateString('en-US', { month:'long', day:'numeric', year:'numeric' })}</p>
      {[['Information We Collect','We collect information you provide directly to us, such as when you create an account, make a purchase, or contact us for support.'],['How We Use Your Information','We use the information we collect to provide, maintain, and improve our services, process transactions, and send you technical notices and support messages.'],['Information Sharing','We do not sell, trade, or otherwise transfer your personally identifiable information to outside parties without your consent.'],['Data Security','We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.'],['Contact Us','If you have any questions about this Privacy Policy, please contact us at privacy@dealfinder.com']].map(([title, content]) => (
        <div key={title as string} style={{ marginBottom:'1.5rem' }}>
          <h2 style={{ fontSize:'1.1rem', fontWeight:700, color:'var(--text-primary)', marginBottom:'0.5rem' }}>{title as string}</h2>
          <p style={{ color:'var(--text-secondary)', lineHeight:1.8 }}>{content as string}</p>
        </div>
      ))}
    </div>
  );
}
