import 'package:direcao_financeira_mobile/app/core/session/user_cache.dart';
import 'package:direcao_financeira_mobile/app/core/subscription/subscription_access_gate.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/subscription_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

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
    final current = user;
    if (current == null) {
      return;
    }

    user = UserEntity(
      id: current.id,
      email: current.email,
      name: current.name,
      role: current.role,
      isActive: current.isActive,
      activeSubscription: activeSubscription,
      subscriptions: subscriptions ?? current.subscriptions,
    );
  }
}

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  test('libera assinatura cancelada ate a data final', () {
    Get.put<UserCache>(
      _FakeUserCache(
        _buildUser(
          _buildSubscription(
            status: 'CANCELED',
            endDate: DateTime.now().add(const Duration(days: 3)),
          ),
        ),
      ),
    );

    expect(SubscriptionAccessGate.hasActivePlan, isTrue);
  });

  test('bloqueia assinatura cancelada depois da data final', () {
    Get.put<UserCache>(
      _FakeUserCache(
        _buildUser(
          _buildSubscription(
            status: 'CANCELED',
            endDate: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ),
      ),
    );

    expect(SubscriptionAccessGate.hasActivePlan, isFalse);
  });

  test('bloqueia assinatura expirada mesmo com data futura', () {
    Get.put<UserCache>(
      _FakeUserCache(
        _buildUser(
          _buildSubscription(
            status: 'EXPIRED',
            endDate: DateTime.now().add(const Duration(days: 3)),
          ),
        ),
      ),
    );

    expect(SubscriptionAccessGate.hasActivePlan, isFalse);
  });
}

UserEntity _buildUser(SubscriptionEntity? activeSubscription) {
  return UserEntity(
    id: 1,
    email: 'samuel@example.com',
    name: 'Samuel',
    role: 'user',
    isActive: true,
    activeSubscription: activeSubscription,
  );
}

SubscriptionEntity _buildSubscription({
  required String status,
  required DateTime? endDate,
}) {
  return SubscriptionEntity(
    id: 1,
    status: status,
    startDate: DateTime.now().subtract(const Duration(days: 10)),
    endDate: endDate,
    autoRenew: false,
  );
}
