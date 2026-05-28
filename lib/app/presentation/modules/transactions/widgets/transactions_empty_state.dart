import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

class TransactionsEmptyState extends StatelessWidget {
  const TransactionsEmptyState({
    super.key,
    required this.monthLabel,
    required this.hasTransactionsLoaded,
  });

  final String monthLabel;
  final bool hasTransactionsLoaded;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final title = hasTransactionsLoaded
        ? 'Nenhuma transação nesse período'
        : 'Nenhuma transação cadastrada';
    final subtitle = hasTransactionsLoaded
        ? 'Não encontramos movimentações para $monthLabel. Troque o mês ou crie uma nova transação.'
        : 'Assim que você registrar entradas ou saídas, elas aparecerão aqui com o resumo do período.';
    final containerPadding = Responsive.hp(context, 6.4).clamp(20.0, 24.0);
    final borderRadius = Responsive.hp(context, 7.4).clamp(24.0, 28.0);
    final iconBoxSize = Responsive.hp(context, 20).clamp(68.0, 76.0);
    final iconBoxRadius = Responsive.hp(context, 6.4).clamp(20.0, 24.0);
    final iconSize = Responsive.sp(context, 36).clamp(30.0, 36.0);
    final titleSize = Responsive.sp(context, 20).clamp(18.0, 20.0);
    final subtitleSize = Responsive.sp(context, 14).clamp(13.0, 14.0);
    final titleSpacing = Responsive.vp(context, 2.2).clamp(14.0, 18.0);
    final subtitleSpacing = Responsive.vp(context, 1.2).clamp(8.0, 10.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(iconBoxRadius),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: iconSize,
              color: AppColors.violet,
            ),
          ),
          SizedBox(height: titleSpacing),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: subtitleSpacing),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.58),
              fontSize: subtitleSize,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
