"use client";
import { useCallback, useEffect, useRef, useState } from "react";
import { PromotionAPI, BankOfferAPI } from "@/lib/api";
import { offerId, offerKind, type OfferRecord } from "@/lib/offer-display";
export function useOfferFeed() {
  const [offers, setOffers] = useState<OfferRecord[]>([]);
  const [featured, setFeatured] = useState<OfferRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [errors, setErrors] = useState<string[]>([]);
  const [hasMore, setHasMore] = useState(false);
  const [offset, setOffset] = useState(0);
  const [now, setNow] = useState(0);
  const generation = useRef(0);
  const reload = useCallback(async () => {
    const version = ++generation.current;
    setLoading(true);
    const results = await Promise.allSettled([
      PromotionAPI.getAll({ limit: 48 }),
      BankOfferAPI.getAll({ limit: 100 }),
      PromotionAPI.getHomepage(),
    ]);
    if (version !== generation.current) return;
    const promotions =
      results[0].status === "fulfilled" ? results[0].value : [];
    const banks = results[1].status === "fulfilled" ? results[1].value : [];
    setErrors([
      ...(results[0].status === "rejected" ? ["promotions"] : []),
      ...(results[1].status === "rejected" ? ["banks"] : []),
    ]);
    if (results[0].status === "fulfilled" || results[1].status === "fulfilled")
      setOffers([...promotions, ...banks]);
    setOffset(promotions.length);
    setHasMore(promotions.length === 48);
    if (results[2].status === "fulfilled")
      setFeatured(results[2].value.featured || []);
    setNow(Date.now());
    setLoading(false);
  }, []);
  const cancel = useCallback(() => {
    generation.current++;
  }, []);
  useEffect(() => {
    void reload();
    const timer = setInterval(() => setNow(Date.now()), 60000);
    return () => {
      cancel();
      clearInterval(timer);
    };
  }, [reload, cancel]);
  async function loadMore() {
    if (loadingMore) return;
    setLoadingMore(true);
    const version = generation.current;
    try {
      const rows = await PromotionAPI.getAll({ limit: 48, skip: offset });
      if (version !== generation.current) return;
      setOffers((prev) => {
        const seen = new Set(prev.map((o) => `${offerKind(o)}:${offerId(o)}`));
        return [
          ...prev,
          ...rows.filter((o) => !seen.has(`${offerKind(o)}:${offerId(o)}`)),
        ];
      });
      setOffset(offset + rows.length);
      setHasMore(rows.length === 48);
      setErrors((prev) => prev.filter((e) => e !== "pagination"));
    } catch {
      if (version === generation.current)
        setErrors((prev) => [
          ...prev.filter((e) => e !== "pagination"),
          "pagination",
        ]);
    } finally {
      setLoadingMore(false);
    }
  }
  return {
    offers,
    featured,
    loading,
    loadingMore,
    errors,
    hasMore,
    now,
    reload,
    loadMore,
  };
}
