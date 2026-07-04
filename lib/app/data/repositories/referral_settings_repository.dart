import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/network/api_error_mapper.dart';
import '../../core/network/api_request_logger.dart';
import '../../domain/entities/referral_settings_entity.dart';
import '../../domain/repositories/i_referral_settings_repository.dart';
import '../datasources/referral_settings_datasource.dart';

class ReferralSettingsRepository implements IReferralSettingsRepository {
  const ReferralSettingsRepository({
    required this.dataSource,
    required this.apiErrorMapper,
    required this.apiRequestLogger,
  });

  final IReferralSettingsDataSource dataSource;
  final ApiErrorMapper apiErrorMapper;
  final ApiRequestLogger apiRequestLogger;

  @override
  Future<Either<Failure, ReferralSettingsEntity>> getSettings() async {
    try {
      return Right(await dataSource.getSettings());
    } catch (error) {
      apiRequestLogger.logRepositoryFailure(
        source: 'ReferralSettingsRepository.getSettings',
        error: error,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          error,
          fallback: 'Nao foi possivel carregar as configuracoes de indicacao.',
        ),
      );
    }
  }
}
