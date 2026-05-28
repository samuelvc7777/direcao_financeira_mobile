import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/network/api_error_mapper.dart';
import '../../core/network/api_request_logger.dart';
import '../../domain/entities/google_api_config_entity.dart';
import '../../domain/repositories/i_google_api_config_repository.dart';
import '../datasources/google_api_config_datasource.dart';

class GoogleApiConfigRepository implements IGoogleApiConfigRepository {
  const GoogleApiConfigRepository({
    required this.dataSource,
    required this.apiErrorMapper,
    required this.apiRequestLogger,
  });

  final IGoogleApiConfigDataSource dataSource;
  final ApiErrorMapper apiErrorMapper;
  final ApiRequestLogger apiRequestLogger;

  @override
  Future<Either<Failure, GoogleApiConfigEntity?>> getConfig() async {
    try {
      return Right(await dataSource.getConfig());
    } catch (error) {
      apiRequestLogger.logRepositoryFailure(
        source: 'GoogleApiConfigRepository.getConfig',
        error: error,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          error,
          fallback: 'Nao foi possivel carregar a configuracao Google.',
        ),
      );
    }
  }
}
