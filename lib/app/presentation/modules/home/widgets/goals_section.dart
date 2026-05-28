import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/goal_entity.dart';
import '../home_controller.dart';

class GoalsSection extends GetView<HomeController> {
  GoalsSection({super.key});

  final NumberFormat _currencyFormat = NumberFormat.simpleCurrency(
    locale: 'pt_BR',
  );

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final goals = controller.goals;
      final totalGoals = goals.length;
      final completed = goals.where((goal) => goal.isCompleted).length;
      final overallProgress = totalGoals > 0
          ? goals.fold<double>(
                  0,
                  (total, goal) => total + goal.cappedProgressPercent,
                ) /
                totalGoals
          : 0.0;

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: context.theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          children: [
            _Header(
              completed: completed,
              total: totalGoals,
              onManage: controller.openGoals,
            ),
            const SizedBox(height: 20),
            if (goals.isEmpty)
              _EmptyGoalsSummary(onManage: controller.openGoals)
            else ...[
              _OverallProgress(progressPercent: overallProgress),
              const SizedBox(height: 16),
              ...goals
                  .take(3)
                  .map(
                    (goal) =>
                        _GoalItem(goal: goal, currencyFormat: _currencyFormat),
                  ),
            ],
          ],
        ),
      );
    });
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.completed,
    required this.total,
    required this.onManage,
  });

  final int completed;
  final int total;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackHeader = constraints.maxWidth < 400;
        final title = Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.flag_rounded,
                color: AppColors.amber,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Minhas Metas',
                    style: TextStyle(
                      color: context.theme.colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$completed de $total concluidas',
                    style: TextStyle(
                      color: context.theme.colorScheme.onSurface.withValues(
                        alpha: 0.4,
                      ),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        if (stackHeader) {
          return Column(
            children: [
              title,
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: _ManageButton(onTap: onManage),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: title),
            _ManageButton(onTap: onManage),
          ],
        );
      },
    );
  }
}

class _ManageButton extends StatelessWidget {
  const _ManageButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: context.theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Gerenciar',
              style: TextStyle(
                color: context.theme.colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: context.theme.colorScheme.onSurface.withValues(alpha: 0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverallProgress extends StatelessWidget {
  const _OverallProgress({required this.progressPercent});

  final double progressPercent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progresso Geral',
              style: TextStyle(
                color: context.theme.colorScheme.onSurface.withValues(
                  alpha: 0.54,
                ),
                fontSize: 13,
              ),
            ),
            Text(
              '${progressPercent.toStringAsFixed(0)}%',
              style: TextStyle(
                color: context.theme.colorScheme.onSurface.withValues(
                  alpha: 0.54,
                ),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progressPercent / 100,
            backgroundColor: context.theme.colorScheme.onSurface.withValues(
              alpha: 0.08,
            ),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.lime),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _EmptyGoalsSummary extends StatelessWidget {
  const _EmptyGoalsSummary({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onManage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.theme.colorScheme.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.theme.colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
        child: Text(
          'Nenhuma meta cadastrada ainda.',
          style: TextStyle(
            color: context.theme.colorScheme.onSurface.withValues(alpha: 0.54),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _GoalItem extends StatelessWidget {
  const _GoalItem({required this.goal, required this.currencyFormat});

  final GoalEntity goal;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                goal.isCompleted
                    ? Icons.check_circle_outline_rounded
                    : Icons.flag_outlined,
                color: goal.isCompleted
                    ? AppColors.success
                    : context.theme.colorScheme.onSurface.withValues(
                        alpha: 0.38,
                      ),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  goal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.theme.colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${goal.cappedProgressPercent.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: context.theme.colorScheme.onSurface.withValues(
                    alpha: 0.54,
                  ),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${currencyFormat.format(goal.currentAmount)} de ${currencyFormat.format(goal.targetAmount)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.theme.colorScheme.onSurface.withValues(
                  alpha: 0.4,
                ),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.cappedProgressRatio,
              backgroundColor: context.theme.colorScheme.onSurface.withValues(
                alpha: 0.08,
              ),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
