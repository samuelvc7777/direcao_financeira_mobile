import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/responsive.dart';
import '../journey_controller.dart';

class MetricPeriodSelector extends GetView<JourneyController> {
  const MetricPeriodSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: Responsive.hp(context, 2.0).clamp(8.0, 16.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(
              Responsive.sp(context, 12).clamp(10.0, 14.0),
            ),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left_rounded,
                  color: colorScheme.onSurface,
                ),
                onPressed: controller.previousDate,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Obx(
                () => Text(
                  controller.dateLabel,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurface,
                ),
                onPressed: controller.nextDate,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          margin: EdgeInsets.symmetric(
            horizontal: Responsive.hp(context, 2.0).clamp(8.0, 16.0),
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(
              Responsive.sp(context, 12).clamp(10.0, 14.0),
            ),
            border: Border.all(color: colorScheme.outlineVariant, width: 1),
          ),
          child: Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTab(
                  context,
                  'Dia',
                  Icons.calendar_today_rounded,
                  controller.selectedFilter.value == 'day',
                  'day',
                ),
                _buildTab(
                  context,
                  'Semana',
                  Icons.view_week_rounded,
                  controller.selectedFilter.value == 'week',
                  'week',
                ),
                _buildTab(
                  context,
                  'Mês',
                  Icons.calendar_month_rounded,
                  controller.selectedFilter.value == 'month',
                  'month',
                ),
                _buildTab(
                  context,
                  'Ano',
                  Icons.calendar_today_outlined,
                  controller.selectedFilter.value == 'year',
                  'year',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(
    BuildContext context,
    String title,
    IconData icon,
    bool isSelected,
    String value,
  ) {
    final colorScheme = context.theme.colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeFilter(value),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: Responsive.vp(context, 1.0).clamp(6.0, 10.0),
          ),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(
              Responsive.sp(context, 10).clamp(8.0, 12.0),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: Responsive.sp(context, 18).clamp(16.0, 22.0),
                color: isSelected
                    ? Colors.white
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : colorScheme.onSurfaceVariant,
                  fontSize: Responsive.sp(context, 11).clamp(10.0, 13.0),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
