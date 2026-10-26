"use client";
import { Suspense, useEffect, useRef, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { useAuth } from "@/contexts/AuthContext";
import { useLanguage } from "@/contexts/LanguageContext";
import { MerchantWorkspaceAPI, ApiError } from "@/lib/api";
import { merchantCopy } from "@/lib/merchant-copy";
import { DEALFINDER_CATEGORIES } from "@/lib/categories";
import { categoryName } from "@/lib/marketplace-copy";
import {
  emptyOffer,
  fromOffer,
  offerPayload,
  validateForm,
  type OfferForm,
} from "@/lib/merchant-form";
import {
  MerchantShell,
  Field,
  Errors,
  ImageUpload,
  useUnsaved,
} from "@/components/merchant/MerchantUI";
import OfferPreview from "@/components/merchant/OfferPreview";
import type { MerchantRecord } from "@/lib/offer-display";
import Link from "next/link";
function Editor() {
  const { user, loading: authLoading } = useAuth();
  const { language } = useLanguage();
  const c = merchantCopy[language];
  const router = useRouter();
  const params = useSearchParams();
  const draftId = params.get("draft");
  const editId = params.get("edit");
  const [form, setForm] = useState<OfferForm>(emptyOffer);
  const [baseline, setBaseline] = useState("");
  const [merchant, setMerchant] = useState<MerchantRecord | null>(null);
  const [key, setKey] = useState("");
  const [loaded, setLoaded] = useState(false);
  const [busy, setBusy] = useState(false);
  const [tab, setTab] = useState(0);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [message, setMessage] = useState("");
  const [failure, setFailure] = useState("");
  const [submitted, setSubmitted] = useState(false);
  const [recovered, setRecovered] = useState(false);
  const [uploadBusy, setUploadBusy] = useState(false);
  const [preview, setPreview] = useState(false);
  const guard = useRef(false);
  const account = user ? `${user._id}:${user.merchantId}` : "";
  const storageKey = account
    ? `df-offer-recovery:${account}:${draftId || editId || "new"}`
    : "";
  const dirty = loaded && !submitted && JSON.stringify(form) !== baseline;
  useUnsaved(dirty);
  useEffect(() => {
    if (authLoading) return;
    if (!user || user.role !== "merchant") {
      router.replace(
        "/login?next=" +
          encodeURIComponent(window.location.pathname + window.location.search),
      );
      return;
    }
    let active = true;
    setLoaded(false);
    setFailure("");
    setSubmitted(false);
    setRecovered(false);
    setMessage("");
    (async () => {
      try {
        const workspace = await MerchantWorkspaceAPI.get();
        let data: OfferForm = {
          ...emptyOffer,
          category: workspace.merchant.category || "food_dining",
          orderLink:
            workspace.merchant.orderLink || workspace.merchant.website || "",
          fulfillmentType:
            workspace.merchant.merchantType === "online"
              ? ("order" as const)
              : ("visit" as const),
        };
        let draftKey = crypto.randomUUID();
        let locked = false;
        if (draftId) {
          const d = await MerchantWorkspaceAPI.draft(draftId);
          data = fromOffer(d.data);
          draftKey = d.clientKey;
          locked = !!d.submittedAt;
        } else if (editId) {
          const source = workspace.promotions.find(
            (p: { _id: string }) => p._id === editId,
          );
          if (!source) throw new Error(c.loadError);
          if (
            String(
              typeof source.merchant === "object"
                ? source.merchant._id
                : source.merchant,
            ) !== String(workspace.merchant._id)
          )
            throw new Error(c.loadError);
          data = fromOffer(source);
        }
        if (!active) return;
        setMerchant(workspace.merchant);
        setBaseline(JSON.stringify(data));
        try {
          const recovery = JSON.parse(
            sessionStorage.getItem(storageKey) || "null",
          );
          if (
            recovery?.account === account &&
            recovery.merchantId === workspace.merchant._id &&
            recovery.form &&
            !locked
          ) {
            data = fromOffer(recovery.form);
            draftKey = recovery.key;
            setRecovered(true);
          }
        } catch {}
        setForm(data);
        setKey(draftKey);
        setSubmitted(locked);
        setLoaded(true);
      } catch (e) {
        if (active) setFailure(e instanceof Error ? e.message : c.loadError);
      }
    })();
    return () => {
      active = false;
    };
    // Primitive account key avoids reinitializing the form for unrelated auth updates.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [authLoading, account, draftId, editId, router]);
  useEffect(() => {
    if (loaded && !submitted && storageKey) {
      try {
        if (dirty)
          sessionStorage.setItem(
            storageKey,
            JSON.stringify({ account, merchantId: merchant?._id, key, form }),
          );
        else sessionStorage.removeItem(storageKey);
      } catch {}
    }
  }, [form, loaded, dirty, storageKey, account, key, submitted, merchant?._id]);
  function update<K extends keyof OfferForm>(k: K, v: OfferForm[K]) {
    setForm((p) => ({ ...p, [k]: v }));
    setMessage("");
  }
  const currency = merchant?.currency || "LKR";
  const payload = offerPayload(form, currency);
  const readiness = validateForm(form);
  const requiredKeys = [
    "title",
    "description",
    "discount",
    "startDate",
    "endDate",
    "category",
    ...(form.fulfillmentType !== "visit" ? ["orderLink"] : []),
    ...(["percentage", "fixed", "special"].includes(form.benefitType)
      ? ["benefitValue"]
      : []),
    ...(form.bankName ? ["cardTypes"] : []),
  ];
  const complete = requiredKeys.filter((k) => !readiness[k]).length;
  function focus(k: string) {
    const groups = [
      ["title", "description", "category", "fulfillmentType", "orderLink"],
      [
        "benefitValue",
        "discount",
        "originalPrice",
        "discountedPrice",
        "minimumSpend",
        "maximumBenefit",
        "bankName",
        "cardTypes",
        "termsAndConditions",
        "code",
      ],
      ["startDate", "endDate", "images"],
    ];
    const i = groups.findIndex((g) => g.includes(k));
    if (i >= 0) setTab(i);
  }
  async function save(submit = false) {
    if (guard.current || submitted || uploadBusy) return;
    setFailure("");
    setMessage("");
    if (submit) {
      const issues = validateForm(form);
      if (Object.keys(issues).length) {
        setErrors(
          Object.fromEntries(
            Object.entries(issues).map(([k, v]) => [k, c[v as keyof typeof c]]),
          ),
        );
        return;
      }
    }
    setErrors({});
    guard.current = true;
    setBusy(true);
    try {
      const draft = await MerchantWorkspaceAPI.save(key, payload);
      setBaseline(JSON.stringify(form));
      sessionStorage.removeItem(storageKey);
      if (submit) {
        const accepted = await MerchantWorkspaceAPI.submit(draft._id);
        if (!accepted.promotionId) throw new Error(c.saveError);
        setSubmitted(true);
        setMessage(c.submitted);
      } else {
        setMessage(c.saved);
        router.replace(`/merchant/dashboard/promotions/new?draft=${draft._id}`);
      }
    } catch (e) {
      setFailure(e instanceof Error ? e.message : c.saveError);
      if (
        e instanceof ApiError &&
        e.details &&
        !Array.isArray(e.details) &&
        typeof e.details === "object"
      ) {
        const messages: Record<string, string> = {
          required: c.requiredError,
          date: c.dateError,
          percentage: c.percentageError,
          number: c.numberError,
          price: c.priceError,
          percentagePrice: c.priceError,
          storeLocation: c.locationError,
          url: c.urlError,
          storeProfile: c.checkStore,
          storeContact: c.contactError,
        };
        setErrors(
          Object.fromEntries(
            Object.entries(e.details).map(([k, v]) => [
              k,
              messages[String(v)] || c.requiredError,
            ]),
          ),
        );
      }
    } finally {
      guard.current = false;
      setBusy(false);
    }
  }
  const field = (
    key: keyof OfferForm,
    label: string,
    type = "text",
    required = false,
    hint?: string,
  ) => (
    <Field
      id={key}
      label={label}
      required={required}
      error={errors[key]}
      hint={hint}
    >
      <input
        type={type}
        value={String(form[key])}
        onChange={(e) => update(key, e.target.value as never)}
      />
    </Field>
  );
  if (!loaded)
    return (
      <MerchantShell title={c.create}>
        {failure ? (
          <div role="alert" className="mw-notice">
            {failure}
            <button
              className="mw-button mw-secondary"
              onClick={() => window.location.reload()}
            >
              {c.retry}
            </button>
          </div>
        ) : (
          <p role="status">{c.loading}</p>
        )}
      </MerchantShell>
    );
  return (
    <MerchantShell
      title={editId ? c.edit : c.create}
      subtitle={c.editIntro}
      actions={
        <Link
          id="store"
          className="mw-button mw-secondary"
          href="/merchant/dashboard/edit-profile"
        >
          {c.store}
        </Link>
      }
    >
      {editId && <div className="mw-notice">{c.copyHint}</div>}
      {recovered && (
        <div role="status" className="mw-notice">
          {c.recovery}
        </div>
      )}
      {message && (
        <div role="status" className="mw-notice">
          {message}
        </div>
      )}
      {failure && (
        <div role="alert" className="mw-notice">
          {failure}
        </div>
      )}
      {submitted && !message && (
        <div className="mw-notice">
          {c.readOnly} <Link href="/merchant/dashboard">{c.back}</Link>
        </div>
      )}
      <Errors errors={errors} labels={c} onFocus={focus} />
      <div className="mw-grid">
        <form
          noValidate
          onSubmit={(e) => {
            e.preventDefault();
            void save(true);
          }}
        >
          <fieldset
            disabled={busy || submitted || uploadBusy}
            style={{ minWidth: 0 }}
          >
            <div className="mw-tabs" role="tablist" aria-label={c.create}>
              {[c.basics, c.benefit, c.schedule].map((label, i) => (
                <button
                  type="button"
                  role="tab"
                  key={i}
                  id={`offer-tab-${i}`}
                  aria-controls={`offer-panel-${i}`}
                  aria-selected={tab === i}
                  tabIndex={tab === i ? 0 : -1}
                  onClick={() => setTab(i)}
                  onKeyDown={(e) => {
                    if (
                      ["ArrowRight", "ArrowLeft", "Home", "End"].includes(e.key)
                    ) {
                      e.preventDefault();
                      const n =
                        e.key === "Home"
                          ? 0
                          : e.key === "End"
                            ? 2
                            : (tab + (e.key === "ArrowRight" ? 1 : 2)) % 3;
                      setTab(n);
                      document.getElementById(`offer-tab-${n}`)?.focus();
                    }
                  }}
                >
                  {label}
                </button>
              ))}
            </div>
            <section
              className="mw-panel"
              role="tabpanel"
              id={`offer-panel-${tab}`}
              aria-labelledby={`offer-tab-${tab}`}
            >
              {tab === 0 && (
                <>
                  <h2>{c.basics}</h2>
                  <div className="mw-fields">
                    <div className="mw-wide">
                      {field("title", c.title, "text", true)}
                    </div>
                    <Field
                      id="category"
                      label={c.category}
                      required
                      error={errors.category}
                    >
                      <select
                        value={form.category}
                        onChange={(e) => update("category", e.target.value)}
                      >
                        {DEALFINDER_CATEGORIES.filter(
                          (x) => !["all", "bank_cards"].includes(x.id),
                        ).map((x) => (
                          <option key={x.id} value={x.id}>
                            {categoryName(x.id, language, x.name)}
                          </option>
                        ))}
                      </select>
                    </Field>
                    <Field
                      id="fulfillmentType"
                      label={c.fulfillment}
                      required
                      error={errors.fulfillmentType}
                    >
                      <select
                        value={form.fulfillmentType}
                        onChange={(e) =>
                          update(
                            "fulfillmentType",
                            e.target.value as OfferForm["fulfillmentType"],
                          )
                        }
                      >
                        <option value="visit">{c.visit}</option>
                        <option value="order">{c.order}</option>
                        <option value="hybrid">{c.both}</option>
                      </select>
                    </Field>
                    <div className="mw-wide">
                      <Field
                        id="description"
                        label={c.description}
                        required
                        error={errors.description}
                      >
                        <textarea
                          maxLength={5000}
                          value={form.description}
                          onChange={(e) =>
                            update("description", e.target.value)
                          }
                        />
                      </Field>
                    </div>
                    {form.fulfillmentType !== "visit" && (
                      <div className="mw-wide">
                        {field("orderLink", c.orderLink, "url", true)}
                        <div className="mw-checks">
                          {(
                            ["deliveryAvailable", "pickupAvailable"] as const
                          ).map((k) => (
                            <label key={k}>
                              <input
                                type="checkbox"
                                checked={form[k]}
                                onChange={(e) => update(k, e.target.checked)}
                              />
                              {k === "deliveryAvailable"
                                ? c.delivery
                                : c.pickup}
                            </label>
                          ))}
                        </div>
                      </div>
                    )}
                    <div className="mw-wide mw-notice">
                      <strong>{merchant?.name}</strong>
                      <p>{String(merchant?.address || "")}</p>
                      <Link href="/merchant/dashboard/edit-profile">
                        {c.store}
                      </Link>
                    </div>
                  </div>
                </>
              )}
              {tab === 1 && (
                <>
                  <h2>{c.benefit}</h2>
                  <div className="mw-fields">
                    <Field id="benefitType" label={c.type}>
                      <select
                        value={form.benefitType}
                        onChange={(e) => update("benefitType", e.target.value)}
                      >
                        {[
                          "percentage",
                          "fixed",
                          "special",
                          "bogo",
                          "other",
                        ].map((t) => (
                          <option key={t} value={t}>
                            {c[t as keyof typeof c]}
                          </option>
                        ))}
                      </select>
                    </Field>
                    {["percentage", "fixed", "special"].includes(
                      form.benefitType,
                    )
                      ? field("benefitValue", c.value, "number", true)
                      : field("discount", c.discount, "text", true)}
                    {!["bogo", "other", "fixed"].includes(form.benefitType) &&
                      field("originalPrice", c.original, "number")}
                    {form.benefitType === "other" && (
                      <>
                        {field("originalPrice", c.original, "number")}
                        {field("discountedPrice", c.current, "number")}
                      </>
                    )}
                    {form.benefitType === "percentage" && (
                      <p className="mw-wide mw-muted">{c.benefitHint}</p>
                    )}
                    {field("minimumSpend", c.minimum, "number")}
                    {field("maximumBenefit", c.maximum, "number")}
                    <div className="mw-wide">
                      {field("bankName", c.bank, "text", false, c.bankHint)}
                    </div>
                    <div className="mw-wide">
                      <fieldset id="cardTypes" tabIndex={-1}>
                        <legend>{c.cards}</legend>
                        <div className="mw-checks">
                          {["credit", "debit", "prepaid"].map((t) => (
                            <label key={t}>
                              <input
                                type="checkbox"
                                checked={form.cardTypes.includes(t)}
                                onChange={() =>
                                  update(
                                    "cardTypes",
                                    form.cardTypes.includes(t)
                                      ? form.cardTypes.filter((x) => x !== t)
                                      : [...form.cardTypes, t],
                                  )
                                }
                              />
                              {c[t as keyof typeof c]}
                            </label>
                          ))}
                        </div>
                        {errors.cardTypes && (
                          <p className="mw-error">{errors.cardTypes}</p>
                        )}
                      </fieldset>
                    </div>
                    {field("code", c.code)}
                    <div className="mw-wide">
                      <Field
                        id="termsAndConditions"
                        label={c.terms}
                        hint={c.conditionHint}
                      >
                        <textarea
                          maxLength={5000}
                          value={form.termsAndConditions}
                          onChange={(e) =>
                            update("termsAndConditions", e.target.value)
                          }
                        />
                      </Field>
                    </div>
                  </div>
                </>
              )}
              {tab === 2 && (
                <>
                  <h2>{c.schedule}</h2>
                  <div className="mw-fields">
                    {field("startDate", c.start, "date", true)}
                    {field("endDate", c.end, "date", true)}
                    <p className="mw-wide mw-muted">{c.timezone}</p>
                    <div className="mw-wide">
                      <h3>{c.images}</h3>
                      <ImageUpload
                        images={form.images}
                        onChange={(v) => update("images", v)}
                        onBusy={setUploadBusy}
                      />
                    </div>
                  </div>
                </>
              )}
            </section>
            <div className="mw-footer">
              <div className="mw-actions">
                {tab > 0 && (
                  <button
                    type="button"
                    className="mw-button mw-secondary"
                    onClick={() => setTab(tab - 1)}
                  >
                    {c.previous}
                  </button>
                )}
                {tab < 2 && (
                  <button
                    type="button"
                    className="mw-button mw-secondary"
                    onClick={() => setTab(tab + 1)}
                  >
                    {c.next}
                  </button>
                )}
              </div>
              <p className="mw-muted">
                {dirty
                  ? c.unsaved
                  : submitted
                    ? c.done
                    : draftId
                      ? c.saved
                      : c.localOnly}
              </p>
            </div>
          </fieldset>
          <div className="mw-panel">
            <p className="mw-muted">
              {complete}/{requiredKeys.length} · {c.completion}
            </p>
            <progress
              aria-label={c.completion}
              value={complete}
              max={requiredKeys.length}
              style={{
                width: "100%",
                height: 8,
                accentColor: "var(--primary-color)",
                margin: "12px 0",
              }}
            />
            <p className="mw-muted">{c.reviewHint}</p>
            <div className="mw-actions" style={{ marginTop: 16 }}>
              <button
                type="button"
                className="mw-button mw-secondary"
                disabled={busy || submitted || uploadBusy}
                onClick={() => void save()}
              >
                {busy ? c.saving : c.saveDraft}
              </button>
              <button
                type="button"
                className="mw-button mw-secondary"
                onClick={() => {
                  setPreview(!preview);
                  if (!preview)
                    setTimeout(() => {
                      const target =
                        document.getElementById("customer-preview");
                      target?.focus({ preventScroll: true });
                      target?.scrollIntoView({
                        block: "start",
                        behavior: "instant",
                      });
                    }, 0);
                }}
                aria-expanded={preview}
              >
                {c.preview}
              </button>
              <button
                type="submit"
                className="mw-button"
                disabled={busy || submitted || uploadBusy}
              >
                {busy ? c.submitting : c.submit}
              </button>
            </div>
          </div>
        </form>
        <div
          id="customer-preview"
          tabIndex={-1}
          aria-label={c.preview}
          role="region"
          className={preview ? "" : "mw-preview-desktop"}
        >
          <OfferPreview
            offer={{
              ...payload,
              _id: "unpublished-preview",
              merchant: merchant || undefined,
            }}
          />
        </div>
      </div>
    </MerchantShell>
  );
}
export default function Page() {
  return (
    <Suspense fallback={<p>Loading…</p>}>
      <Editor />
    </Suspense>
  );
}
