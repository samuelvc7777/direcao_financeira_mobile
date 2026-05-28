import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/traffic_light_settings_entity.dart';
import '../repositories/i_traffic_light_repository.dart';

class GetTrafficLightSettingsUseCase {
  final ITrafficLightRepository repository;

  GetTrafficLightSettingsUseCase(this.repository);

  Future<Either<Failure, TrafficLightSettingsEntity>> call() {
    return repository.getSettings();
  }
}

class SaveTrafficLightSettingsUseCase {
  final ITrafficLightRepository repository;

  SaveTrafficLightSettingsUseCase(this.repository);

  Future<Either<Failure, void>> call(TrafficLightSettingsEntity settings) {
    return repository.saveSettings(settings);
  }
}
