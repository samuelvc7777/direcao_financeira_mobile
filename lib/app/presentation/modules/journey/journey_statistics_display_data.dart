class JourneyStatisticsDisplayData {
  const JourneyStatisticsDisplayData({
    required this.totalTime,
    required this.averageTime,
    required this.drivenKm,
  });

  final String totalTime;
  final String averageTime;
  final String drivenKm;
}

class JourneyStatisticsDisplayComposer {
  const JourneyStatisticsDisplayComposer._();

  static JourneyStatisticsDisplayData compose({
    required int baseTotalTimeSeconds,
    required double baseDrivenKm,
    required int shiftsCount,
    required int liveElapsedSeconds,
    required double liveDrivenKm,
    required bool includeLiveTime,
    required bool includeLiveKm,
  }) {
    final totalSeconds =
        baseTotalTimeSeconds + (includeLiveTime ? liveElapsedSeconds : 0);
    final totalKm = baseDrivenKm + (includeLiveKm ? liveDrivenKm : 0);

    return JourneyStatisticsDisplayData(
      totalTime: formatHms(totalSeconds),
      averageTime: shiftsCount <= 0
          ? '00:00:00'
          : formatHms((totalSeconds / shiftsCount).round()),
      drivenKm: '${totalKm.toStringAsFixed(1)} km',
    );
  }

  static int parseHmsToSeconds(String value) {
    final parts = value.split(':');
    if (parts.length != 3) {
      return 0;
    }

    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = int.tryParse(parts[2]) ?? 0;
    return (hours * 3600) + (minutes * 60) + seconds;
  }

  static double parseKmLabelToDouble(String value) {
    final normalized = value
        .replaceAll('km', '')
        .replaceAll('KM', '')
        .trim()
        .replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  static String formatHms(int totalSeconds) {
    final normalized = totalSeconds < 0 ? 0 : totalSeconds;
    final hours = normalized ~/ 3600;
    final minutes = (normalized % 3600) ~/ 60;
    final seconds = normalized % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
