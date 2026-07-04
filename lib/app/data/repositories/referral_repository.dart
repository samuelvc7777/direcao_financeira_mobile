import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../../core/network/api_error_mapper.dart';
import '../../core/network/api_request_logger.dart';
import '../../domain/entities/referral_entity.dart';
import '../../domain/repositories/i_referral_repository.dart';
import '../datasources/referral_datasource.dart';

class ReferralRepository implements IReferralRepository {
  ReferralRepository({
    required this.remoteDataSource,
    required this.apiErrorMapper,
    required this.apiRequestLogger,
  });

  final IReferralRemoteDataSource remoteDataSource;
  final ApiErrorMapper apiErrorMapper;
  final ApiRequestLogger apiRequestLogger;

  @override
  Future<Either<Failure, ReferralSummaryEntity>> getSummary() async {
    try {
      return Right(await remoteDataSource.getSummary());
    } catch (e) {
      return Left(_mapFailure('ReferralRepository.getSummary', e));
    }
  }

  @override
  Future<Either<Failure, List<ReferralEntity>>> getReferrals() async {
    try {
      return Right(await remoteDataSource.getReferrals());
    } catch (e) {
      return Left(_mapFailure('ReferralRepository.getReferrals', e));
    }
  }

  @override
  Future<Either<Failure, List<PixWithdrawalEntity>>> getWithdrawals() async {
    try {
      return Right(await remoteDataSource.getWithdrawals());
    } catch (e) {
      return Left(_mapFailure('ReferralRepository.getWithdrawals', e));
    }
  }

  @override
  Future<Either<Failure, PixWithdrawalEntity>> requestPixWithdrawal({
    required int amountCents,
    required String cpf,
    required String pixKey,
  }) async {
    try {
      return Right(
        await remoteDataSource.requestPixWithdrawal(
          amountCents: amountCents,
          cpf: cpf,
          pixKey: pixKey,
        ),
      );
    } catch (e) {
      return Left(_mapFailure('ReferralRepository.requestPixWithdrawal', e));
    }
  }

  Failure _mapFailure(String source, Object error) {
    apiRequestLogger.logRepositoryFailure(source: source, error: error);
    if (error is PostgrestException) {
      return ServerFailure(error.message);
    }
    if (error is DioException) {
      return apiErrorMapper.mapToFailure(
        error,
        fallback: 'Erro ao carregar indicacoes.',
      );
    }
    return apiErrorMapper.mapToFailure(
      error,
      fallback: 'Erro inesperado ao carregar indicacoes.',
    );
  }
}
