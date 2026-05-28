import 'package:direcao_financeira_mobile/app/core/session/user_cache.dart';
import 'package:direcao_financeira_mobile/app/core/theme/app_theme.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/subscription_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/user_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/services/premium_access_policy.dart';
import 'package:direcao_financeira_mobile/app/presentation/widgets/premium_access_guard.dart';
import 'package:direcao_financeira_mobile/app/routes/app_pages.dart';
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
    expect(find.text('Assinatura premium'), findsOneWidget);
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
    expect(find.text('Assinatura premium'), findsOneWidget);
  });

  testWidgets('CTA do banner navega para assinatura', (tester) async {
    Get.put<UserCache>(_FakeUserCache(_user(activeSubscription: null)));

    await _pumpGuardApp(
      tester,
      onPressed: () => PremiumAccessGuard().run(() {}),
    );

    await tester.tap(find.text('Acao protegida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('VER ASSINATURA'));
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
    expect(find.text('Assinatura premium'), findsNothing);
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

    expect(find.text('Assinatura premium'), findsOneWidget);
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
