import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../core/errors/failures.dart';
import '../../core/network/api_error_mapper.dart';
import '../../core/network/api_request_logger.dart';
import '../../domain/entities/goal_entity.dart';
import '../../domain/repositories/i_goal_repository.dart';
import '../datasources/goal_datasource.dart';

class GoalRepository implements IGoalRepository {
  GoalRepository({
    required this.dataSource,
    required this.apiErrorMapper,
    required this.apiRequestLogger,
  });

  final IGoalDataSource dataSource;
  final ApiErrorMapper apiErrorMapper;
  final ApiRequestLogger apiRequestLogger;

  @override
  Future<Either<Failure, List<GoalEntity>>> getGoals() async {
    try {
      return Right(await dataSource.getGoals());
    } on DioException catch (error) {
      return Left(
        _mapFailure(
          'GoalRepository.getGoals',
          error,
          'Erro ao carregar metas.',
        ),
      );
    } catch (error) {
      return Left(
        _mapFailure(
          'GoalRepository.getGoals',
          error,
          'Erro inesperado ao carregar metas.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, GoalEntity>> createGoal({
    required String name,
    String? description,
    required int targetAmountCents,
    int currentAmountCents = 0,
    DateTime? targetDate,
  }) async {
    final validation = _validate(name, targetAmountCents, currentAmountCents);
    if (validation != null) {
      return Left(validation);
    }

    try {
      return Right(
        await dataSource.createGoal(
          name: name.trim(),
          description: _normalizeDescription(description),
          targetAmountCents: targetAmountCents,
          currentAmountCents: currentAmountCents,
          targetDate: targetDate,
        ),
      );
    } on DioException catch (error) {
      return Left(
        _mapFailure('GoalRepository.createGoal', error, 'Erro ao criar meta.'),
      );
    } catch (error) {
      return Left(
        _mapFailure(
          'GoalRepository.createGoal',
          error,
          'Erro inesperado ao criar meta.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, GoalEntity>> updateGoal({
    required int id,
    required String name,
    String? description,
    required int targetAmountCents,
    required int currentAmountCents,
    DateTime? targetDate,
  }) async {
    final validation = _validate(name, targetAmountCents, currentAmountCents);
    if (validation != null) {
      return Left(validation);
    }

    try {
      return Right(
        await dataSource.updateGoal(
          id: id,
          name: name.trim(),
          description: _normalizeDescription(description),
          targetAmountCents: targetAmountCents,
          currentAmountCents: currentAmountCents,
          targetDate: targetDate,
        ),
      );
    } on DioException catch (error) {
      return Left(
        _mapFailure(
          'GoalRepository.updateGoal',
          error,
          'Erro ao atualizar meta.',
        ),
      );
    } catch (error) {
      return Left(
        _mapFailure(
          'GoalRepository.updateGoal',
          error,
          'Erro inesperado ao atualizar meta.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, GoalEntity>> completeGoal(int id) async {
    try {
      return Right(await dataSource.completeGoal(id));
    } on DioException catch (error) {
      return Left(
        _mapFailure(
          'GoalRepository.completeGoal',
          error,
          'Erro ao concluir meta.',
        ),
      );
    } catch (error) {
      return Left(
        _mapFailure(
          'GoalRepository.completeGoal',
          error,
          'Erro inesperado ao concluir meta.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, GoalEntity>> archiveGoal(int id) async {
    try {
      return Right(await dataSource.archiveGoal(id));
    } on DioException catch (error) {
      return Left(
        _mapFailure(
          'GoalRepository.archiveGoal',
          error,
          'Erro ao arquivar meta.',
        ),
      );
    } catch (error) {
      return Left(
        _mapFailure(
          'GoalRepository.archiveGoal',
          error,
          'Erro inesperado ao arquivar meta.',
        ),
      );
    }
  }

  Failure? _validate(
    String name,
    int targetAmountCents,
    int currentAmountCents,
  ) {
    if (name.trim().isEmpty) {
      return ValidationFailure('Informe o nome da meta.');
    }

    if (targetAmountCents <= 0) {
      return ValidationFailure('Informe um objetivo maior que zero.');
    }

    if (currentAmountCents < 0) {
      return ValidationFailure('O valor atual nao pode ser negativo.');
    }

    return null;
  }

  String? _normalizeDescription(String? description) {
    final value = description?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  Failure _mapFailure(String source, Object error, String fallback) {
    apiRequestLogger.logRepositoryFailure(source: source, error: error);
    return apiErrorMapper.mapToFailure(error, fallback: fallback);
  }
}
