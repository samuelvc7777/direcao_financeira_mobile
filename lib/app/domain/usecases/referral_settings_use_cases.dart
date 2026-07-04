import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/referral_settings_entity.dart';
import '../repositories/i_referral_settings_repository.dart';

class GetReferralSettingsUseCase {
  const GetReferralSettingsUseCase(this.repository);

  final IReferralSettingsRepository repository;

  Future<Either<Failure, ReferralSettingsEntity>> call() {
    return repository.getSettings();
  }
}
