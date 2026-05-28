import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../domain/entities/recording_entity.dart';
import '../../../widgets/app_loading_indicator.dart';
import '../journey_controller.dart';
import 'journey_period_filter_sheet.dart';

class RecordingsListSection extends GetView<JourneyController> {
  const RecordingsListSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 240) {
          controller.loadMoreRecordings();
        }
        return false;
      },
      child: CustomScrollView(
        key: const PageStorageKey('journey-recordings-tab'),
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
                      children: [
                        Container(
                          padding: EdgeInsets.all(
                            Responsive.sp(context, 10).clamp(8.0, 12.0),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.rose,
                            borderRadius: BorderRadius.circular(
                              Responsive.sp(context, 16).clamp(12.0, 20.0),
                            ),
                          ),
                          child: Icon(
                            Icons.videocam_rounded,
                            color: Colors.white,
                            size: Responsive.sp(context, 24).clamp(20.0, 28.0),
                          ),
                        ),
                        SizedBox(
                          width: Responsive.hp(context, 4.0).clamp(12.0, 20.0),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gravacoes',
                                style: context.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                  fontSize: Responsive.sp(
                                    context,
                                    20,
                                  ).clamp(18.0, 22.0),
                                ),
                              ),
                              SizedBox(height: Responsive.vp(context, 0.5)),
                              Obx(
                                () => Text(
                                  controller.recordingsSectionState.periodLabel,
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.62,
                                    ),
                                    fontSize: Responsive.sp(
                                      context,
                                      14,
                                    ).clamp(12.0, 16.0),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
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
                                  Responsive.sp(context, 12).clamp(8.0, 16.0),
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
                        final state = controller.recordingsSectionState;
                        return Row(
                          children: [
                            _StatusTab(
                              label: 'Todos',
                              icon: Icons.layers_rounded,
                              color: AppColors.royalBlue,
                              selected: state.selectedStatusFilter == 'Todos',
                              onTap: () => controller
                                  .changeRecordingStatusFilter('Todos'),
                            ),
                            _StatusTab(
                              label: 'Gravando',
                              icon: Icons.fiber_manual_record_rounded,
                              color: AppColors.rose,
                              selected:
                                  state.selectedStatusFilter == 'Gravando',
                              onTap: () => controller
                                  .changeRecordingStatusFilter('Gravando'),
                            ),
                            _StatusTab(
                              label: 'Concluidas',
                              icon: Icons.check_circle_outline_rounded,
                              color: AppColors.emerald,
                              selected:
                                  state.selectedStatusFilter == 'Concluidas',
                              onTap: () => controller
                                  .changeRecordingStatusFilter('Concluidas'),
                            ),
                            _StatusTab(
                              label: 'Falhas',
                              icon: Icons.error_outline_rounded,
                              color: AppColors.amber,
                              selected: state.selectedStatusFilter == 'Falhas',
                              onTap: () => controller
                                  .changeRecordingStatusFilter('Falhas'),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                  SizedBox(
                    height: Responsive.vp(context, 1.2).clamp(8.0, 14.0),
                  ),
                  Obx(() {
                    final state = controller.recordingsSectionState;
                    if (state.errorMessage != null && state.isEmpty) {
                      return _RecordingsMessage(
                        icon: Icons.error_outline_rounded,
                        title: 'Nao foi possivel carregar',
                        message: state.errorMessage!,
                      );
                    }

                    if (state.isEmpty) {
                      return const _RecordingsMessage(
                        icon: Icons.video_library_outlined,
                        title: 'Nenhuma gravacao encontrada',
                        message:
                            'As gravacoes feitas pelo app aparecerao aqui.',
                      );
                    }

                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.hp(
                              context,
                              4.0,
                            ).clamp(12.0, 20.0),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${state.visibleCount} de ${state.totalVisibleCount} gravacoes',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.58,
                                  ),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: Responsive.vp(context, 0.8).clamp(6.0, 10.0),
                        ),
                        ...state.visibleRecordings.map(
                          (recording) => _RecordingCard(recording: recording),
                        ),
                        if (state.isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: AppLoadingIndicator(
                              size: AppLoadingSize.compact,
                              accentColor: AppColors.rose,
                            ),
                          ),
                      ],
                    );
                  }),
                  SizedBox(
                    height: Responsive.vp(context, 1.5).clamp(10.0, 18.0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPeriodFilter(BuildContext context) {
    showJourneyPeriodFilterSheet(
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
    final picked = await showJourneyCustomRangeSheet(
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

class _StatusTab extends StatelessWidget {
  const _StatusTab({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            vertical: Responsive.vp(context, 0.9).clamp(6.0, 9.0),
          ),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected
                    ? Colors.white
                    : colorScheme.onSurface.withValues(alpha: 0.62),
                size: Responsive.sp(context, 16).clamp(14.0, 18.0),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : colorScheme.onSurface.withValues(alpha: 0.72),
                  fontSize: Responsive.sp(context, 11).clamp(9.0, 12.0),
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordingCard extends GetView<JourneyController> {
  const _RecordingCard({required this.recording});

  final RecordingEntity recording;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;
    final status = _RecordingStatusData.from(recording.status);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.hp(context, 4.0).clamp(12.0, 20.0),
        vertical: Responsive.vp(context, 0.7).clamp(5.0, 8.0),
      ),
      padding: EdgeInsets.all(Responsive.sp(context, 16).clamp(12.0, 18.0)),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(
          Responsive.sp(context, 18).clamp(14.0, 22.0),
        ),
        border: Border.all(
          color: status.color.withValues(
            alpha: recording.isActive ? 0.55 : 0.18,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: Responsive.sp(context, 44).clamp(38.0, 48.0),
            height: Responsive.sp(context, 44).clamp(38.0, 48.0),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(status.icon, color: status.color),
          ),
          SizedBox(width: Responsive.hp(context, 3.0).clamp(10.0, 16.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDateTime(recording.startedAt),
                        style: context.textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _StatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _InfoChip(
                      icon: Icons.timer_outlined,
                      label: _formatDuration(recording.durationSeconds),
                    ),
                    _InfoChip(
                      icon: Icons.sd_storage_outlined,
                      label: _formatBytes(recording.fileSizeBytes),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                tooltip: 'Abrir gravacao',
                onPressed: recording.isActive
                    ? null
                    : () => controller.openRecording(recording),
                icon: const Icon(Icons.play_circle_outline_rounded),
                color: AppColors.royalBlue,
              ),
              Obx(() {
                final deleting =
                    controller.deletingRecordingId.value == recording.id;
                return IconButton(
                  tooltip: 'Excluir gravacao',
                  onPressed: deleting
                      ? null
                      : () => controller.requestDeleteRecording(recording),
                  icon: deleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline_rounded),
                  color: AppColors.rose,
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _RecordingStatusData status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: context.theme.colorScheme.onSurface.withValues(alpha: 0.55),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: context.theme.colorScheme.onSurface.withValues(alpha: 0.66),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RecordingsMessage extends StatelessWidget {
  const _RecordingsMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    return Padding(
      padding: EdgeInsets.all(Responsive.sp(context, 24).clamp(18.0, 28.0)),
      child: Column(
        children: [
          Icon(
            icon,
            size: Responsive.sp(context, 42).clamp(34.0, 48.0),
            color: colorScheme.onSurface.withValues(alpha: 0.42),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingStatusData {
  const _RecordingStatusData({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  factory _RecordingStatusData.from(String status) {
    switch (status.toUpperCase()) {
      case RecordingStatus.recording:
        return const _RecordingStatusData(
          label: 'Gravando',
          color: AppColors.rose,
          icon: Icons.fiber_manual_record_rounded,
        );
      case RecordingStatus.failed:
        return const _RecordingStatusData(
          label: 'Falhou',
          color: AppColors.amber,
          icon: Icons.error_outline_rounded,
        );
      default:
        return const _RecordingStatusData(
          label: 'Concluida',
          color: AppColors.emerald,
          icon: Icons.check_circle_outline_rounded,
        );
    }
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String _formatDuration(int seconds) {
  if (seconds <= 0) {
    return '00:00';
  }
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
}

String _formatBytes(int bytes) {
  if (bytes <= 0) {
    return '--';
  }
  final mb = bytes / (1024 * 1024);
  if (mb >= 1) {
    return '${mb.toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1024).toStringAsFixed(0)} KB';
}
