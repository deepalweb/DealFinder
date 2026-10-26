export type OfferForm = {
  title: string;
  description: string;
  category: string;
  discount: string;
  code: string;
  startDate: string;
  endDate: string;
  images: string[];
  url: string;
  fulfillmentType: "visit" | "order" | "hybrid";
  orderLink: string;
  visitAvailable: boolean;
  deliveryAvailable: boolean;
  pickupAvailable: boolean;
  originalPrice: string;
  discountedPrice: string;
  bankName: string;
  cardTypes: string[];
  minimumSpend: string;
  maximumBenefit: string;
  termsAndConditions: string;
  benefitType: string;
  benefitValue: string;
};
export const emptyOffer: OfferForm = {
  title: "",
  description: "",
  category: "food_dining",
  discount: "",
  code: "",
  startDate: "",
  endDate: "",
  images: [],
  url: "",
  fulfillmentType: "visit",
  orderLink: "",
  visitAvailable: true,
  deliveryAvailable: false,
  pickupAvailable: false,
  originalPrice: "",
  discountedPrice: "",
  bankName: "",
  cardTypes: [],
  minimumSpend: "",
  maximumBenefit: "",
  termsAndConditions: "",
  benefitType: "other",
  benefitValue: "",
};
export function httpUrl(v: string) {
  try {
    const u = new URL(v);
    return (
      ["http:", "https:"].includes(u.protocol) &&
      !!u.hostname &&
      !u.username &&
      !u.password
    );
  } catch {
    return false;
  }
}
export function phone(v: string) {
  const p = v.replace(/[\s().-]/g, "");
  return /^0\d{9}$/.test(p) ? "+94" + p.slice(1) : p;
}
export function benefit(form: OfferForm, currency = "LKR") {
  if (form.benefitType === "percentage")
    return form.benefitValue ? `${form.benefitValue}% off` : "";
  if (form.benefitType === "fixed")
    return form.benefitValue ? `Save ${currency} ${form.benefitValue}` : "";
  if (form.benefitType === "special")
    return form.benefitValue ? `${currency} ${form.benefitValue}` : "";
  if (form.benefitType === "bogo") return form.discount || "Buy 1, get 1 free";
  return form.discount;
}
export function offerPayload(form: OfferForm, currency = "LKR") {
  const out = { ...form };
  const current =
    form.benefitType === "percentage" && form.originalPrice && form.benefitValue
      ? String(
          Math.round(
            Number(form.originalPrice) *
              (1 - Number(form.benefitValue) / 100) *
              100,
          ) / 100,
        )
      : form.benefitType === "special"
        ? form.benefitValue
        : form.discountedPrice;
  return {
    ...out,
    discount: benefit(form, currency),
    discountedPrice: ["fixed","bogo"].includes(form.benefitType) ? null : current || null,
    originalPrice: ["fixed","bogo"].includes(form.benefitType) ? null : form.originalPrice || null,
    minimumSpend: form.minimumSpend || null,
    maximumBenefit: form.maximumBenefit || null,
    visitAvailable: form.fulfillmentType !== "order",
  };
}
export function dateKey(value: unknown) {
  if (!value) return "";
  const d = new Date(String(value));
  if (!Number.isFinite(d.getTime())) return "";
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Colombo",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(d);
  return `${parts.find((x) => x.type === "year")?.value}-${parts.find((x) => x.type === "month")?.value}-${parts.find((x) => x.type === "day")?.value}`;
}
export function fromOffer(value: Record<string, unknown>): OfferForm {
  const out = { ...emptyOffer };
  for (const key of Object.keys(out) as (keyof OfferForm)[]) {
    const v = value[key];
    if (v !== undefined && v !== null)
      (out as Record<string, unknown>)[key] = Array.isArray(v)
        ? v
        : typeof v === "boolean"
          ? v
          : String(v);
  }
  out.startDate = dateKey(value.startDate);
  out.endDate = dateKey(value.endDate);
  const pct = /^(\d+(?:\.\d+)?)% off$/i.exec(out.discount);
  if (pct) {
    out.benefitType = "percentage";
    out.benefitValue = pct[1];
  }
  if (!out.images.length && typeof value.image === "string")
    out.images = [value.image];
  return out;
}
export function validateForm(f: OfferForm) {
  const e: Record<string, string> = {};
  for (const k of ["title", "description", "category"] as const)
    if (!f[k].trim()) e[k] = "requiredError";
  if (!benefit(f)) e.discount = "requiredError";
  if (
    f.benefitType === "percentage" &&
    (!Number.isFinite(Number(f.benefitValue)) ||
      Number(f.benefitValue) <= 0 ||
      Number(f.benefitValue) > 100)
  )
    e.benefitValue = "percentageError";
  if (
    ["fixed", "special"].includes(f.benefitType) &&
    (!f.benefitValue ||
      !Number.isFinite(Number(f.benefitValue)) ||
      Number(f.benefitValue) <= 0)
  )
    e.benefitValue = "numberError";
  for (const k of [
    "originalPrice",
    "discountedPrice",
    "minimumSpend",
    "maximumBenefit",
  ] as const)
    if (f[k] && (!Number.isFinite(Number(f[k])) || Number(f[k]) < 0))
      e[k] = "numberError";
  if (
    f.originalPrice &&
    f.discountedPrice &&
    f.benefitType !== "percentage" &&
    Number(f.discountedPrice) >= Number(f.originalPrice)
  )
    e.discountedPrice = "priceError";
  if(f.benefitType==='special' && f.originalPrice && Number(f.benefitValue)>=Number(f.originalPrice))e.benefitValue='priceError';
  if (!f.startDate) e.startDate = "requiredError";
  if (!f.endDate || f.endDate < f.startDate || f.endDate < dateKey(new Date()))
    e.endDate = "dateError";
  if (f.fulfillmentType !== "visit" && !httpUrl(f.orderLink))
    e.orderLink = "urlError";
  if (f.bankName && !f.cardTypes.length) e.cardTypes = "requiredError";
  if (f.cardTypes.length && !f.bankName) e.bankName = "requiredError";
  return e;
}
