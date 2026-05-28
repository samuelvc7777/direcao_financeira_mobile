import 'package:direcao_financeira_mobile/app/domain/entities/goal_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoalEntity', () {
    test('calcula progresso em porcentagem com limite visual', () {
      const goal = GoalEntity(
        id: 1,
        userId: 1,
        name: 'Reserva',
        targetAmountCents: 10000,
        currentAmountCents: 12500,
        status: GoalStatus.active,
      );

      expect(goal.progressPercent, 125);
      expect(goal.cappedProgressPercent, 100);
      expect(goal.isReached, isTrue);
    });

    test('retorna progresso zero quando objetivo for invalido', () {
      const goal = GoalEntity(
        id: 1,
        userId: 1,
        name: 'Reserva',
        targetAmountCents: 0,
        currentAmountCents: 5000,
        status: GoalStatus.active,
      );

      expect(goal.progressRatio, 0);
      expect(goal.cappedProgressPercent, 0);
    });
  });
}
