import test from "node:test";
import assert from "node:assert/strict";
import {
  amount,
  displayOffer,
  offerHref,
  isPublicOffer,
  dateValue,
  percentage,
  distanceKm,
  safeReturn,
  supports,
} from "../lib/offer-display.ts";
test("missing prices and benefit caps never become prices or savings", () => {
  for (const value of [null, undefined, "", "  ", false, "not-a-price"])
    assert.equal(amount(value), null);
  const v = displayOffer({
    _id: "a",
    maximumBenefit: 3000,
    originalPrice: null,
    discountedPrice: "",
  });
  assert.equal(v.price, null);
  assert.equal(v.saving, null);
  assert.equal(v.maximum, 3000);
  assert.equal(
    displayOffer({ _id: "b", originalPrice: 3200, discountedPrice: 2400 })
      .saving,
    800,
  );
});
test("standalone bank records route separately while merchant card promotions stay promotions", () => {
  assert.equal(
    offerHref({ _id: "bank", _offerKind: "bank", bankName: "Bank" }),
    "/deal/bank?kind=bank",
  );
  assert.equal(
    offerHref({ _id: "promotion", bankName: "Bank", category: "food_dining" }),
    "/deal/promotion",
  );
});
test("lifecycle follows Colombo day boundaries and never exposes drafts or paused offers", () => {
  const now = Date.parse("2026-10-14T12:00:00+05:30");
  for (const status of ["draft", "scheduled", "admin_paused", "rejected"])
    assert.equal(isPublicOffer({ _id: "a", status }, now), false);
  assert.equal(
    isPublicOffer({ _id: "a", status: "active", endDate: "2026-10-14" }, now),
    true,
  );
  assert.equal(
    isPublicOffer({ _id: "a", status: "active", startDate: "2026-10-15" }, now),
    false,
  );
  assert.equal(
    isPublicOffer({ _id: "a", status: "active", endDate: "2026-10-13" }, now),
    false,
  );
  assert.equal(dateValue("invalid"), null);
  assert.equal(
    new Date(dateValue("2026-10-14", true)).toISOString(),
    "2026-10-14T18:29:59.999Z",
  );
});
test("percentage sorting excludes currency savings and BOGO wording", () => {
  assert.equal(percentage({ discount: "25% off" }), 25);
  assert.equal(percentage({ discount: "LKR 1500 off" }), null);
  assert.equal(percentage({ discount: "Buy 1 get 1" }), null);
});
test("distances require valid merchant coordinates and an explicit area", () => {
  const o = { merchant: { location: { coordinates: [79.854, 6.911] } } };
  const area = {
    label: "Colombo 03",
    latitude: 6.911,
    longitude: 79.854,
    radiusKm: 3,
  };
  assert.equal(distanceKm(o, null), null);
  assert.equal(distanceKm(o, area), 0);
  assert.equal(
    distanceKm({ merchant: { location: { coordinates: [0, 100] } } }, area),
    null,
  );
});
test("sign-in return paths reject external and encoded protocol-relative destinations", () => {
  for (const path of [
    "https://example.com",
    "//example.com",
    "/%2fexample.com",
    "/%5cexample.com",
    "/\\example.com",
  ])
    assert.equal(safeReturn(path), null);
  assert.equal(
    safeReturn("/categories/all?q=pizza"),
    "/categories/all?q=pizza",
  );
});
test("offer fulfillment restrictions take precedence over merchant capability", () => {
  const offer = {
    fulfillmentType: "visit",
    visitAvailable: true,
    deliveryAvailable: false,
    pickupAvailable: false,
    merchant: { deliveryAvailable: true, pickupAvailable: true },
  };
  assert.equal(supports(offer, "delivery"), false);
  assert.equal(supports(offer, "pickup"), false);
  assert.equal(supports(offer, "visit"), true);
});
