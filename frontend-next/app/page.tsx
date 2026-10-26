"use client";
import { useState } from "react";
import Link from "next/link";
import OfferImage from "@/components/marketplace/OfferImage";
import { ArrowRight, Sparkles, ShieldCheck, CreditCard, Flame } from "lucide-react";
import { useLanguage } from "@/contexts/LanguageContext";
import { useArea } from "@/contexts/AreaContext";
import { marketplaceCopy, categoryName } from "@/lib/marketplace-copy";
import {
  displayOffer,
  distanceKm,
  dateValue,
  isPublicOffer,
  offerId,
  offerKind,
  percentage,
  type OfferRecord,
} from "@/lib/offer-display";
import { DEALFINDER_CATEGORIES } from "@/lib/categories";
import AreaSelector from "@/components/marketplace/AreaSelector";
import DealSection, { DealGrid } from "@/components/marketplace/DealSection";
import { useOfferFeed } from "@/components/marketplace/useOfferFeed";
import SkeletonCard from "@/components/ui/SkeletonCard";
export default function Home() {
  const { language } = useLanguage();
  const c = marketplaceCopy[language];
  const { area } = useArea();
  const feed = useOfferFeed();
  const [count, setCount] = useState(8);
  const [sort, setSort] = useState("newest");
  const seen = new Set<string>();
  const key = (o: OfferRecord) => `${offerKind(o)}:${offerId(o)}`;
  const active = feed.offers.filter((o) => isPublicOffer(o, feed.now));
  function take(rows: OfferRecord[], limit = 4) {
    const result = rows.filter((o) => !seen.has(key(o))).slice(0, limit);
    result.forEach((o) => seen.add(key(o)));
    return result;
  }
  const campaign = [...feed.featured, ...active.filter((o) => o.featured)].find(
    (o) => isPublicOffer(o, feed.now),
  );
  if (campaign) seen.add(key(campaign));
  const campaignView = campaign ? displayOffer(campaign) : null;
  const nearby = area
    ? active
        .filter(
          (o) =>
            distanceKm(o, area) !== null &&
            distanceKm(o, area)! <= area.radiusKm,
        )
        .sort((a, b) => distanceKm(a, area)! - distanceKm(b, area)!)
    : active;
  const near = take(nearby);
  const banks = take(
    active.filter((o) => o.bankName || offerKind(o) === "bank"),
  );
  const collections = ["food_dining", "shopping_retail", "health_wellness"]
    .map((id) => ({
      id,
      offers: take(active.filter((o) => o.category === id)),
    }))
    .filter((g) => g.offers.length);
  const ending = take(
    active
      .filter((o) => {
        const end = dateValue(o.endDate, true);
        return (
          end !== null && end >= feed.now && end - feed.now <= 3 * 86400000
        );
      })
      .sort(
        (a, b) => dateValue(a.endDate, true)! - dateValue(b.endDate, true)!,
      ),
  );
  const more = active
    .filter((o) => !seen.has(key(o)))
    .sort((a, b) =>
      sort === "ending"
        ? (dateValue(a.endDate, true) ?? Infinity) -
          (dateValue(b.endDate, true) ?? Infinity)
        : sort === "discount"
          ? (percentage(b) ?? -1) - (percentage(a) ?? -1)
          : (dateValue(b.createdAt) ?? 0) - (dateValue(a.createdAt) ?? 0),
    );
  return (
    <div className="mp-shell">
      <div className="mp-intro">
        <h1>
          {c.title} <span>{c.subtitle}</span>
        </h1>
        <p>{c.intro}</p>
        <div className="mp-intro-highlights">
          <span className="mp-intro-pill">
            <ShieldCheck size={16} />
            Verified Local Stores
          </span>
          <span className="mp-intro-pill">
            <CreditCard size={16} />
            Exclusive Bank Card Perks
          </span>
          <span className="mp-intro-pill">
            <Flame size={16} />
            Live Discounts across Sri Lanka
          </span>
        </div>
      </div>
      {campaignView && (
        <section className="mp-campaign">
          <div className="mp-campaign-copy">
            <span className="mp-campaign-tag">
              <Sparkles size={14} />
              {c.featured} · {campaignView.benefit}
            </span>
            <h2>{campaignView.title}</h2>
            <p>{campaignView.merchantName}</p>
            <Link
              href={campaignView.href}
              className="mp-button mp-primary"
              style={{ marginTop: 20, alignSelf: "flex-start" }}
            >
              {c.view}
              <ArrowRight size={16} />
            </Link>
          </div>
          <div className="mp-campaign-image">
            <OfferImage
              src={campaignView.image}
              alt={campaignView.title}
              sizes="(max-width:767px) 1px, 500px"
              preload
            />
          </div>
        </section>
      )}
      {feed.errors.length > 0 && (
        <div className="mp-state" role="alert">
          <p>
            {c.failed} (
            {feed.errors
              .map((e) =>
                e === "banks"
                  ? c.bank
                  : e === "pagination"
                    ? c.loadMore
                    : c.all,
              )
              .join(", ")}
            )
          </p>
          <button className="mp-button" onClick={() => void feed.reload()}>
            {c.retry}
          </button>
        </div>
      )}
      {feed.loading && !active.length && (
        <div className="mp-section mp-grid" aria-label={c.loading}>
          {[0, 1, 2, 3].map((i) => (
            <SkeletonCard key={i} />
          ))}
        </div>
      )}
      <div className="mp-section-heading" style={{ marginTop: 32 }}>
        <div>
          <h2>{area ? c.nearby : c.general}</h2>
          <p className="mp-muted">
            {area ? `${area.label} · ${area.radiusKm} km` : c.chooseHint}
          </p>
        </div>
        <AreaSelector />
      </div>
      {near.length ? (
        <DealGrid offers={near} />
      ) : (
        !feed.loading && (
          <p className="mp-state">
            {area ? c.noNearby : feed.errors.length ? c.failed : c.empty}
          </p>
        )
      )}
      <DealSection
        title={c.bank}
        subtitle={c.bankHint}
        offers={banks}
        href="/categories/bank_cards"
      />
      {collections.map((g) => (
        <DealSection
          key={g.id}
          title={categoryName(
            g.id,
            language,
            DEALFINDER_CATEGORIES.find((cat) => cat.id === g.id)?.name || g.id,
          )}
          offers={g.offers}
          href={`/categories/${g.id}`}
        />
      ))}
      <DealSection
        title={c.ending}
        offers={ending}
        href="/categories/all?availability=ending&sort=ending"
      />
      <section className="mp-section">
        <div className="mp-section-heading">
          <h2>{c.more}</h2>
          <label className="mp-field">
            {c.sort}
            <select
              aria-label={c.sort}
              value={sort}
              onChange={(e) => {
                setSort(e.target.value);
                setCount(8);
              }}
            >
              <option value="newest">{c.newest}</option>
              <option value="ending">{c.ending}</option>
              <option value="discount">{c.discount}</option>
            </select>
          </label>
        </div>
        <DealGrid offers={more.slice(0, count)} />
        <div className="mp-pagination">
          {count < more.length ? (
            <button className="mp-button" onClick={() => setCount(count + 8)}>
              {c.loadMore}
            </button>
          ) : feed.hasMore ? (
            <button
              className="mp-button"
              disabled={feed.loadingMore}
              onClick={() => void feed.loadMore()}
            >
              {feed.loadingMore ? c.loading : c.loadMore}
            </button>
          ) : (
            active.length > 0 && <p className="mp-muted">{c.end}</p>
          )}
          <Link href="/categories/all" className="mp-button">
            {c.all}
            <ArrowRight size={16} />
          </Link>
        </div>
      </section>
    </div>
  );
}
