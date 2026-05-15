'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { UserAPI, PromotionAPI } from '@/lib/api';

interface Props {
  promotion: any;
  isFavorite?: boolean;
  avgRating?: number | null;
  onFavoriteToggle?: (id: string, isFav: boolean) => void;
}

export default function PromotionCard({ promotion, isFavorite: initialFav = false, avgRating = null, onFavoriteToggle }: Props) {
  const router = useRouter();
  const { user } = useAuth();
  const [isFavorite, setIsFavorite] = useState(initialFav);
  const [renderedAt] = useState(() => Date.now());

  const id = promotion._id || promotion.id;
  const merchantName = typeof promotion.merchant === 'object' ? promotion.merchant?.name : promotion.merchant || '';
  const daysLeft = Math.ceil((new Date(promotion.endDate).getTime() - renderedAt) / 86400000);
  const expiryText = daysLeft < 0 ? 'Expired' : daysLeft === 0 ? 'Ends today' : `${daysLeft}d left`;
  const coords = promotion.merchant?.location?.coordinates;
  const directionsUrl = coords ? `https://www.google.com/maps/dir/?api=1&destination=${coords[1]},${coords[0]}` : null;
  const urgencyText = daysLeft < 0 ? 'Expired' : daysLeft <= 1 ? 'Ending soon' : 'Live now';
  const urgencyBg = daysLeft <= 1 ? 'var(--danger-soft)' : 'rgba(34,197,94,0.1)';
  const urgencyColor = daysLeft <= 1 ? 'var(--danger-color)' : 'var(--success-color)';
  const merchantDistanceMeters =
    typeof promotion.merchant === 'object' && typeof promotion.merchant?.distance === 'number'
      ? promotion.merchant.distance
      : null;
  const distanceKm =
    promotion.aiMeta?.distanceKm !== null && promotion.aiMeta?.distanceKm !== undefined
      ? promotion.aiMeta.distanceKm
      : merchantDistanceMeters !== null
        ? merchantDistanceMeters / 1000
        : null;
  const distanceText = distanceKm !== null && distanceKm !== undefined 
    ? distanceKm < 1 
      ? `${Math.round(distanceKm * 1000)}m away` 
      : `${distanceKm.toFixed(1)}km away`
    : null;

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

  const handleClick = () => {
    PromotionAPI.recordClick(id, { type: 'click' }).catch(() => {});
    router.push(`/deal/${id}`);
  };

  return (
    <div className="promotion-card fade-in cursor-pointer" onClick={handleClick}>
      <button 
        onClick={handleFavorite} 
        style={{ 
          position: 'absolute', 
          top: '0.75rem', 
          left: '0.75rem', 
          zIndex: 10, 
          width: '36px', 
          height: '36px', 
          borderRadius: '50%', 
          background: 'rgba(255,255,255,0.95)', 
          border: 'none',
          boxShadow: '0 4px 12px rgba(0,0,0,0.15)', 
          cursor: 'pointer', 
          display: 'flex', 
          alignItems: 'center', 
          justifyContent: 'center', 
          fontSize: '1rem', 
          transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
          transform: isFavorite ? 'scale(1.1)' : 'scale(1)'
        }}
        onMouseEnter={e => e.currentTarget.style.transform = 'scale(1.15)'}
        onMouseLeave={e => e.currentTarget.style.transform = isFavorite ? 'scale(1.1)' : 'scale(1)'}
      >
        <i className={`${isFavorite ? 'fas' : 'far'} fa-heart`} style={{ color: isFavorite ? 'var(--danger-color)' : 'var(--text-secondary)', transition: 'color 0.2s' }}></i>
      </button>

      <div style={{ position: 'relative', overflow: 'hidden', height: '200px', flexShrink: 0, background: 'linear-gradient(135deg, #f3f4f6 0%, #e5e7eb 100%)' }}>
        <img 
          src={promotion.image || 'https://placehold.co/400x200?text=No+Image&bg=f3f4f6&textcolor=6b7280'} 
          alt={promotion.title}
          style={{ 
            width: '100%', 
            height: '100%', 
            objectFit: 'cover', 
            transition: 'transform 0.5s cubic-bezier(0.4, 0, 0.2, 1)'
          }}
          onMouseEnter={e => (e.currentTarget.style.transform = 'scale(1.08)')}
          onMouseLeave={e => (e.currentTarget.style.transform = 'scale(1)')} 
        />
        <div className="discount-badge" style={{ position: 'absolute', top: '0.75rem', right: '0.75rem' }}>
          {promotion.discount} OFF
        </div>
        <div
          style={{
            position: 'absolute',
            right: '0.75rem',
            bottom: '0.75rem',
            display: 'inline-flex',
            alignItems: 'center',
            gap: '0.35rem',
            padding: '0.4rem 0.7rem',
            borderRadius: '999px',
            background: urgencyBg,
            color: urgencyColor,
            fontSize: '0.75rem',
            fontWeight: 800,
            backdropFilter: 'blur(12px)',
            border: '1px solid rgba(255,255,255,0.4)',
            boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
          }}
        >
          <i className={`fas ${daysLeft <= 1 ? 'fa-fire' : 'fa-bolt'}`}></i>
          {urgencyText}
        </div>
      </div>

      <div style={{ padding: '1.25rem', display: 'flex', flexDirection: 'column', flexGrow: 1 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '0.65rem', flexWrap: 'wrap', gap: '0.5rem' }}>
          <span style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--primary-color)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
            <i className="fas fa-store-alt" style={{ marginRight: '0.3rem' }}></i>{merchantName}
          </span>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
            {distanceText && (
              <span style={{ 
                fontSize: '0.72rem', 
                padding: '0.25rem 0.6rem', 
                borderRadius: '999px', 
                background: 'rgba(59,130,246,0.1)', 
                color: '#2563eb', 
                border: '1px solid rgba(59,130,246,0.2)', 
                display: 'flex', 
                alignItems: 'center', 
                gap: '0.3rem',
                fontWeight: 700
              }}>
                <i className="fas fa-location-arrow"></i> {distanceText}
              </span>
            )}
            <span style={{ 
              fontSize: '0.72rem', 
              padding: '0.25rem 0.6rem', 
              borderRadius: '999px', 
              background: daysLeft <= 1 ? 'var(--warning-soft)' : 'var(--light-gray)', 
              color: daysLeft <= 1 ? 'var(--warning-color)' : 'var(--text-secondary)', 
              border: `1px solid ${daysLeft <= 1 ? 'rgba(249, 115, 22, 0.3)' : 'var(--border-color)'}`, 
              display: 'flex', 
              alignItems: 'center', 
              gap: '0.3rem',
              fontWeight: 700
            }}>
              <i className="far fa-clock"></i> {expiryText}
            </span>
          </div>
        </div>

        <h3 style={{ fontWeight: 800, fontSize: '1rem', color: 'var(--text-primary)', margin: '0 0 0.5rem', lineHeight: '1.4', minHeight: '2.8rem', display: '-webkit-box', WebkitLineClamp: 3, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
          {promotion.title}
        </h3>

        {avgRating && (
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.3rem', marginBottom: '0.6rem' }}>
            {[1,2,3,4,5].map(s => (
              <i key={s} className={`fa-star ${avgRating >= s ? 'fas' : 'far'}`} style={{ fontSize: '0.75rem', color: '#fbbf24' }}></i>
            ))}
            <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', fontWeight: 600, marginLeft: '0.15rem' }}>{avgRating.toFixed(1)}</span>
          </div>
        )}

        <p style={{ fontSize: '0.875rem', color: 'var(--text-secondary)', lineHeight: '1.6', minHeight: '4rem', overflow: 'hidden', margin: 0, display: '-webkit-box', WebkitLineClamp: 4, WebkitBoxOrient: 'vertical' }}>
          {promotion.description}
        </p>

        <div style={{ flexGrow: 1 }} />

        <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', paddingTop: '1rem', borderTop: '1px solid var(--border-color)', marginTop: '1rem' }}>
          {directionsUrl ? (
            <a href={directionsUrl} target="_blank" rel="noopener noreferrer"
              onClick={e => e.stopPropagation()}
              className="btn" 
              style={{ 
                flex: 1, 
                justifyContent: 'center', 
                fontSize: '0.8rem', 
                padding: '0.5rem 0.6rem', 
                border: '1.5px solid rgba(22,163,74,0.3)', 
                background: 'var(--success-soft)', 
                color: 'var(--success-color)',
                fontWeight: 700
              }}>
              <i className="fas fa-location-dot"></i> Nearby
            </a>
          ) : (
            <button disabled style={{ 
              flex: 1, 
              justifyContent: 'center', 
              fontSize: '0.8rem', 
              padding: '0.5rem 0.6rem', 
              border: '1.5px solid var(--border-color)', 
              background: 'var(--light-gray)', 
              color: 'var(--text-secondary)', 
              borderRadius: '0.75rem', 
              cursor: 'not-allowed', 
              display: 'flex', 
              alignItems: 'center', 
              gap: '0.3rem', 
              opacity: 0.5,
              fontWeight: 700
            }}>
              <i className="fas fa-location-dot"></i> Nearby
            </button>
          )}
          {promotion.url ? (
            <a href={promotion.url} target="_blank" rel="noopener noreferrer"
              onClick={e => { e.stopPropagation(); PromotionAPI.recordClick(id, { type: 'click' }).catch(() => {}); }}
              className="btn btn-primary" 
              style={{ 
                flex: 1, 
                justifyContent: 'center', 
                fontSize: '0.8rem', 
                padding: '0.5rem 0.6rem'
              }}>
              <i className="fas fa-bolt"></i> Get Deal
            </a>
          ) : (
            <button onClick={handleClick}
              className="btn btn-primary" 
              style={{ 
                flex: 1, 
                justifyContent: 'center', 
                fontSize: '0.8rem', 
                padding: '0.5rem 0.6rem'
              }}>
              <i className="fas fa-bolt"></i> Get Deal
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
