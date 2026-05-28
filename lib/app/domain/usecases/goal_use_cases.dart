import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/goal_entity.dart';
import '../repositories/i_goal_repository.dart';

class LoadGoalsUseCase {
  LoadGoalsUseCase(this._repository);

  final IGoalRepository _repository;

  Future<Either<Failure, List<GoalEntity>>> call() {
    return _repository.getGoals();
  }
}

class CreateGoalUseCase {
  CreateGoalUseCase(this._repository);

  final IGoalRepository _repository;

  Future<Either<Failure, GoalEntity>> call({
    required String name,
    String? description,
    required int targetAmountCents,
    int currentAmountCents = 0,
    DateTime? targetDate,
  }) {
    return _repository.createGoal(
      name: name,
      description: description,
      targetAmountCents: targetAmountCents,
      currentAmountCents: currentAmountCents,
      targetDate: targetDate,
    );
  }
}

class UpdateGoalUseCase {
  UpdateGoalUseCase(this._repository);

  final IGoalRepository _repository;

  Future<Either<Failure, GoalEntity>> call({
    required int id,
    required String name,
    String? description,
    required int targetAmountCents,
    required int currentAmountCents,
    DateTime? targetDate,
  }) {
    return _repository.updateGoal(
      id: id,
      name: name,
      description: description,
      targetAmountCents: targetAmountCents,
      currentAmountCents: currentAmountCents,
      targetDate: targetDate,
    );
  }
}

class CompleteGoalUseCase {
  CompleteGoalUseCase(this._repository);

  final IGoalRepository _repository;

  Future<Either<Failure, GoalEntity>> call(int id) {
    return _repository.completeGoal(id);
  }
}

class ArchiveGoalUseCase {
  ArchiveGoalUseCase(this._repository);

  final IGoalRepository _repository;

  Future<Either<Failure, GoalEntity>> call(int id) {
    return _repository.archiveGoal(id);
  }
}
