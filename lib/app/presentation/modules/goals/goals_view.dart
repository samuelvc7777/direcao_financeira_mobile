import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/app_loading_indicator.dart';
import '../../../core/theme/app_colors.dart';
import 'goals_controller.dart';
import 'widgets/goal_form_sheet.dart';
import 'widgets/goals_content.dart';
import 'widgets/goals_empty_state.dart';
import 'widgets/goals_error_state.dart';

class GoalsView extends GetView<GoalsController> {
  const GoalsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Metas'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => controller.loadGoals(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        backgroundColor: AppColors.amber,
        child: const Icon(Icons.add_rounded),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoadingScreen(
            label: 'Carregando metas',
            accentColor: AppColors.amber,
          );
        }

        final error = controller.errorMessage.value;
        if (error != null) {
          return GoalsErrorState(
            message: error,
            onRetry: () => controller.loadGoals(),
          );
        }

        if (controller.visibleGoals.isEmpty) {
          return GoalsEmptyState(onCreate: () => _openForm(context));
        }

        return GoalsContent(
          activeGoals: controller.activeGoals,
          completedGoals: controller.completedGoals,
          archivedGoals: controller.archivedGoals,
          overallProgressPercent: controller.overallProgressPercent,
          onCreate: () => _openForm(context),
          onEdit: (goal) => _openForm(context, goal: goal),
          onComplete: controller.completeGoal,
          onArchive: controller.confirmArchiveGoal,
        );
      }),
    );
  }

  void _openForm(BuildContext context, {dynamic goal}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => GoalFormSheet(goal: goal),
    );
  }
}
