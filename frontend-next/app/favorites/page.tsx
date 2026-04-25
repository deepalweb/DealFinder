'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { UserAPI } from '@/lib/api';
import PromotionCard from '@/components/ui/PromotionCard';
import SkeletonCard from '@/components/ui/SkeletonCard';
import HeroSection from '@/components/ui/HeroSection';

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
      <HeroSection
        icon="fa-heart"
        title="My Favorites"
        subtitle={loading ? 'Loading...' : `${favorites.length} saved deal${favorites.length !== 1 ? 's' : ''}`}
        gradient="linear-gradient(135deg, rgba(37,99,235,0.92) 0%, rgba(236,72,153,0.82) 52%, rgba(245,158,11,0.82) 100%)"
        bgImage="https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=1600&auto=format&fit=crop&q=60"
      />

      <div className="page-shell">
        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {Array.from({ length: 4 }).map((_, i) => <SkeletonCard key={i} />)}
          </div>
        ) : favorites.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {favorites.map(p => <PromotionCard key={p._id || p.id} promotion={p} onFavoriteToggle={handleFavoriteToggle} />)}
          </div>
        ) : (
          <div className="empty-state">
            <div className="empty-icon"><i className="fas fa-heart-crack"></i></div>
            <h2 style={{ fontWeight: 800, marginBottom: '0.5rem', color: 'var(--text-primary)' }}>No favorites yet</h2>
            <p style={{ color: 'var(--text-secondary)', marginBottom: '1.5rem' }}>Save the deals you want to come back to, and they’ll appear here.</p>
            <Link href="/categories/all" className="btn btn-primary"><i className="fas fa-search"></i> Browse All Deals</Link>
          </div>
        )}
      </div>
    </div>
  );
}
