"use client";
import { useEffect, useMemo, useRef, useState } from "react";
import Link from "next/link";
import { useParams, useRouter, useSearchParams } from "next/navigation";
import { SlidersHorizontal, X } from "lucide-react";
import { AiAPI } from "@/lib/api";
import { DEALFINDER_CATEGORIES, normalizeCategoryId } from "@/lib/categories";
import { useLanguage } from "@/contexts/LanguageContext";
import { useArea } from "@/contexts/AreaContext";
import { marketplaceCopy, categoryName } from "@/lib/marketplace-copy";
import {
  isPublicOffer,
  offerKind,
  offerId,
  displayOffer,
  dateValue,
  percentage,
  distanceKm,
  supports,
  type OfferRecord,
} from "@/lib/offer-display";
import { useOfferFeed } from "@/components/marketplace/useOfferFeed";
import { DealGrid } from "@/components/marketplace/DealSection";
import AreaSelector from "@/components/marketplace/AreaSelector";
import SkeletonCard from "@/components/ui/SkeletonCard";
export default function CategoryPageClient() {
  const { categoryId } = useParams<{ categoryId: string }>();
  const router = useRouter();
  const params = useSearchParams();
  const { language } = useLanguage();
  const { area } = useArea();
  const c = marketplaceCopy[language];
  const feed = useOfferFeed();
  const [searchRows, setSearchRows] = useState<OfferRecord[]>([]);
  const [searchLoading, setSearchLoading] = useState(false);
  const [searchError, setSearchError] = useState(false);
  const [retry, setRetry] = useState(0);
  const [count, setCount] = useState(12);
  const dialog = useRef<HTMLDialogElement>(null);
  const q = params.get("q") || "";
  const sort = params.get("sort") || "newest";
  const bank = params.get("bank") || "";
  const card = params.get("card") || "";
  const mode = params.get("mode") || "";
  const availability = params.get("availability") || "active";
  const category = normalizeCategoryId(categoryId);
  const banks = Array.from(
    new Set(feed.offers.map((o) => o.bankName).filter((b): b is string => !!b)),
  ).sort();
  function change(updates: Record<string, string>) {
    const next = new URLSearchParams(params.toString());
    Object.entries(updates).forEach(([key, value]) =>
      value ? next.set(key, value) : next.delete(key),
    );
    setCount(12);
    router.push(`/categories/${categoryId}${next.size ? "?" + next : ""}`);
  }
  useEffect(() => {
    if (!q) {
      setSearchRows([]);
      setSearchError(false);
      setSearchLoading(false);
      return;
    }
    let cancelled = false;
    setSearchLoading(true);
    setSearchError(false);
    const timer = setTimeout(() => {
      AiAPI.search({
        query: q,
        filters:
          category === "all" || category === "bank_cards"
            ? {}
            : { categories: [category] },
        location: area,
        limit: 80,
      })
        .then((response) => {
          if (!cancelled) setSearchRows(response.results || []);
        })
        .catch(() => {
          if (!cancelled) setSearchError(true);
        })
        .finally(() => {
          if (!cancelled) setSearchLoading(false);
        });
    }, 300);
    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [q, category, area, retry]);
  const offers = useMemo(() => {
    const bankMatches = feed.offers.filter(
      (o) =>
        offerKind(o) === "bank" &&
        `${o.title} ${o.description} ${o.bankName}`
          .toLowerCase()
          .includes(q.toLowerCase()),
    );
    const rows = q ? [...searchRows, ...bankMatches] : feed.offers;
    const seen = new Set<string>();
    return rows
      .filter((o) => {
        const key = `${offerKind(o)}:${offerId(o)}`;
        if (seen.has(key)) return false;
        seen.add(key);
        if (!isPublicOffer(o, feed.now, availability === "all")) return false;
        if (category === "bank_cards" && !displayOffer(o).bank) return false;
        if (
          category !== "all" &&
          category !== "bank_cards" &&
          normalizeCategoryId(o.category) !== category
        )
          return false;
        if (bank && o.bankName !== bank) return false;
        if (card && !o.cardTypes?.includes(card)) return false;
        if (!supports(o, mode)) return false;
        const end = dateValue(o.endDate, true);
        if (
          availability === "ending" &&
          (end === null || end < feed.now || end > feed.now + 3 * 86400000)
        )
          return false;
        if (
          area &&
          offerKind(o) !== "bank" &&
          (distanceKm(o, area) === null || distanceKm(o, area)! > area.radiusKm)
        )
          return false;
        return true;
      })
      .sort((a, b) =>
        sort === "discount"
          ? (percentage(b) ?? -1) - (percentage(a) ?? -1)
          : sort === "ending"
            ? (dateValue(a.endDate, true) ?? Infinity) -
              (dateValue(b.endDate, true) ?? Infinity)
            : sort === "distance"
              ? (distanceKm(a, area) ?? Infinity) -
                (distanceKm(b, area) ?? Infinity)
              : (dateValue(b.createdAt) ?? 0) - (dateValue(a.createdAt) ?? 0),
      );
  }, [
    q,
    searchRows,
    feed.offers,
    feed.now,
    availability,
    category,
    bank,
    card,
    mode,
    area,
    sort,
  ]);
  const filterControls = (prefix: string) => (
    <div className="mp-filters">
      <h2>{c.filters}</h2>
      <AreaSelector />
      <label className="mp-field" htmlFor={`${prefix}-category`}>
        {c.category}
        <select
          aria-label={c.category}
          id={`${prefix}-category`}
          value={category}
          onChange={(e) =>
            router.push(`/categories/${e.target.value}?${params}`)
          }
        >
          {DEALFINDER_CATEGORIES.map((cat) => (
            <option key={cat.id} value={cat.id}>
              {categoryName(cat.id, language, cat.name)}
            </option>
          ))}
        </select>
      </label>
      <label className="mp-field">
        {c.bankFilter}
        <select
          aria-label={c.bankFilter}
          value={bank}
          onChange={(e) => change({ bank: e.target.value })}
        >
          <option value="">{c.all}</option>
          {banks.map((b) => (
            <option key={b}>{b}</option>
          ))}
        </select>
      </label>
      <label className="mp-field">
        {c.cardType}
        <select
          aria-label={c.cardType}
          value={card}
          onChange={(e) => change({ card: e.target.value })}
        >
          <option value="">{c.all}</option>
          {["credit", "debit", "prepaid"].map((type) => (
            <option value={type} key={type}>
              {c[type as "credit" | "debit" | "prepaid"]}
            </option>
          ))}
        </select>
      </label>
      <label className="mp-field">
        {c.fulfillment}
        <select
          aria-label={c.fulfillment}
          value={mode}
          onChange={(e) => change({ mode: e.target.value })}
        >
          <option value="">{c.all}</option>
          <option value="visit">{c.visit}</option>
          <option value="delivery">{c.delivery}</option>
          <option value="pickup">{c.pickup}</option>
        </select>
      </label>
      <label className="mp-field">
        {c.available}
        <select
          aria-label={c.available}
          value={availability}
          onChange={(e) => change({ availability: e.target.value })}
        >
          <option value="active">{c.available}</option>
          <option value="ending">{c.ending}</option>
        </select>
      </label>
      <button
        className="mp-button"
        onClick={() => router.push(`/categories/${categoryId}`)}
      >
        {c.clear}
      </button>
    </div>
  );
  const loading = q ? searchLoading : feed.loading;
  const failed = searchError || feed.errors.length > 0;
  const title =
    category === "all"
      ? c.all
      : categoryName(
          category,
          language,
          DEALFINDER_CATEGORIES.find((cat) => cat.id === category)?.name ||
            category,
        );
  return (
    <div className="mp-shell mp-results">
      {filterControls("desktop")}
      <section>
        <div className="mp-result-toolbar">
          <div>
            <h1>{title}</h1>
            <p className="mp-muted" aria-live="polite">
              {loading ? c.loading : `${offers.length} ${c.loaded}`}
              {q && ` · “${q}”`}
            </p>
          </div>
          <button
            className="mp-button mp-mobile-filter"
            onClick={() => dialog.current?.showModal()}
          >
            <SlidersHorizontal size={18} />
            {c.filters}
          </button>
          <label className="mp-field">
            {c.sort}
            <select
              aria-label={c.sort}
              value={sort}
              onChange={(e) => change({ sort: e.target.value })}
            >
              <option value="newest">{c.newest}</option>
              <option value="discount">{c.discount}</option>
              <option value="ending">{c.ending}</option>
              {area && <option value="distance">{c.nearest}</option>}
            </select>
          </label>
        </div>
        <form action={`/categories/${categoryId}`} className="mp-search">
          <label className="sr-only" htmlFor="results-query">
            {c.search}
          </label>
          <input
            id="results-query"
            key={q}
            name="q"
            defaultValue={q}
            placeholder={c.search}
          />
          {Array.from(params.entries())
            .filter(([k]) => k !== "q")
            .map(([k, v]) => (
              <input key={k} type="hidden" name={k} value={v} />
            ))}
          <button
            type="submit"
            className="mp-search-submit"
            aria-label={c.searchAction}
          >
            →
          </button>
        </form>
        <div className="mp-chips">
          {Array.from(params.entries())
            .filter(([, v]) => v)
            .map(([k, v]) => (
              <button
                className="mp-chip"
                key={k}
                onClick={() => change({ [k]: "" })}
              >
                {k}: {v}
                <X size={14} />
              </button>
            ))}
        </div>
        {failed && (
          <div className="mp-state" role="alert">
            <p>{c.failed}</p>
            <button
              className="mp-button"
              onClick={() => {
                setRetry(retry + 1);
                void feed.reload();
              }}
            >
              {c.retry}
            </button>
          </div>
        )}
        {loading && !offers.length ? (
          <div className="mp-grid">
            {[0, 1, 2].map((n) => (
              <SkeletonCard key={n} />
            ))}
          </div>
        ) : (
          <DealGrid offers={offers.slice(0, count)} />
        )}
        {!loading && !failed && !offers.length && (
          <div className="mp-state">
            <p>{c.noMatches}</p>
            <button
              className="mp-button"
              onClick={() => router.push(`/categories/${categoryId}`)}
            >
              {c.clear}
            </button>
            {area && <AreaSelector />}
          </div>
        )}
        <div className="mp-pagination">
          {count < offers.length ? (
            <button className="mp-button" onClick={() => setCount(count + 12)}>
              {c.loadMore}
            </button>
          ) : !q && feed.hasMore ? (
            <button
              disabled={feed.loadingMore}
              className="mp-button"
              onClick={() => void feed.loadMore()}
            >
              {c.loadMore}
            </button>
          ) : (
            !loading && offers.length > 0 && <p className="mp-muted">{c.end}</p>
          )}
          <Link href="/merchants">{c.stores}</Link>
        </div>
      </section>
      <dialog ref={dialog} className="mp-dialog" aria-label={c.filters}>
        <div className="mp-dialog-heading">
          <h2>{c.filters}</h2>
          <button
            className="mp-icon"
            aria-label={c.close}
            onClick={() => dialog.current?.close()}
          >
            <X />
          </button>
        </div>
        {filterControls("mobile")}
        <button
          className="mp-button mp-primary"
          onClick={() => dialog.current?.close()}
        >
          {c.close}
        </button>
      </dialog>
    </div>
  );
}
