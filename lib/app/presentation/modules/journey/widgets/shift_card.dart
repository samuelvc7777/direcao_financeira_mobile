import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../domain/entities/shift_entity.dart';
import '../../../../routes/app_pages.dart';

class ShiftCard extends StatelessWidget {
  const ShiftCard({
    super.key,
    required this.shift,
    this.onDelete,
    this.isDeleting = false,
  });

  final ShiftEntity shift;
  final VoidCallback? onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(
        bottom: Responsive.vp(context, 1.5).clamp(8.0, 12.0),
      ),
      padding: EdgeInsets.all(Responsive.sp(context, 16.0).clamp(12.0, 20.0)),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.2)
            : colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(
          Responsive.sp(context, 20).clamp(16.0, 24.0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: Responsive.sp(context, 40).clamp(36.0, 44.0),
            height: Responsive.sp(context, 40).clamp(36.0, 44.0),
            decoration: BoxDecoration(
              color: isDark ? Colors.black : colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.royalBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Text(
                shift.index.toString(),
                style: TextStyle(
                  color: AppColors.royalBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.sp(context, 16).clamp(14.0, 18.0),
                ),
              ),
            ),
          ),
          SizedBox(width: Responsive.hp(context, 4.0).clamp(12.0, 20.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.62),
                      size: Responsive.sp(context, 16).clamp(14.0, 18.0),
                    ),
                    SizedBox(
                      width: Responsive.hp(context, 2.0).clamp(6.0, 10.0),
                    ),
                    Text(
                      shift.date,
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.62),
                        fontSize: Responsive.sp(context, 14).clamp(12.0, 16.0),
                      ),
                    ),
                    if (shift.isPendingSync) ...[
                      SizedBox(
                        width: Responsive.hp(context, 2.0).clamp(6.0, 10.0),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.hp(
                            context,
                            2.0,
                          ).clamp(6.0, 10.0),
                          vertical: Responsive.vp(context, 0.4).clamp(3.0, 5.0),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Pendente',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: Responsive.sp(
                              context,
                              11,
                            ).clamp(10.0, 12.0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: Responsive.vp(context, 1.0).clamp(6.0, 10.0)),
                Row(
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.62),
                      size: Responsive.sp(context, 16).clamp(14.0, 18.0),
                    ),
                    SizedBox(
                      width: Responsive.hp(context, 2.0).clamp(6.0, 10.0),
                    ),
                    Text(
                      'Inicio: ${shift.startTime}',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: Responsive.sp(context, 14).clamp(12.0, 16.0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.vp(context, 0.8).clamp(4.0, 8.0)),
                Row(
                  children: [
                    Icon(
                      Icons.stop_rounded,
                      color: AppColors.rose,
                      size: Responsive.sp(context, 16).clamp(14.0, 18.0),
                    ),
                    SizedBox(
                      width: Responsive.hp(context, 2.0).clamp(6.0, 10.0),
                    ),
                    Text(
                      'Fim: ${shift.endTime}',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: Responsive.sp(context, 14).clamp(12.0, 16.0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.vp(context, 0.8).clamp(4.0, 8.0)),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: AppColors.royalBlue,
                      size: Responsive.sp(context, 16).clamp(14.0, 18.0),
                    ),
                    SizedBox(
                      width: Responsive.hp(context, 2.0).clamp(6.0, 10.0),
                    ),
                    Text(
                      'Tempo total: ${shift.duration}',
                      style: TextStyle(
                        color: AppColors.royalBlue,
                        fontSize: Responsive.sp(context, 14).clamp(12.0, 16.0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (shift.drivenKm != null || shift.hasRoute) ...[
                  SizedBox(height: Responsive.vp(context, 0.8).clamp(4.0, 8.0)),
                  if (shift.drivenKm != null)
                    Row(
                      children: [
                        Icon(
                          Icons.route_rounded,
                          color: AppColors.electricCyan,
                          size: Responsive.sp(context, 16).clamp(14.0, 18.0),
                        ),
                        SizedBox(
                          width: Responsive.hp(context, 2.0).clamp(6.0, 10.0),
                        ),
                        Text(
                          '${shift.drivenKm} km rodados',
                          style: TextStyle(
                            color: AppColors.electricCyan,
                            fontSize: Responsive.sp(
                              context,
                              14,
                            ).clamp(12.0, 16.0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  if (shift.hasRoute) ...[
                    SizedBox(
                      height: Responsive.vp(context, 1.0).clamp(6.0, 10.0),
                    ),
                    InkWell(
                      onTap: () =>
                          Get.toNamed(AppRoutes.shiftRoute, arguments: shift),
                      borderRadius: BorderRadius.circular(
                        Responsive.sp(context, 8).clamp(6.0, 10.0),
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.hp(
                            context,
                            3.0,
                          ).clamp(10.0, 14.0),
                          vertical: Responsive.vp(context, 0.5).clamp(4.0, 8.0),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.electricCyan.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            Responsive.sp(context, 8).clamp(6.0, 10.0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              color: AppColors.electricCyan,
                              size: Responsive.sp(
                                context,
                                14,
                              ).clamp(12.0, 16.0),
                            ),
                            SizedBox(
                              width: Responsive.hp(
                                context,
                                1.5,
                              ).clamp(4.0, 8.0),
                            ),
                            Text(
                              'Ver Rota',
                              style: TextStyle(
                                color: AppColors.electricCyan,
                                fontSize: Responsive.sp(
                                  context,
                                  12,
                                ).clamp(10.0, 14.0),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Excluir turno',
                onPressed: isDeleting ? null : onDelete,
                icon: isDeleting
                    ? SizedBox(
                        width: Responsive.sp(context, 18).clamp(16.0, 20.0),
                        height: Responsive.sp(context, 18).clamp(16.0, 20.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.rose,
                        ),
                      )
                    : Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.rose,
                        size: Responsive.sp(context, 22).clamp(18.0, 24.0),
                      ),
              ),
              Icon(
                shift.isPendingSync
                    ? Icons.sync_problem_rounded
                    : Icons.check_circle_rounded,
                color: shift.isPendingSync
                    ? AppColors.warning
                    : AppColors.royalBlue,
                size: Responsive.sp(context, 22).clamp(18.0, 24.0),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
