import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../core/errors/failures.dart';
import '../../core/network/api_error_mapper.dart';
import '../../core/network/api_request_logger.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/i_category_repository.dart';
import '../datasources/category_datasource.dart';

class CategoryRepository implements ICategoryRepository {
  CategoryRepository({
    required this.dataSource,
    required this.apiErrorMapper,
    required this.apiRequestLogger,
  });

  final ICategoryDataSource dataSource;
  final ApiErrorMapper apiErrorMapper;
  final ApiRequestLogger apiRequestLogger;

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    try {
      return Right(await dataSource.getCategories());
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'CategoryRepository.getCategories',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao carregar categorias.',
        ),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'CategoryRepository.getCategories',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao carregar categorias.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, CategoryEntity>> createCategory({
    required String name,
    required CategoryType type,
    required String color,
    required String icon,
  }) async {
    try {
      return Right(
        await dataSource.createCategory(
          name: name,
          type: type,
          color: color,
          icon: icon,
        ),
      );
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'CategoryRepository.createCategory',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(e, fallback: 'Erro ao criar categoria.'),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'CategoryRepository.createCategory',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao criar categoria.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, CategoryEntity>> updateCategory({
    required int id,
    required String name,
    required CategoryType type,
    required String color,
    required String icon,
  }) async {
    try {
      return Right(
        await dataSource.updateCategory(
          id: id,
          name: name,
          type: type,
          color: color,
          icon: icon,
        ),
      );
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'CategoryRepository.updateCategory',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao atualizar categoria.',
        ),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'CategoryRepository.updateCategory',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao atualizar categoria.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deactivateCategory(int id) async {
    try {
      await dataSource.deactivateCategory(id);
      return const Right(null);
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'CategoryRepository.deactivateCategory',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao desativar categoria.',
        ),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'CategoryRepository.deactivateCategory',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao desativar categoria.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> reactivateCategory(int id) async {
    try {
      await dataSource.reactivateCategory(id);
      return const Right(null);
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'CategoryRepository.reactivateCategory',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(e, fallback: 'Erro ao reativar categoria.'),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'CategoryRepository.reactivateCategory',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao reativar categoria.',
        ),
      );
    }
  }
}
