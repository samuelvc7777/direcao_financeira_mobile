import '../models/goal_model.dart';

abstract class IGoalDataSource {
  Future<List<GoalModel>> getGoals();

  Future<GoalModel> createGoal({
    required String name,
    String? description,
    required int targetAmountCents,
    int currentAmountCents = 0,
    DateTime? targetDate,
  });

  Future<GoalModel> updateGoal({
    required int id,
    required String name,
    String? description,
    required int targetAmountCents,
    required int currentAmountCents,
    DateTime? targetDate,
  });

  Future<GoalModel> completeGoal(int id);

  Future<GoalModel> archiveGoal(int id);
}
