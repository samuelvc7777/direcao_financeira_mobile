import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/costs_gains_settings_entity.dart';

abstract class ICostsGainsRepository {
  Future<Either<Failure, CostsGainsSettingsEntity?>> getCurrentUserSettings();
  Future<Either<Failure, bool>> hasCurrentUserSettings();
  Future<Either<Failure, CostsGainsSettingsEntity>> saveCurrentUserSettings(
    CostsGainsSettingsEntity entity,
  );
}
