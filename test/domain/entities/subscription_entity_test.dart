import 'package:direcao_financeira_mobile/app/domain/entities/subscription_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionEntity.grantsAccess', () {
    test('libera ACTIVE vigente', () {
      expect(
        _subscription(
          status: 'ACTIVE',
          endDate: DateTime.now().add(const Duration(days: 1)),
        ).grantsAccess,
        isTrue,
      );
    });

    test('libera TRIAL vigente', () {
      expect(
        _subscription(
          status: 'TRIAL',
          endDate: DateTime.now().add(const Duration(days: 1)),
        ).grantsAccess,
        isTrue,
      );
    });

    test('libera CANCELED vigente', () {
      expect(
        _subscription(
          status: 'CANCELED',
          endDate: DateTime.now().add(const Duration(days: 1)),
        ).grantsAccess,
        isTrue,
      );
    });

    test('bloqueia CANCELED vencida', () {
      expect(
        _subscription(
          status: 'CANCELED',
          endDate: DateTime.now().subtract(const Duration(days: 1)),
        ).grantsAccess,
        isFalse,
      );
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
