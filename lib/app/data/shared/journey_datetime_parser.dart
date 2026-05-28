DateTime parseJourneyDateTimeToLocal(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw FormatException('Timestamp de jornada vazio.');
  }

  final hasTimezone = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(normalized);
  final parsed = DateTime.parse(hasTimezone ? normalized : '${normalized}Z');
  return parsed.toLocal();
}
