'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { UserAPI } from '@/lib/api';
import PromotionCard from '@/components/ui/PromotionCard';
import SkeletonCard from '@/components/ui/SkeletonCard';

export default function FavoritesPage() {
  const { user } = useAuth();
  const router = useRouter();
  const [favorites, setFavorites] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) { router.push('/login'); return; }
    UserAPI.getFavorites(user._id).then(data => setFavorites(data.map((p: any) => ({ ...p, id: p._id || p.id })))).catch(() => {}).finally(() => setLoading(false));
  }, [user]);

  const handleFavoriteToggle = (id: string, isFav: boolean) => {
    if (!isFav) setFavorites(prev => prev.filter(p => (p._id || p.id) !== id));
  };

  return (
    <div>
      <div style={{ background: 'linear-gradient(135deg, #f43f5e 0%, #ec4899 50%, #8b5cf6 100%)', padding: '3rem 0' }}>
        <div className="max-w-7xl mx-auto px-4 text-center text-white">
          <div style={{ width: '56px', height: '56px', background: 'rgba(255,255,255,0.2)', borderRadius: '1rem', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '1.5rem', margin: '0 auto 0.75rem' }}>
            <i className="fas fa-heart"></i>
          </div>
          <h1 style={{ fontSize: '2.5rem', fontWeight: 800, letterSpacing: '-0.02em', marginBottom: '0.5rem' }}>My Favorites</h1>
          <p style={{ opacity: 0.85 }}>{loading ? '...' : `${favorites.length} saved deal${favorites.length !== 1 ? 's' : ''}`}</p>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 py-8">
        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {Array.from({ length: 4 }).map((_, i) => <SkeletonCard key={i} />)}
          </div>
        ) : favorites.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {favorites.map(p => <PromotionCard key={p._id || p.id} promotion={p} onFavoriteToggle={handleFavoriteToggle} />)}
          </div>
        ) : (
          <div className="text-center py-16">
            <div style={{ fontSize: '4rem', marginBottom: '1rem' }}>💔</div>
            <h2 style={{ fontWeight: 700, marginBottom: '0.5rem' }}>No favorites yet</h2>
            <p style={{ color: 'var(--text-secondary)', marginBottom: '1.5rem' }}>Click the ❤️ on any deal to save it here</p>
            <Link href="/categories/all" className="btn btn-primary"><i className="fas fa-search"></i> Browse All Deals</Link>
          </div>
        )}
      </div>
    </div>
  );
}
