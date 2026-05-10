import 'package:flutter/material.dart';

enum DealUrgencyTier {
  expired,
  endingNow,
  endingToday,
  endingSoon,
  active,
}

class DealExpiryHelper {
  // Shared urgency tiers:
  // expired     -> already ended
  // endingNow   -> less than 1 hour remaining
  // endingToday -> less than 24 hours remaining
  // endingSoon  -> 1 to 3 days remaining
  // active      -> more than 3 days remaining
  static Duration? remaining(DateTime? endDate, {DateTime? now}) {
    if (endDate == null) return null;
    final diff = endDate.difference(now ?? DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  static bool isExpired(DateTime? endDate, {DateTime? now}) {
    final value = remaining(endDate, now: now);
    return value != null && value == Duration.zero;
  }

  static String? formatCompact(DateTime? endDate, {DateTime? now}) {
    final diff = remaining(endDate, now: now);
    if (diff == null) return null;
    if (diff == Duration.zero) return 'Expired';

    if (diff.inDays >= 1) {
      final days = diff.inDays;
      final hours = diff.inHours % 24;
      return '${days}d ${hours}h';
    }

    if (diff.inHours >= 1) {
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      return '${hours}h ${minutes}m';
    }

    if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m';
    }

    return '<1m';
  }

  static String? formatWithSuffix(DateTime? endDate, {DateTime? now}) {
    final value = formatCompact(endDate, now: now);
    if (value == null || value == 'Expired') return value;
    return '$value left';
  }

  static bool isEndingToday(DateTime? endDate, {DateTime? now}) {
    if (endDate == null) return false;
    final current = now ?? DateTime.now();
    if (endDate.isBefore(current)) return false;
    final endOfToday = DateTime(current.year, current.month, current.day + 1);
    return endDate.isBefore(endOfToday);
  }

  static DealUrgencyTier tier(DateTime? endDate, {DateTime? now}) {
    final diff = remaining(endDate, now: now);
    if (diff == null) return DealUrgencyTier.active;
    if (diff == Duration.zero) return DealUrgencyTier.expired;
    if (diff.inHours < 1) return DealUrgencyTier.endingNow;
    if (diff.inHours < 24) return DealUrgencyTier.endingToday;
    if (diff.inDays <= 3) return DealUrgencyTier.endingSoon;
    return DealUrgencyTier.active;
  }

  static Color urgencyColor(BuildContext context, DateTime? endDate) {
    switch (tier(endDate)) {
      case DealUrgencyTier.expired:
        return const Color(0xFF475467);
      case DealUrgencyTier.endingNow:
      case DealUrgencyTier.endingToday:
        return const Color(0xFFB42318);
      case DealUrgencyTier.endingSoon:
        return const Color(0xFF9A3412);
      case DealUrgencyTier.active:
        return const Color(0xFF475467);
    }
  }

  static Color urgencyBackgroundColor(DateTime? endDate) {
    switch (tier(endDate)) {
      case DealUrgencyTier.expired:
        return const Color(0xFFF2F4F7);
      case DealUrgencyTier.endingNow:
      case DealUrgencyTier.endingToday:
        return const Color(0xFFFEF3F2);
      case DealUrgencyTier.endingSoon:
        return const Color(0xFFFFF4ED);
      case DealUrgencyTier.active:
        return const Color(0xFFF2F4F7);
    }
  }

  static Color urgencyBorderColor(DateTime? endDate) {
    switch (tier(endDate)) {
      case DealUrgencyTier.expired:
        return const Color(0xFFD0D5DD);
      case DealUrgencyTier.endingNow:
      case DealUrgencyTier.endingToday:
        return const Color(0xFFFDA29B);
      case DealUrgencyTier.endingSoon:
        return const Color(0xFFF9B189);
      case DealUrgencyTier.active:
        return const Color(0xFFD0D5DD);
    }
  }
}
