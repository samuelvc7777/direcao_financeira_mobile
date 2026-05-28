class SupabaseTimeRange {
  const SupabaseTimeRange({required this.start, required this.endExclusive});

  final DateTime start;
  final DateTime endExclusive;
}

class SupabaseTimeFilter {
  const SupabaseTimeFilter._();

  static SupabaseTimeRange resolve({
    required String filter,
    String? date,
    String? endDate,
  }) {
    final parsedDate = _parseDate(date) ?? DateTime.now();

    switch (filter) {
      case 'custom':
        final customStart = _parseDate(date) ?? parsedDate;
        final customEnd = _parseDate(endDate) ?? customStart;
        return SupabaseTimeRange(
          start: DateTime(customStart.year, customStart.month, customStart.day),
          endExclusive: DateTime(
            customEnd.year,
            customEnd.month,
            customEnd.day,
          ).add(const Duration(days: 1)),
        );
      case 'week':
        final startOfWeek = parsedDate.subtract(
          Duration(days: parsedDate.weekday - 1),
        );
        return SupabaseTimeRange(
          start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          endExclusive: DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day,
          ).add(const Duration(days: 7)),
        );
      case 'month':
        return SupabaseTimeRange(
          start: DateTime(parsedDate.year, parsedDate.month),
          endExclusive: DateTime(parsedDate.year, parsedDate.month + 1),
        );
      case 'year':
        return SupabaseTimeRange(
          start: DateTime(parsedDate.year),
          endExclusive: DateTime(parsedDate.year + 1),
        );
      case 'day':
      default:
        return SupabaseTimeRange(
          start: DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
          endExclusive: DateTime(
            parsedDate.year,
            parsedDate.month,
            parsedDate.day,
          ).add(const Duration(days: 1)),
        );
    }
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value)?.toLocal();
  }
}
