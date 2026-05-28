import 'package:direcao_financeira_mobile/app/domain/entities/subscription_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/services/premium_access_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PremiumAccessPolicy', () {
    const policy = PremiumAccessPolicy();

    test('bloqueia quando nao ha assinatura', () {
      final decision = policy.evaluate(null);

      expect(decision.isAllowed, isFalse);
      expect(decision.reason, PremiumAccessBlockReason.noSubscription);
    });

    test('bloqueia assinatura vencida', () {
      final decision = policy.evaluate(
        _subscription(
          status: 'ACTIVE',
          endDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );

      expect(decision.isAllowed, isFalse);
      expect(decision.reason, PremiumAccessBlockReason.expiredOrInactive);
    });

    test('bloqueia status sem acesso', () {
      final decision = policy.evaluate(
        _subscription(
          status: 'PENDING',
          endDate: DateTime.now().add(const Duration(days: 1)),
        ),
      );

      expect(decision.isAllowed, isFalse);
      expect(decision.reason, PremiumAccessBlockReason.expiredOrInactive);
    });

    test('libera assinatura vigente', () {
      final decision = policy.evaluate(
        _subscription(
          status: 'ACTIVE',
          endDate: DateTime.now().add(const Duration(days: 1)),
        ),
      );

      expect(decision.isAllowed, isTrue);
      expect(decision.reason, isNull);
    });

    test('libera CANCELED com endDate futura', () {
      final decision = policy.evaluate(
        _subscription(
          status: 'CANCELED',
          endDate: DateTime.now().add(const Duration(days: 1)),
        ),
      );

      expect(decision.isAllowed, isTrue);
    });

    test('bloqueia CANCELED com endDate vencida', () {
      final decision = policy.evaluate(
        _subscription(
          status: 'CANCELED',
          endDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );

      expect(decision.isAllowed, isFalse);
    });
  });
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
