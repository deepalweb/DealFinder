"use client";
import Link from "next/link";
import { ArrowRight } from "lucide-react";
import PromotionCard from "@/components/ui/PromotionCard";
import { offerId, offerKind, type OfferRecord } from "@/lib/offer-display";
import { marketplaceCopy } from "@/lib/marketplace-copy";
import { useLanguage } from "@/contexts/LanguageContext";
export function DealGrid({ offers }: { offers: OfferRecord[] }) {
  return (
    <div className="mp-grid">
      {offers.map((o) => (
        <PromotionCard key={`${offerKind(o)}:${offerId(o)}`} promotion={o} />
      ))}
    </div>
  );
}
export default function DealSection({
  title,
  subtitle,
  offers,
  href,
}: {
  title: string;
  subtitle?: string;
  offers: OfferRecord[];
  href?: string;
}) {
  const { language } = useLanguage();
  if (!offers.length) return null;
  return (
    <section className="mp-section">
      <div className="mp-section-heading">
        <div>
          <h2>{title}</h2>
          {subtitle && <p>{subtitle}</p>}
        </div>
        {href && (
          <Link href={href}>
            {marketplaceCopy[language].seeAll}
            <ArrowRight size={16} />
          </Link>
        )}
      </div>
      <DealGrid offers={offers} />
    </section>
  );
}
