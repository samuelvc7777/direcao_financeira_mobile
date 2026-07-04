import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/referral_settings_entity.dart';

abstract class IReferralSettingsRepository {
  Future<Either<Failure, ReferralSettingsEntity>> getSettings();
}
