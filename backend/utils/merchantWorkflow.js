const {
  normalizePromotionDateInput,
  getColomboDateKey,
} = require("./promotionLifecycle");
const CATEGORIES = [
  "shopping_retail",
  "electronics",
  "food_dining",
  "beauty_salon",
  "daily_essentials",
  "health_wellness",
  "repairs_services",
  "entertainment_activities",
  "education_courses",
  "auto_services",
  "other",
];
const FIELDS = [
  "benefitType",
  "benefitValue",
  "title",
  "description",
  "category",
  "discount",
  "code",
  "startDate",
  "endDate",
  "images",
  "url",
  "fulfillmentType",
  "orderLink",
  "visitAvailable",
  "deliveryAvailable",
  "pickupAvailable",
  "originalPrice",
  "discountedPrice",
  "bankName",
  "cardTypes",
  "minimumSpend",
  "maximumBenefit",
  "termsAndConditions",
];
function pickDraft(input) {
  const output = {};
  const numeric = new Set([
    "benefitValue",
    "originalPrice",
    "discountedPrice",
    "minimumSpend",
    "maximumBenefit",
  ]);
  for (const key of FIELDS)
    if (Object.hasOwn(input, key)) output[key] = input[key];
  for (const [key, value] of Object.entries(output)) {
    if (["images", "cardTypes"].includes(key)) {
      if (
        !Array.isArray(value) ||
        value.length > (key === "images" ? 5 : 3) ||
        value.some((x) => typeof x !== "string" || x.length > 2048)
      )
        throw new Error("Invalid " + key);
    } else if (
      ["visitAvailable", "deliveryAvailable", "pickupAvailable"].includes(key)
    ) {
      if (typeof value !== "boolean") throw new Error("Invalid " + key);
    } else if (!numeric.has(key) && typeof value !== "string") {
      throw new Error("Invalid " + key);
    } else if (
      typeof value !== "string" &&
      typeof value !== "number" &&
      value !== null
    )
      throw new Error("Invalid " + key);
    else if (
      typeof value === "string" &&
      value.length >
        (["description", "termsAndConditions"].includes(key) ? 5000 : 2048)
    )
      throw new Error("Field too long: " + key);
  }
  return output;
}
function httpUrl(value) {
  try {
    const u = new URL(value);
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
function normalizePhone(value) {
  let phone = String(value || "").replace(/[\s().-]/g, "");
  if (/^0\d{9}$/.test(phone)) phone = "+94" + phone.slice(1);
  return phone;
}
function validateOffer(data, merchant, now = new Date()) {
  const errors = {};
  if(data.benefitType==='special')data={...data,discountedPrice:data.benefitValue};
  if (
    data.benefitType &&
    !["percentage", "fixed", "special", "bogo", "other"].includes(
      data.benefitType,
    )
  )
    errors.discount = "required";
  if (
    ["percentage", "fixed", "special"].includes(data.benefitType) &&
    (!Number.isFinite(Number(data.benefitValue)) ||
      Number(data.benefitValue) <= 0 ||
      (data.benefitType === "percentage" && Number(data.benefitValue) > 100))
  )
    errors.discount = "percentage";
  for (const key of ["title", "description", "discount"])
    if (!String(data[key] || "").trim()) errors[key] = "required";
  if (!CATEGORIES.includes(data.category)) errors.category = "required";
  if (!["visit", "order", "hybrid"].includes(data.fulfillmentType))
    errors.fulfillmentType = "required";
  const s = normalizePromotionDateInput(data.startDate, "start"),
    e = normalizePromotionDateInput(data.endDate, "end");
  if (
    !s ||
    !Number.isFinite(s.getTime()) ||
    (/^\d{4}-\d{2}-\d{2}$/.test(data.startDate || "") &&
      getColomboDateKey(s) !== data.startDate)
  )
    errors.startDate = "date";
  if (
    !e ||
    !Number.isFinite(e.getTime()) ||
    e <= s ||
    e < now ||
    (/^\d{4}-\d{2}-\d{2}$/.test(data.endDate || "") &&
      Number.isFinite(e.getTime()) &&
      getColomboDateKey(e) !== data.endDate)
  )
    errors.endDate = "date";
  const percent = /^(\d+(?:\.\d+)?)% off$/i.exec(String(data.discount || ""));
  if (percent && (Number(percent[1]) <= 0 || Number(percent[1]) > 100))
    errors.discount = "percentage";
  for (const key of [
    "originalPrice",
    "discountedPrice",
    "minimumSpend",
    "maximumBenefit",
  ])
    if (
      data[key] !== undefined &&
      data[key] !== null &&
      data[key] !== "" &&
      (!Number.isFinite(Number(data[key])) || Number(data[key]) < 0)
    )
      errors[key] = "number";
  if (
    data.originalPrice !== undefined &&
    data.discountedPrice !== undefined &&
    data.originalPrice !== null &&
    data.discountedPrice !== null &&
    data.originalPrice !== "" &&
    data.discountedPrice !== "" &&
    Number(data.discountedPrice) >= Number(data.originalPrice)
  )
    errors.discountedPrice = "price";
  if (
    percent &&
    data.originalPrice > 0 &&
    data.discountedPrice !== undefined &&
    data.discountedPrice !== null &&
    data.discountedPrice !== "" &&
    Math.abs(
      Number(data.discountedPrice) -
        Number(data.originalPrice) * (1 - Number(percent[1]) / 100),
    ) > 0.01
  )
    errors.discountedPrice = "percentagePrice";
  if (["visit", "hybrid"].includes(data.fulfillmentType)) {
    const coords = merchant.location?.coordinates;
    if (
      merchant.merchantType === "online" ||
      !merchant.address?.trim() ||
      !Array.isArray(coords) ||
      coords.length !== 2 ||
      !coords.every(Number.isFinite) ||
      Math.abs(coords[0]) > 180 ||
      Math.abs(coords[1]) > 90
    )
      errors.fulfillmentType = "storeLocation";
  }
  if (
    ["order", "hybrid"].includes(data.fulfillmentType) &&
    !httpUrl(
      data.orderLink || data.url || merchant.orderLink || merchant.website,
    )
  )
    errors.orderLink = "url";
  for (const key of ["url", "orderLink"])
    if (data[key] && !httpUrl(data[key])) errors[key] = "url";
  if(data.benefitType==='fixed' && data.originalPrice!==null && data.originalPrice!==undefined && data.originalPrice!=='' && data.discountedPrice!==null && data.discountedPrice!==undefined && data.discountedPrice!=='' && Math.abs(Number(data.originalPrice)-Number(data.discountedPrice)-Number(data.benefitValue))>0.01)errors.discount='price';
  if (data.cardTypes?.some((x) => !["credit", "debit", "prepaid"].includes(x)))
    errors.cardTypes = "required";
  if (data.cardTypes?.length && !data.bankName?.trim())
    errors.bankName = "required";
  if (data.bankName?.trim() && !data.cardTypes?.length)
    errors.cardTypes = "required";
  if (
    !merchant.name?.trim() ||
    !(merchant.profile || merchant.description)?.trim() ||
    !merchant.category
  )
    errors.store = "storeProfile";
  if (
    !/^\+?[1-9]\d{6,14}$/.test(normalizePhone(merchant.contactNumber)) &&
    !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(merchant.contactInfo || "")) &&
    !httpUrl(merchant.website) &&
    !Object.values(merchant.socialMedia || {}).some(httpUrl)
  )
    errors.store = "storeContact";
  if (data.images?.some((x) => !httpUrl(x) && !x.startsWith("/assets/")))
    errors.images = "url";
  return errors;
}
function promotionPayload(data, merchant) {
  const out = pickDraft(data);
  const currency = merchant.currency || "LKR";
  if (out.benefitType === "percentage")
    out.discount = `${out.benefitValue}% off`;
  if (out.benefitType === "fixed")
    out.discount = `Save ${currency} ${out.benefitValue}`;
  if (out.benefitType === "special") {
    out.discount = `${currency} ${out.benefitValue}`;
    out.discountedPrice = out.benefitValue;
  }
  if (out.benefitType === "percentage" && out.originalPrice)
    out.discountedPrice =
      Math.round(
        Number(out.originalPrice) * (1 - Number(out.benefitValue) / 100) * 100,
      ) / 100;
  for (const key of [
    "originalPrice",
    "discountedPrice",
    "minimumSpend",
    "maximumBenefit",
  ]) {
    if (out[key] === null || out[key] === "" || out[key] === undefined)
      delete out[key];
    else out[key] = Number(out[key]);
  }
  return {
    ...out,
    code: out.code || "",
    image: out.images?.[0] || "",
    startDate: normalizePromotionDateInput(out.startDate, "start"),
    endDate: normalizePromotionDateInput(out.endDate, "end"),
    orderLink:
      out.orderLink || out.url || merchant.orderLink || merchant.website || "",
    merchant: merchant._id,
    status: "pending_review",
    featured: false,
    adminVerified: false,
  };
}
function owns(user, record) {
  return (
    user?.role === "admin" ||
    (user?.role === "merchant" &&
      String(user.merchantId) === String(record.merchant))
  );
}
// Offers from these stores never appear on public surfaces.
const HIDDEN_MERCHANT_STATUSES = ['suspended', 'rejected', 'pending_approval', 'needs_review'];
const isPublicMerchant = (merchant) => !!merchant && !HIDDEN_MERCHANT_STATUSES.includes(merchant.status);

module.exports = {
  HIDDEN_MERCHANT_STATUSES,
  isPublicMerchant,
  CATEGORIES,
  FIELDS,
  pickDraft,
  httpUrl,
  normalizePhone,
  validateOffer,
  promotionPayload,
  owns,
};
