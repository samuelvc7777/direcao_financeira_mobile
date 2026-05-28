import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/network/api_error_mapper.dart';
import '../../core/network/api_request_logger.dart';
import '../../domain/entities/costs_gains_settings_entity.dart';
import '../../domain/repositories/i_costs_gains_repository.dart';
import '../datasources/costs_gains_settings_datasource.dart';
import '../models/costs_gains_settings_model.dart';

class CostsGainsRepository implements ICostsGainsRepository {
  CostsGainsRepository({
    required this.dataSource,
    required this.apiErrorMapper,
    required this.apiRequestLogger,
  });

  final ICostsGainsSettingsDataSource dataSource;
  final ApiErrorMapper apiErrorMapper;
  final ApiRequestLogger apiRequestLogger;

  @override
  Future<Either<Failure, CostsGainsSettingsEntity?>>
  getCurrentUserSettings() async {
    try {
      return Right(await dataSource.getCurrentUserSettings());
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'CostsGainsRepository.getCurrentUserSettings',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao carregar configuracoes de custos e ganhos.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> hasCurrentUserSettings() async {
    try {
      return Right(await dataSource.hasCurrentUserSettings());
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'CostsGainsRepository.hasCurrentUserSettings',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao verificar configuracoes de custos e ganhos.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, CostsGainsSettingsEntity>> saveCurrentUserSettings(
    CostsGainsSettingsEntity entity,
  ) async {
    try {
      return Right(
        await dataSource.saveCurrentUserSettings(
          CostsGainsSettingsModel.fromEntity(entity),
        ),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'CostsGainsRepository.saveCurrentUserSettings',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao salvar configuracoes de custos e ganhos.',
        ),
      );
    }
  }
}
