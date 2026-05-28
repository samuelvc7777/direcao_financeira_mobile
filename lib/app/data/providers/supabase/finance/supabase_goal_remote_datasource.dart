import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../domain/entities/goal_entity.dart';
import '../../../datasources/goal_datasource.dart';
import '../../../models/goal_model.dart';
import '../shared/supabase_table_names.dart';
import '../shared/supabase_user_scope.dart';

class SupabaseGoalRemoteDataSource implements IGoalDataSource {
  SupabaseGoalRemoteDataSource({required this.client})
    : userScope = SupabaseUserScope(client: client);

  final SupabaseClient client;
  final SupabaseUserScope userScope;

  @override
  Future<List<GoalModel>> getGoals() async {
    final userId = await userScope.getCurrentUserId();
    final rows = await client
        .from(SupabaseTableNames.goals)
        .select()
        .eq('userId', userId)
        .order('createdAt', ascending: false);

    return (rows as List)
        .map((row) => GoalModel.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  @override
  Future<GoalModel> createGoal({
    required String name,
    String? description,
    required int targetAmountCents,
    int currentAmountCents = 0,
    DateTime? targetDate,
  }) async {
    final userId = await userScope.getCurrentUserId();
    final now = DateTime.now().toUtc().toIso8601String();
    final row = await client
        .from(SupabaseTableNames.goals)
        .insert({
          'userId': userId,
          'name': name,
          'description': description,
          'targetAmountCents': targetAmountCents,
          'currentAmountCents': currentAmountCents,
          'status': GoalStatusCodec.encode(GoalStatus.active),
          'targetDate': targetDate?.toUtc().toIso8601String(),
          'completedAt': null,
          'updatedAt': now,
        })
        .select()
        .single();

    return GoalModel.fromJson(Map<String, dynamic>.from(row));
  }

  @override
  Future<GoalModel> updateGoal({
    required int id,
    required String name,
    String? description,
    required int targetAmountCents,
    required int currentAmountCents,
    DateTime? targetDate,
  }) async {
    final userId = await userScope.getCurrentUserId();
    final row = await client
        .from(SupabaseTableNames.goals)
        .update({
          'name': name,
          'description': description,
          'targetAmountCents': targetAmountCents,
          'currentAmountCents': currentAmountCents,
          'targetDate': targetDate?.toUtc().toIso8601String(),
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .eq('userId', userId)
        .select()
        .single();

    return GoalModel.fromJson(Map<String, dynamic>.from(row));
  }

  @override
  Future<GoalModel> completeGoal(int id) async {
    final userId = await userScope.getCurrentUserId();
    final now = DateTime.now().toUtc().toIso8601String();
    final row = await client
        .from(SupabaseTableNames.goals)
        .update({
          'status': GoalStatusCodec.encode(GoalStatus.completed),
          'completedAt': now,
          'updatedAt': now,
        })
        .eq('id', id)
        .eq('userId', userId)
        .select()
        .single();

    return GoalModel.fromJson(Map<String, dynamic>.from(row));
  }

  @override
  Future<GoalModel> archiveGoal(int id) async {
    final userId = await userScope.getCurrentUserId();
    final row = await client
        .from(SupabaseTableNames.goals)
        .update({
          'status': GoalStatusCodec.encode(GoalStatus.archived),
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .eq('userId', userId)
        .select()
        .single();

    return GoalModel.fromJson(Map<String, dynamic>.from(row));
  }
}
