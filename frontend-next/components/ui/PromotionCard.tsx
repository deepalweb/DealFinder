'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { UserAPI, PromotionAPI } from '@/lib/api';
import { getCurrencySymbol } from '@/lib/currency';

interface Props {
  promotion: any;
  isFavorite?: boolean;
  avgRating?: number | null;
  onFavoriteToggle?: (id: string, isFav: boolean) => void;
}

function formatMoney(amount: number, currencySymbol: string) {
  const hasDecimals = !Number.isInteger(amount);

  return `${currencySymbol}${amount.toLocaleString(undefined, {
    minimumFractionDigits: hasDecimals ? 2 : 0,
    maximumFractionDigits: 2,
  })}`;
}

export default function PromotionCard({ promotion, isFavorite: initialFav = false, avgRating = null, onFavoriteToggle }: Props) {
  const router = useRouter();
  const { user } = useAuth();
  const [isFavorite, setIsFavorite] = useState(initialFav);
  const [renderedAt] = useState(() => Date.now());

  const id = promotion._id || promotion.id;
  const isBankCardOffer = promotion.category === 'bank_cards' || promotion.bankName || (Array.isArray(promotion.cardTypes) && promotion.cardTypes.length > 0) || promotion.offerType;
  const merchantName = typeof promotion.merchant === 'object'
    ? promotion.merchant?.name
    : promotion.merchant || promotion.bankName || (isBankCardOffer ? 'Bank Offer' : '');
  const daysLeft = Math.ceil((new Date(promotion.endDate).getTime() - renderedAt) / 86400000);
  const expiryText = daysLeft < 0 ? 'Expired' : daysLeft === 0 ? 'Ends today' : `Ends in ${daysLeft}d`;
  const coords = promotion.merchant?.location?.coordinates;
  const directionsUrl = coords ? `https://www.google.com/maps/dir/?api=1&destination=${coords[1]},${coords[0]}` : null;
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

  const currencySymbol = getCurrencySymbol(
    (typeof promotion.merchant === 'object' && promotion.merchant?.currency) || 'LKR'
  );
  const originalPrice = Number.isFinite(Number(promotion.originalPrice)) ? Number(promotion.originalPrice) : null;
  const discountedPrice = Number.isFinite(Number(promotion.discountedPrice)) ? Number(promotion.discountedPrice) : null;
  const savingsAmount =
    originalPrice !== null && discountedPrice !== null && originalPrice > discountedPrice
      ? originalPrice - discountedPrice
      : Number.isFinite(Number(promotion.maximumBenefit))
        ? Number(promotion.maximumBenefit)
        : null;
  const primaryPrice = discountedPrice ?? originalPrice;
  const priceText = primaryPrice !== null ? formatMoney(primaryPrice, currencySymbol) : null;
  const saveText = savingsAmount !== null ? `Save ${formatMoney(savingsAmount, currencySymbol)}` : null;
  const imageSrc = promotion.image || 'https://placehold.co/800x1000?text=No+Image&bg=f3f4f6&textcolor=6b7280';

  const handleFavorite = async (e: React.MouseEvent) => {
    e.stopPropagation();
    if (isBankCardOffer && !promotion.merchant) return;
    if (!user) { router.push('/login'); return; }
    const next = !isFavorite;
    setIsFavorite(next);
    try {
      if (next) await UserAPI.addFavorite(user._id, id);
      else await UserAPI.removeFavorite(user._id, id);
      onFavoriteToggle?.(id, next);
    } catch {
      setIsFavorite(!next);
    }
  };

  const handleClick = () => {
    PromotionAPI.recordClick(id, { type: 'click' }).catch(() => {});
    router.push(`/deal/${id}`);
  };

  return (
    <div
      className="promotion-card fade-in cursor-pointer"
      onClick={handleClick}
      style={{
        minHeight: '420px',
        background: 'linear-gradient(180deg, #ffffff 0%, #f8fbff 100%)',
      }}
    >
      <button
        onClick={handleFavorite}
        aria-label={isFavorite ? 'Remove from favorites' : 'Add to favorites'}
        style={{
          position: 'absolute',
          top: '0.85rem',
          left: '0.85rem',
          zIndex: 20,
          width: '40px',
          height: '40px',
          borderRadius: '999px',
          background: 'rgba(255,255,255,0.92)',
          border: '1px solid rgba(255,255,255,0.7)',
          boxShadow: '0 12px 28px rgba(15,23,42,0.18)',
          cursor: 'pointer',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontSize: '1rem',
          transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
          transform: isFavorite ? 'scale(1.08)' : 'scale(1)',
          opacity: isBankCardOffer && !promotion.merchant ? 0.55 : 1,
          backdropFilter: 'blur(12px)',
        }}
        onMouseEnter={e => { e.currentTarget.style.transform = isFavorite ? 'scale(1.12)' : 'scale(1.08)'; }}
        onMouseLeave={e => { e.currentTarget.style.transform = isFavorite ? 'scale(1.08)' : 'scale(1)'; }}
      >
        <i className={`${isFavorite ? 'fas' : 'far'} fa-heart`} style={{ color: isFavorite ? 'var(--danger-color)' : '#334155', transition: 'color 0.2s' }}></i>
      </button>

      <div style={{ position: 'relative', minHeight: '420px', overflow: 'hidden', display: 'flex', alignItems: 'flex-end' }}>
        <img
          src={imageSrc}
          alt={promotion.title}
          style={{
            position: 'absolute',
            inset: 0,
            width: '100%',
            height: '100%',
            objectFit: 'cover',
            objectPosition: 'center center',
            filter: 'saturate(1.1) contrast(1.06)',
            transform: 'scale(1.06)',
            transition: 'transform 0.55s cubic-bezier(0.4, 0, 0.2, 1)',
          }}
          onMouseEnter={e => { e.currentTarget.style.transform = 'scale(1.12)'; }}
          onMouseLeave={e => { e.currentTarget.style.transform = 'scale(1.06)'; }}
        />

        <div
          style={{
            position: 'absolute',
            inset: 0,
            background: 'linear-gradient(180deg, rgba(15,23,42,0.02) 0%, rgba(15,23,42,0.02) 58%, rgba(15,23,42,0.28) 72%, rgba(15,23,42,0.84) 100%)',
          }}
        />

        <div
          style={{
            position: 'absolute',
            top: '0.85rem',
            right: '0.85rem',
            zIndex: 10,
            display: 'flex',
            gap: '0.45rem',
            flexWrap: 'wrap',
            justifyContent: 'flex-end',
            maxWidth: 'calc(100% - 4.5rem)',
          }}
        >
          {promotion.discount && (
            <span
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                padding: '0.42rem 0.75rem',
                borderRadius: '999px',
                background: 'linear-gradient(135deg, rgba(22,163,74,0.95), rgba(74,222,128,0.88))',
                color: '#fff',
                fontSize: '0.78rem',
                fontWeight: 900,
                boxShadow: '0 12px 26px rgba(22,163,74,0.3)',
                letterSpacing: '0.01em',
              }}
            >
              {promotion.discount} OFF
            </span>
          )}
          <span
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '0.35rem',
              padding: '0.42rem 0.72rem',
              borderRadius: '999px',
              background: 'rgba(255,255,255,0.18)',
              color: '#fff',
              fontSize: '0.76rem',
              fontWeight: 800,
              border: '1px solid rgba(255,255,255,0.22)',
              backdropFilter: 'blur(12px)',
              textShadow: '0 1px 3px rgba(0,0,0,0.18)',
            }}
          >
            <i className="far fa-clock"></i>
            {expiryText}
          </span>
        </div>

        <div
          style={{
            position: 'relative',
            zIndex: 5,
            width: '100%',
            padding: '1rem',
            display: 'flex',
            flexDirection: 'column',
            gap: '0.9rem',
          }}
        >
          {(merchantName || avgRating) ? (
            <div
              style={{
                display: 'inline-flex',
                alignSelf: 'flex-start',
                alignItems: 'center',
                gap: '0.45rem',
                padding: '0.45rem 0.72rem',
                borderRadius: '999px',
                background: 'rgba(12,18,28,0.22)',
                border: '1px solid rgba(255,255,255,0.14)',
                color: 'rgba(255,255,255,0.96)',
                backdropFilter: 'blur(16px)',
                boxShadow: '0 12px 24px rgba(0,0,0,0.18)',
                maxWidth: '100%',
              }}
            >
              {merchantName ? (
                <>
                  <i className={`fas ${isBankCardOffer ? 'fa-credit-card' : 'fa-store-alt'}`} style={{ fontSize: '0.72rem' }}></i>
                  <span
                    style={{
                      fontSize: '0.72rem',
                      fontWeight: 800,
                      letterSpacing: '0.04em',
                      textTransform: 'uppercase',
                      whiteSpace: 'nowrap',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                    }}
                  >
                    {merchantName}
                  </span>
                </>
              ) : null}
              {avgRating ? (
                <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.2rem', fontSize: '0.72rem', fontWeight: 800 }}>
                  <i className="fas fa-star" style={{ color: '#fbbf24' }}></i>
                  {avgRating.toFixed(1)}
                </span>
              ) : null}
            </div>
          ) : null}

          <div
            style={{
              padding: '0.95rem',
              borderRadius: '1.05rem',
              background: 'linear-gradient(180deg, rgba(12,18,28,0.14), rgba(12,18,28,0.34))',
              border: '1px solid rgba(255,255,255,0.12)',
              backdropFilter: 'blur(18px)',
              boxShadow: '0 18px 36px rgba(0,0,0,0.22)',
            }}
          >
            <h3
              style={{
                fontWeight: 900,
                fontSize: '1.22rem',
                color: '#fff',
                margin: '0 0 0.7rem',
                lineHeight: '1.2',
                display: '-webkit-box',
                WebkitLineClamp: 2,
                WebkitBoxOrient: 'vertical',
                overflow: 'hidden',
                textShadow: '0 4px 18px rgba(0,0,0,0.38)',
              }}
            >
              {promotion.title}
            </h3>

            <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', gap: '0.9rem', flexWrap: 'wrap' }}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.18rem' }}>
                {priceText ? (
                  <span style={{ fontSize: '1.45rem', fontWeight: 900, color: '#fff', lineHeight: 1, textShadow: '0 4px 18px rgba(0,0,0,0.38)' }}>
                    {priceText}
                  </span>
                ) : (
                  <span style={{ fontSize: '1rem', fontWeight: 800, color: 'rgba(255,255,255,0.94)' }}>
                    {promotion.discount || 'Deal live now'}
                  </span>
                )}

                <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', flexWrap: 'wrap' }}>
                  {saveText && (
                    <span style={{ fontSize: '0.84rem', fontWeight: 800, color: '#bbf7d0' }}>
                      {saveText}
                    </span>
                  )}
                  {originalPrice !== null && discountedPrice !== null && originalPrice > discountedPrice && (
                    <span style={{ fontSize: '0.8rem', color: 'rgba(255,255,255,0.72)', textDecoration: 'line-through' }}>
                      {formatMoney(originalPrice, currencySymbol)}
                    </span>
                  )}
                </div>
              </div>

              {distanceText && (
                <div
                  style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '0.42rem',
                    padding: '0.48rem 0.7rem',
                    borderRadius: '999px',
                    background: 'rgba(255,255,255,0.16)',
                    color: '#fff',
                    border: '1px solid rgba(255,255,255,0.14)',
                    backdropFilter: 'blur(12px)',
                    fontSize: '0.78rem',
                    fontWeight: 800,
                    textShadow: '0 1px 3px rgba(0,0,0,0.15)',
                  }}
                >
                  <i className="fas fa-location-arrow"></i>
                  {distanceText}
                </div>
              )}
            </div>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem' }}>
            {directionsUrl ? (
              <a
                href={directionsUrl}
                target="_blank"
                rel="noopener noreferrer"
                onClick={e => e.stopPropagation()}
                aria-label="Open directions"
                style={{
                  width: '44px',
                  height: '44px',
                  borderRadius: '999px',
                  display: 'inline-flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  background: 'rgba(255,255,255,0.14)',
                  color: '#fff',
                  border: '1px solid rgba(255,255,255,0.18)',
                  backdropFilter: 'blur(12px)',
                  boxShadow: '0 12px 24px rgba(0,0,0,0.18)',
                  flexShrink: 0,
                }}
              >
                <i className="fas fa-location-dot"></i>
              </a>
            ) : null}

            {promotion.url ? (
              <a
                href={promotion.url}
                target="_blank"
                rel="noopener noreferrer"
                onClick={e => { e.stopPropagation(); PromotionAPI.recordClick(id, { type: 'click' }).catch(() => {}); }}
                className="btn btn-primary"
                style={{
                  flex: 1,
                  justifyContent: 'center',
                  fontSize: '0.88rem',
                  padding: '0.85rem 1rem',
                  borderRadius: '0.95rem',
                  boxShadow: '0 16px 28px rgba(108,59,255,0.32)',
                }}
              >
                <i className="fas fa-bolt"></i>
                Get Deal
              </a>
            ) : (
              <button
                onClick={e => {
                  e.stopPropagation();
                  handleClick();
                }}
                className="btn btn-primary"
                style={{
                  flex: 1,
                  justifyContent: 'center',
                  fontSize: '0.88rem',
                  padding: '0.85rem 1rem',
                  borderRadius: '0.95rem',
                  boxShadow: '0 16px 28px rgba(108,59,255,0.32)',
                }}
              >
                <i className="fas fa-bolt"></i>
                Get Deal
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
