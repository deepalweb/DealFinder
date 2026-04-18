'use client';

import { useEffect, useState } from 'react';
import { PromotionAPI } from '@/lib/api';

export default function DebugPage() {
  const [homepage, setHomepage] = useState<any>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        console.log('🔍 Fetching homepage via PromotionAPI...');
        const data = await PromotionAPI.getHomepage();
        console.log('✅ API Response:', data);
        
        setHomepage(data);
      } catch (err: any) {
        console.error('❌ Error:', err);
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  if (loading) return <div style={{ padding: '2rem' }}>Loading...</div>;
  if (error) return <div style={{ padding: '2rem', color: 'red' }}>Error: {error}</div>;

  return (
    <div style={{ padding: '2rem', fontFamily: 'monospace' }}>
      <h1>🐛 Debug: Homepage API Response</h1>
      
      <div style={{ marginBottom: '2rem', padding: '1rem', background: '#f5f5f5', borderRadius: '8px' }}>
        <h2>Featured Deals: {homepage?.featured?.length || 0}</h2>
        {homepage?.featured?.map((d: any) => (
          <div key={d._id} style={{ padding: '1rem', border: '1px solid #ccc', marginBottom: '1rem' }}>
            <strong>{d.title}</strong>
            <pre>{JSON.stringify({ title: d.title, featured: d.featured, merchant: d.merchant?.name }, null, 2)}</pre>
          </div>
        ))}
      </div>

      <div style={{ marginBottom: '2rem', padding: '1rem', background: '#f5f5f5', borderRadius: '8px' }}>
        <h2>Latest Deals: {homepage?.latest?.length || 0}</h2>
        <pre>{JSON.stringify(homepage?.latest?.slice(0, 2), null, 2)}</pre>
      </div>
    </div>
  );
}
