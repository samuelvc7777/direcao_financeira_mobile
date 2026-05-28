enum TrafficLightPosition { topo, esquerda, direita, rodape }

enum TrafficLightTheme { claro, escuro, verde }

class TrafficLightSettingsEntity {
  final TrafficLightPosition position;
  final TrafficLightTheme theme;
  final Map<String, bool> indicators;
  final Map<String, bool> monitoredApps;
  final double fontSize;
  final double opacity;
  final double cardDuration;
  final bool colorBlindMode;
  final double gainPerKmBad;
  final double gainPerKmGood;
  final double gainPerHourBad;
  final double gainPerHourGood;
  final double passengerRatingBad;
  final double passengerRatingGood;
  final bool passengerRatingCustomized;

  TrafficLightSettingsEntity({
    required this.position,
    required this.theme,
    required this.indicators,
    required this.monitoredApps,
    required this.fontSize,
    required this.opacity,
    required this.cardDuration,
    required this.colorBlindMode,
    required this.gainPerKmBad,
    required this.gainPerKmGood,
    required this.gainPerHourBad,
    required this.gainPerHourGood,
    required this.passengerRatingBad,
    required this.passengerRatingGood,
    required this.passengerRatingCustomized,
  });
}
