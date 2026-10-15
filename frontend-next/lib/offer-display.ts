export type OfferKind = "promotion" | "bank";
export type MerchantRecord = {
  _id?: string;
  id?: string;
  name?: string;
  currency?: string;
  address?: string;
  orderLink?: string;
  deliveryAvailable?: boolean;
  pickupAvailable?: boolean;
  location?: { coordinates?: number[] };
  distance?: number;
};
export type OfferRecord = {
  _id?: string;
  id?: string;
  _offerKind?: OfferKind;
  title?: string;
  description?: string;
  image?: string;
  images?: string[];
  category?: string;
  merchant?: MerchantRecord | string;
  bankName?: string;
  cardTypes?: string[];
  offerType?: string;
  applicableCategories?: string[];
  discount?: string | number;
  price?: unknown;
  originalPrice?: unknown;
  discountedPrice?: unknown;
  minimumSpend?: unknown;
  maximumBenefit?: unknown;
  startDate?: string;
  endDate?: string;
  createdAt?: string;
  status?: string;
  featured?: boolean;
  code?: string;
  url?: string;
  websiteUrl?: string;
  orderLink?: string;
  fulfillmentType?: string;
  visitAvailable?: boolean;
  deliveryAvailable?: boolean;
  pickupAvailable?: boolean;
  termsAndConditions?: string;
  aiMeta?: { distanceKm?: number | null };
};
export function offerKind(offer: OfferRecord): OfferKind {
  return offer._offerKind === "bank" || offer.category === "bank_cards"
    ? "bank"
    : "promotion";
}
export function offerId(offer: OfferRecord) {
  return String(offer._id || offer.id || "");
}
export function offerHref(offer: OfferRecord) {
  return `/deal/${encodeURIComponent(offerId(offer))}${offerKind(offer) === "bank" ? "?kind=bank" : ""}`;
}
export function amount(value: unknown): number | null {
  if (
    value === null ||
    value === undefined ||
    typeof value === "boolean" ||
    (typeof value === "string" && !value.trim())
  )
    return null;
  const n = Number(value);
  return Number.isFinite(n) && n >= 0 ? n : null;
}
export function dateValue(value?: string, end = false): number | null {
  if (!value) return null;
  const raw = /^\d{4}-\d{2}-\d{2}$/.test(value)
    ? `${value}T${end ? "23:59:59.999" : "00:00:00.000"}+05:30`
    : value;
  const date = Date.parse(raw);
  return Number.isFinite(date) ? date : null;
}
export function isPublicOffer(
  offer: OfferRecord,
  now = Date.now(),
  includeExpired = false,
) {
  if (!offerId(offer)) return false;
  if (
    offer.status &&
    !["active", ...(includeExpired ? ["expired"] : [])].includes(offer.status)
  )
    return false;
  const local = new Date(now + 19800000);
  const dayStart =
    Date.UTC(local.getUTCFullYear(), local.getUTCMonth(), local.getUTCDate()) -
    19800000;
  const start = dateValue(offer.startDate);
  const end = dateValue(offer.endDate, true);
  return (
    (start === null || start < dayStart + 86400000) &&
    (includeExpired || end === null || end >= dayStart)
  );
}
export function percentage(offer: OfferRecord): number | null {
  // "Up to X%" is a cap, not a saving, so it does not count for sorting or filtering.
  const match = String(offer.discount ?? "").match(/^(\d+(?:\.\d+)?)\s*%/);
  return match ? Number(match[1]) : null;
}
export function formatPrice(value: number, currency = "LKR", locale = "en-LK") {
  return new Intl.NumberFormat(locale, {
    style: "currency",
    currency: /^[A-Z]{3}$/.test(currency) ? currency : "LKR",
    maximumFractionDigits: Number.isInteger(value) ? 0 : 2,
  }).format(value);
}
export function expiryLabel(value: string | undefined, language = "en") {
  const time = dateValue(value, true);
  return time === null
    ? null
    : new Intl.DateTimeFormat(language === "en" ? "en-LK" : language, {
        timeZone: "Asia/Colombo",
        day: "numeric",
        month: "short",
        year: "numeric",
      }).format(time);
}
export function safeImage(value?: string) {
  return value &&
    (value.startsWith("/assets/") ||
      /^https?:\/\//.test(value) ||
      /^data:image\//.test(value))
    ? value
    : "/assets/offer-placeholder.svg";
}
export function displayOffer(offer: OfferRecord) {
  const merchant = typeof offer.merchant === "object" ? offer.merchant : null;
  const current = amount(offer.discountedPrice) ?? amount(offer.price);
  const previous = amount(offer.originalPrice);
  return {
    id: offerId(offer),
    kind: offerKind(offer),
    href: offerHref(offer),
    merchantName: merchant?.name || offer.bankName || "",
    title: offer.title || "",
    currency: merchant?.currency || "LKR",
    price: current,
    previous:
      current !== null && previous !== null && previous > current
        ? previous
        : null,
    saving:
      current !== null && previous !== null && previous > current
        ? previous - current
        : null,
    minimum: amount(offer.minimumSpend),
    maximum: amount(offer.maximumBenefit),
    benefit: String(offer.discount ?? "").trim(),
    image: safeImage(offer.image || offer.images?.[0]),
    bank: !!offer.bankName || offerKind(offer) === "bank",
  };
}
export function safeReturn(value: string | null) {
  if (!value) return null;
  try {
    const path = decodeURIComponent(value.split(/[?#]/)[0]);
    return /^\/(?!\/)/.test(path) &&
      !/[\\\r\n]/.test(path) &&
      !/[\r\n]/.test(value)
      ? value
      : null;
  } catch {
    return null;
  }
}
export type Area = {
  label: string;
  latitude: number;
  longitude: number;
  radiusKm: number;
};
export function distanceKm(
  offer: OfferRecord,
  area: Area | null,
): number | null {
  const coordinates =
    typeof offer.merchant === "object"
      ? offer.merchant.location?.coordinates
      : null;
  if (
    !area ||
    !coordinates ||
    coordinates.length < 2 ||
    !coordinates.every(Number.isFinite)
  )
    return null;
  const [lng, lat] = coordinates;
  if (Math.abs(lat) > 90 || Math.abs(lng) > 180) return null;
  const rad = Math.PI / 180;
  const a =
    Math.sin(((lat - area.latitude) * rad) / 2) ** 2 +
    Math.cos(area.latitude * rad) *
      Math.cos(lat * rad) *
      Math.sin(((lng - area.longitude) * rad) / 2) ** 2;
  return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(Math.max(0, 1 - a)));
}
export function supports(offer: OfferRecord, mode: string) {
  if (!mode) return true;
  const merchant = typeof offer.merchant === "object" ? offer.merchant : null;
  if (mode === "delivery")
    return typeof offer.deliveryAvailable === "boolean"
      ? offer.deliveryAvailable
      : ["order", "order_online", "hybrid"].includes(
          offer.fulfillmentType || "",
        ) && merchant?.deliveryAvailable === true;
  if (mode === "pickup")
    return typeof offer.pickupAvailable === "boolean"
      ? offer.pickupAvailable
      : ["order", "order_online", "hybrid"].includes(
          offer.fulfillmentType || "",
        ) && merchant?.pickupAvailable === true;
  return (
    offer.visitAvailable === true ||
    ["visit", "visit_store", "hybrid"].includes(offer.fulfillmentType || "")
  );
}
