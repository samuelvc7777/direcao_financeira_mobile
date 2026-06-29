import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../transactions_controller.dart';

class TransactionsFilterTabs extends StatelessWidget {
  const TransactionsFilterTabs({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final TransactionsFilter selectedFilter;
  final ValueChanged<TransactionsFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;

    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.58)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : colorScheme.outlineVariant.withValues(alpha: 0.42),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Row(
            children: [
              _FilterTab(
                label: TransactionsFilter.all.label,
                icon: Icons.filter_list_rounded,
                accentColor: AppColors.royalBlue,
                isSelected: selectedFilter == TransactionsFilter.all,
                onTap: () => onFilterChanged(TransactionsFilter.all),
              ),
              const SizedBox(width: 5),
              _FilterTab(
                label: TransactionsFilter.income.label,
                icon: Icons.arrow_upward_rounded,
                accentColor: AppColors.emerald,
                isSelected: selectedFilter == TransactionsFilter.income,
                onTap: () => onFilterChanged(TransactionsFilter.income),
              ),
              const SizedBox(width: 5),
              _FilterTab(
                label: TransactionsFilter.expense.label,
                icon: Icons.arrow_downward_rounded,
                accentColor: AppColors.rose,
                isSelected: selectedFilter == TransactionsFilter.expense,
                onTap: () => onFilterChanged(TransactionsFilter.expense),
              ),
            ],
          ),
        ),
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
    final neutralColor = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : colorScheme.onSurface.withValues(alpha: 0.62);
    final foregroundColor = isSelected ? accentColor : neutralColor;

    return Expanded(
      child: SizedBox.expand(
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(19),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              curve: Curves.easeOutCubic,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: isDark ? 0.18 : 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: isSelected
                      ? accentColor.withValues(alpha: isDark ? 0.36 : 0.28)
                      : Colors.transparent,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 15, color: foregroundColor),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
