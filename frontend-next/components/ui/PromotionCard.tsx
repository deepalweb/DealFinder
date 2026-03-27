'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { UserAPI, PromotionAPI } from '@/lib/api';
import toast from 'react-hot-toast';

interface Props {
  promotion: any;
  onFavoriteToggle?: (id: string, isFav: boolean) => void;
}

export default function PromotionCard({ promotion, onFavoriteToggle }: Props) {
  const router = useRouter();
  const { user } = useAuth();
  const [isFavorite, setIsFavorite] = useState(false);
  const [copied, setCopied] = useState(false);
  const [avgRating, setAvgRating] = useState<number | null>(null);

  const id = promotion._id || promotion.id;
  const merchantName = typeof promotion.merchant === 'object' ? promotion.merchant?.name : promotion.merchant || '';
  const daysLeft = Math.ceil((new Date(promotion.endDate).getTime() - Date.now()) / 86400000);
  const expiryText = daysLeft < 0 ? 'Expired' : daysLeft === 0 ? 'Ends today' : `${daysLeft}d left`;

  useEffect(() => {
    if (!user) return;
    UserAPI.getFavorites(user._id).then(favs => {
      setIsFavorite(favs.some((f: any) => (f._id || f.id) === id));
    }).catch(() => {});
    PromotionAPI.getRatings(id).then(ratings => {
      if (ratings.length > 0) setAvgRating(ratings.reduce((s: number, r: any) => s + r.value, 0) / ratings.length);
    }).catch(() => {});
  }, [id, user]);

  const handleFavorite = async (e: React.MouseEvent) => {
    e.stopPropagation();
    if (!user) { router.push('/login'); return; }
    const next = !isFavorite;
    setIsFavorite(next);
    try {
      if (next) await UserAPI.addFavorite(user._id, id);
      else await UserAPI.removeFavorite(user._id, id);
      onFavoriteToggle?.(id, next);
    } catch { setIsFavorite(!next); }
  };

  const handleCopy = (e: React.MouseEvent) => {
    e.stopPropagation();
    navigator.clipboard.writeText(promotion.code);
    setCopied(true);
    toast.success('Code copied!');
    setTimeout(() => setCopied(false), 2000);
  };

  const handleClick = () => {
    PromotionAPI.recordClick(id, { type: 'click' }).catch(() => {});
    router.push(`/deal/${id}`);
  };

  return (
    <div className="promotion-card fade-in cursor-pointer" onClick={handleClick} style={{ position: 'relative' }}>
      {/* Favorite button */}
      <button onClick={handleFavorite} style={{ position: 'absolute', top: '0.75rem', left: '0.75rem', zIndex: 10, width: '32px', height: '32px', borderRadius: '50%', background: 'rgba(255,255,255,0.9)', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '0.9rem', transition: 'all 0.2s' }}>
        <i className={`${isFavorite ? 'fas text-red-500' : 'far'} fa-heart`} style={{ color: isFavorite ? '#ef4444' : '#64748b' }}></i>
      </button>

      {/* Image */}
      <div style={{ position: 'relative', overflow: 'hidden', height: '180px' }}>
        <img src={promotion.image || 'https://via.placeholder.com/400x180?text=No+Image'} alt={promotion.title}
          style={{ width: '100%', height: '100%', objectFit: 'cover', transition: 'transform 0.4s ease' }}
          onMouseEnter={e => (e.currentTarget.style.transform = 'scale(1.04)')}
          onMouseLeave={e => (e.currentTarget.style.transform = 'scale(1)')} />
        <div className="discount-badge" style={{ position: 'absolute', top: '0.75rem', right: '0.75rem' }}>
          {promotion.discount} OFF
        </div>
      </div>

      {/* Content */}
      <div style={{ padding: '1rem' }}>
        <div className="flex items-center justify-between mb-2">
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--primary-color)', textTransform: 'uppercase', letterSpacing: '0.04em' }}>
            <i className="fas fa-store-alt mr-1"></i>{merchantName}
          </span>
          <span style={{ fontSize: '0.72rem', padding: '0.2rem 0.5rem', borderRadius: '9999px', background: 'var(--light-gray)', color: 'var(--text-secondary)', border: '1px solid var(--border-color)', display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
            <i className="far fa-clock"></i> {expiryText}
          </span>
        </div>

        <h3 style={{ fontWeight: 700, fontSize: '0.95rem', color: 'var(--text-primary)', margin: '0 0 0.4rem', lineHeight: 1.4 }}>{promotion.title}</h3>

        {avgRating && (
          <div className="flex items-center gap-1 mb-2">
            {[1,2,3,4,5].map(s => (
              <i key={s} className={`fa-star ${avgRating >= s ? 'fas' : 'far'}`} style={{ fontSize: '0.7rem', color: '#fbbf24' }}></i>
            ))}
            <span style={{ fontSize: '0.72rem', color: 'var(--text-secondary)' }}>{avgRating.toFixed(1)}</span>
          </div>
        )}

        <p style={{ fontSize: '0.825rem', color: 'var(--text-secondary)', marginBottom: '0.875rem', lineHeight: 1.5, display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
          {promotion.description}
        </p>

        <div className="flex items-center justify-between">
          <code className="promo-code">{promotion.code}</code>
          <button onClick={handleCopy} className="btn btn-primary" style={{ fontSize: '0.8rem', padding: '0.35rem 0.875rem' }}>
            <i className={`fas ${copied ? 'fa-check' : 'fa-copy'}`}></i> {copied ? 'Copied!' : 'Copy'}
          </button>
        </div>
      </div>
    </div>
  );
}
