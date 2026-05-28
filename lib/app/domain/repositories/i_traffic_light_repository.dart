import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/traffic_light_settings_entity.dart';

abstract class ITrafficLightRepository {
  Future<Either<Failure, TrafficLightSettingsEntity>> getSettings();
  Future<Either<Failure, void>> saveSettings(TrafficLightSettingsEntity settings);
}
