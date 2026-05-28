import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

Future<void> showJourneyPeriodFilterSheet({
  required BuildContext context,
  required String selectedFilter,
  required String periodLabel,
  required VoidCallback onToday,
  required VoidCallback onWeek,
  required VoidCallback onMonth,
  required Future<void> Function() onCustomRange,
}) async {
  final choice = await showModalBottomSheet<_JourneyPeriodChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _JourneyPeriodFilterSheet(
      selectedFilter: selectedFilter,
      periodLabel: periodLabel,
    ),
  );

  switch (choice) {
    case _JourneyPeriodChoice.today:
      onToday();
      break;
    case _JourneyPeriodChoice.week:
      onWeek();
      break;
    case _JourneyPeriodChoice.month:
      onMonth();
      break;
    case _JourneyPeriodChoice.custom:
      await onCustomRange();
      break;
    case null:
      break;
  }
}

Future<DateTimeRange?> showJourneyCustomRangeSheet({
  required BuildContext context,
  required String periodLabel,
  DateTime? initialStart,
  DateTime? initialEnd,
}) async {
  final shouldOpenCalendar = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _JourneyCustomRangeSheet(periodLabel: periodLabel),
  );

  if (shouldOpenCalendar != true) {
    return null;
  }

  if (!context.mounted) {
    return null;
  }

  final colorScheme = Theme.of(context).colorScheme;
  final initialRange = initialStart != null && initialEnd != null
      ? DateTimeRange(start: initialStart, end: initialEnd)
      : null;

  return showDateRangePicker(
    context: context,
    firstDate: DateTime(2020),
    lastDate: DateTime.now(),
    initialDateRange: initialRange,
    builder: (context, child) {
      final theme = Theme.of(context);
      return Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: AppColors.royalBlue,
            onPrimary: Colors.white,
            surface: colorScheme.surface,
            onSurface: colorScheme.onSurface,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            headerBackgroundColor: AppColors.royalBlue,
            headerForegroundColor: Colors.white,
            rangeSelectionBackgroundColor: AppColors.royalBlue.withValues(
              alpha: 0.18,
            ),
            rangePickerBackgroundColor: colorScheme.surface,
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return colorScheme.onSurface;
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.royalBlue;
              }
              return null;
            }),
            todayForegroundColor: WidgetStateProperty.all(AppColors.royalBlue),
            todayBorder: BorderSide(
              color: AppColors.royalBlue.withValues(alpha: 0.5),
            ),
            cancelButtonStyle: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurface.withValues(alpha: 0.72),
            ),
            confirmButtonStyle: TextButton.styleFrom(
              foregroundColor: AppColors.royalBlue,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
        child: child!,
      );
    },
  );
}

enum _JourneyPeriodChoice { today, week, month, custom }

class _JourneyPeriodFilterSheet extends StatelessWidget {
  const _JourneyPeriodFilterSheet({
    required this.selectedFilter,
    required this.periodLabel,
  });

  final String selectedFilter;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          padding: EdgeInsets.fromLTRB(
            Responsive.hp(context, 4.5).clamp(16.0, 24.0),
            12,
            Responsive.hp(context, 4.5).clamp(16.0, 24.0),
            18 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              SizedBox(height: Responsive.vp(context, 1.8).clamp(12.0, 18.0)),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(
                      Responsive.sp(context, 10).clamp(8.0, 12.0),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(
                        Responsive.sp(context, 16).clamp(12.0, 18.0),
                      ),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.royalBlue,
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
                          'Filtrar periodo',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: Responsive.sp(
                              context,
                              20,
                            ).clamp(18.0, 22.0),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          periodLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.66,
                            ),
                            fontSize: Responsive.sp(
                              context,
                              13,
                            ).clamp(12.0, 15.0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.vp(context, 2.0).clamp(14.0, 20.0)),
              _JourneyPeriodOption(
                title: 'Hoje',
                subtitle: 'Atualiza o painel com o dia atual',
                icon: Icons.today_rounded,
                color: AppColors.emerald,
                isSelected: selectedFilter == 'day',
                onTap: () =>
                    Navigator.of(context).pop(_JourneyPeriodChoice.today),
              ),
              SizedBox(height: Responsive.vp(context, 1.2).clamp(8.0, 12.0)),
              _JourneyPeriodOption(
                title: 'Esta semana',
                subtitle: 'Agrupa a jornada da semana corrente',
                icon: Icons.date_range_rounded,
                color: AppColors.royalBlue,
                isSelected: selectedFilter == 'week',
                onTap: () =>
                    Navigator.of(context).pop(_JourneyPeriodChoice.week),
              ),
              SizedBox(height: Responsive.vp(context, 1.2).clamp(8.0, 12.0)),
              _JourneyPeriodOption(
                title: 'Este mes',
                subtitle: 'Mostra a visao consolidada do mes atual',
                icon: Icons.calendar_view_month_rounded,
                color: AppColors.amber,
                isSelected: selectedFilter == 'month',
                onTap: () =>
                    Navigator.of(context).pop(_JourneyPeriodChoice.month),
              ),
              SizedBox(height: Responsive.vp(context, 1.2).clamp(8.0, 12.0)),
              _JourneyPeriodOption(
                title: 'Personalizado',
                subtitle: 'Escolha um intervalo especifico no calendario',
                icon: Icons.edit_calendar_rounded,
                color: AppColors.violet,
                isSelected: selectedFilter == 'custom',
                onTap: () =>
                    Navigator.of(context).pop(_JourneyPeriodChoice.custom),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyCustomRangeSheet extends StatelessWidget {
  const _JourneyCustomRangeSheet({required this.periodLabel});

  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          padding: EdgeInsets.fromLTRB(
            Responsive.hp(context, 4.5).clamp(16.0, 24.0),
            12,
            Responsive.hp(context, 4.5).clamp(16.0, 24.0),
            18 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              SizedBox(height: Responsive.vp(context, 1.8).clamp(12.0, 18.0)),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(
                      Responsive.sp(context, 10).clamp(8.0, 12.0),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.violet.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(
                        Responsive.sp(context, 16).clamp(12.0, 18.0),
                      ),
                    ),
                    child: const Icon(
                      Icons.edit_calendar_rounded,
                      color: AppColors.violet,
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
                          'Intervalo personalizado',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: Responsive.sp(
                              context,
                              20,
                            ).clamp(18.0, 22.0),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Escolha um recorte sob medida para analisar sua jornada.',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.66,
                            ),
                            fontSize: Responsive.sp(
                              context,
                              13,
                            ).clamp(12.0, 15.0),
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.vp(context, 2.0).clamp(14.0, 20.0)),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(
                  Responsive.sp(context, 16).clamp(14.0, 18.0),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.violet.withValues(alpha: 0.10),
                      AppColors.royalBlue.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.violet.withValues(alpha: 0.24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.violet.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: AppColors.violet,
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
                            'Periodo atual',
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.62,
                              ),
                              fontSize: Responsive.sp(
                                context,
                                12,
                              ).clamp(11.0, 14.0),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            periodLabel,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: Responsive.sp(
                                context,
                                15,
                              ).clamp(14.0, 17.0),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: Responsive.vp(context, 1.6).clamp(10.0, 16.0)),
              Text(
                'Voce vai escolher a data inicial e final no calendario da jornada.',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.64),
                  fontSize: Responsive.sp(context, 12).clamp(11.0, 14.0),
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              SizedBox(height: Responsive.vp(context, 2.0).clamp(14.0, 20.0)),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.violet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text(
                    'ESCOLHER INTERVALO',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyPeriodOption extends StatelessWidget {
  const _JourneyPeriodOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(Responsive.sp(context, 16).clamp(14.0, 18.0)),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.12)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.34)
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isSelected ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: Responsive.hp(context, 3.0).clamp(10.0, 14.0)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: Responsive.sp(context, 14).clamp(13.0, 16.0),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.66),
                        fontSize: Responsive.sp(context, 12).clamp(11.0, 14.0),
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: Responsive.hp(context, 2.0).clamp(8.0, 12.0)),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.chevron_right_rounded,
                color: isSelected
                    ? color
                    : colorScheme.onSurface.withValues(alpha: 0.36),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
