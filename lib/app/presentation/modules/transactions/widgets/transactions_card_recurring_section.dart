import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../domain/entities/transaction_entity.dart';
import '../transactions_controller.dart';
import 'transactions_day_group_section.dart';

class TransactionsCardRecurringSection extends StatelessWidget {
  const TransactionsCardRecurringSection({
    super.key,
    required this.groups,
    required this.transactionCount,
    required this.isExpanded,
    required this.amountFormat,
    required this.compactAmountFormat,
    required this.onToggleExpanded,
    required this.onTransactionTap,
  });

  final List<TransactionsDayGroup> groups;
  final int transactionCount;
  final bool isExpanded;
  final NumberFormat amountFormat;
  final NumberFormat compactAmountFormat;
  final VoidCallback onToggleExpanded;
  final ValueChanged<TransactionEntity> onTransactionTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final verticalGap = Responsive.vp(context, 2.0).clamp(14.0, 16.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onToggleExpanded,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.hp(context, 4).clamp(14.0, 16.0),
                vertical: Responsive.vp(context, 1.7).clamp(12.0, 14.0),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.violet.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.credit_card_rounded,
                      color: AppColors.violet,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cartao e recorrentes',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$transactionCount ${transactionCount == 1 ? 'transacao' : 'transacoes'} no topo',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.58,
                            ),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: isExpanded
              ? Padding(
                  padding: EdgeInsets.only(top: verticalGap),
                  child: Column(
                    children: [
                      for (var index = 0; index < groups.length; index++) ...[
                        TransactionsDayGroupSection(
                          group: groups[index],
                          amountFormat: amountFormat,
                          compactAmountFormat: compactAmountFormat,
                          onTransactionTap: onTransactionTap,
                        ),
                        if (index != groups.length - 1)
                          SizedBox(
                            height: Responsive.vp(
                              context,
                              2.2,
                            ).clamp(16.0, 18.0),
                          ),
                      ],
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
