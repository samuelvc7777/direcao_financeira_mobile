import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/goal_entity.dart';
import 'goal_card.dart';
import 'goals_summary_header.dart';

class GoalsContent extends StatelessWidget {
  const GoalsContent({
    super.key,
    required this.activeGoals,
    required this.completedGoals,
    required this.archivedGoals,
    required this.overallProgressPercent,
    required this.onCreate,
    required this.onEdit,
    required this.onComplete,
    required this.onArchive,
  });

  final List<GoalEntity> activeGoals;
  final List<GoalEntity> completedGoals;
  final List<GoalEntity> archivedGoals;
  final double overallProgressPercent;
  final VoidCallback onCreate;
  final ValueChanged<GoalEntity> onEdit;
  final ValueChanged<GoalEntity> onComplete;
  final ValueChanged<GoalEntity> onArchive;

  @override
  Widget build(BuildContext context) {
    final totalVisible = activeGoals.length + completedGoals.length;
    return RefreshIndicator(
      onRefresh: () async {},
      notificationPredicate: (_) => false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GoalsSummaryHeader(
                        totalGoals: totalVisible,
                        completedGoals: completedGoals.length,
                        overallProgressPercent: overallProgressPercent,
                      ),
                      const SizedBox(height: 18),
                      _GoalSection(
                        title: 'Ativas',
                        goals: activeGoals,
                        onTap: (goal) => _showGoalActions(context, goal),
                      ),
                      if (completedGoals.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _GoalSection(
                          title: 'Concluidas',
                          goals: completedGoals,
                          onTap: (goal) => _showGoalActions(context, goal),
                        ),
                      ],
                      if (archivedGoals.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _GoalSection(
                          title: 'Arquivadas',
                          goals: archivedGoals,
                          onTap: (goal) => _showGoalActions(context, goal),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showGoalActions(BuildContext context, GoalEntity goal) async {
    final action = await showModalBottomSheet<_GoalAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GoalActionsSheet(goal: goal),
    );

    if (action == _GoalAction.edit) {
      onEdit(goal);
      return;
    }

    if (action == _GoalAction.complete) {
      onComplete(goal);
      return;
    }

    if (action == _GoalAction.archive) {
      onArchive(goal);
    }
  }
}

class _GoalSection extends StatelessWidget {
  const _GoalSection({
    required this.title,
    required this.goals,
    required this.onTap,
  });

  final String title;
  final List<GoalEntity> goals;
  final ValueChanged<GoalEntity> onTap;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        ...goals.map(
          (goal) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GoalCard(goal: goal, onTap: () => onTap(goal)),
          ),
        ),
      ],
    );
  }
}

enum _GoalAction { edit, complete, archive }

class _GoalActionsSheet extends StatelessWidget {
  _GoalActionsSheet({required this.goal});

  final GoalEntity goal;
  final NumberFormat _currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(goal);

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.flag_rounded, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _subtitle(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _GoalActionTile(
                icon: Icons.edit_outlined,
                title: 'Editar meta',
                subtitle: 'Alterar valores, prazo ou descricao',
                color: AppColors.amber,
                onTap: () => Navigator.of(context).pop(_GoalAction.edit),
              ),
              if (!goal.isCompleted && !goal.isArchived) ...[
                const SizedBox(height: 10),
                _GoalActionTile(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Concluir meta',
                  subtitle: 'Marcar esta meta como finalizada',
                  color: AppColors.success,
                  onTap: () => Navigator.of(context).pop(_GoalAction.complete),
                ),
              ],
              if (!goal.isArchived) ...[
                const SizedBox(height: 10),
                _GoalActionTile(
                  icon: Icons.archive_outlined,
                  title: 'Arquivar meta',
                  subtitle: 'Remover da lista principal',
                  color: AppColors.rose,
                  onTap: () => Navigator.of(context).pop(_GoalAction.archive),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    final value =
        '${_currency.format(goal.currentAmount)} de ${_currency.format(goal.targetAmount)}';
    if (goal.targetDate == null) {
      return value;
    }

    return '$value - limite ${_dateFormat.format(goal.targetDate!)}';
  }

  Color _statusColor(GoalEntity goal) {
    if (goal.isCompleted) return AppColors.success;
    if (goal.isArchived) return AppColors.textLight;
    return AppColors.amber;
  }
}

class _GoalActionTile extends StatelessWidget {
  const _GoalActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
