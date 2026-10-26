"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import Image from "next/image";
import OfferImage from "@/components/marketplace/OfferImage";
import {
  Bookmark,
  ArrowLeft,
  ExternalLink,
  MapPin,
  Copy,
  Check,
  Share2,
  Star,
  ChevronDown,
  ChevronUp,
  Store,
  Ticket,
  MessageCircle,
} from "lucide-react";
import GoogleMapView from "@/components/ui/GoogleMapView";
import toast from "react-hot-toast";
import { BankOfferAPI, PromotionAPI } from "@/lib/api";
import { useAuth } from "@/contexts/AuthContext";
import { useLanguage } from "@/contexts/LanguageContext";
import { useArea } from "@/contexts/AreaContext";
import { useSavedOffers } from "@/contexts/SavedOffersContext";
import { marketplaceCopy } from "@/lib/marketplace-copy";
import {
  displayOffer,
  distanceKm,
  expiryLabel,
  isPublicOffer,
  safeImage,
  formatPrice,
  type OfferRecord,
} from "@/lib/offer-display";
import DealSection from "@/components/marketplace/DealSection";
type Review = {
  _id?: string;
  id?: string;
  text: string;
  createdAt?: string;
  user?: { name?: string };
};
export default function DealPageClient({
  dealId,
  kind,
}: {
  dealId: string;
  kind?: "bank";
}) {
  const router = useRouter();
  const { user } = useAuth();
  const { language } = useLanguage();
  const { area } = useArea();
  const saved = useSavedOffers();
  const c = marketplaceCopy[language];
  const [deal, setDeal] = useState<OfferRecord | null>(null);
  const [bankRecord, setBankRecord] = useState(kind === "bank");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [retry, setRetry] = useState(0);
  const [now, setNow] = useState(0);
  const [image, setImage] = useState("");
  const [comments, setComments] = useState<Review[]>([]);
  const [reviewError, setReviewError] = useState(false);
  const [ratings, setRatings] = useState<{ value: number }[]>([]);
  const [related, setRelated] = useState<OfferRecord[]>([]);
  const [text, setText] = useState("");
  const [saving, setSaving] = useState(false);
  const [posting, setPosting] = useState(false);
  const [copied, setCopied] = useState(false);
  const [termsOpen, setTermsOpen] = useState(false);
  const [shareOpen, setShareOpen] = useState(false);
  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(false);
    setReviewError(false);
    setComments([]);
    setRatings([]);
    setRelated([]);
    async function load() {
      let result: OfferRecord;
      let isBank = kind === "bank";
      if (isBank) result = await BankOfferAPI.getById(dealId);
      else {
        try {
          result = await PromotionAPI.getById(dealId);
        } catch {
          result = await BankOfferAPI.getById(dealId);
          isBank = true;
        }
      }
      if (cancelled) return;
      if (!isPublicOffer(result, Date.now(), true)) {
        setError(true);
        setDeal(null);
        setLoading(false);
        return;
      }
      setDeal(result);
      setBankRecord(isBank);
      setNow(Date.now());
      setImage(safeImage(result.image || result.images?.[0]));
      setLoading(false);
      if (!isBank) {
        const reviews = await Promise.allSettled([
          PromotionAPI.getComments(dealId),
          PromotionAPI.getRatings(dealId),
        ]);
        if (cancelled) return;
        if (reviews[0].status === "fulfilled") setComments(reviews[0].value);
        else setReviewError(true);
        if (reviews[1].status === "fulfilled") setRatings(reviews[1].value);
        else setReviewError(true);
      }
      const source = await Promise.allSettled([
        PromotionAPI.getAll({ limit: 48 }),
        BankOfferAPI.getAll({ limit: 48 }),
      ]);
      if (cancelled) return;
      const all = source.flatMap((r) =>
        r.status === "fulfilled" ? r.value : [],
      );
      setRelated(
        all
          .filter(
            (o) =>
              isPublicOffer(o) &&
              o.category === result.category &&
              (o._id || o.id) !== dealId,
          )
          .slice(0, 4),
      );
    }
    void load().catch(() => {
      if (!cancelled) {
        setError(true);
        setDeal(null);
        setLoading(false);
      }
    });
    return () => {
      cancelled = true;
    };
  }, [dealId, kind, retry]);
  useEffect(() => {
    const timer = setInterval(() => setNow(Date.now()), 60000);
    return () => clearInterval(timer);
  }, []);
  function signIn(save = false) {
    if (save)
      sessionStorage.setItem(
        "df-pending-save",
        JSON.stringify({ id: dealId, userId: null }),
      );
    router.push(
      `/login?next=${encodeURIComponent(window.location.pathname + window.location.search)}`,
    );
  }
  async function favorite() {
    if (!user) {
      signIn(true);
      return;
    }
    setSaving(true);
    try {
      await saved.setSaved(dealId, !saved.ids.has(dealId));
    } catch {
      toast.error(c.saveFailed);
    } finally {
      setSaving(false);
    }
  }
  async function copy() {
    try {
      if (deal?.code) {
        await navigator.clipboard.writeText(deal.code);
        setCopied(true);
        setTimeout(() => setCopied(false), 2500);
        toast.success(c.copySuccess);
      }
    } catch {
      toast.error(c.copyFailed);
    }
  }
  async function share() {
    if (typeof navigator !== "undefined" && navigator.share) {
      try {
        await navigator.share({
          title: deal?.title || "Deal on DealFinder",
          text: `Check out this deal on DealFinder: ${deal?.title || ""}`,
          url: window.location.href,
        });
      } catch {}
    } else {
      setShareOpen((prev) => !prev);
    }
  }
  async function copyLink() {
    try {
      await navigator.clipboard.writeText(window.location.href);
      toast.success(c.copySuccess || "Link copied!");
      setShareOpen(false);
    } catch {
      toast.error(c.copyFailed);
    }
  }
  async function rate(value: number) {
    if (!user) {
      signIn();
      return;
    }
    try {
      const values = await PromotionAPI.addRating(dealId, {
        userId: user._id,
        value,
      });
      setRatings(values);
      toast.success(c.ratingSaved);
    } catch {
      toast.error(c.ratingFailed);
    }
  }
  async function comment(event: React.FormEvent) {
    event.preventDefault();
    if (!user) {
      signIn();
      return;
    }
    if (!text.trim()) return;
    setPosting(true);
    try {
      const result = await PromotionAPI.addComment(dealId, {
        userId: user._id,
        text,
      });
      setComments((prev) => [
        ...prev,
        { ...result, user: { name: user.name } },
      ]);
      setText("");
    } catch {
      toast.error(c.commentFailed);
    } finally {
      setPosting(false);
    }
  }
  if (loading)
    return (
      <div className="mp-shell mp-detail" aria-label={c.loading}>
        <div className="skeleton" style={{ height: 400, borderRadius: 16 }} />
      </div>
    );
  if (error || !deal)
    return (
      <div className="mp-shell mp-detail">
        <div className="mp-state" role="alert">
          <p>{c.failed}</p>
          <button className="mp-button" onClick={() => setRetry(retry + 1)}>
            {c.retry}
          </button>
        </div>
      </div>
    );
  const v = displayOffer(deal);
  const active = isPublicOffer(deal, now);
  const merchant = typeof deal.merchant === "object" ? deal.merchant : null;
  const merchantId = merchant
    ? merchant._id || merchant.id
    : typeof deal.merchant === "string"
      ? deal.merchant
      : null;
  const distance = distanceKm(deal, area);
  const end = expiryLabel(deal.endDate, language);
  const start = expiryLabel(deal.startDate, language);
  const external = deal.orderLink || deal.url || deal.websiteUrl || merchant?.orderLink;
  const validExternal =
    external && /^https?:\/\//.test(external) ? external : null;
  const coordinates = merchant?.location?.coordinates;
  const rating = ratings.length
    ? ratings.reduce((sum, r) => sum + r.value, 0) / ratings.length
    : null;
  const money = (value: number) =>
    formatPrice(value, v.currency, language === "en" ? "en-LK" : language);
  return (
    <div className="mp-shell mp-detail">
      <button
        className="mp-button"
        onClick={() =>
          window.history.length > 1
            ? router.back()
            : router.push("/categories/all")
        }
      >
        <ArrowLeft size={18} />
        {c.back}
      </button>
      <div className="mp-detail-layout">
        <section>
          <div className="mp-detail-photo">
            <OfferImage
              src={image || "/assets/offer-placeholder.svg"}
              alt={v.title}
              sizes="(max-width:767px) 100vw, 850px"
              preload
            />
          </div>
          {deal.images && deal.images.length > 1 && (
            <div className="mp-chips">
              {deal.images.map((src, index) => (
                <button
                  className="mp-chip"
                  key={index}
                  aria-label={`${c.viewImage} ${index + 1}`}
                  aria-pressed={image === src}
                  onClick={() => setImage(safeImage(src))}
                >
                  <Image
                    src={safeImage(src)}
                    alt=""
                    width={64}
                    height={48}
                    className="object-cover"
                  />
                </button>
              ))}
            </div>
          )}
          <p className="mp-merchant">
            {merchantId ? (
              <Link href={`/merchants/${merchantId}`}>{v.merchantName}</Link>
            ) : (
              v.merchantName
            )}
          </p>
          <h1 className="mp-detail-title">{v.title}</h1>
          <p className="mp-muted">
            {merchant?.address}
            {distance !== null && ` · ≈ ${distance.toFixed(1)} km`}
          </p>
          <p
            style={{ marginBlock: 20, lineHeight: 1.8, whiteSpace: "pre-wrap" }}
          >
            {deal.description}
          </p>

          {/* Embedded Interactive Map */}
          {coordinates &&
            coordinates.length >= 2 &&
            coordinates.every(Number.isFinite) && (
              <div className="mp-map-card">
                <div className="mp-map-header">
                  <h3>
                    <MapPin size={18} style={{ color: "var(--primary-color)" }} />
                    {merchant?.name || v.merchantName}
                  </h3>
                  <a
                    className="mp-button"
                    style={{ minHeight: 34, padding: "6px 12px", fontSize: 13 }}
                    href={`https://www.google.com/maps/dir/?api=1&destination=${coordinates[1]},${coordinates[0]}`}
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    <MapPin size={14} />
                    {c.directions}
                  </a>
                </div>
                <GoogleMapView
                  lat={coordinates[1]}
                  lng={coordinates[0]}
                  points={[
                    {
                      id: String(dealId),
                      lat: coordinates[1],
                      lng: coordinates[0],
                      title: merchant?.name || v.merchantName || v.title,
                    },
                  ]}
                  height="220px"
                />
              </div>
            )}

          {/* Interactive Terms & Conditions Accordion */}
          <div className="mp-accordion">
            <button
              type="button"
              className="mp-accordion-summary"
              style={{
                width: "100%",
                background: "none",
                border: "none",
                color: "inherit",
                textAlign: "left",
              }}
              onClick={() => setTermsOpen((prev) => !prev)}
              aria-expanded={termsOpen}
            >
              <span>{c.conditions}</span>
              {termsOpen ? <ChevronUp size={18} /> : <ChevronDown size={18} />}
            </button>
            <div
              className="mp-chips"
              style={{
                paddingInline: 20,
                marginBlock: 0,
                paddingBottom: 12,
              }}
            >
              {end && (
                <span className="mp-intro-pill">
                  {c.ends}: {end}
                </span>
              )}
              {v.minimum !== null && (
                <span className="mp-intro-pill">
                  {c.minimum}: {money(v.minimum)}
                </span>
              )}
              {deal.bankName && (
                <span className="mp-intro-pill">{deal.bankName}</span>
              )}
            </div>
            {termsOpen && (
              <div className="mp-accordion-content">
                <p>
                  {start && `${start} — `}
                  {end ? `${c.ends} ${end}` : c.dateUnknown}
                </p>
                {deal.bankName && (
                  <p>
                    {deal.bankName} ·{" "}
                    {deal.cardTypes
                      ?.map(
                        (type) =>
                          c[type as "credit" | "debit" | "prepaid"] || type,
                      )
                      .join(", ")}
                  </p>
                )}
                {v.minimum !== null && (
                  <p>
                    {c.minimum}: {money(v.minimum)}
                  </p>
                )}
                {v.maximum !== null && (
                  <p>
                    {c.maximum}: {money(v.maximum)}
                  </p>
                )}
                <p>
                  {[
                    deal.visitAvailable && c.visit,
                    deal.deliveryAvailable && c.delivery,
                    deal.pickupAvailable && c.pickup,
                  ]
                    .filter(Boolean)
                    .join(" · ")}
                </p>
                {deal.termsAndConditions && (
                  <p style={{ whiteSpace: "pre-wrap" }}>
                    {deal.termsAndConditions}
                  </p>
                )}
              </div>
            )}
          </div>
        </section>
        <aside className="mp-detail-panel mp-detail-actions">
          <p className="mp-price">{v.benefit}</p>
          {v.price !== null && (
            <p className="mp-price">
              {money(v.price)}{" "}
              {v.previous !== null && <del>{money(v.previous)}</del>}
            </p>
          )}
          <p className="mp-muted">
            {active ? (end ? `${c.ends} ${end}` : c.dateUnknown) : c.expired}
          </p>
          <h2>{c.how}</h2>
          <p>{v.bank ? c.eligibility : deal.code ? c.code : c.website}</p>
          {v.minimum !== null && (
            <p>
              {c.minimum}: {money(v.minimum)}
            </p>
          )}
          {v.maximum !== null && (
            <p>
              {c.maximum}: {money(v.maximum)}
            </p>
          )}
          {deal.code && (
            <div className="mp-code">
              <code>{deal.code}</code>
              <button
                className="mp-button"
                disabled={!active}
                onClick={() => void copy()}
              >
                <Copy size={18} />
                {c.code}
              </button>
            </div>
          )}
          {validExternal && (
            <a
              className="mp-button mp-primary"
              href={validExternal}
              target="_blank"
              rel="noopener noreferrer"
              onClick={() => {
                if (!bankRecord)
                  void PromotionAPI.recordClick(dealId, {
                    type: "click",
                  }).catch(() => {});
              }}
            >
              <ExternalLink size={18} />
              {c.website}
            </a>
          )}
          {deal.fulfillmentType !== "order" && deal.visitAvailable !== false && coordinates &&
            coordinates.length >= 2 &&
            coordinates.every(Number.isFinite) && (
              <a
                className="mp-button"
                href={`https://www.google.com/maps/dir/?api=1&destination=${coordinates[1]},${coordinates[0]}`}
                target="_blank"
                rel="noopener noreferrer"
              >
                <MapPin size={18} />
                {c.directions}
              </a>
            )}
          {!bankRecord && (
            <button
              className="mp-button"
              disabled={saving || (!!user && !saved.ready)}
              aria-pressed={saved.ids.has(dealId)}
              onClick={() => void favorite()}
            >
              <Bookmark size={18} />
              {saved.ids.has(dealId) ? c.unsave : c.save}
            </button>
          )}
          <button className="mp-button" onClick={() => void share()}>
            <Share2 size={18} />
            {c.share}
          </button>
          {merchantId && (
            <Link className="mp-button" href={`/merchants/${merchantId}`}>
              {c.stores}
            </Link>
          )}
        </aside>
      </div>
      {!bankRecord && (
        <section className="mp-detail-panel">
          <h2>{c.reviews}</h2>
          {reviewError && (
            <div className="mp-state">
              <p>{c.failed}</p>
              <button className="mp-button" onClick={() => setRetry(retry + 1)}>
                {c.retry}
              </button>
            </div>
          )}
          {rating !== null && (
            <p>
              {rating.toFixed(1)} / 5 · {ratings.length} {c.ratings}
            </p>
          )}
          <div className="mp-chips">
            {[1, 2, 3, 4, 5].map((n) => (
              <button
                className="mp-button"
                key={n}
                aria-label={`${c.ratingPrompt} ${n} / 5`}
                onClick={() => void rate(n)}
              >
                <Star size={18} />
                {n}
              </button>
            ))}
          </div>
          {comments.map((review, index) => (
            <article
              key={review._id || review.id || index}
              style={{
                borderTop: "1px solid var(--border-color)",
                paddingBlock: 16,
              }}
            >
              <strong>{review.user?.name}</strong>
              <p>{review.text}</p>
            </article>
          ))}
          <form onSubmit={comment}>
            <label className="mp-field">
              {c.comment}
              <textarea
                value={text}
                onChange={(e) => setText(e.target.value)}
                rows={3}
                required
              />
            </label>
            <button className="mp-button" disabled={posting}>
              {user ? c.postComment : c.signIn}
            </button>
          </form>
        </section>
      )}

      <DealSection title={c.more} offers={related} />
    </div>
  );
}
