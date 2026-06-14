class TimeRestriction {
  final bool enabled;
  final int startHour; // 0-23
  final int startMinute; // 0-59
  final int endHour; // 0-23
  final int endMinute; // 0-59

  const TimeRestriction({
    required this.enabled,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  factory TimeRestriction.defaults() => const TimeRestriction(
        enabled: false,
        startHour: 6,
        startMinute: 0,
        endHour: 21,
        endMinute: 0,
      );

  /// Returns true when the restriction is disabled or [time] is within the
  /// allowed window. Supports overnight ranges (e.g. 22:00 to 06:00).
  bool isAllowed(DateTime time) {
    if (!enabled) return true;
    final current = time.hour * 60 + time.minute;
    final start = startHour * 60 + startMinute;
    final end = endHour * 60 + endMinute;
    if (start <= end) {
      return current >= start && current <= end;
    } else {
      // Overnight range
      return current >= start || current <= end;
    }
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
      };

  factory TimeRestriction.fromJson(Map<String, dynamic> json) {
    return TimeRestriction(
      enabled: json['enabled'] as bool? ?? false,
      startHour: json['startHour'] as int? ?? 6,
      startMinute: json['startMinute'] as int? ?? 0,
      endHour: json['endHour'] as int? ?? 21,
      endMinute: json['endMinute'] as int? ?? 0,
    );
  }
}
