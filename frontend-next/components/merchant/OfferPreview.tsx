"use client";
import { useLanguage } from "@/contexts/LanguageContext";
import { merchantCopy } from "@/lib/merchant-copy";
import {
  displayOffer,
  expiryLabel,
  formatPrice,
  type OfferRecord,
} from "@/lib/offer-display";
import OfferImage from "@/components/marketplace/OfferImage";
export default function OfferPreview({ offer }: { offer: OfferRecord }) {
  const { language } = useLanguage();
  const c = merchantCopy[language];
  const v = displayOffer(offer);
  const money = (n: number) =>
    formatPrice(n, v.currency, language === "en" ? "en-LK" : language);
  return (
    <aside className="mw-preview">
      <div className="mw-panel">
        <span className="mw-eyebrow">{c.unpublished}</span>
        <h2>{c.preview}</h2>
        <p className="mw-muted">{c.previewHint}</p>
        <article className="mp-offer">
          <div className="mp-offer-image">
            <OfferImage
              src={v.image}
              alt={v.title || c.title}
              sizes="(max-width:900px) 100vw, 380px"
            />
          </div>
          <div className="mp-offer-body">
            <span className="mw-benefit">{v.benefit || c.discount}</span>
            <p className="mw-muted">{v.merchantName}</p>
            <h3>{v.title || c.title}</h3>
            {v.price !== null && (
              <p>
                <strong>{money(v.price)}</strong>{" "}
                {v.previous !== null && <del>{money(v.previous)}</del>}
              </p>
            )}
            <p>{String(offer.description || "")}</p>
            {v.bank && (
              <p>
                {String(offer.bankName || "")} ·{" "}
                {(offer.cardTypes || [])
                  .map((t) => c[t as keyof typeof c] || t)
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
              {offer.fulfillmentType === "order"
                ? c.order
                : offer.fulfillmentType === "hybrid"
                  ? c.both
                  : c.visit}
            </p>
            <p>{expiryLabel(offer.endDate, language) || c.end}</p>
            {!!offer.code && (
              <p>
                {c.code}: <code>{String(offer.code)}</code>
              </p>
            )}
            {!!offer.termsAndConditions && (
              <p className="mw-preline">{String(offer.termsAndConditions)}</p>
            )}
            {offer.fulfillmentType !== "visit" && !!offer.orderLink && (
              <p className="mw-wrap">
                {c.orderLink}: {String(offer.orderLink)}
              </p>
            )}
          </div>
        </article>
      </div>
    </aside>
  );
}
