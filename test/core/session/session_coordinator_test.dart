import 'package:direcao_financeira_mobile/app/core/network/realtime_client.dart';
import 'package:direcao_financeira_mobile/app/core/session/authenticated_session.dart';
import 'package:direcao_financeira_mobile/app/core/session/session_coordinator.dart';
import 'package:direcao_financeira_mobile/app/core/session/session_store.dart';
import 'package:direcao_financeira_mobile/app/core/session/user_cache.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/user_entity.dart';
import 'package:direcao_financeira_mobile/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeSessionStore implements SessionStore {
  String? token;
  bool clearCalled = false;

  @override
  Future<void> clearToken() async {
    clearCalled = true;
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
  bool clearCalled = false;

  @override
  Future<void> clearUser() async {
    clearCalled = true;
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
    activeSubscription,
    subscriptions,
  }) async {}
}

class _FakeRealtimeClient implements RealtimeClient {
  @override
  final RxBool isOnline = true.obs;

  String? connectedToken;
  bool disconnectCalled = false;

  @override
  void connect({required String token}) {
    connectedToken = token;
    isOnline.value = true;
  }

  @override
  void disconnect() {
    disconnectCalled = true;
  }

  @override
  Future<void> dispose() async {}

  @override
  void off(String event, [void Function(dynamic payload)? handler]) {}

  @override
  void on(String event, void Function(dynamic payload) handler) {}
}

class _FakeRemoteSessionException implements Exception {}

UserEntity _buildUser() {
  return UserEntity(
    id: 1,
    email: 'samuel@example.com',
    name: 'Samuel',
    role: 'user',
    isActive: true,
  );
}

void main() {
  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  test(
    'handleAuthenticatedSession persiste sessao e conecta realtime',
    () async {
      final sessionStore = _FakeSessionStore();
      final userCache = _FakeUserCache();
      final realtimeClient = _FakeRealtimeClient();
      final coordinator = DefaultSessionCoordinator(
        sessionStore: sessionStore,
        userCache: userCache,
        realtimeClient: realtimeClient,
      );

      await coordinator.handleAuthenticatedSession(
        AuthenticatedSession(token: 'token-123', user: _buildUser()),
      );

      expect(sessionStore.token, 'token-123');
      expect(userCache.user?.email, 'samuel@example.com');
      expect(realtimeClient.connectedToken, 'token-123');
    },
  );

  test('logout limpa sessao local e desconecta realtime', () async {
    final sessionStore = _FakeSessionStore()..token = 'token-123';
    final userCache = _FakeUserCache()..user = _buildUser();
    final realtimeClient = _FakeRealtimeClient();
    final coordinator = DefaultSessionCoordinator(
      sessionStore: sessionStore,
      userCache: userCache,
      realtimeClient: realtimeClient,
    );

    await coordinator.logout();

    expect(sessionStore.clearCalled, isTrue);
    expect(userCache.clearCalled, isTrue);
    expect(realtimeClient.disconnectCalled, isTrue);
    expect(sessionStore.token, isNull);
    expect(userCache.user, isNull);
  });

  testWidgets(
    'restoreSession limpa sessao invalida e redireciona para login',
    (tester) async {
      final sessionStore = _FakeSessionStore()..token = 'token-invalido';
      final userCache = _FakeUserCache()..user = _buildUser();
      final realtimeClient = _FakeRealtimeClient();
      final coordinator = DefaultSessionCoordinator(
        sessionStore: sessionStore,
        userCache: userCache,
        realtimeClient: realtimeClient,
        restoreRemoteSession: (_) async {
          throw _FakeRemoteSessionException();
        },
      );

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.initial,
          getPages: [
            GetPage(
              name: AppRoutes.initial,
              page: () => const Scaffold(body: Text('Initial Screen')),
            ),
            GetPage(
              name: AppRoutes.login,
              page: () => const Scaffold(body: Text('Login Screen')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await coordinator.restoreSession();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(sessionStore.clearCalled, isTrue);
      expect(userCache.clearCalled, isTrue);
      expect(realtimeClient.disconnectCalled, isTrue);
      expect(Get.currentRoute, AppRoutes.login);
      expect(find.text('Login Screen'), findsOneWidget);
    },
  );

  testWidgets('expireSession encerra sessao e redireciona para login', (
    tester,
  ) async {
    final sessionStore = _FakeSessionStore()..token = 'token-123';
    final userCache = _FakeUserCache()..user = _buildUser();
    final realtimeClient = _FakeRealtimeClient();
    final coordinator = DefaultSessionCoordinator(
      sessionStore: sessionStore,
      userCache: userCache,
      realtimeClient: realtimeClient,
    );

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.initial,
        getPages: [
          GetPage(
            name: AppRoutes.initial,
            page: () => const Scaffold(body: Text('Initial Screen')),
          ),
          GetPage(
            name: AppRoutes.login,
            page: () => const Scaffold(body: Text('Login Screen')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await coordinator.expireSession();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(sessionStore.clearCalled, isTrue);
    expect(userCache.clearCalled, isTrue);
    expect(realtimeClient.disconnectCalled, isTrue);
    expect(Get.currentRoute, AppRoutes.login);
    expect(find.text('Login Screen'), findsOneWidget);
  });
}
