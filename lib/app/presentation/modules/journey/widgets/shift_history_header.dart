import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

class ShiftHistoryHeader extends StatelessWidget {
  const ShiftHistoryHeader({
    super.key,
    required this.onOpenMetrics,
    required this.onOpenFilter,
    required this.filterLabel,
    required this.filterIcon,
  });

  final VoidCallback onOpenMetrics;
  final VoidCallback onOpenFilter;
  final String filterLabel;
  final IconData filterIcon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.all(Responsive.sp(context, 20).clamp(16.0, 24.0)),
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
                      Responsive.sp(context, 16).clamp(12.0, 20.0),
                    ),
                  ),
                  child: Icon(
                    Icons.work_history,
                    color: Colors.white,
                    size: Responsive.sp(context, 24).clamp(20.0, 28.0),
                  ),
                ),
                SizedBox(width: Responsive.hp(context, 4.0).clamp(12.0, 20.0)),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Turnos',
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          fontSize: Responsive.sp(
                            context,
                            20,
                          ).clamp(18.0, 22.0),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: Responsive.vp(context, 0.5)),
                      Text(
                        'Gestao de jornada',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.62),
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
          SizedBox(width: Responsive.hp(context, 2.0).clamp(6.0, 10.0)),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.bar_chart,
                  color: colorScheme.onSurface.withValues(alpha: 0.54),
                  size: Responsive.sp(context, 24).clamp(20.0, 28.0),
                ),
                onPressed: onOpenMetrics,
              ),
              InkWell(
                onTap: onOpenFilter,
                borderRadius: BorderRadius.circular(
                  Responsive.sp(context, 12).clamp(8.0, 16.0),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.hp(context, 3.0).clamp(10.0, 14.0),
                    vertical: Responsive.vp(context, 1.0).clamp(6.0, 10.0),
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : colorScheme.onSurface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(
                      Responsive.sp(context, 12).clamp(8.0, 16.0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        filterIcon,
                        size: Responsive.sp(context, 16).clamp(14.0, 18.0),
                        color: colorScheme.onSurface.withValues(alpha: 0.54),
                      ),
                      SizedBox(
                        width: Responsive.hp(context, 2.0).clamp(6.0, 10.0),
                      ),
                      Text(
                        filterLabel,
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
            ],
          ),
        ],
      ),
    );
  }
}
