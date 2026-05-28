import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../core/errors/failures.dart';
import '../../core/network/api_error_mapper.dart';
import '../../core/network/api_request_logger.dart';
import '../../core/session/session_coordinator.dart';
import '../../core/session/session_store.dart';
import '../../core/session/user_cache.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/auth_datasource.dart';
import '../models/user_model.dart';

class AuthRepository implements IAuthRepository {
  AuthRepository({
    required this.remoteDataSource,
    required this.sessionStore,
    required this.userCache,
    required this.sessionCoordinator,
    required this.apiErrorMapper,
    required this.apiRequestLogger,
  });

  final IAuthRemoteDataSource remoteDataSource;
  final SessionStore sessionStore;
  final UserCache userCache;
  final SessionCoordinator sessionCoordinator;
  final ApiErrorMapper apiErrorMapper;
  final ApiRequestLogger apiRequestLogger;

  @override
  Future<Either<Failure, UserEntity>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await remoteDataSource.login(
        email: email,
        password: password,
      );
      await sessionCoordinator.handleAuthenticatedSession(response);
      return Right(response.user);
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'AuthRepository.login',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(e, fallback: 'Erro ao realizar login.'),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'AuthRepository.login',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao realizar login.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await remoteDataSource.register(
        name: name,
        email: email,
        password: password,
      );
      await sessionCoordinator.handleAuthenticatedSession(response);
      return Right(response.user);
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'AuthRepository.register',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(e, fallback: 'Erro ao realizar cadastro.'),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'AuthRepository.register',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao realizar cadastro.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await remoteDataSource.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'AuthRepository.sendPasswordResetEmail',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao enviar recuperacao de senha.',
        ),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'AuthRepository.sendPasswordResetEmail',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao enviar recuperacao de senha.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> updatePassword(String password) async {
    try {
      await remoteDataSource.updatePassword(password: password);
      return const Right(null);
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'AuthRepository.updatePassword',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(e, fallback: 'Erro ao atualizar senha.'),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'AuthRepository.updatePassword',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao atualizar senha.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> saveToken(String token) async {
    try {
      await sessionStore.saveToken(token);
      return const Right(null);
    } catch (_) {
      return Left(DatabaseFailure('Erro ao salvar token.'));
    }
  }

  @override
  Future<Either<Failure, String?>> getToken() async {
    try {
      return Right(sessionStore.getToken());
    } catch (_) {
      return Left(DatabaseFailure('Erro ao ler token.'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfilePhotoBase64(
    String? profilePhotoBase64,
  ) async {
    try {
      final user = await remoteDataSource.updateProfilePhotoBase64(
        profilePhotoBase64: profilePhotoBase64,
      );
      await userCache.saveUser(user);
      return Right(user);
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'AuthRepository.updateProfilePhotoBase64',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao atualizar foto de perfil.',
        ),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'AuthRepository.updateProfilePhotoBase64',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao atualizar foto de perfil.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> saveUser(UserEntity user) async {
    try {
      final userModel = user is UserModel
          ? user
          : UserModel(
              id: user.id,
              email: user.email,
              name: user.name,
              role: user.role,
              isActive: user.isActive,
              createdAt: user.createdAt,
              updatedAt: user.updatedAt,
              profilePhotoBase64: user.profilePhotoBase64,
              activeSubscription: user.activeSubscription,
              subscriptions: user.subscriptions,
            );
      await userCache.saveUser(userModel);
      return const Right(null);
    } catch (_) {
      return Left(DatabaseFailure('Erro ao salvar dados do usuario.'));
    }
  }

  @override
  Either<Failure, UserEntity?> getStoredUser() {
    try {
      return Right(userCache.getUser());
    } catch (_) {
      return Left(DatabaseFailure('Erro ao ler dados do usuario.'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await sessionCoordinator.logout();
      return const Right(null);
    } catch (_) {
      return Left(DatabaseFailure('Erro ao fazer logout.'));
    }
  }
}
