import 'package:dartz/dartz.dart';
import 'package:direcao_financeira_mobile/app/core/dashboard/dashboard_refresh_notifier.dart';
import 'package:direcao_financeira_mobile/app/core/errors/failures.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/goal_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/repositories/i_goal_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/usecases/goal_use_cases.dart';
import 'package:direcao_financeira_mobile/app/presentation/modules/goals/goals_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  late _FakeGoalRepository repository;
  late DefaultDashboardRefreshNotifier notifier;
  late GoalsController controller;

  setUp(() {
    Get.testMode = true;
    repository = _FakeGoalRepository();
    notifier = DefaultDashboardRefreshNotifier();
    controller = GoalsController(
      loadGoalsUseCase: LoadGoalsUseCase(repository),
      createGoalUseCase: CreateGoalUseCase(repository),
      updateGoalUseCase: UpdateGoalUseCase(repository),
      completeGoalUseCase: CompleteGoalUseCase(repository),
      archiveGoalUseCase: ArchiveGoalUseCase(repository),
      dashboardRefreshNotifier: notifier,
    );
  });

  tearDown(Get.reset);

  test('carrega metas e separa ativas/concluidas/arquivadas', () async {
    repository.goals = [
      _goal(1, GoalStatus.active),
      _goal(2, GoalStatus.completed),
      _goal(3, GoalStatus.archived),
    ];

    await controller.loadGoals();

    expect(controller.activeGoals, hasLength(1));
    expect(controller.completedGoals, hasLength(1));
    expect(controller.archivedGoals, hasLength(1));
    expect(controller.visibleGoals, hasLength(2));
  });

  test('createGoal adiciona meta e solicita refresh da home', () async {
    final created = await controller.createGoal(
      name: 'Reserva',
      targetAmountCents: 10000,
      currentAmountCents: 1000,
    );

    expect(created, isTrue);
    expect(controller.goals, hasLength(1));
    expect(notifier.refreshTick.value, 1);
  });

  test('loadGoals registra mensagem de erro', () async {
    repository.failure = ServerFailure('Falha planejada');

    await controller.loadGoals();

    expect(controller.errorMessage.value, 'Falha planejada');
    expect(controller.goals, isEmpty);
  });
}

GoalEntity _goal(int id, GoalStatus status) {
  return GoalEntity(
    id: id,
    userId: 1,
    name: 'Meta $id',
    targetAmountCents: 10000,
    currentAmountCents: 5000,
    status: status,
  );
}

class _FakeGoalRepository implements IGoalRepository {
  List<GoalEntity> goals = [];
  Failure? failure;

  @override
  Future<Either<Failure, List<GoalEntity>>> getGoals() async {
    final currentFailure = failure;
    if (currentFailure != null) {
      return Left(currentFailure);
    }

    return Right(goals);
  }

  @override
  Future<Either<Failure, GoalEntity>> createGoal({
    required String name,
    String? description,
    required int targetAmountCents,
    int currentAmountCents = 0,
    DateTime? targetDate,
  }) async {
    final goal = GoalEntity(
      id: goals.length + 1,
      userId: 1,
      name: name,
      description: description,
      targetAmountCents: targetAmountCents,
      currentAmountCents: currentAmountCents,
      status: GoalStatus.active,
      targetDate: targetDate,
    );
    goals.add(goal);
    return Right(goal);
  }

  @override
  Future<Either<Failure, GoalEntity>> updateGoal({
    required int id,
    required String name,
    String? description,
    required int targetAmountCents,
    required int currentAmountCents,
    DateTime? targetDate,
  }) async {
    final goal = GoalEntity(
      id: id,
      userId: 1,
      name: name,
      description: description,
      targetAmountCents: targetAmountCents,
      currentAmountCents: currentAmountCents,
      status: GoalStatus.active,
      targetDate: targetDate,
    );
    return Right(goal);
  }

  @override
  Future<Either<Failure, GoalEntity>> completeGoal(int id) async {
    return Right(_goal(id, GoalStatus.completed));
  }

  @override
  Future<Either<Failure, GoalEntity>> archiveGoal(int id) async {
    return Right(_goal(id, GoalStatus.archived));
  }
}
