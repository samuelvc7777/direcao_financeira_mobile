import 'package:direcao_financeira_mobile/app/core/session/user_cache.dart';
import 'package:direcao_financeira_mobile/app/core/theme/app_theme.dart';
import 'package:direcao_financeira_mobile/app/core/errors/failures.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/plan_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/store_product_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/store_purchase_event_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/subscription_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/user_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/repositories/i_subscription_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/services/premium_access_policy.dart';
import 'package:direcao_financeira_mobile/app/domain/usecases/subscription_use_cases.dart';
import 'package:direcao_financeira_mobile/app/presentation/widgets/premium_access_guard.dart';
import 'package:direcao_financeira_mobile/app/routes/app_pages.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
    PremiumAccessGuard.resetForTesting();
    Get.put<PremiumAccessPolicy>(const PremiumAccessPolicy());
  });

  tearDown(() {
    PremiumAccessGuard.resetForTesting();
    Get.reset();
  });

  testWidgets('bloqueia callback protegido quando nao ha assinatura', (
    tester,
  ) async {
    var called = false;
    Get.put<UserCache>(_FakeUserCache(_user(activeSubscription: null)));

    await _pumpGuardApp(
      tester,
      onPressed: () => PremiumAccessGuard().run(() {
        called = true;
      }),
    );

    await tester.tap(find.text('Acao protegida'));
    await tester.pumpAndSettle();

    expect(called, isFalse);
    expect(find.text('7 dias grátis'), findsOneWidget);
  });

  testWidgets('bloqueia callback protegido quando assinatura esta vencida', (
    tester,
  ) async {
    var called = false;
    Get.put<UserCache>(
      _FakeUserCache(
        _user(
          activeSubscription: _subscription(
            status: 'ACTIVE',
            endDate: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ),
      ),
    );

    await _pumpGuardApp(
      tester,
      onPressed: () => PremiumAccessGuard().run(() {
        called = true;
      }),
    );

    await tester.tap(find.text('Acao protegida'));
    await tester.pumpAndSettle();

    expect(called, isFalse);
    expect(find.text('7 dias grátis'), findsOneWidget);
  });

  testWidgets('CTA do banner navega para assinatura', (tester) async {
    Get.put<UserCache>(_FakeUserCache(_user(activeSubscription: null)));

    await _pumpGuardApp(
      tester,
      onPressed: () => PremiumAccessGuard().run(() {}),
    );

    await tester.tap(find.text('Acao protegida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver planos'));
    await tester.pumpAndSettle();

    expect(find.text('Tela de assinatura'), findsOneWidget);
  });

  testWidgets('executa callback com assinatura CANCELED vigente', (
    tester,
  ) async {
    var called = false;
    Get.put<UserCache>(
      _FakeUserCache(
        _user(
          activeSubscription: _subscription(
            status: 'CANCELED',
            endDate: DateTime.now().add(const Duration(days: 1)),
          ),
        ),
      ),
    );

    await _pumpGuardApp(
      tester,
      onPressed: () => PremiumAccessGuard().run(() {
        called = true;
      }),
    );

    await tester.tap(find.text('Acao protegida'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(find.text('7 dias grátis'), findsNothing);
  });

  testWidgets('nao empilha banners em toque repetido', (tester) async {
    Get.put<UserCache>(_FakeUserCache(_user(activeSubscription: null)));

    await _pumpGuardApp(
      tester,
      onPressed: () => PremiumAccessGuard().run(() {}),
    );

    await tester.tap(find.text('Acao protegida'));
    await tester.tap(find.text('Acao protegida'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('7 dias grátis'), findsOneWidget);
  });
  testWidgets('atualiza cache remoto antes de bloquear recurso premium', (
    tester,
  ) async {
    var called = false;
    final userCache = _FakeUserCache(_user(activeSubscription: null));
    final subscriptionRepository = _FakeSubscriptionRepository(userCache)
      ..activeSubscription = _subscription(
        status: 'ACTIVE',
        endDate: DateTime.now().add(const Duration(days: 7)),
      );
    Get.put<UserCache>(userCache);

    await _pumpGuardApp(
      tester,
      onPressed: () =>
          PremiumAccessGuard(
            getMySubscriptionUseCase: GetMySubscriptionUseCase(
              subscriptionRepository,
            ),
            syncStoredUserSubscriptionUseCase:
                SyncStoredUserSubscriptionUseCase(subscriptionRepository),
          ).run(() {
            called = true;
          }),
    );

    await tester.tap(find.text('Acao protegida'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(subscriptionRepository.syncStoredUserCalled, isTrue);
    expect(userCache.getUser()?.activeSubscription?.grantsAccess, isTrue);
    expect(find.text('7 dias grátis'), findsNothing);
  });
}

Future<void> _pumpGuardApp(
  WidgetTester tester, {
  required VoidCallback onPressed,
}) async {
  await tester.pumpWidget(
    GetMaterialApp(
      theme: AppTheme.dark,
      getPages: [
        GetPage(
          name: AppRoutes.subscription,
          page: () => const Scaffold(body: Text('Tela de assinatura')),
        ),
      ],
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: onPressed,
            child: const Text('Acao protegida'),
          ),
        ),
      ),
    ),
  );
}

UserEntity _user({required SubscriptionEntity? activeSubscription}) {
  return UserEntity(
    id: 1,
    email: 'samuel@example.com',
    name: 'Samuel',
    role: 'user',
    isActive: true,
    activeSubscription: activeSubscription,
  );
}

SubscriptionEntity _subscription({required String status, DateTime? endDate}) {
  return SubscriptionEntity(
    id: 1,
    status: status,
    startDate: DateTime.now().subtract(const Duration(days: 30)),
    endDate: endDate,
    autoRenew: true,
  );
}

class _FakeUserCache implements UserCache {
  _FakeUserCache(this.user);

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
  }) async {
    final currentUser = user;
    if (currentUser == null) {
      return;
    }

    user = UserEntity(
      id: currentUser.id,
      email: currentUser.email,
      name: currentUser.name,
      role: currentUser.role,
      isActive: currentUser.isActive,
      createdAt: currentUser.createdAt,
      updatedAt: currentUser.updatedAt,
      profilePhotoBase64: currentUser.profilePhotoBase64,
      activeSubscription: activeSubscription,
      subscriptions: subscriptions ?? currentUser.subscriptions,
    );
  }
}

class _FakeSubscriptionRepository implements ISubscriptionRepository {
  _FakeSubscriptionRepository(this.userCache);

  final UserCache userCache;
  SubscriptionEntity? activeSubscription;
  bool syncStoredUserCalled = false;

  @override
  Stream<StorePurchaseEventEntity> get purchaseUpdates => const Stream.empty();

  @override
  Future<Either<Failure, SubscriptionEntity?>> getMySubscription() async =>
      Right(activeSubscription);

  @override
  Future<Either<Failure, void>> syncStoredUser({
    SubscriptionEntity? activeSubscription,
    List<SubscriptionEntity>? subscriptions,
  }) async {
    syncStoredUserCalled = true;
    await userCache.syncUserSubscription(
      activeSubscription: activeSubscription,
      subscriptions: subscriptions,
    );
    return const Right(null);
  }

  @override
  Future<Either<Failure, SubscriptionEntity?>> cancelSubscription() async =>
      const Right(null);

  @override
  Future<Either<Failure, SubscriptionEntity?>> changePlan(int planId) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> completePurchase(String productId) async =>
      const Right(null);

  @override
  Future<Either<Failure, List<PlanEntity>>> getAvailablePlans() async =>
      const Right([]);

  @override
  Future<Either<Failure, List<SubscriptionEntity>>>
  getSubscriptionHistory() async => const Right([]);

  @override
  Future<Either<Failure, List<StoreProductEntity>>> getStoreProducts(
    Set<String> productIds,
  ) async => const Right([]);

  @override
  Future<Either<Failure, bool>> isStoreAvailable() async => const Right(false);

  @override
  Future<Either<Failure, SubscriptionEntity?>> renewSubscription({
    required bool autoRenew,
  }) async => const Right(null);

  @override
  Future<Either<Failure, void>> restorePurchases({
    String? applicationUserName,
  }) async => const Right(null);

  @override
  Future<Either<Failure, void>> buyProduct({
    required String productId,
    String? applicationUserName,
  }) async => const Right(null);

  @override
  Future<Either<Failure, SubscriptionEntity?>> syncStorePurchase({
    required int planId,
    required String productId,
    required String purchaseToken,
    String? purchaseId,
  }) async => const Right(null);
}
