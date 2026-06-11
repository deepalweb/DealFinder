import 'package:flutter/material.dart';

import '../models/promotion.dart';
import '../services/search_matcher.dart';

class DealCapabilityPreset {
  final String id;
  final String label;
  final String description;
  final IconData icon;

  const DealCapabilityPreset({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
  });
}

const String capabilityDelivery = 'delivery';
const String capabilityPickup = 'pickup';
const String capabilityVisitStore = 'visit_store';
const String capabilityBudgetMeals = 'budget_meals';
const String capabilitySameDayService = 'same_day_service';
const String capabilityUnderRs2000 = 'under_rs_2000';
const String capabilityVerified = 'verified';
const String capabilityQrRedeemable = 'qr_redeemable';
const String capabilityEndingToday = 'ending_today';
const String capabilityHighestRated = 'highest_rated';
const String capabilityHideReported = 'hide_reported';

const List<DealCapabilityPreset> dealCapabilityPresets = [
  DealCapabilityPreset(
    id: capabilityDelivery,
    label: 'Delivery',
    description: 'Deals you can order in',
    icon: Icons.delivery_dining,
  ),
  DealCapabilityPreset(
    id: capabilityPickup,
    label: 'Pickup',
    description: 'Order ahead and collect fast',
    icon: Icons.shopping_bag_outlined,
  ),
  DealCapabilityPreset(
    id: capabilityVisitStore,
    label: 'Visit Store',
    description: 'Best for in-store browsing',
    icon: Icons.storefront_outlined,
  ),
  DealCapabilityPreset(
    id: capabilityBudgetMeals,
    label: 'Budget Meals',
    description: 'Food and cafe deals under Rs. 2000',
    icon: Icons.lunch_dining_outlined,
  ),
  DealCapabilityPreset(
    id: capabilitySameDayService,
    label: 'Same Day Service',
    description: 'Fast services and urgent fixes',
    icon: Icons.bolt_outlined,
  ),
  DealCapabilityPreset(
    id: capabilityUnderRs2000,
    label: 'Under Rs. 2000',
    description: 'Low-cost deals across categories',
    icon: Icons.currency_rupee,
  ),
  DealCapabilityPreset(
    id: capabilityVerified,
    label: 'Verified',
    description: 'Admin-verified and trusted deals',
    icon: Icons.verified_rounded,
  ),
  DealCapabilityPreset(
    id: capabilityQrRedeemable,
    label: 'QR Redeemable',
    description: 'In-store deals you can redeem with QR',
    icon: Icons.qr_code_2_rounded,
  ),
  DealCapabilityPreset(
    id: capabilityEndingToday,
    label: 'Ending Today',
    description: 'Deals expiring before midnight',
    icon: Icons.schedule_rounded,
  ),
  DealCapabilityPreset(
    id: capabilityHighestRated,
    label: 'Top Rated',
    description: 'Deals with strong user ratings',
    icon: Icons.star_rounded,
  ),
  DealCapabilityPreset(
    id: capabilityHideReported,
    label: 'Hide Reported',
    description: 'Remove deals with open issue reports',
    icon: Icons.report_off_outlined,
  ),
];

DealCapabilityPreset? findDealCapabilityPreset(String? id) {
  if (id == null || id.isEmpty) return null;
  for (final preset in dealCapabilityPresets) {
    if (preset.id == id) return preset;
  }
  return null;
}

double? effectivePromotionPrice(Promotion promotion) {
  return promotion.discountedPrice ??
      promotion.price ??
      promotion.originalPrice;
}

bool matchesDealCapabilityPreset(Promotion promotion, String presetId) {
  final normalizedCategory =
      SearchMatcher.normalizeCategory(promotion.category);
  final normalizedTitle = SearchMatcher.normalize(promotion.title);
  final normalizedDescription = SearchMatcher.normalize(promotion.description);
  final price = effectivePromotionPrice(promotion);

  switch (presetId) {
    case capabilityDelivery:
      return promotion.supportsDelivery;
    case capabilityPickup:
      return promotion.supportsPickup;
    case capabilityVisitStore:
      return promotion.supportsVisit;
    case capabilityBudgetMeals:
      return normalizedCategory == 'food_dining' &&
          price != null &&
          price <= 2000;
    case capabilitySameDayService:
      if (normalizedCategory != 'repairs_services') return false;
      const fastTerms = [
        'same day',
        'same day service',
        'today',
        'express',
        'quick',
        'urgent',
        'within hours',
      ];
      if (fastTerms.any(
        (term) =>
            normalizedTitle.contains(term) ||
            normalizedDescription.contains(term),
      )) {
        return true;
      }
      return promotion.supportsDelivery || promotion.supportsPickup;
    case capabilityUnderRs2000:
      return price != null && price <= 2000;
    case capabilityVerified:
      return promotion.trustStatus == 'verified' || promotion.adminVerified;
    case capabilityQrRedeemable:
      return promotion.supportsVisit && promotion.status != 'admin_paused';
    case capabilityEndingToday:
      final endDate = promotion.endDate;
      if (endDate == null) return false;
      final now = DateTime.now();
      final endOfToday = DateTime(now.year, now.month, now.day + 1);
      return endDate.isAfter(now) && endDate.isBefore(endOfToday);
    case capabilityHighestRated:
      return (promotion.averageRating ?? 0) >= 4 && promotion.ratingsCount > 0;
    case capabilityHideReported:
      return promotion.trustStatus != 'reported';
    default:
      return true;
  }
}
