import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../widgets/app_loading_indicator.dart';
import '../journey_controller.dart';
import 'journey_period_filter_sheet.dart';
import 'shift_card.dart';
import 'shift_history_header.dart';
import 'shift_history_panels.dart';

class ShiftHistorySection extends GetView<JourneyController> {
  const ShiftHistorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 240) {
          controller.loadMoreShifts();
        }
        return false;
      },
      child: CustomScrollView(
        key: const PageStorageKey('journey-shifts-tab'),
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.symmetric(
                vertical: Responsive.vp(context, 1.0).clamp(6.0, 10.0),
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.midnight
                    : colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(
                  Responsive.sp(context, 24).clamp(20.0, 28.0),
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : colorScheme.onSurface.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(
                    () => ShiftHistoryHeader(
                      onOpenMetrics: () =>
                          Get.toNamed('/journey/shift-metrics'),
                      onOpenFilter: controller.isCurrentPeriodTodayFilter
                          ? () => _openPeriodFilter(context)
                          : controller.resetToTodayFilter,
                      filterLabel: controller.isCurrentPeriodTodayFilter
                          ? 'Filtrar'
                          : 'Resetar',
                      filterIcon: controller.isCurrentPeriodTodayFilter
                          ? Icons.calendar_today
                          : Icons.restart_alt_rounded,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.hp(context, 4.0).clamp(12.0, 20.0),
                    ),
                    child: Obx(
                      () => controller.hasActiveShift
                          ? ShiftActivePanel(controller: controller)
                          : ShiftStartPanel(controller: controller),
                    ),
                  ),
                  SizedBox(
                    height: Responsive.vp(context, 3.0).clamp(20.0, 28.0),
                  ),
                  Divider(
                    color: colorScheme.onSurface.withValues(alpha: 0.10),
                    indent: Responsive.hp(context, 5.0).clamp(16.0, 24.0),
                    endIndent: Responsive.hp(context, 5.0).clamp(16.0, 24.0),
                  ),
                  SizedBox(
                    height: Responsive.vp(context, 2.0).clamp(12.0, 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.hp(context, 5.0).clamp(16.0, 24.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Histórico recente',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.sp(
                              context,
                              16,
                            ).clamp(14.0, 18.0),
                          ),
                        ),
                        Obx(() {
                          final state = controller.historySectionState;
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.hp(
                                context,
                                3.0,
                              ).clamp(10.0, 14.0),
                              vertical: Responsive.vp(
                                context,
                                0.8,
                              ).clamp(4.0, 8.0),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.royalBlue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                Responsive.sp(context, 12).clamp(8.0, 16.0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.work_outline,
                                  size: Responsive.sp(
                                    context,
                                    14,
                                  ).clamp(12.0, 16.0),
                                  color: AppColors.royalBlue,
                                ),
                                SizedBox(
                                  width: Responsive.hp(
                                    context,
                                    2.0,
                                  ).clamp(6.0, 10.0),
                                ),
                                Text(
                                  '${state.totalCount} turnos',
                                  style: TextStyle(
                                    color: AppColors.royalBlue,
                                    fontSize: Responsive.sp(
                                      context,
                                      12,
                                    ).clamp(10.0, 14.0),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: Responsive.vp(context, 2.0).clamp(12.0, 20.0),
                  ),
                  const SizedBox.shrink(),
                  SizedBox(
                    height: Responsive.vp(context, 2.0).clamp(12.0, 20.0),
                  ),
                ],
              ),
            ),
          ),
          Obx(() {
            final state = controller.historySectionState;
            if (state.isEmpty) {
              return SliverToBoxAdapter(
                child: _ShiftEmptyState(
                  message: state.errorMessage ?? 'Nenhum turno encontrado',
                  onRetry: state.errorMessage != null
                      ? controller.retryJourneyData
                      : null,
                ),
              );
            }

            return SliverList.builder(
              itemCount: state.shifts.length + 1,
              itemBuilder: (context, index) {
                if (index == state.shifts.length) {
                  return _ShiftPaginationFooter(controller: controller);
                }

                final shift = state.shifts[index];
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.hp(context, 4.0).clamp(12.0, 20.0),
                  ),
                  child: ShiftCard(
                    shift: shift,
                    isDeleting: controller.isDeletingShift(shift),
                    onDelete: () => controller.requestDeleteShift(shift),
                  ),
                );
              },
            );
          }),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Future<void> _openPeriodFilter(BuildContext context) {
    return showJourneyPeriodFilterSheet(
      context: context,
      selectedFilter: controller.selectedFilter.value,
      periodLabel: controller.dateLabel,
      onToday: () => controller.applyQuickFilter('day'),
      onWeek: () => controller.applyQuickFilter('week'),
      onMonth: () => controller.applyQuickFilter('month'),
      onCustomRange: () => _pickCustomRange(context),
    );
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final DateTimeRange? picked = await showJourneyCustomRangeSheet(
      context: context,
      periodLabel: controller.dateLabel,
      initialStart: controller.customStartDate.value,
      initialEnd: controller.customEndDate.value,
    );

    if (picked != null) {
      controller.setCustomRange(picked.start, picked.end);
    }
  }
}

class _ShiftEmptyState extends StatelessWidget {
  const _ShiftEmptyState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(Responsive.sp(context, 32.0).clamp(24.0, 40.0)),
      child: Center(
        child: Column(
          children: [
            Text(
              message,
              style: TextStyle(
                color: context.theme.colorScheme.onSurface.withValues(
                  alpha: 0.54,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShiftPaginationFooter extends StatelessWidget {
  const _ShiftPaginationFooter({required this.controller});

  final JourneyController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Obx(() {
      final state = controller.historySectionState;
      final totalCount = state.totalCount;
      final loadedCount = state.loadedCount;

      if (loadedCount == 0) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: EdgeInsets.fromLTRB(
          Responsive.hp(context, 4.0).clamp(12.0, 20.0),
          8,
          Responsive.hp(context, 4.0).clamp(12.0, 20.0),
          0,
        ),
        child: Column(
          children: [
            Text(
              'Exibindo $loadedCount de $totalCount turnos',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.54),
                fontSize: Responsive.sp(context, 12).clamp(10.0, 14.0),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (state.isLoadingMore) ...[
              const SizedBox(height: 10),
              const AppLoadingIndicator(
                size: AppLoadingSize.compact,
                accentColor: AppColors.royalBlue,
                onDark: true,
              ),
            ] else if (state.hasMore) ...[
              const SizedBox(height: 10),
              Text(
                'Role para carregar mais turnos',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.38),
                  fontSize: Responsive.sp(context, 11).clamp(10.0, 13.0),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}
