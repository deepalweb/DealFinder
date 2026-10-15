"use client";
import { useEffect, useState, useRef } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/contexts/AuthContext";
import { useLanguage } from "@/contexts/LanguageContext";
import { MerchantAPI, MerchantWorkspaceAPI } from "@/lib/api";
import { merchantCopy } from "@/lib/merchant-copy";
import { DEALFINDER_CATEGORIES, normalizeCategoryId } from "@/lib/categories";
import { categoryName } from "@/lib/marketplace-copy";
import { CURRENCIES } from "@/lib/currency";
import { phone, httpUrl } from "@/lib/merchant-form";
import {
  MerchantShell,
  Field,
  Errors,
  ImageUpload,
  useUnsaved,
} from "@/components/merchant/MerchantUI";
import MapPicker from "@/components/ui/MapPicker";
import Link from "next/link";
type Hours = Record<string, { open: string; close: string; closed: boolean }>;
type StoreForm = {
  name: string;
  profile: string;
  category: string;
  currency: string;
  merchantType: string;
  website: string;
  orderLink: string;
  contactInfo: string;
  contactNumber: string;
  address: string;
  logo: string;
  banner: string;
  deliveryAvailable: boolean;
  pickupAvailable: boolean;
  socialMedia: Record<string, string>;
  openingHours: Hours;
  location: { type: "Point"; coordinates: number[] } | null;
};
const weekdays = [
  "monday",
  "tuesday",
  "wednesday",
  "thursday",
  "friday",
  "saturday",
  "sunday",
];
const empty: StoreForm = {
  name: "",
  profile: "",
  category: "food_dining",
  currency: "LKR",
  merchantType: "offline",
  website: "",
  orderLink: "",
  contactInfo: "",
  contactNumber: "",
  address: "",
  logo: "",
  banner: "",
  deliveryAvailable: false,
  pickupAvailable: false,
  socialMedia: { facebook: "", instagram: "", twitter: "", tiktok: "" },
  openingHours: {},
  location: null,
};
export default function StoreProfile() {
  const { user, loading: authLoading } = useAuth();
  const { language } = useLanguage();
  const c = merchantCopy[language];
  const router = useRouter();
  const [form, setForm] = useState<StoreForm>(empty);
  const [baseline, setBaseline] = useState("");
  const [id, setId] = useState("");
  const [loaded, setLoaded] = useState(false);
  const [busy, setBusy] = useState(false);
  const [uploadBusy, setUploadBusy] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [failure, setFailure] = useState("");
  const [message, setMessage] = useState("");
  const [recovered, setRecovered] = useState(false);
  const lock = useRef(false);
  const account = user ? `${user._id}:${user.merchantId}` : "";
  const recoveryKey = `df-store-recovery:${account}`;
  const dirty = loaded && JSON.stringify(form) !== baseline;
  useUnsaved(dirty);
  useEffect(() => {
    if (authLoading) return;
    if (!user || user.role !== "merchant") {
      router.replace("/login?next=%2Fmerchant%2Fdashboard%2Fedit-profile");
      return;
    }
    let active = true;
    setLoaded(false);
    setFailure("");
    (async () => {
      try {
        const w = await MerchantWorkspaceAPI.get();
        if (!active) return;
        const m = w.merchant;
        const data = {
          ...empty,
          ...Object.fromEntries(
            Object.keys(empty).map((k) => [
              k,
              m[k] ?? empty[k as keyof StoreForm],
            ]),
          ),
          category: normalizeCategoryId(m.category),
          profile: m.profile || m.description || "",
          socialMedia: { ...empty.socialMedia, ...m.socialMedia },
          openingHours: m.openingHours || {},
        } as StoreForm;
        setId(m._id);
        setBaseline(JSON.stringify(data));
        try {
          const recovery = JSON.parse(
            sessionStorage.getItem(recoveryKey) || "null",
          );
          if (recovery?.account === account && recovery.merchantId === m._id) {
            setForm({ ...data, ...recovery.form });
            setRecovered(true);
          } else setForm(data);
        } catch {
          setForm(data);
        }
        setLoaded(true);
      } catch (e) {
        if (active) setFailure(e instanceof Error ? e.message : c.loadError);
      }
    })();
    return () => {
      active = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [authLoading, account, router]);
  useEffect(() => {
    if (loaded && account)
      try {
        if (dirty)
          sessionStorage.setItem(
            recoveryKey,
            JSON.stringify({ account, merchantId: id, form }),
          );
        else sessionStorage.removeItem(recoveryKey);
      } catch {}
  }, [form, dirty, loaded, account, recoveryKey, id]);
  function update<K extends keyof StoreForm>(k: K, v: StoreForm[K]) {
    setForm((p) => ({ ...p, [k]: v }));
    setMessage("");
  }
  async function save() {
    if (lock.current || uploadBusy) return;
    const issues: Record<string, string> = {};
    for (const k of ["name", "category", "profile"] as const)
      if (!form[k].trim()) issues[k] = c.requiredError;
    for (const k of ["website", "orderLink"] as const)
      if (form[k] && !httpUrl(form[k])) issues[k] = c.urlError;
    if (!form.contactNumber && !form.contactInfo && !form.website && !Object.values(form.socialMedia).some(httpUrl))
      issues.contactNumber = c.contactError;
    if (
      form.contactInfo &&
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.contactInfo)
    )
      issues.contactInfo = c.contactError;
    if (
      form.contactNumber &&
      !/^\+?[1-9]\d{6,14}$/.test(phone(form.contactNumber))
    )
      issues.contactNumber = c.phoneError;
    if (form.merchantType !== "online") {
      if (!form.address.trim()) issues.address = c.requiredError;
      if (!form.location) issues.location = c.locationError;
    }
    if (
      form.merchantType !== "offline" &&
      !httpUrl(form.orderLink || form.website)
    )
      issues.orderLink = c.urlError;
    for (const [k, v] of Object.entries(form.socialMedia))
      if (v && !httpUrl(v)) issues[`social-${k}`] = c.urlError;
    for (const v of Object.values(form.openingHours))
      if (
        !v.closed &&
        ((v.open && !v.close) ||
          (!v.open && v.close) ||
          (v.open && v.close && v.close <= v.open))
      )
        issues.openingHours = c.dateError;
    setErrors(issues);
    if (Object.keys(issues).length) return;
    setFailure("");
    lock.current = true;
    setBusy(true);
    try {
      const payload = { ...form, contactNumber: phone(form.contactNumber) };
      const accepted = await MerchantAPI.update(id, {
        ...payload,
        description: form.profile,
      });
      if (!accepted._id && !accepted.id) throw new Error(c.saveError);
      setForm(payload);
      setBaseline(JSON.stringify(payload));
      sessionStorage.removeItem(recoveryKey);
      setMessage(c.saved);
    } catch (e) {
      setFailure(e instanceof Error ? e.message : c.saveError);
    } finally {
      setBusy(false);
      lock.current = false;
    }
  }
  const field = (
    k: keyof StoreForm,
    label: string,
    type = "text",
    required = false,
    hint?: string,
  ) => (
    <Field
      id={k}
      label={label}
      required={required}
      hint={hint}
      error={errors[k]}
    >
      <input
        type={type}
        value={String(form[k])}
        onChange={(e) => update(k, e.target.value as never)}
      />
    </Field>
  );
  if (!loaded)
    return (
      <MerchantShell title={c.store}>
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
      title={c.store}
      subtitle={c.storeIntro}
      actions={
        <Link className="mw-button mw-secondary" href={`/merchants/${id}`}>
          {c.viewStore}
        </Link>
      }
    >
      {recovered && <div className="mw-notice">{c.recovery}</div>}
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
      <Errors
        errors={errors}
        labels={{
          ...c,
          contactInfo: c.email,
          contactNumber: c.phone,
          openingHours: c.hours,
        }}
      />
      <form
        noValidate
        onSubmit={(e) => {
          e.preventDefault();
          void save();
        }}
      >
        <fieldset disabled={busy || uploadBusy} style={{ minWidth: 0 }}>
          <div className="mw-grid">
            <div>
              <section className="mw-panel">
                <h2>{c.identity}</h2>
                <div className="mw-fields">
                  {field("name", c.name, "text", true)}
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
                  <div className="mw-wide">
                    <Field
                      id="profile"
                      label={c.profile}
                      required
                      error={errors.profile}
                    >
                      <textarea
                        maxLength={500}
                        value={form.profile}
                        onChange={(e) => update("profile", e.target.value)}
                      />
                    </Field>
                  </div>
                  <Field id="merchantType" label={c.mode}>
                    <select
                      value={form.merchantType}
                      onChange={(e) => update("merchantType", e.target.value)}
                    >
                      {["offline", "online", "hybrid"].map((k) => (
                        <option key={k} value={k}>
                          {c[k as keyof typeof c]}
                        </option>
                      ))}
                    </select>
                  </Field>
                  <Field id="currency" label={c.currency}>
                    <select
                      value={form.currency}
                      onChange={(e) => update("currency", e.target.value)}
                    >
                      {CURRENCIES.map((x) => (
                        <option key={x.code} value={x.code}>
                          {x.code} · {x.name}
                        </option>
                      ))}
                    </select>
                  </Field>
                </div>
              </section>
              <section className="mw-panel">
                <h2>{c.contact}</h2>
                <p className="mw-muted" style={{ marginBottom: 20 }}>
                  {c.private}
                </p>
                <div className="mw-fields">
                  {field(
                    "contactNumber",
                    c.phone,
                    "tel",
                    false,
                    "+94 77 123 4567",
                  )}
                  {field("contactInfo", c.email, "email")}
                  {field("website", c.website, "url")}
                  {form.merchantType !== "offline" &&
                    field("orderLink", c.orderLink, "url", true)}
                </div>
                <details style={{ marginTop: 24 }}>
                  <summary>{c.social}</summary>
                  <p className="mw-muted">{c.socialHint}</p>
                  <div className="mw-fields" style={{ marginTop: 16 }}>
                    {Object.keys(form.socialMedia).map((k) => (
                      <Field
                        key={k}
                        id={`social-${k}`}
                        label={
                          k === "twitter"
                            ? "X / Twitter"
                            : k.charAt(0).toUpperCase() + k.slice(1)
                        }
                        error={errors[`social-${k}`]}
                      >
                        <input
                          type="url"
                          value={form.socialMedia[k]}
                          onChange={(e) =>
                            update("socialMedia", {
                              ...form.socialMedia,
                              [k]: e.target.value,
                            })
                          }
                        />
                      </Field>
                    ))}
                  </div>
                </details>
              </section>
              {form.merchantType !== "online" && (
                <section className="mw-panel">
                  <h2>{c.location}</h2>
                  {field("address", c.address, "text", true)}
                  <div id="location" tabIndex={-1} style={{ marginTop: 20 }}>
                    <h3>{c.map}</h3>
                    {errors.location && (
                      <p className="mw-error">{errors.location}</p>
                    )}
                    <MapPicker
                      lat={form.location?.coordinates[1] ?? null}
                      lng={form.location?.coordinates[0] ?? null}
                      onChange={(lat, lng) =>
                        update("location", {
                          type: "Point",
                          coordinates: [lng, lat],
                        })
                      }
                      height="300px"
                    />
                    {form.location && (
                      <p className="mw-muted">
                        {form.location.coordinates[1].toFixed(5)},{" "}
                        {form.location.coordinates[0].toFixed(5)}
                      </p>
                    )}
                  </div>
                  <details style={{ marginTop: 24 }}>
                    <summary>{c.hours}</summary>
                    <p className="mw-muted">{c.hoursHint}</p>
                    <div className="mw-hours" id="openingHours" tabIndex={-1}>
                      {weekdays.map((day, i) => {
                        const v = form.openingHours[day] || {
                          open: "",
                          close: "",
                          closed: false,
                        };
                        return (
                          <div key={day}>
                            <span>
                              {new Intl.DateTimeFormat(
                                language === "en" ? "en-LK" : language,
                                { weekday: "long" },
                              ).format(new Date(2026, 0, 5 + i))}
                            </span>
                            <Field id={`${day}-open`} label={c.open}>
                              <input
                                type="time"
                                disabled={v.closed}
                                value={v.open || ""}
                                onChange={(e) =>
                                  update("openingHours", {
                                    ...form.openingHours,
                                    [day]: { ...v, open: e.target.value },
                                  })
                                }
                              />
                            </Field>
                            <Field id={`${day}-close`} label={c.close}>
                              <input
                                type="time"
                                disabled={v.closed}
                                value={v.close || ""}
                                onChange={(e) =>
                                  update("openingHours", {
                                    ...form.openingHours,
                                    [day]: { ...v, close: e.target.value },
                                  })
                                }
                              />
                            </Field>
                            <label className="mw-checks">
                              <input
                                type="checkbox"
                                checked={v.closed}
                                onChange={(e) =>
                                  update("openingHours", {
                                    ...form.openingHours,
                                    [day]: { ...v, closed: e.target.checked },
                                  })
                                }
                              />
                              {c.closed}
                            </label>
                          </div>
                        );
                      })}
                    </div>
                    {errors.openingHours && (
                      <p className="mw-error">{errors.openingHours}</p>
                    )}
                  </details>
                </section>
              )}
            </div>
            <aside>
              <section className="mw-panel">
                <h2>{c.branding}</h2>
                <h3>{c.logo}</h3>
                <ImageUpload
                  images={form.logo ? [form.logo] : []}
                  onChange={(v) => update("logo", v[0] || "")}
                  max={1}
                  onBusy={setUploadBusy}
                />
                <h3 style={{ marginTop: 28 }}>{c.banner}</h3>
                <ImageUpload
                  images={form.banner ? [form.banner] : []}
                  onChange={(v) => update("banner", v[0] || "")}
                  max={1}
                  onBusy={setUploadBusy}
                />
              </section>
              <div className="mw-notice">
                <h3>{form.name || c.name}</h3>
                <p>{form.profile}</p>
                <p className="mw-muted">{c.storeIntro}</p>
              </div>
            </aside>
          </div>
        </fieldset>
        <div className="mw-footer">
          <p className="mw-muted">{dirty ? c.unsaved : message || ""}</p>
          <button
            className="mw-button"
            type="submit"
            disabled={busy || uploadBusy}
          >
            {busy ? c.saving : c.saveStore}
          </button>
        </div>
      </form>
    </MerchantShell>
  );
}
