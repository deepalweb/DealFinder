/// Store schedules use Colombo local time. Unknown/malformed hours remain unknown.
class MerchantHours {
  static const _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];
  static int? _minutes(dynamic value) {
    if (value is! String || !RegExp(r'^\d{1,2}:\d{2}$').hasMatch(value)) {
      return null;
    }
    final parts = value.split(':').map(int.parse).toList();
    if (parts[0] > 23 || parts[1] > 59) return null;
    return parts[0] * 60 + parts[1];
  }

  static bool? isOpen(Map<String, dynamic>? hours, {DateTime? now}) {
    if (hours == null) return null;
    final local = (now ?? DateTime.now())
        .toUtc()
        .add(const Duration(hours: 5, minutes: 30));
    final minutes = local.hour * 60 + local.minute;
    final previous = hours[_days[(local.weekday + 5) % 7]];
    if (previous is Map && previous['closed'] != true) {
      final open = _minutes(previous['open']);
      final close = _minutes(previous['close']);
      if (open != null && close != null && close < open && minutes < close) {
        return true;
      }
    }
    final today = hours[_days[local.weekday - 1]];
    if (today is! Map) return null;
    if (today['closed'] == true) return false;
    final open = _minutes(today['open']);
    final close = _minutes(today['close']);
    if (open == null || close == null || open == close) return null;
    return close < open ? minutes >= open : minutes >= open && minutes < close;
  }
}
