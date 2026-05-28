import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../domain/entities/ride_entity.dart';
import '../../../widgets/app_loading_indicator.dart';
import '../journey_controller.dart';
import 'journey_period_filter_sheet.dart';

class RidesListSection extends GetView<JourneyController> {
  const RidesListSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 240) {
          controller.loadMoreRides();
        }
        return false;
      },
      child: CustomScrollView(
        key: const PageStorageKey('journey-rides-tab'),
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.symmetric(
                vertical: Responsive.vp(context, 1.0).clamp(6.0, 10.0),
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.midnight : colorScheme.surface,
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
                  Padding(
                    padding: EdgeInsets.all(
                      Responsive.sp(context, 20).clamp(16.0, 24.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(
                                  Responsive.sp(context, 10).clamp(8.0, 12.0),
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.royalBlue,
                                  borderRadius: BorderRadius.circular(
                                    Responsive.sp(
                                      context,
                                      16,
                                    ).clamp(12.0, 20.0),
                                  ),
                                ),
                                child: Icon(
                                  Icons.directions_car,
                                  color: Colors.white,
                                  size: Responsive.sp(
                                    context,
                                    24,
                                  ).clamp(20.0, 28.0),
                                ),
                              ),
                              SizedBox(
                                width: Responsive.hp(
                                  context,
                                  4.0,
                                ).clamp(12.0, 20.0),
                              ),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Corridas',
                                      style: context.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                            fontSize: Responsive.sp(
                                              context,
                                              20,
                                            ).clamp(18.0, 22.0),
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(
                                      height: Responsive.vp(context, 0.5),
                                    ),
                                    Text(
                                      'Período atual',
                                      style: context.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.62),
                                            fontSize: Responsive.sp(
                                              context,
                                              14,
                                            ).clamp(12.0, 16.0),
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: Responsive.hp(context, 2.0).clamp(6.0, 10.0),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.bar_chart,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.54,
                                ),
                                size: Responsive.sp(
                                  context,
                                  24,
                                ).clamp(20.0, 28.0),
                              ),
                              onPressed: () {
                                Get.toNamed('/journey/metrics');
                              },
                            ),
                            Obx(
                              () => InkWell(
                                onTap: controller.isCurrentPeriodTodayFilter
                                    ? () => _openPeriodFilter(context)
                                    : controller.resetToTodayFilter,
                                borderRadius: BorderRadius.circular(
                                  Responsive.sp(context, 12).clamp(8.0, 16.0),
                                ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Responsive.hp(
                                      context,
                                      3.0,
                                    ).clamp(10.0, 14.0),
                                    vertical: Responsive.vp(
                                      context,
                                      1.0,
                                    ).clamp(6.0, 10.0),
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : colorScheme.onSurface.withValues(
                                            alpha: 0.06,
                                          ),
                                    borderRadius: BorderRadius.circular(
                                      Responsive.sp(
                                        context,
                                        12,
                                      ).clamp(8.0, 16.0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        controller.isCurrentPeriodTodayFilter
                                            ? Icons.calendar_today
                                            : Icons.restart_alt_rounded,
                                        size: Responsive.sp(
                                          context,
                                          16,
                                        ).clamp(14.0, 18.0),
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.54,
                                        ),
                                      ),
                                      SizedBox(
                                        width: Responsive.hp(
                                          context,
                                          2.0,
                                        ).clamp(6.0, 10.0),
                                      ),
                                      Text(
                                        controller.isCurrentPeriodTodayFilter
                                            ? 'Filtrar'
                                            : 'Resetar',
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontSize: Responsive.sp(
                                            context,
                                            14,
                                          ).clamp(12.0, 16.0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.hp(context, 4.0).clamp(12.0, 20.0),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(
                        Responsive.sp(context, 4).clamp(2.0, 6.0),
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.2)
                            : colorScheme.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(
                          Responsive.sp(context, 16).clamp(12.0, 20.0),
                        ),
                      ),
                      child: Obx(() {
                        final state = controller.ridesSectionState;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTab(
                              context,
                              'Todos',
                              Icons.layers,
                              state.selectedStatusFilter == 'Todos',
                              AppColors.royalBlue,
                            ),
                            _buildTab(
                              context,
                              'Pendentes',
                              Icons.hourglass_empty,
                              state.selectedStatusFilter == 'Pendentes',
                              AppColors.amber,
                            ),
                            _buildTab(
                              context,
                              'Finalizados',
                              Icons.check_circle_outline,
                              state.selectedStatusFilter == 'Finalizados',
                              AppColors.emerald,
                            ),
                            _buildTab(
                              context,
                              'Cancelados',
                              Icons.cancel_outlined,
                              state.selectedStatusFilter == 'Cancelados',
                              AppColors.rose,
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                  SizedBox(
                    height: Responsive.vp(context, 2.0).clamp(12.0, 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.hp(context, 5.0).clamp(16.0, 24.0),
                    ),
                    child: Obx(() {
                      final state = controller.ridesSectionState;
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.hp(
                            context,
                            3.0,
                          ).clamp(10.0, 14.0),
                          vertical: Responsive.vp(context, 0.8).clamp(4.0, 8.0),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.royalBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(
                            Responsive.sp(context, 12).clamp(8.0, 16.0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.directions_car,
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
                              '${state.totalVisibleCount} corridas',
                              style: TextStyle(
                                color: AppColors.royalBlue,
                                fontSize: Responsive.sp(
                                  context,
                                  12,
                                ).clamp(10.0, 14.0),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              state.periodLabel,
                              style: TextStyle(
                                color: AppColors.royalBlue.withValues(
                                  alpha: 0.85,
                                ),
                                fontSize: Responsive.sp(
                                  context,
                                  12,
                                ).clamp(10.0, 14.0),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    }),
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
            final state = controller.ridesSectionState;
            if (state.isEmpty) {
              return SliverToBoxAdapter(
                child: _RidesEmptyState(
                  message: state.errorMessage ?? 'Nenhuma corrida encontrada',
                  onRetry: state.errorMessage != null
                      ? controller.retryJourneyData
                      : null,
                ),
              );
            }

            return SliverList.builder(
              itemCount: state.visibleRides.length + 1,
              itemBuilder: (context, index) {
                if (index == state.visibleRides.length) {
                  return _RidePaginationFooter(controller: controller);
                }

                final ride = state.visibleRides[index];
                return _RideHistoryCard(
                  ride: ride,
                  onTap: () => _showRideActions(context, ride),
                  formatCurrency: controller.formatCurrency,
                );
              },
            );
          }),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    String title,
    IconData icon,
    bool isSelected,
    Color selectedColor,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeRideStatusFilter(title),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: Responsive.vp(context, 1.5).clamp(8.0, 14.0),
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? selectedColor.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(
              Responsive.sp(context, 12).clamp(10.0, 14.0),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: Responsive.sp(context, 20).clamp(18.0, 22.0),
                color: isSelected
                    ? Colors.white
                    : context.theme.colorScheme.onSurface.withValues(
                        alpha: 0.54,
                      ),
              ),
              SizedBox(height: Responsive.vp(context, 0.5).clamp(2.0, 6.0)),
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : context.theme.colorScheme.onSurface.withValues(
                          alpha: 0.54,
                        ),
                  fontSize: Responsive.sp(context, 10).clamp(8.0, 12.0),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRideActions(BuildContext context, RideEntity ride) async {
    final action = await showModalBottomSheet<_RideAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RideActionsSheet(
        ride: ride,
        formatCurrency: controller.formatCurrency,
      ),
    );

    if (action == _RideAction.details) {
      controller.openRideDetails(ride);
      return;
    }

    if (action == _RideAction.delete) {
      await controller.requestDeleteRide(ride);
    }
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

class _RidesEmptyState extends StatelessWidget {
  const _RidesEmptyState({required this.message, required this.onRetry});

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

enum _RideAction { details, delete }

class _RideActionsSheet extends StatelessWidget {
  const _RideActionsSheet({required this.ride, required this.formatCurrency});

  final RideEntity ride;
  final String Function(int) formatCurrency;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

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
                      color: AppColors.royalBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.directions_car_filled_outlined,
                      color: AppColors.royalBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ride.date} ${ride.time} - ${formatCurrency(ride.grossValueCents)}',
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
                          ride.passenger,
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
              _RideActionTile(
                icon: Icons.receipt_long_outlined,
                title: 'Ver detalhes',
                subtitle: 'Abrir resumo completo da corrida',
                color: AppColors.royalBlue,
                onTap: () => Navigator.of(context).pop(_RideAction.details),
              ),
              const SizedBox(height: 10),
              _RideActionTile(
                icon: Icons.delete_outline_rounded,
                title: 'Excluir corrida',
                subtitle: 'Remover esta corrida do historico',
                color: AppColors.rose,
                onTap: () => Navigator.of(context).pop(_RideAction.delete),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RideActionTile extends StatelessWidget {
  const _RideActionTile({
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
    final colorScheme = context.theme.colorScheme;

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

class _RidePaginationFooter extends StatelessWidget {
  const _RidePaginationFooter({required this.controller});

  final JourneyController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.ridesSectionState;
      final visibleCount = state.visibleCount;

      if (visibleCount == 0) {
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
              'Exibindo $visibleCount corridas',
              style: TextStyle(
                color: context.theme.colorScheme.onSurface.withValues(
                  alpha: 0.54,
                ),
                fontSize: Responsive.sp(context, 12).clamp(10.0, 14.0),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (state.isLoadingMore) ...[
              const SizedBox(height: 10),
              const AppLoadingIndicator(
                size: AppLoadingSize.compact,
                accentColor: AppColors.royalBlue,
                onDark: false,
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _RideHistoryCard extends StatelessWidget {
  final RideEntity ride;
  final VoidCallback onTap;
  final String Function(int) formatCurrency;

  const _RideHistoryCard({
    required this.ride,
    required this.onTap,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;
    final statusColor = ride.status == 'PENDING'
        ? AppColors.amber
        : ride.status == 'FINISHED'
        ? AppColors.emerald
        : AppColors.rose;
    final statusIcon = ride.status == 'PENDING'
        ? Icons.hourglass_empty
        : ride.status == 'FINISHED'
        ? Icons.check_circle_outline
        : Icons.cancel_outlined;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        Responsive.sp(context, 20).clamp(16.0, 24.0),
      ),
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: Responsive.hp(context, 4.0).clamp(12.0, 20.0),
          vertical: Responsive.vp(context, 1.0).clamp(6.0, 10.0),
        ),
        padding: EdgeInsets.all(Responsive.sp(context, 16).clamp(12.0, 20.0)),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.2)
              : colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(
            Responsive.sp(context, 20).clamp(16.0, 24.0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(
                          Responsive.sp(context, 8).clamp(6.0, 10.0),
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black : colorScheme.surface,
                          borderRadius: BorderRadius.circular(
                            Responsive.sp(context, 12).clamp(8.0, 16.0),
                          ),
                        ),
                        child: Icon(
                          Icons.directions_car,
                          size: Responsive.sp(context, 24).clamp(20.0, 28.0),
                          color: ride.appName.toLowerCase() == 'uber'
                              ? colorScheme.onSurface
                              : AppColors.amber,
                        ),
                      ),
                      SizedBox(
                        width: Responsive.hp(context, 3.0).clamp(10.0, 14.0),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride.appName,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: Responsive.sp(
                                  context,
                                  16,
                                ).clamp(14.0, 18.0),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${ride.date} às ${ride.time}',
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.54,
                                ),
                                fontSize: Responsive.sp(
                                  context,
                                  12,
                                ).clamp(10.0, 14.0),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: Responsive.hp(context, 2.0).clamp(8.0, 12.0)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCurrency(ride.grossValueCents),
                      style: TextStyle(
                        color: AppColors.emerald,
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.sp(context, 16).clamp(14.0, 18.0),
                      ),
                    ),
                    SizedBox(
                      height: Responsive.vp(context, 0.5).clamp(2.0, 6.0),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.hp(
                          context,
                          2.0,
                        ).clamp(6.0, 10.0),
                        vertical: Responsive.vp(context, 0.2).clamp(2.0, 4.0),
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          Responsive.sp(context, 8).clamp(6.0, 10.0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            statusIcon,
                            size: Responsive.sp(context, 10).clamp(8.0, 12.0),
                            color: statusColor,
                          ),
                          SizedBox(
                            width: Responsive.hp(context, 1.0).clamp(4.0, 6.0),
                          ),
                          Text(
                            ride.status == 'PENDING'
                                ? 'Pendente'
                                : ride.status == 'FINISHED'
                                ? 'Finalizada'
                                : 'Cancelada',
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: Responsive.sp(
                                context,
                                10,
                              ).clamp(8.0, 12.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: Responsive.vp(context, 2.0).clamp(12.0, 20.0)),
            _RideRouteRow(icon: Icons.location_on, text: ride.origin),
            if (_hasRideType) ...[
              SizedBox(height: Responsive.vp(context, 0.8).clamp(4.0, 8.0)),
              _RideTypeChip(label: ride.rideType!.trim()),
            ],
            SizedBox(height: Responsive.vp(context, 0.8).clamp(4.0, 8.0)),
            _RideRouteRow(icon: Icons.flag, text: ride.destination),
            SizedBox(height: Responsive.vp(context, 1.0).clamp(6.0, 10.0)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: Responsive.sp(context, 16).clamp(14.0, 18.0),
                        color: colorScheme.onSurface.withValues(alpha: 0.54),
                      ),
                      SizedBox(
                        width: Responsive.hp(context, 2.0).clamp(6.0, 10.0),
                      ),
                      Expanded(
                        child: Text(
                          ride.passenger,
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.70,
                            ),
                            fontSize: Responsive.sp(
                              context,
                              14,
                            ).clamp(12.0, 16.0),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: Responsive.hp(context, 2.0).clamp(8.0, 12.0)),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: Responsive.sp(context, 16).clamp(14.0, 18.0),
                      color: colorScheme.onSurface.withValues(alpha: 0.54),
                    ),
                    SizedBox(
                      width: Responsive.hp(context, 1.0).clamp(4.0, 6.0),
                    ),
                    Text(
                      '${ride.durationMinutes}min',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.54),
                        fontSize: Responsive.sp(context, 14).clamp(12.0, 16.0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasRideType => ride.rideType?.trim().isNotEmpty == true;
}

class _RideTypeChip extends StatelessWidget {
  const _RideTypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Row(
      children: [
        Icon(
          Icons.alt_route_rounded,
          size: Responsive.sp(context, 16).clamp(14.0, 18.0),
          color: AppColors.royalBlue,
        ),
        SizedBox(width: Responsive.hp(context, 2.0).clamp(6.0, 10.0)),
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.hp(context, 2.0).clamp(8.0, 12.0),
              vertical: Responsive.vp(context, 0.4).clamp(3.0, 6.0),
            ),
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.royalBlue.withValues(alpha: 0.20),
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.78),
                fontSize: Responsive.sp(context, 12).clamp(10.0, 14.0),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RideRouteRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RideRouteRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: Responsive.sp(context, 16).clamp(14.0, 18.0),
          color: colorScheme.onSurface.withValues(alpha: 0.54),
        ),
        SizedBox(width: Responsive.hp(context, 2.0).clamp(6.0, 10.0)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.70),
              fontSize: Responsive.sp(context, 14).clamp(12.0, 16.0),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
