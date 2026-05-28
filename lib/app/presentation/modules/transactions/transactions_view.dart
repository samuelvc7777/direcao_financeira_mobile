import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/subscription/subscription_access_gate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../routes/app_pages.dart';
import '../../widgets/app_month_selector.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/custom_app_bar.dart';
import 'transactions_controller.dart';
import 'widgets/transaction_type_selector_sheet.dart';
import 'widgets/transactions_card_recurring_section.dart';
import 'widgets/transactions_day_group_section.dart';
import 'widgets/transactions_empty_state.dart';
import 'widgets/transactions_filter_tabs.dart';
import 'widgets/transactions_summary_cards.dart';

class TransactionsView extends GetView<TransactionsController> {
  const TransactionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 40),
        child: Obx(
          () => CustomAppBar(
            title: 'Transações',
            subtitle: controller.selectedMonthSubtitle,
            leadingIcon: Icons.receipt_long_rounded,
            showBackButton: false,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateTransactionFlow,
        backgroundColor: colorScheme.primary,
        elevation: 8,
        child: Icon(Icons.add_rounded, color: colorScheme.onPrimary, size: 28),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoadingScreen(
            label: 'Carregando transações',
            accentColor: AppColors.violet,
          );
        }

        final currencyFormat = NumberFormat.currency(
          locale: 'pt_BR',
          symbol: 'R\$ ',
        );
        final compactCurrencyFormat = NumberFormat.currency(
          locale: 'pt_BR',
          symbol: 'R\$ ',
          decimalDigits: 0,
        );
        final cardRecurringGroups =
            controller.groupedCardRecurringVisibleTransactions;
        final normalGroups = controller.groupedNormalVisibleTransactions;
        final hasVisibleTransactions =
            cardRecurringGroups.isNotEmpty || normalGroups.isNotEmpty;
        final isCardRecurringSectionExpanded =
            controller.isCardRecurringSectionExpanded.value;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            final horizontalPadding = isWide
                ? 0.0
                : Responsive.hp(context, 4.8).clamp(16.0, 18.0);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    Responsive.vp(context, 18).clamp(132.0, 148.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppMonthSelector(
                        label: controller.selectedMonthLabelUppercase,
                        onPrevious: controller.goToPreviousMonth,
                        onNext: controller.goToNextMonth,
                      ),
                      SizedBox(
                        height: Responsive.vp(context, 1.2).clamp(8.0, 10.0),
                      ),
                      TransactionsSummaryCards(
                        incomeAmount: currencyFormat.format(
                          controller.totalIncomeCents / 100,
                        ),
                        expenseAmount: currencyFormat.format(
                          controller.totalExpenseCents / 100,
                        ),
                        balanceAmount: currencyFormat.format(
                          controller.balanceCents / 100,
                        ),
                      ),
                      SizedBox(
                        height: Responsive.vp(context, 2.2).clamp(16.0, 18.0),
                      ),
                      TransactionsFilterTabs(
                        selectedFilter: controller.selectedFilter.value,
                        onChanged: controller.changeFilter,
                      ),
                      SizedBox(
                        height: Responsive.vp(context, 3).clamp(20.0, 24.0),
                      ),
                      if (!hasVisibleTransactions)
                        TransactionsEmptyState(
                          monthLabel: controller.selectedMonthSubtitle,
                          hasTransactionsLoaded:
                              controller.transactions.isNotEmpty,
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (cardRecurringGroups.isNotEmpty) ...[
                              TransactionsCardRecurringSection(
                                groups: cardRecurringGroups,
                                transactionCount: controller
                                    .cardRecurringVisibleTransactions
                                    .length,
                                isExpanded: isCardRecurringSectionExpanded,
                                amountFormat: currencyFormat,
                                compactAmountFormat: compactCurrencyFormat,
                                onToggleExpanded:
                                    controller.toggleCardRecurringSection,
                                onTransactionTap: (transaction) => unawaited(
                                  _showTransactionActions(context, transaction),
                                ),
                              ),
                              if (normalGroups.isNotEmpty)
                                SizedBox(
                                  height: Responsive.vp(
                                    context,
                                    2.6,
                                  ).clamp(18.0, 22.0),
                                ),
                            ],
                            for (
                              var index = 0;
                              index < normalGroups.length;
                              index++
                            ) ...[
                              TransactionsDayGroupSection(
                                group: normalGroups[index],
                                amountFormat: currencyFormat,
                                compactAmountFormat: compactCurrencyFormat,
                                onTransactionTap: (transaction) => unawaited(
                                  _showTransactionActions(context, transaction),
                                ),
                              ),
                              if (index != normalGroups.length - 1)
                                SizedBox(
                                  height: Responsive.vp(
                                    context,
                                    2.2,
                                  ).clamp(16.0, 18.0),
                                ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Future<void> _openCreateTransactionFlow() async {
    if (!await SubscriptionAccessGate.ensureAccess()) {
      return;
    }

    Get.bottomSheet(
      const TransactionTypeSelectorSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> _onEditTransaction(TransactionEntity transaction) async {
    if (!await SubscriptionAccessGate.ensureAccess()) {
      return;
    }

    if (transaction.assetType == AssetType.creditCard) {
      Get.toNamed(AppRoutes.transactionCreditCard, arguments: transaction);
    } else {
      Get.toNamed(AppRoutes.transactionExpense, arguments: transaction);
    }
  }

  Future<void> _showTransactionActions(
    BuildContext context,
    TransactionEntity transaction,
  ) async {
    final action = await showModalBottomSheet<_TransactionAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransactionActionsSheet(transaction: transaction),
    );

    switch (action) {
      case _TransactionAction.edit:
        await _onEditTransaction(transaction);
        return;
      case _TransactionAction.delete:
        if (await SubscriptionAccessGate.ensureAccess()) {
          _onDeleteTransaction(transaction);
        }
        return;
      case _TransactionAction.cancel:
      case null:
        return;
    }
  }

  void _onDeleteTransaction(TransactionEntity transaction) {
    final isInstallment = transaction.installmentGroupId != null;
    final isRecurring = transaction.recurrenceGroupId != null;
    final isGrouped = isInstallment || isRecurring;
    final theme = Get.theme;
    final colorScheme = theme.colorScheme;
    final surfaceColor = colorScheme.surface;
    final titleColor = colorScheme.onSurface;
    final bodyColor = colorScheme.onSurface.withValues(alpha: 0.72);
    final secondaryActionColor = colorScheme.errorContainer;
    Get.closeAllSnackbars();

    Get.dialog(
      AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Excluir Transação',
          style: TextStyle(color: titleColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          isInstallment
              ? 'Esta transação faz parte de uma compra parcelada. O que deseja fazer?'
              : isRecurring
              ? 'Esta transação faz parte de uma recorrência mensal. O que deseja fazer?'
              : 'Deseja realmente excluir esta transação?',
          style: TextStyle(color: bodyColor),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
          ),
          if (isGrouped)
            ElevatedButton(
              onPressed: () {
                if (controller.isDeletingTransaction(transaction.id)) {
                  return;
                }

                Get.closeAllSnackbars();
                Get.back();
                controller.deleteTransaction(
                  transaction.id,
                  scope: TransactionMutationScope.all,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryActionColor,
                foregroundColor: colorScheme.onErrorContainer,
                elevation: 0,
              ),
              child: Text(isRecurring ? 'Todas Ocorrências' : 'Todas Parcelas'),
            ),
          ElevatedButton(
            onPressed: () {
              if (controller.isDeletingTransaction(transaction.id)) {
                return;
              }

              Get.closeAllSnackbars();
              Get.back();
              controller.deleteTransaction(
                transaction.id,
                scope: TransactionMutationScope.current,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              elevation: 0,
            ),
            child: Text(isGrouped ? 'Apenas esta' : 'Excluir'),
          ),
        ],
      ),
    );
  }
}

enum _TransactionAction { edit, delete, cancel }

class _TransactionActionsSheet extends StatelessWidget {
  const _TransactionActionsSheet({required this.transaction});

  final TransactionEntity transaction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final isGrouped =
        transaction.installmentGroupId != null ||
        transaction.recurrenceGroupId != null;
    final canEditOrDelete = !transaction.isInternalInvoicePayment;
    final statusColor = transaction.type == TransactionType.expense
        ? AppColors.rose
        : AppColors.emerald;
    final statusLabel = transaction.type == TransactionType.expense
        ? 'Saída'
        : 'Entrada';
    final title = transaction.categoryName?.trim().isNotEmpty == true
        ? transaction.categoryName!.trim()
        : transaction.description.trim();
    final amountLabel = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$ ',
    ).format(transaction.displayedAmount);

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      transaction.type == TransactionType.expense
                          ? Icons.trending_down_rounded
                          : Icons.trending_up_rounded,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$statusLabel - $amountLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (canEditOrDelete) ...[
                _TransactionActionTile(
                  icon: Icons.edit_outlined,
                  title: 'Editar transação',
                  subtitle: 'Abrir a tela para ajustar os dados',
                  color: AppColors.amber,
                  onTap: () =>
                      Navigator.of(context).pop(_TransactionAction.edit),
                ),
                const SizedBox(height: 10),
                _TransactionActionTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Excluir transação',
                  subtitle: isGrouped
                      ? 'Você ainda escolhe se remove só esta ocorrência'
                      : 'Remover este lançamento da lista',
                  color: AppColors.rose,
                  onTap: () =>
                      Navigator.of(context).pop(_TransactionAction.delete),
                ),
              ] else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.62,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'Lançamento interno. Não há ações de edição ou exclusão.',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              _TransactionActionTile(
                icon: Icons.close_rounded,
                title: 'Cancelar',
                subtitle: 'Fechar este menu',
                color: colorScheme.onSurfaceVariant,
                isEmphasis: false,
                onTap: () =>
                    Navigator.of(context).pop(_TransactionAction.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionActionTile extends StatelessWidget {
  const _TransactionActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isEmphasis = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isEmphasis;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(
        alpha: isEmphasis ? 0.62 : 0.42,
      ),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
