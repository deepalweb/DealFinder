'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { PromotionAPI, UserAPI } from '@/lib/api';
import { getCurrencySymbol } from '@/lib/currency';
import { useAuth } from '@/contexts/AuthContext';
import PromotionCard from '@/components/ui/PromotionCard';
import toast from 'react-hot-toast';

export default function DealPageClient({ dealId }: { dealId: string }) {
  const router = useRouter();
  const { user } = useAuth();

  const [deal, setDeal] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [copied, setCopied] = useState(false);
  const [isFavorite, setIsFavorite] = useState(false);
  const [comments, setComments] = useState<any[]>([]);
  const [ratings, setRatings] = useState<any[]>([]);
  const [commentText, setCommentText] = useState('');
  const [userRating, setUserRating] = useState(0);
  const [hoverRating, setHoverRating] = useState(0);
  const [relatedDeals, setRelatedDeals] = useState<any[]>([]);
  const [merchantDeals, setMerchantDeals] = useState<any[]>([]);
  const [analytics, setAnalytics] = useState<any>(null);
  const [timeLeft, setTimeLeft] = useState({ days: 0, hours: 0, minutes: 0, seconds: 0 });
  const [distance, setDistance] = useState<number | null>(null);

  useEffect(() => {
    setLoading(true);
    Promise.all([
      PromotionAPI.getById(dealId),
      PromotionAPI.getComments(dealId),
      PromotionAPI.getRatings(dealId),
      PromotionAPI.getAnalyticsByPromotion(dealId).catch(() => null),
    ]).then(([d, c, r, a]) => {
      setDeal(d);
      setComments(c);
      setRatings(r);
      setAnalytics(a);
      if (user) {
        const found = r.find((x: any) => x.user?._id === user._id);
        if (found) setUserRating(found.value);
        UserAPI.getFavorites(user._id).then(favs => {
          setIsFavorite(favs.some((f: any) => (f._id || f.id) === dealId));
        }).catch(() => {});
      }
      const merchantId = typeof d.merchant === 'object' ? d.merchant?._id : d.merchant;
      if (merchantId) {
        PromotionAPI.getByMerchant(merchantId).then((deals: any[]) => {
          setMerchantDeals(deals.filter((p: any) => (p._id || p.id) !== dealId).slice(0, 4));
        }).catch(() => {});
      }
      PromotionAPI.getAll().then((all: any[]) => {
        setRelatedDeals(all.filter((p: any) => p.category === d.category && (p._id || p.id) !== dealId).slice(0, 4));
      }).catch(() => {});
      
      // Calculate distance if merchant has location
      if (d.merchant?.location?.coordinates && navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
          (pos) => {
            const [lon, lat] = d.merchant.location.coordinates;
            const R = 6371; // Earth radius in km
            const dLat = (lat - pos.coords.latitude) * Math.PI / 180;
            const dLon = (lon - pos.coords.longitude) * Math.PI / 180;
            const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                      Math.cos(pos.coords.latitude * Math.PI / 180) * Math.cos(lat * Math.PI / 180) *
                      Math.sin(dLon/2) * Math.sin(dLon/2);
            const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
            setDistance(R * c);
          },
          () => {}
        );
      }
    }).catch(() => toast.error('Deal not found.')).finally(() => setLoading(false));
  }, [dealId, user]);

  // Countdown timer effect
  useEffect(() => {
    if (!deal) return;
    const updateTimer = () => {
      const now = Date.now();
      const end = new Date(deal.endDate).getTime();
      const diff = end - now;
      if (diff <= 0) {
        setTimeLeft({ days: 0, hours: 0, minutes: 0, seconds: 0 });
        return;
      }
      setTimeLeft({
        days: Math.floor(diff / (1000 * 60 * 60 * 24)),
        hours: Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60)),
        minutes: Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60)),
        seconds: Math.floor((diff % (1000 * 60)) / 1000),
      });
    };
    updateTimer();
    const timer = setInterval(updateTimer, 1000);
    return () => clearInterval(timer);
  }, [deal]);

  const handleCopy = () => {
    navigator.clipboard.writeText(deal.code);
    setCopied(true);
    toast.success('Promo code copied!');
    setTimeout(() => setCopied(false), 2000);
  };

  const handleShare = () => {
    if (navigator.share) navigator.share({ title: deal.title, url: window.location.href });
    else { navigator.clipboard.writeText(window.location.href); toast.success('Link copied!'); }
  };

  const handleFavorite = async () => {
    if (!user) { router.push('/login'); return; }
    const next = !isFavorite;
    setIsFavorite(next);
    try {
      if (next) await UserAPI.addFavorite(user._id, dealId);
      else await UserAPI.removeFavorite(user._id, dealId);
      toast.success(next ? 'Added to favorites!' : 'Removed from favorites');
    } catch { setIsFavorite(!next); }
  };

  const handleComment = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) { router.push('/login'); return; }
    if (!commentText.trim()) return;
    try {
      const c = await PromotionAPI.addComment(dealId, { userId: user._id, text: commentText });
      setComments(prev => [...prev, { ...c, user: { _id: user._id, name: user.name } }]);
      setCommentText('');
      toast.success('Comment posted!');
    } catch { toast.error('Failed to post comment.'); }
  };

  const handleRate = async (value: number) => {
    if (!user) { router.push('/login'); return; }
    try {
      const updated = await PromotionAPI.addRating(dealId, { userId: user._id, value });
      setRatings(updated);
      setUserRating(value);
      toast.success('Rating saved!');
    } catch { toast.error('Failed to save rating.'); }
  };

  const avgRating = ratings.length > 0 ? ratings.reduce((s: number, r: any) => s + r.value, 0) / ratings.length : null;
  const merchantName = deal ? (typeof deal.merchant === 'object' ? deal.merchant?.name : deal.merchant) : '';
  const merchantId = deal ? (typeof deal.merchant === 'object' ? deal.merchant?._id : deal.merchant) : null;
  const currencySymbol = deal ? getCurrencySymbol(deal.merchant?.currency) : '$';
  const daysLeft = deal ? Math.ceil((new Date(deal.endDate).getTime() - Date.now()) / 86400000) : 0;
  const isExpired = daysLeft < 0;

  if (loading) return (
    <div className="max-w-5xl mx-auto px-4 py-8">
      <div className="skeleton mb-4" style={{ height: '16px', width: '80px' }}></div>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="md:col-span-2 skeleton-card" style={{ height: '500px' }}></div>
        <div className="skeleton-card" style={{ height: '300px' }}></div>
      </div>
    </div>
  );

  if (!deal) return (
    <div className="text-center py-16">
      <div style={{ fontSize: '3rem', marginBottom: '1rem' }}>😕</div>
      <h2 style={{ fontWeight: 700, marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Deal not found</h2>
      <p style={{ color: 'var(--text-secondary)', marginBottom: '1.5rem' }}>This deal may have expired or been removed.</p>
      <button className="btn btn-primary" onClick={() => router.push('/categories/all')}>Browse All Deals</button>
    </div>
  );

  return (
    <div className="max-w-5xl mx-auto px-4 py-8">
      <button onClick={() => router.back()} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', background: 'none', border: 'none', color: 'var(--primary-color)', cursor: 'pointer', fontWeight: 500, marginBottom: '1.5rem', fontSize: '0.9rem' }}>
        <i className="fas fa-arrow-left"></i> Back
      </button>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="md:col-span-2">
          <div className="promotion-card fade-in overflow-hidden">
            {deal.image ? (
              <div style={{ position: 'relative', overflow: 'hidden' }}>
                {/* Main image */}
                <div style={{ position: 'relative', height: '300px', overflow: 'hidden' }}>
                  <img src={deal.image} alt={deal.title} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                  <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(to top, rgba(0,0,0,0.6) 0%, transparent 50%)' }}></div>
                  <div style={{ position: 'absolute', top: '1rem', left: '1rem', display: 'flex', gap: '0.5rem' }}>
                    {deal.featured && <span style={{ background: 'linear-gradient(135deg,#fbbf24,#f59e0b)', color: '#fff', fontSize: '0.75rem', fontWeight: 700, padding: '0.3rem 0.75rem', borderRadius: '9999px' }}>⭐ Featured</span>}
                    {isExpired && <span style={{ background: 'rgba(239,68,68,0.9)', color: '#fff', fontSize: '0.75rem', fontWeight: 700, padding: '0.3rem 0.75rem', borderRadius: '9999px' }}>Expired</span>}
                  </div>
                  <div className="discount-badge" style={{ position: 'absolute', top: '1rem', right: '1rem', fontSize: '1rem' }}>{deal.discount} OFF</div>
                  <div style={{ position: 'absolute', bottom: '1rem', left: '1.25rem', right: '1.25rem' }}>
                    <h1 style={{ color: '#fff', fontSize: '1.5rem', fontWeight: 800, margin: 0, letterSpacing: '-0.02em', textShadow: '0 2px 8px rgba(0,0,0,0.5)' }}>{deal.title}</h1>
                  </div>
                </div>
                {/* Thumbnail strip for multiple images */}
                {deal.images?.length > 1 && (
                  <div style={{ display: 'flex', gap: '0.5rem', padding: '0.75rem', overflowX: 'auto', background: 'var(--light-gray)', scrollbarWidth: 'none' }}>
                    {deal.images.map((img: string, i: number) => (
                      <img key={i} src={img} alt={`Image ${i+1}`}
                        onClick={() => { const el = document.querySelector('.deal-main-img') as HTMLImageElement; if (el) el.src = img; }}
                        style={{ width: '64px', height: '64px', objectFit: 'cover', borderRadius: '0.5rem', cursor: 'pointer', flexShrink: 0, border: i === 0 ? '2px solid var(--primary-color)' : '2px solid transparent', transition: 'border-color 0.2s' }}
                        onMouseEnter={e => (e.currentTarget.style.borderColor = 'var(--primary-color)')}
                        onMouseLeave={e => (e.currentTarget.style.borderColor = i === 0 ? 'var(--primary-color)' : 'transparent')} />
                    ))}
                  </div>
                )}
              </div>
            ) : (
              <div style={{ padding: '1.5rem 1.5rem 0' }}>
                <h1 style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--text-primary)', letterSpacing: '-0.02em', margin: 0 }}>{deal.title}</h1>
              </div>
            )}

            <div style={{ padding: '1.5rem' }}>
              <div className="flex items-center justify-between flex-wrap gap-2 mb-4">
                <div className="flex items-center gap-2 flex-wrap">
                  {merchantId ? (
                    <Link href={`/merchants/${merchantId}`} style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--primary-color)', textTransform: 'uppercase', letterSpacing: '0.04em', textDecoration: 'none', display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                      <i className="fas fa-store-alt"></i>{merchantName}
                    </Link>
                  ) : (
                    <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--primary-color)', textTransform: 'uppercase', letterSpacing: '0.04em' }}>
                      <i className="fas fa-store-alt mr-1"></i>{merchantName}
                    </span>
                  )}
                  {deal.category && (
                    <Link href={`/categories/${deal.category}`} style={{ fontSize: '0.75rem', padding: '0.2rem 0.6rem', borderRadius: '9999px', background: 'var(--light-gray)', color: 'var(--text-secondary)', border: '1px solid var(--border-color)', textDecoration: 'none', textTransform: 'capitalize' }}>
                      {deal.category}
                    </Link>
                  )}
                  {distance && (
                    <span style={{ fontSize: '0.75rem', padding: '0.2rem 0.6rem', borderRadius: '9999px', background: 'rgba(16,185,129,0.08)', color: '#059669', border: '1px solid rgba(16,185,129,0.2)', display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                      <i className="fas fa-map-marker-alt"></i> {distance.toFixed(1)} km away
                    </span>
                  )}
                </div>
                <span style={{ fontSize: '0.75rem', padding: '0.2rem 0.6rem', borderRadius: '9999px', background: isExpired ? 'rgba(239,68,68,0.08)' : 'rgba(16,185,129,0.08)', color: isExpired ? '#ef4444' : '#059669', border: `1px solid ${isExpired ? 'rgba(239,68,68,0.2)' : 'rgba(16,185,129,0.2)'}`, display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                  <i className="far fa-clock"></i>
                  {isExpired ? 'Expired' : daysLeft === 0 ? 'Ends today!' : `${daysLeft} days left`}
                </span>
              </div>

              <p style={{ color: 'var(--text-secondary)', lineHeight: 1.8, marginBottom: '1.25rem', fontSize: '0.95rem' }}>{deal.description}</p>

              {/* Trust Signals */}
              <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap', marginBottom: '1.25rem', padding: '1rem', borderRadius: '0.875rem', background: 'rgba(99,102,241,0.04)', border: '1px solid rgba(99,102,241,0.15)' }}>
                {analytics?.clicks > 0 && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                    <i className="fas fa-fire" style={{ color: '#f59e0b', fontSize: '0.9rem' }}></i>
                    <span style={{ fontSize: '0.8rem', fontWeight: 600, color: 'var(--text-primary)' }}>
                      {analytics.clicks} {analytics.clicks === 1 ? 'person' : 'people'} claimed this
                    </span>
                  </div>
                )}
                {ratings.length > 0 && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                    <i className="fas fa-star" style={{ color: '#fbbf24', fontSize: '0.9rem' }}></i>
                    <span style={{ fontSize: '0.8rem', fontWeight: 600, color: 'var(--text-primary)' }}>
                      {avgRating?.toFixed(1)} rating from {ratings.length} {ratings.length === 1 ? 'user' : 'users'}
                    </span>
                  </div>
                )}
                {!isExpired && daysLeft <= 3 && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                    <i className="fas fa-bolt" style={{ color: '#ef4444', fontSize: '0.9rem' }}></i>
                    <span style={{ fontSize: '0.8rem', fontWeight: 700, color: '#ef4444' }}>
                      Ending soon!
                    </span>
                  </div>
                )}
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                  <i className="fas fa-shield-check" style={{ color: '#059669', fontSize: '0.9rem' }}></i>
                  <span style={{ fontSize: '0.8rem', fontWeight: 600, color: '#059669' }}>Verified Deal</span>
                </div>
              </div>

              {/* Live Countdown Timer */}
              {!isExpired && daysLeft <= 7 && (
                <div style={{ marginBottom: '1.25rem', padding: '1rem', borderRadius: '0.875rem', background: 'linear-gradient(135deg, rgba(239,68,68,0.08), rgba(245,158,11,0.08))', border: '1.5px solid rgba(239,68,68,0.2)' }}>
                  <div className="flex items-center justify-between flex-wrap gap-3">
                    <div>
                      <p style={{ fontSize: '0.75rem', fontWeight: 700, color: '#ef4444', marginBottom: '0.25rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                        <i className="fas fa-clock mr-1"></i> Deal Ends In
                      </p>
                      <div className="flex items-center gap-2">
                        {timeLeft.days > 0 && (
                          <div style={{ textAlign: 'center' }}>
                            <div style={{ fontSize: '1.5rem', fontWeight: 800, color: '#ef4444', lineHeight: 1 }}>{timeLeft.days}</div>
                            <div style={{ fontSize: '0.65rem', color: 'var(--text-secondary)', textTransform: 'uppercase' }}>Days</div>
                          </div>
                        )}
                        <div style={{ textAlign: 'center' }}>
                          <div style={{ fontSize: '1.5rem', fontWeight: 800, color: '#ef4444', lineHeight: 1 }}>{String(timeLeft.hours).padStart(2, '0')}</div>
                          <div style={{ fontSize: '0.65rem', color: 'var(--text-secondary)', textTransform: 'uppercase' }}>Hours</div>
                        </div>
                        <span style={{ fontSize: '1.5rem', fontWeight: 800, color: '#ef4444' }}>:</span>
                        <div style={{ textAlign: 'center' }}>
                          <div style={{ fontSize: '1.5rem', fontWeight: 800, color: '#ef4444', lineHeight: 1 }}>{String(timeLeft.minutes).padStart(2, '0')}</div>
                          <div style={{ fontSize: '0.65rem', color: 'var(--text-secondary)', textTransform: 'uppercase' }}>Mins</div>
                        </div>
                        <span style={{ fontSize: '1.5rem', fontWeight: 800, color: '#ef4444' }}>:</span>
                        <div style={{ textAlign: 'center' }}>
                          <div style={{ fontSize: '1.5rem', fontWeight: 800, color: '#ef4444', lineHeight: 1 }}>{String(timeLeft.seconds).padStart(2, '0')}</div>
                          <div style={{ fontSize: '0.65rem', color: 'var(--text-secondary)', textTransform: 'uppercase' }}>Secs</div>
                        </div>
                      </div>
                    </div>
                    <div style={{ fontSize: '2rem' }}>⏰</div>
                  </div>
                </div>
              )}

              <div className="flex items-center gap-4 mb-5 flex-wrap" style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
                <span><i className="far fa-calendar-alt mr-1" style={{ color: 'var(--primary-color)' }}></i>
                  {new Date(deal.startDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })} → {new Date(deal.endDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                </span>
                {deal.originalPrice && deal.discountedPrice && (
                  <span style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <span style={{ textDecoration: 'line-through', color: 'var(--text-secondary)' }}>{currencySymbol}{deal.originalPrice}</span>
                    <span style={{ fontWeight: 700, color: '#059669', fontSize: '1rem' }}>{currencySymbol}{deal.discountedPrice}</span>
                    <span style={{ background: 'rgba(16,185,129,0.1)', color: '#059669', padding: '0.1rem 0.4rem', borderRadius: '0.375rem', fontSize: '0.75rem', fontWeight: 700 }}>
                      Save {currencySymbol}{(deal.originalPrice - deal.discountedPrice).toFixed(2)}
                    </span>
                  </span>
                )}
              </div>

              <div style={{ background: 'linear-gradient(135deg, rgba(99,102,241,0.06), rgba(99,102,241,0.1))', borderRadius: '1rem', padding: '1.25rem', marginBottom: '1.25rem', border: '1.5px dashed var(--primary-color)' }}>
                <p style={{ fontSize: '0.72rem', fontWeight: 700, color: 'var(--primary-color)', marginBottom: '0.625rem', textTransform: 'uppercase', letterSpacing: '0.08em' }}>
                  <i className="fas fa-ticket-alt mr-1"></i> Promo Code
                </p>
                <div className="flex items-center gap-3 flex-wrap">
                  <code style={{ fontSize: '1.4rem', fontWeight: 800, letterSpacing: '0.12em', color: 'var(--primary-color)', fontFamily: 'monospace' }}>{deal.code}</code>
                  <button onClick={handleCopy} className="btn btn-primary" style={{ fontSize: '0.875rem', padding: '0.5rem 1.25rem' }}>
                    <i className={`fas ${copied ? 'fa-check' : 'fa-copy'}`}></i> {copied ? 'Copied!' : 'Copy Code'}
                  </button>
                </div>
              </div>

              <div className="flex gap-3 flex-wrap mb-6">
                {deal.url && (
                  <a href={deal.url} target="_blank" rel="noopener noreferrer"
                    onClick={() => PromotionAPI.recordClick(dealId, { type: 'click' }).catch(() => {})}
                    className="btn btn-primary" style={{ flex: 1, justifyContent: 'center', minWidth: '160px', padding: '0.875rem', fontSize: '1rem', fontWeight: 700 }}>
                    <i className="fas fa-bolt"></i> Claim Deal Now
                  </a>
                )}
                <button onClick={handleFavorite} className="btn" style={{ border: `1.5px solid ${isFavorite ? 'rgba(239,68,68,0.3)' : 'var(--border-color)'}`, background: isFavorite ? 'rgba(239,68,68,0.06)' : 'var(--card-bg)', color: isFavorite ? '#ef4444' : 'var(--text-secondary)', padding: '0.75rem 1.25rem' }}>
                  <i className={`${isFavorite ? 'fas' : 'far'} fa-heart`}></i> {isFavorite ? 'Saved' : 'Save'}
                </button>
                <button onClick={handleShare} className="btn" style={{ border: '1.5px solid var(--border-color)', background: 'var(--card-bg)', color: 'var(--text-secondary)', padding: '0.75rem 1.25rem' }}>
                  <i className="fas fa-share-alt"></i> Share
                </button>
              </div>

              <div style={{ borderTop: '1px solid var(--border-color)', paddingTop: '1.5rem', marginBottom: '1.5rem' }}>
                <div className="flex items-center justify-between mb-3 flex-wrap gap-2">
                  <h3 style={{ fontWeight: 700, color: 'var(--text-primary)', margin: 0, fontSize: '1rem' }}>
                    <i className="fas fa-star mr-2" style={{ color: '#fbbf24' }}></i>Rate this deal
                  </h3>
                  {avgRating && (
                    <div className="flex items-center gap-1">
                      {[1,2,3,4,5].map(s => <i key={s} className={`fa-star ${avgRating >= s ? 'fas' : 'far'}`} style={{ fontSize: '0.875rem', color: '#fbbf24' }}></i>)}
                      <span style={{ fontSize: '0.875rem', color: 'var(--text-secondary)', marginLeft: '0.25rem' }}>{avgRating.toFixed(1)} ({ratings.length} ratings)</span>
                    </div>
                  )}
                </div>
                <div className="flex items-center gap-1">
                  {[1,2,3,4,5].map(s => (
                    <button key={s} type="button" onClick={() => handleRate(s)} onMouseEnter={() => setHoverRating(s)} onMouseLeave={() => setHoverRating(0)}
                      style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: '1.75rem', color: (hoverRating || userRating) >= s ? '#fbbf24' : '#d1d5db', transition: 'all 0.15s', transform: hoverRating === s ? 'scale(1.2)' : 'scale(1)' }}>
                      <i className="fas fa-star"></i>
                    </button>
                  ))}
                  {userRating > 0 && <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', marginLeft: '0.5rem' }}>Your rating: {userRating}/5</span>}
                </div>
                {!user && <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', marginTop: '0.5rem' }}><Link href="/login" style={{ color: 'var(--primary-color)', fontWeight: 600 }}>Login</Link> to rate this deal</p>}
              </div>

              <div style={{ borderTop: '1px solid var(--border-color)', paddingTop: '1.5rem' }}>
                <h3 style={{ fontWeight: 700, color: 'var(--text-primary)', marginBottom: '1rem', fontSize: '1rem' }}>
                  <i className="fas fa-comments mr-2" style={{ color: 'var(--primary-color)' }}></i>Comments ({comments.length})
                </h3>
                <div style={{ maxHeight: '280px', overflowY: 'auto', marginBottom: '1rem', display: 'flex', flexDirection: 'column', gap: '0.625rem' }}>
                  {comments.length === 0 ? (
                    <p style={{ color: 'var(--text-secondary)', fontSize: '0.875rem', textAlign: 'center', padding: '1.5rem 0' }}>No comments yet. Be the first to comment!</p>
                  ) : comments.map((c, i) => (
                    <div key={i} style={{ padding: '0.875rem', borderRadius: '0.75rem', background: 'var(--light-gray)', border: '1px solid var(--border-color)' }}>
                      <div className="flex items-center gap-2 mb-1">
                        <div style={{ width: '28px', height: '28px', borderRadius: '50%', background: 'linear-gradient(135deg,#6366f1,#f43f5e)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontSize: '0.7rem', fontWeight: 700, flexShrink: 0 }}>
                          {(c.user?.name || 'U').charAt(0).toUpperCase()}
                        </div>
                        <span style={{ fontWeight: 600, fontSize: '0.8rem', color: 'var(--primary-color)' }}>{c.user?.name || 'User'}</span>
                        {c.createdAt && <span style={{ fontSize: '0.72rem', color: 'var(--text-secondary)', marginLeft: 'auto' }}>{new Date(c.createdAt).toLocaleDateString()}</span>}
                      </div>
                      <p style={{ margin: 0, fontSize: '0.875rem', color: 'var(--text-primary)', lineHeight: 1.5 }}>{c.text}</p>
                    </div>
                  ))}
                </div>
                <form onSubmit={handleComment} className="flex gap-2">
                  <input type="text" value={commentText} onChange={e => setCommentText(e.target.value)}
                    placeholder={user ? 'Write a comment...' : 'Login to comment'}
                    disabled={!user}
                    style={{ flex: 1, padding: '0.75rem 1rem', borderRadius: '0.75rem', border: '1.5px solid var(--border-color)', background: 'var(--card-bg)', color: 'var(--text-primary)', fontSize: '0.875rem', outline: 'none' }} />
                  <button type="submit" className="btn btn-primary" disabled={!user} style={{ padding: '0.75rem 1.25rem' }}>Post</button>
                </form>
              </div>
            </div>
          </div>
        </div>

        <div className="flex flex-col gap-5">
          <div className="promotion-card" style={{ padding: '1.25rem' }}>
            <h3 style={{ fontWeight: 700, fontSize: '0.9rem', color: 'var(--text-primary)', marginBottom: '1rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Deal Info</h3>
            <div className="flex flex-col gap-3">
              {[
                { icon: 'fa-tag', label: 'Discount', value: `${deal.discount} OFF` },
                { icon: 'fa-ticket-alt', label: 'Code', value: deal.code },
                { icon: 'fa-th-large', label: 'Category', value: deal.category?.charAt(0).toUpperCase() + deal.category?.slice(1) },
                { icon: 'fa-calendar-alt', label: 'Expires', value: new Date(deal.endDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) },
              ].map(item => (
                <div key={item.label} className="flex items-center justify-between">
                  <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                    <i className={`fas ${item.icon}`} style={{ color: 'var(--primary-color)', width: '14px' }}></i> {item.label}
                  </span>
                  <span style={{ fontSize: '0.8rem', fontWeight: 600, color: 'var(--text-primary)' }}>{item.value}</span>
                </div>
              ))}
            </div>
            {deal.url && (
              <a href={deal.url} target="_blank" rel="noopener noreferrer"
                onClick={() => PromotionAPI.recordClick(dealId, { type: 'click' }).catch(() => {})}
                className="btn btn-primary" style={{ width: '100%', justifyContent: 'center', marginTop: '1rem', padding: '0.875rem', fontWeight: 700 }}>
                <i className="fas fa-bolt"></i> Claim Deal Now
              </a>
            )}
          </div>

          {merchantId && (
            <div className="promotion-card" style={{ padding: '1.25rem' }}>
              <h3 style={{ fontWeight: 700, fontSize: '0.9rem', color: 'var(--text-primary)', marginBottom: '1rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Store</h3>
              <div className="flex items-center gap-3 mb-3">
                <div style={{ width: '44px', height: '44px', borderRadius: '50%', background: 'linear-gradient(135deg,#6366f1,#f43f5e)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontWeight: 700, fontSize: '1rem', flexShrink: 0 }}>
                  {merchantName.charAt(0).toUpperCase()}
                </div>
                <div>
                  <p style={{ fontWeight: 700, fontSize: '0.9rem', color: 'var(--text-primary)', margin: 0 }}>{merchantName}</p>
                  <p style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', margin: 0 }}>{merchantDeals.length + 1} deals available</p>
                </div>
              </div>
              <Link href={`/merchants/${merchantId}`} className="btn" style={{ width: '100%', justifyContent: 'center', border: '1.5px solid var(--border-color)', background: 'var(--card-bg)', color: 'var(--text-primary)', fontSize: '0.85rem' }}>
                <i className="fas fa-store"></i> Visit Store
              </Link>
              {deal.merchant?.location?.coordinates && (
                <a href={`https://www.google.com/maps/dir/?api=1&destination=${deal.merchant.location.coordinates[1]},${deal.merchant.location.coordinates[0]}`}
                  target="_blank" rel="noopener noreferrer"
                  className="btn" style={{ width: '100%', justifyContent: 'center', marginTop: '0.5rem', border: '1.5px solid rgba(16,185,129,0.3)', background: 'rgba(16,185,129,0.06)', color: '#059669', fontSize: '0.85rem' }}>
                  <i className="fas fa-directions"></i> Get Directions
                </a>
              )}
            </div>
          )}

          {merchantDeals.length > 0 && (
            <div className="promotion-card" style={{ padding: '1.25rem' }}>
              <h3 style={{ fontWeight: 700, fontSize: '0.9rem', color: 'var(--text-primary)', marginBottom: '1rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>More from {merchantName}</h3>
              <div className="flex flex-col gap-2">
                {merchantDeals.map((p: any) => (
                  <Link key={p._id || p.id} href={`/deal/${p._id || p.id}`}
                    style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', padding: '0.625rem', borderRadius: '0.625rem', border: '1px solid var(--border-color)', textDecoration: 'none', transition: 'all 0.15s', background: 'var(--card-bg)' }}
                    onMouseEnter={e => (e.currentTarget.style.borderColor = 'var(--primary-color)')}
                    onMouseLeave={e => (e.currentTarget.style.borderColor = 'var(--border-color)')}>
                    {p.image && <img src={p.image} alt={p.title} style={{ width: '40px', height: '40px', borderRadius: '0.375rem', objectFit: 'cover', flexShrink: 0 }} />}
                    <div style={{ minWidth: 0 }}>
                      <p style={{ fontWeight: 600, fontSize: '0.8rem', color: 'var(--text-primary)', margin: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{p.title}</p>
                      <p style={{ fontSize: '0.72rem', color: 'var(--primary-color)', margin: 0, fontWeight: 700 }}>{p.discount} OFF</p>
                    </div>
                  </Link>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>

      {relatedDeals.length > 0 && (
        <div style={{ marginTop: '3rem' }}>
          <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--text-primary)', marginBottom: '1.25rem', letterSpacing: '-0.02em', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <i className="fas fa-tags" style={{ color: 'var(--primary-color)' }}></i> Related Deals
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
            {relatedDeals.map((p: any) => <PromotionCard key={p._id || p.id} promotion={p} />)}
          </div>
        </div>
      )}

      {/* Sticky Mobile CTA */}
      {deal.url && (
        <div className="md:hidden" style={{ position: 'fixed', bottom: 0, left: 0, right: 0, padding: '0.875rem', background: 'var(--card-bg)', borderTop: '1.5px solid var(--border-color)', boxShadow: '0 -4px 12px rgba(0,0,0,0.08)', zIndex: 50 }}>
          <a href={deal.url} target="_blank" rel="noopener noreferrer"
            onClick={() => PromotionAPI.recordClick(dealId, { type: 'click' }).catch(() => {})}
            className="btn btn-primary" style={{ width: '100%', justifyContent: 'center', padding: '0.875rem', fontSize: '1rem', fontWeight: 700 }}>
            <i className="fas fa-bolt"></i> Claim Deal Now
          </a>
        </div>
      )}
    </div>
  );
}
