import 'package:get_storage/get_storage.dart';
import '../../domain/entities/traffic_light_settings_entity.dart';
import '../models/traffic_light_settings_model.dart';

abstract class ITrafficLightLocalDataSource {
  Future<TrafficLightSettingsModel> getSettings();
  Future<void> saveSettings(TrafficLightSettingsModel settings);
}

class TrafficLightLocalDataSourceImpl implements ITrafficLightLocalDataSource {
  final GetStorage storage;
  final String _key = 'traffic_light_settings';

  TrafficLightLocalDataSourceImpl({required this.storage});

  @override
  Future<TrafficLightSettingsModel> getSettings() async {
    final json = storage.read(_key);
    if (json == null) {
      return TrafficLightSettingsModel(
        position: TrafficLightPosition.topo,
        theme: TrafficLightTheme.escuro,
        indicators: {
          'R\$/Km': true,
          'R\$/Hora': true,
          'Lucro/H': true,
          'Nota': true,
        },
        monitoredApps: {
          'Uber': true,
          '99': true,
          'inDrive': true,
          'MoveSj': true,
          'MeLevaSJ': false,
          'GooglePhotos': false,
        },
        fontSize: 12.0,
        opacity: 100.0,
        cardDuration: 10.0,
        colorBlindMode: false,
        gainPerKmBad: 1.57,
        gainPerKmGood: 2.60,
        gainPerHourBad: 19.67,
        gainPerHourGood: 32.50,
        passengerRatingBad: 4.6,
        passengerRatingGood: 5.0,
        passengerRatingCustomized: false,
      );
    }
    return TrafficLightSettingsModel.fromJson(Map<String, dynamic>.from(json));
  }

  @override
  Future<void> saveSettings(TrafficLightSettingsModel settings) async {
    await storage.write(_key, settings.toJson());
  }
}
