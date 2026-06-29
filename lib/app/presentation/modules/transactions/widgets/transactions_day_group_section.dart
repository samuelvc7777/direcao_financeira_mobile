import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/transaction_entity.dart';
import '../transactions_controller.dart';

class TransactionsDayGroupSection extends StatelessWidget {
  const TransactionsDayGroupSection({
    super.key,
    required this.group,
    required this.amountFormat,
    required this.compactAmountFormat,
    required this.onTransactionTap,
  });

  final TransactionsDayGroup group;
  final NumberFormat amountFormat;
  final NumberFormat compactAmountFormat;
  final ValueChanged<TransactionEntity> onTransactionTap;

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatGroupDate(group.date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TransactionDateHeader(dateLabel: dateLabel),
        const SizedBox(height: 10),
        Column(
          children: [
            for (var index = 0; index < group.transactions.length; index++) ...[
              _TransactionFinanceCard(
                entry: group.transactions[index],
                amountFormat: amountFormat,
                onTap: () =>
                    onTransactionTap(group.transactions[index].transaction),
              ),
              if (index != group.transactions.length - 1)
                const SizedBox(height: 10),
            ],
          ],
        ),
      ],
    );
  }
}

String _formatGroupDate(DateTime date) {
  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);
  final dateOnly = DateTime(date.year, date.month, date.day);

  if (dateOnly == todayOnly) {
    return 'Hoje, ${DateFormat('dd/MM/yyyy', 'pt_BR').format(date)}';
  }

  if (dateOnly == todayOnly.subtract(const Duration(days: 1))) {
    return 'Ontem, ${DateFormat('dd/MM/yyyy', 'pt_BR').format(date)}';
  }

  final weekday = DateFormat('EEEE', 'pt_BR').format(date);
  final capitalizedWeekday = weekday.isEmpty
      ? weekday
      : '${weekday[0].toUpperCase()}${weekday.substring(1)}';
  return '$capitalizedWeekday, ${DateFormat('dd/MM/yyyy', 'pt_BR').format(date)}';
}

class _TransactionDateHeader extends StatelessWidget {
  const _TransactionDateHeader({required this.dateLabel});

  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 13,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                dateLabel,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _TransactionFinanceCard extends StatelessWidget {
  const _TransactionFinanceCard({
    required this.entry,
    required this.amountFormat,
    required this.onTap,
  });

  final DisplayedTransactionEntry entry;
  final NumberFormat amountFormat;
  final VoidCallback onTap;

  TransactionEntity get transaction => entry.transaction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;
    final isTransfer = entry.kind == DisplayedTransactionKind.transfer;
    final stateColor = _resolveStateColor();
    final title = _resolveTitle();
    final subtitle = _resolveSubtitle(title);
    final secondaryChipLabel = _resolveSecondaryChipLabel();
    final dateTimeLabel = DateFormat(
      'dd/MM HH:mm',
      'pt_BR',
    ).format(transaction.transactionDate);
    final amountLabel = amountFormat.format(transaction.displayedAmount);
    final amountPrefix = transaction.type == TransactionType.expense
        ? '-'
        : '+';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? stateColor.withValues(alpha: 0.05)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: stateColor.withValues(alpha: 0.40)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(
                  alpha: isDark ? 0.20 : 0.08,
                ),
                blurRadius: 16,
                offset: const Offset(0, 8),
                spreadRadius: -10,
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: stateColor,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(18),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: stateColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                _resolveIcon(),
                                color: stateColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  if (subtitle != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            _AmountPill(
                              label: '$amountPrefix $amountLabel',
                              color: stateColor,
                              icon: transaction.type == TransactionType.expense
                                  ? Icons.north_east_rounded
                                  : Icons.south_west_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 5,
                          children: [
                            _DateTimeLabel(dateTimeLabel: dateTimeLabel),
                            _InfoChip(
                              label: _resolveStatusChipLabel(isTransfer),
                              icon: _resolveStatusChipIcon(isTransfer),
                              backgroundColor: stateColor.withValues(
                                alpha: 0.12,
                              ),
                              borderColor: stateColor.withValues(alpha: 0.28),
                              textColor: stateColor,
                            ),
                            _InfoChip(
                              label: secondaryChipLabel,
                              icon: _resolveSecondaryChipIcon(),
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                              borderColor: colorScheme.outlineVariant,
                              textColor: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _resolveTitle() {
    if (entry.isInvoicePaymentTransfer) {
      return 'Pagamento de fatura';
    }

    final categoryName = transaction.categoryName?.trim();
    if (categoryName != null && categoryName.isNotEmpty) {
      return categoryName;
    }

    return transaction.description.trim();
  }

  String? _resolveSubtitle(String title) {
    if (entry.isInvoicePaymentTransfer) {
      final sourceName = transaction.assetName?.trim();
      final targetName = entry.pairedTransaction?.assetName?.trim();
      if (sourceName != null &&
          sourceName.isNotEmpty &&
          targetName != null &&
          targetName.isNotEmpty) {
        return '$sourceName -> $targetName';
      }
      if (sourceName != null && sourceName.isNotEmpty) {
        return sourceName;
      }
      return 'Pagamento da fatura com saldo da conta';
    }

    final description = transaction.description.trim();
    if (description.isEmpty) {
      return null;
    }

    if (description.toLowerCase() == title.toLowerCase()) {
      return null;
    }

    return description;
  }

  String _resolveSecondaryChipLabel() {
    if (entry.isInvoicePaymentTransfer) {
      final targetName = entry.pairedTransaction?.assetName?.trim();
      if (targetName != null && targetName.isNotEmpty) {
        return targetName;
      }
      return 'Cartao';
    }

    if (transaction.assetType == AssetType.creditCard) {
      if (transaction.installmentNumber != null &&
          transaction.installmentCount != null) {
        return '${transaction.installmentNumber}/${transaction.installmentCount}';
      }
      return 'A vista';
    }

    if (transaction.recurrenceNumber != null &&
        transaction.recurrenceCount != null) {
      return '${transaction.recurrenceNumber}/${transaction.recurrenceCount}';
    }

    if (transaction.recurrenceGroupId != null) {
      return 'Recorrente';
    }

    final assetName = transaction.assetName?.trim();
    if (assetName != null && assetName.isNotEmpty) {
      return assetName;
    }

    return 'A vista';
  }

  IconData _resolveSecondaryChipIcon() {
    if (entry.isInvoicePaymentTransfer) {
      return Icons.outbox_rounded;
    }

    if (transaction.recurrenceGroupId != null) {
      return Icons.repeat_rounded;
    }

    return transaction.assetType == AssetType.creditCard
        ? Icons.layers_rounded
        : Icons.account_balance_wallet_rounded;
  }

  IconData _resolveIcon() {
    if (entry.isInvoicePaymentTransfer) {
      return Icons.receipt_long_rounded;
    }

    final iconMap = <String, IconData>{
      'car': Icons.directions_car_rounded,
      'food': Icons.restaurant_rounded,
      'health': Icons.health_and_safety_rounded,
      'home': Icons.home_rounded,
      'education': Icons.school_rounded,
      'transporte': Icons.directions_bus_rounded,
      'salary': Icons.work_rounded,
      'income': Icons.south_west_rounded,
      'expense': Icons.north_east_rounded,
      'shopping': Icons.shopping_bag_rounded,
      'default': Icons.payments_rounded,
    };

    return iconMap[transaction.categoryIcon] ??
        (transaction.assetType == AssetType.creditCard
            ? Icons.credit_card_rounded
            : transaction.type == TransactionType.expense
            ? Icons.north_east_rounded
            : Icons.south_west_rounded);
  }

  String _resolveStatusChipLabel(bool isTransfer) {
    if (transaction.status == TransactionStatus.pending) {
      return isTransfer ? 'Transferencia' : 'Pendente';
    }

    return transaction.type == TransactionType.expense ? 'Pago' : 'Recebido';
  }

  IconData _resolveStatusChipIcon(bool isTransfer) {
    if (transaction.status == TransactionStatus.pending) {
      return isTransfer ? Icons.swap_horiz_rounded : Icons.schedule_rounded;
    }

    return transaction.type == TransactionType.expense
        ? Icons.north_east_rounded
        : Icons.south_west_rounded;
  }

  Color _resolveStateColor() {
    return transaction.type == TransactionType.expense
        ? AppColors.rose
        : AppColors.emerald;
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTimeLabel extends StatelessWidget {
  const _DateTimeLabel({required this.dateTimeLabel});

  final String dateTimeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_rounded,
            size: 13,
            color: context.theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 4),
          Text(
            dateTimeLabel,
            style: TextStyle(
              color: context.theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountPill extends StatelessWidget {
  const _AmountPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 88),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
