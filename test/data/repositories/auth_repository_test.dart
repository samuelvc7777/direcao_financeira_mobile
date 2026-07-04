import 'package:dartz/dartz.dart';
import 'package:direcao_financeira_mobile/app/core/errors/failures.dart';
import 'package:direcao_financeira_mobile/app/core/network/api_error_mapper.dart';
import 'package:direcao_financeira_mobile/app/core/network/api_request_logger.dart';
import 'package:direcao_financeira_mobile/app/core/session/authenticated_session.dart';
import 'package:direcao_financeira_mobile/app/core/session/session_coordinator.dart';
import 'package:direcao_financeira_mobile/app/core/session/session_store.dart';
import 'package:direcao_financeira_mobile/app/core/session/user_cache.dart';
import 'package:direcao_financeira_mobile/app/data/datasources/auth_datasource.dart';
import 'package:direcao_financeira_mobile/app/data/dtos/auth_session_dto.dart';
import 'package:direcao_financeira_mobile/app/data/models/user_model.dart';
import 'package:direcao_financeira_mobile/app/data/repositories/auth_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/subscription_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/dio_test_helpers.dart';
import '../../support/test_entities.dart';

class _FakeAuthRemoteDataSource implements IAuthRemoteDataSource {
  AuthSessionDto? loginResponse;
  AuthSessionDto? registerResponse;
  Object? loginError;
  Object? registerError;
  Object? passwordResetError;
  String? passwordResetEmail;
  String? updatedPassword;
  UserModel? updatedProfilePhotoResponse;
  String? updatedProfilePhotoBase64;

  @override
  Future<AuthSessionDto> login({
    required String email,
    required String password,
  }) async {
    if (loginError != null) {
      throw loginError!;
    }
    return loginResponse!;
  }

  @override
  Future<AuthSessionDto> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (registerError != null) {
      throw registerError!;
    }
    return registerResponse!;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    if (passwordResetError != null) {
      throw passwordResetError!;
    }
    passwordResetEmail = email;
  }

  @override
  Future<void> updatePassword({required String password}) async {
    updatedPassword = password;
  }

  @override
  Future<UserModel> updateProfilePhotoBase64({
    required String? profilePhotoBase64,
  }) async {
    updatedProfilePhotoBase64 = profilePhotoBase64;
    return updatedProfilePhotoResponse ?? buildUser();
  }
}

class _FakeSessionStore implements SessionStore {
  String? token;

  @override
  Future<void> clearToken() async {
    token = null;
  }

  @override
  String? getToken() => token;

  @override
  Future<void> saveToken(String token) async {
    this.token = token;
  }
}

class _FakeUserCache implements UserCache {
  UserEntity? user;

  @override
  Future<void> clearUser() async {
    user = null;
  }

  @override
  UserEntity? getUser() => user;

  @override
  Future<void> saveUser(UserEntity user) async {
    this.user = user;
  }

  @override
  Future<void> syncUserSubscription({
    SubscriptionEntity? activeSubscription,
    List<SubscriptionEntity>? subscriptions,
  }) async {}
}

class _FakeSessionCoordinator implements SessionCoordinator {
  AuthenticatedSession? authenticatedSession;
  bool logoutCalled = false;

  @override
  Future<void> expireSession({String? message}) async {}

  @override
  Future<void> handleAuthenticatedSession(AuthenticatedSession session) async {
    authenticatedSession = session;
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<void> restoreSession() async {}
}

void main() {
  late _FakeAuthRemoteDataSource remoteDataSource;
  late _FakeSessionStore sessionStore;
  late _FakeUserCache userCache;
  late _FakeSessionCoordinator sessionCoordinator;
  late AuthRepository repository;

  setUp(() {
    remoteDataSource = _FakeAuthRemoteDataSource();
    sessionStore = _FakeSessionStore();
    userCache = _FakeUserCache();
    sessionCoordinator = _FakeSessionCoordinator();
    repository = AuthRepository(
      remoteDataSource: remoteDataSource,
      sessionStore: sessionStore,
      userCache: userCache,
      sessionCoordinator: sessionCoordinator,
      apiErrorMapper: const ApiErrorMapper(),
      apiRequestLogger: ApiRequestLogger(
        apiErrorMapper: const ApiErrorMapper(),
      ),
    );
  });

  test('login retorna usuario e persiste sessao autenticada', () async {
    final user = buildUser();
    remoteDataSource.loginResponse = AuthSessionDto(
      token: 'token-123',
      user: user,
    );

    final result = await repository.login('samuel@example.com', '123456');

    expect(result, isA<Right<Failure, UserEntity>>());
    expect(sessionCoordinator.authenticatedSession?.token, 'token-123');
    expect(sessionCoordinator.authenticatedSession?.user.email, user.email);
  });

  test('login mapeia DioException com message da API', () async {
    remoteDataSource.loginError = dioBadResponse(
      statusCode: 401,
      data: {'message': 'Credenciais invalidas'},
      path: '/auth/login',
      method: 'POST',
    );

    final result = await repository.login('samuel@example.com', 'errada');

    expect(result.isLeft(), isTrue);
    expect(
      result.swap().getOrElse(() => ServerFailure('x')).message,
      'Credenciais invalidas',
    );
  });

  test('register usa fallback quando a API nao envia message', () async {
    remoteDataSource.registerError = dioBadResponse(
      statusCode: 500,
      data: {'error': 'boom'},
      path: '/auth/register',
      method: 'POST',
    );

    final result = await repository.register(
      'Samuel',
      'samuel@example.com',
      '123456',
    );

    expect(result.isLeft(), isTrue);
    expect(
      result.swap().getOrElse(() => ServerFailure('x')).message,
      'Erro ao realizar cadastro.',
    );
  });

  test('register mapeia falha inesperada', () async {
    remoteDataSource.registerError = Exception('falha');

    final result = await repository.register(
      'Samuel',
      'samuel@example.com',
      '123456',
    );

    expect(result.isLeft(), isTrue);
    expect(
      result.swap().getOrElse(() => ServerFailure('x')).message,
      'Erro inesperado ao realizar cadastro.',
    );
  });

  test('sendPasswordResetEmail delega envio para datasource', () async {
    final result = await repository.sendPasswordResetEmail(
      'samuel@example.com',
    );

    expect(result.isRight(), isTrue);
    expect(remoteDataSource.passwordResetEmail, 'samuel@example.com');
  });

  test('updateProfilePhotoBase64 salva foto no cache local', () async {
    final updatedUser = buildUser(profilePhotoBase64: 'foto-base64');
    remoteDataSource.updatedProfilePhotoResponse = updatedUser;

    final result = await repository.updateProfilePhotoBase64('foto-base64');

    expect(result.isRight(), isTrue);
    expect(remoteDataSource.updatedProfilePhotoBase64, 'foto-base64');
    expect(userCache.user?.profilePhotoBase64, 'foto-base64');
  });
}
