"use client";
import { useState } from "react";
import OfferImage from "@/components/marketplace/OfferImage";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Bookmark, Clock, MapPin, ArrowUpRight } from "lucide-react";
import toast from "react-hot-toast";
import { useAuth } from "@/contexts/AuthContext";
import { useLanguage } from "@/contexts/LanguageContext";
import { useArea } from "@/contexts/AreaContext";
import { useSavedOffers } from "@/contexts/SavedOffersContext";
import { PromotionAPI } from "@/lib/api";
import { marketplaceCopy } from "@/lib/marketplace-copy";
import {
  displayOffer,
  distanceKm,
  expiryLabel,
  formatPrice,
  type OfferRecord,
} from "@/lib/offer-display";
interface Props {
  promotion: OfferRecord;
  isFavorite?: boolean;
  avgRating?: number | null;
  onFavoriteToggle?: (id: string, isFav: boolean) => void;
}
export default function PromotionCard({
  promotion,
  isFavorite: initialFavorite,
  onFavoriteToggle,
}: Props) {
  const { user } = useAuth();
  const { language } = useLanguage();
  const { area } = useArea();
  const saved = useSavedOffers();
  const router = useRouter();
  const c = marketplaceCopy[language];
  const v = displayOffer(promotion);
  const [busy, setBusy] = useState(false);
  const isFavorite =
    saved.ids.has(v.id) || (initialFavorite === true && !saved.ready);
  const distance = distanceKm(promotion, area);
  const end = expiryLabel(promotion.endDate, language);
  const money = (n: number) =>
    formatPrice(n, v.currency, language === "en" ? "en-LK" : language);
  const trackOpen = () => {
    if (v.kind === "promotion")
      void PromotionAPI.recordClick(v.id, { type: "click" }).catch(() => {});
  };
  async function toggle() {
    if (!user) {
      sessionStorage.setItem(
        "df-pending-save",
        JSON.stringify({ id: v.id, userId: null }),
      );
      router.push(
        `/login?next=${encodeURIComponent(window.location.pathname + window.location.search)}`,
      );
      return;
    }
    setBusy(true);
    try {
      await saved.setSaved(v.id, !isFavorite);
      onFavoriteToggle?.(v.id, !isFavorite);
    } catch {
      toast.error(c.saveFailed);
    } finally {
      setBusy(false);
    }
  }
  return (
    <article className="mp-offer">
      <div className="mp-offer-image">
        <Link
          href={v.href}
          onClick={trackOpen}
          aria-label={`${c.view}: ${v.title}`}
        >
          <OfferImage
            src={v.image}
            alt={v.title}
            sizes="(max-width:639px) 100vw, (max-width:1023px) 50vw, (max-width:1279px) 33vw, 25vw"
          />
        </Link>
        {v.benefit && <span className="mp-benefit">{v.benefit}</span>}
        {v.kind === "promotion" && (
          <button
            className="mp-save"
            onClick={toggle}
            disabled={busy || (!!user && !saved.ready)}
            aria-label={isFavorite ? c.unsave : c.save}
            aria-pressed={isFavorite}
          >
            <Bookmark size={20} fill={isFavorite ? "currentColor" : "none"} />
          </button>
        )}
      </div>
      <div className="mp-offer-body">
        {v.merchantName && <p className="mp-merchant">{v.merchantName}</p>}
        <h3>
          <Link href={v.href} onClick={trackOpen}>
            {v.title}
          </Link>
        </h3>
        {v.price !== null && (
          <p className="mp-price">
            {money(v.price)}{" "}
            {v.previous !== null && <del>{money(v.previous)}</del>}
          </p>
        )}
        {v.bank && (
          <p className="mp-conditions">
            {promotion.bankName} ·{" "}
            {promotion.cardTypes
              ?.map((type) => c[type as "credit" | "debit" | "prepaid"] || type)
              .join(", ")}
          </p>
        )}
        <div className="mp-conditions">
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
          {[
            promotion.visitAvailable && c.visit,
            promotion.deliveryAvailable && c.delivery,
            promotion.pickupAvailable && c.pickup,
          ]
            .filter(Boolean)
            .join(" · ")}
        </div>
        <div className="mp-offer-meta">
          {distance !== null && (
            <span>
              <MapPin size={14} />≈{" "}
              {distance < 1
                ? `${Math.round(distance * 1000)} m`
                : `${distance.toFixed(1)} km`}
            </span>
          )}
          {end && (
            <span>
              <Clock size={14} />
              {c.ends} {end}
            </span>
          )}
        </div>
        <Link className="mp-offer-link" href={v.href} onClick={trackOpen}>
          {c.view}
          <ArrowUpRight size={16} />
        </Link>
      </div>
    </article>
  );
}
