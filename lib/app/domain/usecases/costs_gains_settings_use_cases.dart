import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/costs_gains_settings_entity.dart';
import '../repositories/i_costs_gains_repository.dart';

class GetCostsGainsSettingsUseCase {
  GetCostsGainsSettingsUseCase(this.repository);

  final ICostsGainsRepository repository;

  Future<Either<Failure, CostsGainsSettingsEntity?>> call() {
    return repository.getCurrentUserSettings();
  }
}

class HasCostsGainsSettingsUseCase {
  HasCostsGainsSettingsUseCase(this.repository);

  final ICostsGainsRepository repository;

  Future<Either<Failure, bool>> call() {
    return repository.hasCurrentUserSettings();
  }
}

class SaveCostsGainsSettingsUseCase {
  SaveCostsGainsSettingsUseCase(this.repository);

  final ICostsGainsRepository repository;

  Future<Either<Failure, CostsGainsSettingsEntity>> call(
    CostsGainsSettingsEntity entity,
  ) {
    return repository.saveCurrentUserSettings(entity);
  }
}
