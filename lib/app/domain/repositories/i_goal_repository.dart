import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/goal_entity.dart';

abstract class IGoalRepository {
  Future<Either<Failure, List<GoalEntity>>> getGoals();

  Future<Either<Failure, GoalEntity>> createGoal({
    required String name,
    String? description,
    required int targetAmountCents,
    int currentAmountCents = 0,
    DateTime? targetDate,
  });

  Future<Either<Failure, GoalEntity>> updateGoal({
    required int id,
    required String name,
    String? description,
    required int targetAmountCents,
    required int currentAmountCents,
    DateTime? targetDate,
  });

  Future<Either<Failure, GoalEntity>> completeGoal(int id);

  Future<Either<Failure, GoalEntity>> archiveGoal(int id);
}
