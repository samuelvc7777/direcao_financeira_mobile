import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../home_controller.dart';
import 'package:direcao_financeira_mobile/app/core/theme/app_colors.dart';
import '../../../../domain/entities/transaction_entity.dart';

class RecentTransactionsSection extends GetView<HomeController> {
  const RecentTransactionsSection({
    super.key,
    required this.onViewAllTransactions,
  });

  final VoidCallback onViewAllTransactions;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final dateFormat = DateFormat('dd/MM', 'pt_BR');

    return Obx(() {
      final transacoes = controller.ultimasTransacoes.take(5).toList();
      final isVisible = controller.isBalanceVisible.value;

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: context.theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.royalBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: AppColors.royalBlue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Últimas transações',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.royalBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onViewAllTransactions,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Ver todas',
                      style: TextStyle(
                        color: AppColors.royalBlue.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...transacoes.map(
              (t) => _buildTransactionItem(
                context,
                t,
                isVisible,
                currencyFormat,
                dateFormat,
              ),
            ),
            if (transacoes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Nenhuma transacao registrada.',
                  style: TextStyle(
                    color: context.theme.colorScheme.onSurface.withValues(
                      alpha: 0.3,
                    ),
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildTransactionItem(
    BuildContext context,
    TransactionEntity transacao,
    bool isVisible,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    final valor = transacao.amount;
    final isNegativo = transacao.type == TransactionType.expense;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 390;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.theme.colorScheme.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.theme.colorScheme.onSurface.withValues(
                alpha: 0.05,
              ),
            ),
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildLeading(isNegativo),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildInfo(context, transacao, dateFormat),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _buildValue(
                        valor,
                        isNegativo,
                        isVisible,
                        currencyFormat,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    _buildLeading(isNegativo),
                    const SizedBox(width: 14),
                    Expanded(child: _buildInfo(context, transacao, dateFormat)),
                    const SizedBox(width: 12),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _buildValue(
                          valor,
                          isNegativo,
                          isVisible,
                          currencyFormat,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildLeading(bool isNegativo) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (isNegativo ? AppColors.rose : AppColors.emerald).withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isNegativo ? Icons.arrow_downward : Icons.arrow_upward,
        color: isNegativo ? AppColors.rose : AppColors.emerald,
        size: 18,
      ),
    );
  }

  Widget _buildInfo(
    BuildContext context,
    TransactionEntity transacao,
    DateFormat dateFormat,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          transacao.description,
          style: TextStyle(
            color: context.theme.colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${transacao.categoryName ?? 'Sem categoria'} • ${dateFormat.format(transacao.transactionDate)}',
          style: TextStyle(
            color: context.theme.colorScheme.onSurface.withValues(alpha: 0.4),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildValue(
    double valor,
    bool isNegativo,
    bool isVisible,
    NumberFormat currencyFormat,
  ) {
    return Text(
      isVisible
          ? '${isNegativo ? '- ' : '+ '}${currencyFormat.format(valor)}'
          : 'R\$ ....',
      style: TextStyle(
        color: isNegativo ? AppColors.rose : AppColors.emerald,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
