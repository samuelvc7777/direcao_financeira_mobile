import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../widgets/scale_button.dart';
import '../transactions_controller.dart';

class TransactionsFilterTabs extends StatelessWidget {
  const TransactionsFilterTabs({
    super.key,
    required this.selectedFilter,
    required this.onChanged,
  });

  final TransactionsFilter selectedFilter;
  final ValueChanged<TransactionsFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;
    final containerPadding = Responsive.hp(context, 1.2).clamp(4.0, 6.0);
    final spacing = Responsive.hp(context, 2.2).clamp(6.0, 8.0);
    final borderRadius = Responsive.hp(context, 6.4).clamp(18.0, 20.0);

    return Container(
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.deepNavy : colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterTab(
              label: TransactionsFilter.all.label,
              icon: Icons.layers_rounded,
              accentColor: AppColors.royalBlue,
              isSelected: selectedFilter == TransactionsFilter.all,
              onTap: () => onChanged(TransactionsFilter.all),
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: _FilterTab(
              label: TransactionsFilter.income.label,
              icon: Icons.arrow_upward_rounded,
              accentColor: AppColors.emerald,
              isSelected: selectedFilter == TransactionsFilter.income,
              onTap: () => onChanged(TransactionsFilter.income),
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: _FilterTab(
              label: TransactionsFilter.expense.label,
              icon: Icons.arrow_downward_rounded,
              accentColor: AppColors.rose,
              isSelected: selectedFilter == TransactionsFilter.expense,
              onTap: () => onChanged(TransactionsFilter.expense),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;
    final horizontalPadding = Responsive.hp(context, 3.2).clamp(8.0, 10.0);
    final verticalPadding = Responsive.vp(context, 1.2).clamp(8.0, 10.0);
    final borderRadius = Responsive.hp(context, 5.4).clamp(16.0, 18.0);
    final iconSize = Responsive.sp(context, 18).clamp(16.0, 18.0);
    final labelSize = Responsive.sp(context, 14).clamp(13.0, 14.0);
    final neutralText = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : colorScheme.onSurface.withValues(alpha: 0.62);

    return ScaleButton(
      enableHaptic: false,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: isDark ? 0.18 : 0.12)
              : (isDark
                    ? AppColors.midnight
                    : colorScheme.surfaceContainerLowest),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: isDark ? 0.42 : 0.30)
                : colorScheme.outlineVariant.withValues(
                    alpha: isDark ? 0.22 : 0.5,
                  ),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: isDark ? 0.12 : 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: iconSize,
                      color: isSelected ? accentColor : neutralText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? accentColor : neutralText,
                        fontSize: labelSize,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
