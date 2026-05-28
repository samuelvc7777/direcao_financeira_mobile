import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../journey_controller.dart';

class DailyStatisticsSection extends GetView<JourneyController> {
  const DailyStatisticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.bar_chart_rounded,
                          color: AppColors.royalBlue,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Estatísticas',
                          style: context.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Obx(() {
                  String label = 'Resumo das atividades de Hoje';
                  switch (controller.selectedFilter.value) {
                    case 'week':
                      label = 'Resumo das atividades da Semana';
                      break;
                    case 'month':
                      label = 'Resumo das atividades do Mês';
                      break;
                    case 'year':
                      label = 'Resumo das atividades do Ano';
                      break;
                  }
                  return Text(
                    label,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  );
                }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildStatCard(
                  context,
                  icon: Icons.work_outline_rounded,
                  title: 'Total de Turnos',
                  value: controller.totalShifts,
                  color: AppColors.royalBlue,
                ),
                _buildStatCard(
                  context,
                  icon: Icons.schedule_rounded,
                  title: 'Tempo Total',
                  value: controller.totalTime,
                  color: AppColors.emerald,
                ),
                _buildStatCard(
                  context,
                  icon: Icons.update_rounded,
                  title: 'Tempo Médio',
                  value: controller.averageTime,
                  color: AppColors.amber,
                ),
                _buildStatCard(
                  context,
                  icon: Icons.route_rounded,
                  title: 'Km Rodados',
                  value: controller.drivenKm,
                  color: AppColors.electricCyan,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required RxString value,
    required Color color,
  }) {
    final colorScheme = context.theme.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.24), width: 1),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: context.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Obx(
            () => Text(
              value.value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
