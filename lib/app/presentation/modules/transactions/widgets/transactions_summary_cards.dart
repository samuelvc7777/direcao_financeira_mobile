import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

class TransactionsSummaryCards extends StatelessWidget {
  const TransactionsSummaryCards({
    super.key,
    required this.incomeAmount,
    required this.expenseAmount,
    required this.balanceAmount,
  });

  final String incomeAmount;
  final String expenseAmount;
  final String balanceAmount;

  @override
  Widget build(BuildContext context) {
    final spacing = Responsive.hp(context, 3.2).clamp(8.0, 10.0);

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Entradas',
            value: incomeAmount,
            color: AppColors.emerald,
            icon: Icons.arrow_upward_rounded,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: _SummaryCard(
            label: 'Saídas',
            value: expenseAmount,
            color: AppColors.rose,
            icon: Icons.arrow_downward_rounded,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: _SummaryCard(
            label: 'Saldo',
            value: balanceAmount,
            color: AppColors.royalBlue,
            icon: Icons.account_balance_wallet_rounded,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;
    final horizontalPadding = Responsive.hp(context, 3.2).clamp(8.0, 10.0);
    final verticalPadding = Responsive.vp(context, 1.5).clamp(10.0, 12.0);
    final borderRadius = Responsive.hp(context, 5.0).clamp(16.0, 20.0);
    final iconSize = Responsive.sp(context, 16).clamp(14.0, 16.0);
    final labelSize = Responsive.sp(context, 12).clamp(10.0, 12.0);
    final valueSize = Responsive.sp(context, 14).clamp(12.0, 14.0);
    final contentSpacing = Responsive.vp(context, 1.0).clamp(6.0, 8.0);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.midnight : colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: iconSize),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                    fontSize: labelSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: contentSpacing),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: valueSize,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
