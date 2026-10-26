"use client";
import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Plus, Store, FileText } from "lucide-react";
import { useAuth } from "@/contexts/AuthContext";
import { useLanguage } from "@/contexts/LanguageContext";
import { MerchantWorkspaceAPI } from "@/lib/api";
import { merchantCopy } from "@/lib/merchant-copy";
import {
  displayOffer,
  type OfferRecord,
  type MerchantRecord,
} from "@/lib/offer-display";
import { MerchantShell } from "@/components/merchant/MerchantUI";
type Draft = { _id: string; data: Record<string, unknown>; updatedAt: string };
export default function MerchantDashboard() {
  const { user, loading: authLoading } = useAuth();
  const { language } = useLanguage();
  const c = merchantCopy[language];
  const router = useRouter();
  const [merchant, setMerchant] = useState<MerchantRecord | null>(null);
  const [promotions, setPromotions] = useState<OfferRecord[]>([]);
  const [drafts, setDrafts] = useState<Draft[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [filter, setFilter] = useState("all");
  const [revision, setRevision] = useState(0);
  const account = user ? `${user._id}:${user.merchantId}` : "";
  useEffect(() => {
    if (authLoading) return;
    if (!user || user.role !== "merchant") {
      router.replace("/login?next=%2Fmerchant%2Fdashboard");
      return;
    }
    let active = true;
    setLoading(true);
    setError("");
    MerchantWorkspaceAPI.get()
      .then((w) => {
        if (active) {
          setMerchant(w.merchant);
          setPromotions(w.promotions);
          setDrafts(w.drafts);
        }
      })
      .catch((e) => {
        if (active) setError(e instanceof Error ? e.message : c.loadError);
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [authLoading, account, revision, router]);
  const statuses = [
    "all",
    "draft",
    "pending_review",
    "scheduled",
    "active",
    "expired",
    "rejected",
    "admin_paused",
  ];
  const shown = promotions.filter(
    (p) => filter === "all" || p.status === filter,
  );
  const visibleDrafts = filter === "all" || filter === "draft" ? drafts : [];
  return (
    <MerchantShell
      title={merchant?.name || c.workspace}
      subtitle={c.intro}
      actions={
        <>
          <Link
            className="mw-button mw-secondary"
            href="/merchant/dashboard/edit-profile"
          >
            <Store size={18} />
            {c.store}
          </Link>
          <Link className="mw-button" href="/merchant/dashboard/promotions/new">
            <Plus size={18} />
            {c.create}
          </Link>
        </>
      }
    >
      {loading ? (
        <p role="status">{c.loading}</p>
      ) : error ? (
        <div role="alert" className="mw-notice">
          {error}
          <button
            className="mw-button mw-secondary"
            onClick={() => setRevision((x) => x + 1)}
          >
            {c.retry}
          </button>
        </div>
      ) : (
        <>
          <div className="mw-stats">
            {["active", "pending_review", "scheduled", "draft"].map(
              (status) => (
                <button
                  className="mw-stat"
                  key={status}
                  onClick={() => setFilter(status)}
                >
                  <span>{c[status as keyof typeof c]}</span>
                  <strong>
                    {status === "draft"
                      ? drafts.length
                      : promotions.filter((p) => p.status === status).length}
                  </strong>
                </button>
              ),
            )}
          </div>
          <p className="mw-muted" style={{ marginBottom: 24 }}>
            {c.noMetrics}
          </p>
          <div className="mw-notice">{c.qr}</div>
          <section aria-label={c.promotions}>
            <div className="mw-heading">
              <h2>{c.promotions}</h2>
              <div className="mw-field">
                <label htmlFor="status-filter">{c.promotions}</label>
                <select
                  id="status-filter"
                  value={filter}
                  onChange={(e) => setFilter(e.target.value)}
                >
                  {statuses.map((s) => (
                    <option key={s} value={s}>
                      {c[s as keyof typeof c]}
                    </option>
                  ))}
                </select>
              </div>
            </div>
            <div className="mw-list">
              {visibleDrafts.map((d) => (
                <article className="mw-row" key={d._id}>
                  <div>
                    <span className="mw-eyebrow">
                      <FileText size={16} />
                      {c.draft}
                    </span>
                    <h3>{String(d.data.title || c.create)}</h3>
                    <p className="mw-muted">
                      {new Intl.DateTimeFormat(
                        language === "en" ? "en-LK" : language,
                        { dateStyle: "medium", timeZone: "Asia/Colombo" },
                      ).format(new Date(d.updatedAt))}
                    </p>
                  </div>
                  <Link
                    className="mw-button mw-secondary"
                    href={`/merchant/dashboard/promotions/new?draft=${d._id}`}
                  >
                    {c.resume}
                  </Link>
                </article>
              ))}
              {shown.map((p) => {
                const v = displayOffer({
                  ...p,
                  merchant: merchant || undefined,
                });
                return (
                  <article className="mw-row" key={v.id}>
                    <div>
                      <span className="mw-eyebrow">
                        {c[p.status as keyof typeof c] || String(p.status)}
                      </span>
                      <h3>{v.title}</h3>
                      <p className="mw-muted">{v.benefit}</p>
                    </div>
                    <div className="mw-actions">
                      {p.status === "active" && (
                        <Link className="mw-button mw-secondary" href={v.href}>
                          {c.preview}
                        </Link>
                      )}
                      <Link
                        className="mw-button mw-secondary"
                        href={`/merchant/dashboard/promotions/new?edit=${v.id}`}
                      >
                        {c.edit}
                      </Link>
                    </div>
                  </article>
                );
              })}
              {!shown.length && !visibleDrafts.length && (
                <div className="mw-panel">
                  <h3>{c.empty}</h3>
                  <Link
                    className="mw-button"
                    href="/merchant/dashboard/promotions/new"
                  >
                    {c.create}
                  </Link>
                </div>
              )}
            </div>
          </section>
        </>
      )}
    </MerchantShell>
  );
}
