import '../../domain/entities/traffic_light_settings_entity.dart';

class TrafficLightSettingsModel extends TrafficLightSettingsEntity {
  TrafficLightSettingsModel({
    required super.position,
    required super.theme,
    required super.indicators,
    required super.monitoredApps,
    required super.fontSize,
    required super.opacity,
    required super.cardDuration,
    required super.colorBlindMode,
    required super.gainPerKmBad,
    required super.gainPerKmGood,
    required super.gainPerHourBad,
    required super.gainPerHourGood,
    required super.passengerRatingBad,
    required super.passengerRatingGood,
    required super.passengerRatingCustomized,
  });

  factory TrafficLightSettingsModel.fromJson(Map<String, dynamic> json) {
    return TrafficLightSettingsModel(
      position: TrafficLightPosition.values[json['position'] ?? 0],
      theme: TrafficLightTheme.values[json['theme'] ?? 1],
      indicators: Map<String, bool>.from(
        json['indicators'] ??
            {'R\$/Km': true, 'R\$/Hora': true, 'Lucro/H': true, 'Nota': true},
      ),
      monitoredApps: Map<String, bool>.from(
        json['monitoredApps'] ??
            {
              'Uber': true,
              '99': true,
              'inDrive': true,
              'MoveSj': true,
              'MeLevaSJ': false,
              'GooglePhotos': false,
            },
      ),
      fontSize: (json['fontSize'] ?? 12.0).toDouble(),
      opacity: (json['opacity'] ?? 100.0).toDouble(),
      cardDuration: (json['cardDuration'] ?? 10.0).toDouble(),
      colorBlindMode: json['colorBlindMode'] ?? false,
      gainPerKmBad: (json['gainPerKmBad'] ?? 1.57).toDouble(),
      gainPerKmGood: (json['gainPerKmGood'] ?? 2.60).toDouble(),
      gainPerHourBad: (json['gainPerHourBad'] ?? 19.67).toDouble(),
      gainPerHourGood: (json['gainPerHourGood'] ?? 32.50).toDouble(),
      passengerRatingBad: (json['passengerRatingBad'] ?? 4.6).toDouble(),
      passengerRatingGood: (json['passengerRatingGood'] ?? 5.0).toDouble(),
      passengerRatingCustomized: json['passengerRatingCustomized'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'position': position.index,
      'theme': theme.index,
      'indicators': indicators,
      'monitoredApps': monitoredApps,
      'fontSize': fontSize,
      'opacity': opacity,
      'cardDuration': cardDuration,
      'colorBlindMode': colorBlindMode,
      'gainPerKmBad': gainPerKmBad,
      'gainPerKmGood': gainPerKmGood,
      'gainPerHourBad': gainPerHourBad,
      'gainPerHourGood': gainPerHourGood,
      'passengerRatingBad': passengerRatingBad,
      'passengerRatingGood': passengerRatingGood,
      'passengerRatingCustomized': passengerRatingCustomized,
    };
  }

  factory TrafficLightSettingsModel.fromEntity(
    TrafficLightSettingsEntity entity,
  ) {
    return TrafficLightSettingsModel(
      position: entity.position,
      theme: entity.theme,
      indicators: entity.indicators,
      monitoredApps: entity.monitoredApps,
      fontSize: entity.fontSize,
      opacity: entity.opacity,
      cardDuration: entity.cardDuration,
      colorBlindMode: entity.colorBlindMode,
      gainPerKmBad: entity.gainPerKmBad,
      gainPerKmGood: entity.gainPerKmGood,
      gainPerHourBad: entity.gainPerHourBad,
      gainPerHourGood: entity.gainPerHourGood,
      passengerRatingBad: entity.passengerRatingBad,
      passengerRatingGood: entity.passengerRatingGood,
      passengerRatingCustomized: entity.passengerRatingCustomized,
    );
  }
}
