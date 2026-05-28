import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/dashboard/dashboard_refresh_notifier.dart';
import '../../../core/feedback/app_snackbar.dart';
import '../../../domain/entities/goal_entity.dart';
import '../../../domain/usecases/goal_use_cases.dart';

class GoalsController extends GetxController {
  GoalsController({
    required this.loadGoalsUseCase,
    required this.createGoalUseCase,
    required this.updateGoalUseCase,
    required this.completeGoalUseCase,
    required this.archiveGoalUseCase,
    required this.dashboardRefreshNotifier,
  });

  final LoadGoalsUseCase loadGoalsUseCase;
  final CreateGoalUseCase createGoalUseCase;
  final UpdateGoalUseCase updateGoalUseCase;
  final CompleteGoalUseCase completeGoalUseCase;
  final ArchiveGoalUseCase archiveGoalUseCase;
  final DashboardRefreshNotifier dashboardRefreshNotifier;

  final isLoading = true.obs;
  final isSubmitting = false.obs;
  final errorMessage = RxnString();
  final goals = <GoalEntity>[].obs;

  List<GoalEntity> get activeGoals =>
      goals.where((goal) => goal.isActive).toList();
  List<GoalEntity> get completedGoals =>
      goals.where((goal) => goal.isCompleted).toList();
  List<GoalEntity> get archivedGoals =>
      goals.where((goal) => goal.isArchived).toList();
  List<GoalEntity> get visibleGoals =>
      goals.where((goal) => !goal.isArchived).toList();

  double get overallProgressPercent {
    final visible = visibleGoals;
    if (visible.isEmpty) {
      return 0;
    }

    final total = visible.fold<double>(
      0,
      (sum, goal) => sum + goal.cappedProgressPercent,
    );
    return total / visible.length;
  }

  @override
  void onInit() {
    super.onInit();
    loadGoals();
  }

  Future<void> loadGoals({bool silent = false}) async {
    if (!silent) {
      isLoading.value = true;
    }
    errorMessage.value = null;

    final result = await loadGoalsUseCase();
    result.fold(
      (failure) => errorMessage.value = failure.message,
      (data) => goals.assignAll(data),
    );

    isLoading.value = false;
  }

  Future<bool> createGoal({
    required String name,
    String? description,
    required int targetAmountCents,
    required int currentAmountCents,
    DateTime? targetDate,
  }) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;

    final result = await createGoalUseCase(
      name: name,
      description: description,
      targetAmountCents: targetAmountCents,
      currentAmountCents: currentAmountCents,
      targetDate: targetDate,
    );

    isSubmitting.value = false;
    return result.fold(
      (failure) {
        _showFeedback('Nao foi possivel criar', failure.message);
        return false;
      },
      (goal) {
        goals.insert(0, goal);
        dashboardRefreshNotifier.requestRefresh();
        _showFeedback('Meta criada', 'Sua meta foi salva com sucesso.');
        return true;
      },
    );
  }

  Future<bool> updateGoal({
    required int id,
    required String name,
    String? description,
    required int targetAmountCents,
    required int currentAmountCents,
    DateTime? targetDate,
  }) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;

    final result = await updateGoalUseCase(
      id: id,
      name: name,
      description: description,
      targetAmountCents: targetAmountCents,
      currentAmountCents: currentAmountCents,
      targetDate: targetDate,
    );

    isSubmitting.value = false;
    return result.fold(
      (failure) {
        _showFeedback('Nao foi possivel atualizar', failure.message);
        return false;
      },
      (goal) {
        _replaceGoal(goal);
        dashboardRefreshNotifier.requestRefresh();
        _showFeedback('Meta atualizada', 'As alteracoes foram salvas.');
        return true;
      },
    );
  }

  Future<void> completeGoal(GoalEntity goal) async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    final result = await completeGoalUseCase(goal.id);
    isSubmitting.value = false;

    result.fold(
      (failure) => _showFeedback('Nao foi possivel concluir', failure.message),
      (updatedGoal) {
        _replaceGoal(updatedGoal);
        dashboardRefreshNotifier.requestRefresh();
        _showFeedback(
          'Meta concluida',
          'Parabens, meta marcada como concluida.',
        );
      },
    );
  }

  Future<void> confirmArchiveGoal(GoalEntity goal) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Arquivar meta?'),
        content: Text(
          'A meta "${goal.name}" saira da lista principal, mas continua no historico.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Arquivar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await archiveGoal(goal);
    }
  }

  Future<void> archiveGoal(GoalEntity goal) async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    final result = await archiveGoalUseCase(goal.id);
    isSubmitting.value = false;

    result.fold(
      (failure) => _showFeedback('Nao foi possivel arquivar', failure.message),
      (updatedGoal) {
        _replaceGoal(updatedGoal);
        dashboardRefreshNotifier.requestRefresh();
        _showFeedback('Meta arquivada', 'A meta saiu da lista principal.');
      },
    );
  }

  void _replaceGoal(GoalEntity goal) {
    final index = goals.indexWhere((item) => item.id == goal.id);
    if (index == -1) {
      goals.insert(0, goal);
      return;
    }

    goals[index] = goal;
  }

  void _showFeedback(String title, String message) {
    if (Get.testMode) {
      debugPrint('[GoalsController] $title - $message');
      return;
    }

    AppSnackbar.show(title, message);
  }
}
