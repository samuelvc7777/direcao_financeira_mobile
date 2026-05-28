import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../core/errors/failures.dart';
import '../../core/network/api_error_mapper.dart';
import '../../core/network/api_request_logger.dart';
import '../../domain/entities/credit_card_entity.dart';
import '../../domain/repositories/i_credit_card_repository.dart';
import '../datasources/credit_card_datasource.dart';

class CreditCardRepository implements ICreditCardRepository {
  CreditCardRepository({
    required this.dataSource,
    required this.apiErrorMapper,
    required this.apiRequestLogger,
  });

  final ICreditCardDataSource dataSource;
  final ApiErrorMapper apiErrorMapper;
  final ApiRequestLogger apiRequestLogger;

  @override
  Future<Either<Failure, List<CreditCardEntity>>> getCreditCards() async {
    try {
      return Right(await dataSource.getCreditCards());
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'CreditCardRepository.getCreditCards',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao carregar cartoes de credito.',
        ),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'CreditCardRepository.getCreditCards',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao carregar cartoes de credito.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, CreditCardEntity>> createCreditCard({
    required String name,
    required String brand,
    required String color,
    required int limitCents,
    required int closingDay,
    required int dueDay,
    required String lastFourDigits,
  }) async {
    try {
      return Right(
        await dataSource.createCreditCard(
          name: name,
          brand: brand,
          color: color,
          limitCents: limitCents,
          closingDay: closingDay,
          dueDay: dueDay,
          lastFourDigits: lastFourDigits,
        ),
      );
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'CreditCardRepository.createCreditCard',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao criar cartao de credito.',
        ),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'CreditCardRepository.createCreditCard',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao criar cartao de credito.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, CreditCardEntity>> updateCreditCard({
    required int id,
    required String name,
    required String brand,
    required String color,
    required int limitCents,
    required int closingDay,
    required int dueDay,
    required String lastFourDigits,
    bool? isActive,
  }) async {
    try {
      return Right(
        await dataSource.updateCreditCard(
          id: id,
          name: name,
          brand: brand,
          color: color,
          limitCents: limitCents,
          closingDay: closingDay,
          dueDay: dueDay,
          lastFourDigits: lastFourDigits,
          isActive: isActive,
        ),
      );
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'CreditCardRepository.updateCreditCard',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao atualizar cartao de credito.',
        ),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'CreditCardRepository.updateCreditCard',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao atualizar cartao de credito.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deactivateCreditCard(int id) async {
    try {
      await dataSource.deactivateCreditCard(id);
      return const Right(null);
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'CreditCardRepository.deactivateCreditCard',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao desativar cartao de credito.',
        ),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'CreditCardRepository.deactivateCreditCard',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao desativar cartao de credito.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> reactivateCreditCard(int id) async {
    try {
      await dataSource.reactivateCreditCard(id);
      return const Right(null);
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'CreditCardRepository.reactivateCreditCard',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao reativar cartao de credito.',
        ),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'CreditCardRepository.reactivateCreditCard',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao reativar cartao de credito.',
        ),
      );
    }
  }
}
