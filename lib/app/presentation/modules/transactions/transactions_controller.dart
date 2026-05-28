import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/dashboard/dashboard_refresh_notifier.dart';
import '../../../core/feedback/app_snackbar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/bank_account_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/credit_card_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/usecases/transaction_use_cases.dart';

enum TransactionsFilter {
  all,
  income,
  expense;

  String get label {
    switch (this) {
      case TransactionsFilter.all:
        return 'Todos';
      case TransactionsFilter.income:
        return 'Entradas';
      case TransactionsFilter.expense:
        return 'Saídas';
    }
  }
}

enum DisplayedTransactionKind { income, expense, transfer }

class DisplayedTransactionEntry {
  DisplayedTransactionEntry.regular(this.transaction)
    : pairedTransaction = null,
      kind = transaction.type == TransactionType.expense
          ? DisplayedTransactionKind.expense
          : DisplayedTransactionKind.income;

  DisplayedTransactionEntry.invoicePayment({
    required this.transaction,
    required this.pairedTransaction,
  }) : kind = DisplayedTransactionKind.transfer;

  final TransactionEntity transaction;
  final TransactionEntity? pairedTransaction;
  final DisplayedTransactionKind kind;

  bool get isInvoicePaymentTransfer =>
      kind == DisplayedTransactionKind.transfer;

  bool get canEditOrDelete => !isInvoicePaymentTransfer;

  DateTime get transactionDate => transaction.transactionDate;

  bool get isCardOrRecurring {
    return transaction.assetType == AssetType.creditCard ||
        pairedTransaction?.assetType == AssetType.creditCard ||
        transaction.recurrenceGroupId != null ||
        pairedTransaction?.recurrenceGroupId != null;
  }

  bool get affectsBalance =>
      transaction.status == TransactionStatus.cleared &&
      (pairedTransaction?.status ?? TransactionStatus.cleared) ==
          TransactionStatus.cleared;

  int get totalCents {
    if (!affectsBalance) {
      return 0;
    }

    if (isInvoicePaymentTransfer) {
      return -transaction.displayedAmountCents;
    }

    final signal = kind == DisplayedTransactionKind.expense
        ? -1
        : kind == DisplayedTransactionKind.income
        ? 1
        : 0;
    return transaction.displayedAmountCents * signal;
  }
}

class TransactionsDayGroup {
  TransactionsDayGroup({required this.date, required this.transactions});

  final DateTime date;
  final List<DisplayedTransactionEntry> transactions;

  int get totalCents => transactions.fold<int>(
    0,
    (total, transaction) => total + transaction.totalCents,
  );
}

class TransactionsController extends GetxController {
  final CreateTransactionUseCase createTransactionUseCase;
  final UpdateTransactionUseCase updateTransactionUseCase;
  final DeleteTransactionUseCase deleteTransactionUseCase;
  final GetTransactionsUseCase getTransactionsUseCase;
  final GetCategoriesUseCase getCategoriesUseCase;
  final GetBankAccountsUseCase getBankAccountsUseCase;
  final GetCreditCardsUseCase getCreditCardsUseCase;
  final DashboardRefreshNotifier dashboardRefreshNotifier;

  TransactionsController({
    required this.createTransactionUseCase,
    required this.updateTransactionUseCase,
    required this.deleteTransactionUseCase,
    required this.getTransactionsUseCase,
    required this.getCategoriesUseCase,
    required this.getBankAccountsUseCase,
    required this.getCreditCardsUseCase,
    required this.dashboardRefreshNotifier,
  });

  final isSubmitting = false.obs;
  final isLoading = true.obs;
  final deletingTransactionIds = <int>{}.obs;

  final transactions = <TransactionEntity>[].obs;
  final categories = <CategoryEntity>[].obs;
  final activeAccounts = <BankAccountEntity>[].obs;
  final activeCards = <CreditCardEntity>[].obs;
  final selectedFilter = TransactionsFilter.all.obs;
  final selectedMonth = DateTime(DateTime.now().year, DateTime.now().month).obs;
  final isCardRecurringSectionExpanded = false.obs;
  Worker? _dashboardRefreshWorker;

  @override
  void onInit() {
    super.onInit();
    loadData();
    _dashboardRefreshWorker = ever<int>(dashboardRefreshNotifier.refreshTick, (
      _,
    ) {
      loadData(silent: true);
    });
  }

  @override
  void onClose() {
    _dashboardRefreshWorker?.dispose();
    super.onClose();
  }

  Future<void> loadData({bool silent = false}) async {
    if (!silent) {
      isLoading.value = true;
    }

    final categoriesFuture = getCategoriesUseCase();
    final bankAccountsFuture = getBankAccountsUseCase();
    final creditCardsFuture = getCreditCardsUseCase();
    final transactionsFuture = getTransactionsUseCase(selectedMonth.value);

    final categoriesResult = await categoriesFuture;
    final bankAccountsResult = await bankAccountsFuture;
    final creditCardsResult = await creditCardsFuture;
    final transactionsResult = await transactionsFuture;

    categoriesResult.fold(
      (failure) => debugPrint('Erro categorias: ${failure.message}'),
      (data) =>
          categories.assignAll(data.where((category) => category.isActive)),
    );

    bankAccountsResult.fold(
      (failure) => debugPrint('Erro contas: ${failure.message}'),
      (data) =>
          activeAccounts.assignAll(data.where((account) => account.isActive)),
    );

    creditCardsResult.fold(
      (failure) => debugPrint('Erro cartoes: ${failure.message}'),
      (data) => activeCards.assignAll(data.where((card) => card.isActive)),
    );

    transactionsResult.fold(
      (failure) => debugPrint('Erro transacoes: ${failure.message}'),
      (data) {
        final sortedData = List<TransactionEntity>.from(data)
          ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

        transactions.assignAll(sortedData);

        if (sortedData.isNotEmpty &&
            !_hasTransactionsInSelectedMonth(sortedData)) {
          final latestDate = sortedData.first.transactionDate;
          selectedMonth.value = DateTime(latestDate.year, latestDate.month);
        }
      },
    );

    if (!silent) {
      isLoading.value = false;
    }
  }

  List<CategoryEntity> get incomeCategories => categories
      .where((category) => category.type.name.toUpperCase() == 'INCOME')
      .toList();

  List<CategoryEntity> get expenseCategories => categories
      .where((category) => category.type.name.toUpperCase() == 'EXPENSE')
      .toList();

  List<TransactionEntity> get monthTransactions {
    return transactions
        .where(
          (transaction) =>
              transaction.transactionDate.year == selectedMonth.value.year &&
              transaction.transactionDate.month == selectedMonth.value.month,
        )
        .toList();
  }

  List<DisplayedTransactionEntry> get visibleTransactions {
    final displayed = displayedMonthTransactions;

    switch (selectedFilter.value) {
      case TransactionsFilter.all:
        return displayed;
      case TransactionsFilter.income:
        return displayed
            .where(
              (transaction) =>
                  transaction.kind == DisplayedTransactionKind.income,
            )
            .toList();
      case TransactionsFilter.expense:
        return displayed
            .where(
              (transaction) =>
                  transaction.kind == DisplayedTransactionKind.expense ||
                  transaction.kind == DisplayedTransactionKind.transfer,
            )
            .toList();
    }
  }

  List<DisplayedTransactionEntry> get displayedMonthTransactions =>
      _buildDisplayedTransactions(monthTransactions);

  List<DisplayedTransactionEntry> get cardRecurringVisibleTransactions =>
      visibleTransactions
          .where((transaction) => transaction.isCardOrRecurring)
          .toList();

  List<DisplayedTransactionEntry> get normalVisibleTransactions =>
      visibleTransactions
          .where((transaction) => !transaction.isCardOrRecurring)
          .toList();

  int get totalIncomeCents => displayedMonthTransactions
      .where(
        (transaction) =>
            transaction.affectsBalance &&
            transaction.kind == DisplayedTransactionKind.income,
      )
      .fold<int>(
        0,
        (total, transaction) =>
            total + transaction.transaction.displayedAmountCents,
      );

  int get totalExpenseCents => displayedMonthTransactions
      .where(
        (transaction) =>
            transaction.affectsBalance &&
            (transaction.kind == DisplayedTransactionKind.expense ||
                transaction.kind == DisplayedTransactionKind.transfer),
      )
      .fold<int>(
        0,
        (total, transaction) =>
            total + transaction.transaction.displayedAmountCents,
      );

  int get balanceCents => totalIncomeCents - totalExpenseCents;

  String get selectedMonthSubtitle {
    final formatted = DateFormat(
      "MMMM 'de' yyyy",
      'pt_BR',
    ).format(selectedMonth.value);
    return _capitalize(formatted);
  }

  String get selectedMonthLabelUppercase => DateFormat(
    'MMMM yyyy',
    'pt_BR',
  ).format(selectedMonth.value).toUpperCase();

  List<TransactionsDayGroup> get groupedCardRecurringVisibleTransactions =>
      _groupTransactionsByDay(cardRecurringVisibleTransactions);

  List<TransactionsDayGroup> get groupedNormalVisibleTransactions =>
      _groupTransactionsByDay(normalVisibleTransactions);

  List<TransactionsDayGroup> get groupedVisibleTransactions {
    return _groupTransactionsByDay(visibleTransactions);
  }

  List<TransactionsDayGroup> _groupTransactionsByDay(
    List<DisplayedTransactionEntry> source,
  ) {
    final buckets = <DateTime, List<DisplayedTransactionEntry>>{};

    for (final transaction in source) {
      final day = DateTime(
        transaction.transactionDate.year,
        transaction.transactionDate.month,
        transaction.transactionDate.day,
      );

      buckets
          .putIfAbsent(day, () => <DisplayedTransactionEntry>[])
          .add(transaction);
    }

    final groups =
        buckets.entries
            .map(
              (entry) => TransactionsDayGroup(
                date: entry.key,
                transactions: entry.value
                  ..sort(
                    (a, b) => b.transactionDate.compareTo(a.transactionDate),
                  ),
              ),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    return groups;
  }

  void changeFilter(TransactionsFilter filter) {
    selectedFilter.value = filter;
    isCardRecurringSectionExpanded.value = false;
  }

  void toggleCardRecurringSection() {
    isCardRecurringSectionExpanded.value =
        !isCardRecurringSectionExpanded.value;
  }

  Future<void> goToPreviousMonth() async {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month - 1,
    );
    isCardRecurringSectionExpanded.value = false;
    await loadData(silent: true);
  }

  Future<void> goToNextMonth() async {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month + 1,
    );
    isCardRecurringSectionExpanded.value = false;
    await loadData(silent: true);
  }

  Future<bool> createTransaction({
    required TransactionType type,
    TransactionStatus status = TransactionStatus.cleared,
    required AssetType assetType,
    required int amountCents,
    required int categoryId,
    required String description,
    required DateTime transactionDate,
    int? bankAccountId,
    int? creditCardId,
    int? installmentCount,
    int? recurrenceCount,
  }) async {
    isSubmitting.value = true;

    final result = await createTransactionUseCase(
      type: type,
      status: status,
      assetType: assetType,
      amountCents: amountCents,
      categoryId: categoryId,
      description: description,
      transactionDate: transactionDate,
      bankAccountId: bankAccountId,
      creditCardId: creditCardId,
      installmentCount: installmentCount,
      recurrenceCount: recurrenceCount,
    );

    isSubmitting.value = false;

    return result.fold(
      (failure) {
        AppSnackbar.show(
          'Erro',
          failure.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withValues(alpha: 0.12),
          colorText: Get.theme.colorScheme.onSurface,
          margin: const EdgeInsets.all(16),
        );
        return false;
      },
      (transaction) {
        if (type == TransactionType.income) {
          dev.log(
            'Receita adicionada: R\$ ${amountCents / 100} - $description',
            name: 'TRANSACTION',
          );
        }

        selectedMonth.value = DateTime(
          transaction.transactionDate.year,
          transaction.transactionDate.month,
        );
        dashboardRefreshNotifier.requestRefresh();
        return _finalizeCreateTransaction();
      },
    );
  }

  Future<bool> _finalizeCreateTransaction() async {
    await loadData(silent: true);

    Get.back();

    AppSnackbar.show(
      'Sucesso',
      'Transação registrada com sucesso.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success.withValues(alpha: 0.12),
      colorText: Get.theme.colorScheme.onSurface,
      margin: const EdgeInsets.all(16),
    );

    return true;
  }

  Future<void> updateTransaction(
    int id, {
    TransactionStatus? status,
    int? categoryId,
    String? description,
    int? amountCents,
    DateTime? transactionDate,
    TransactionMutationScope? scope,
    bool closeAfterSuccess = true,
  }) async {
    isSubmitting.value = true;

    final result = await updateTransactionUseCase(
      id,
      status: status,
      categoryId: categoryId,
      description: description,
      amountCents: amountCents,
      transactionDate: transactionDate,
      scope: scope,
    );

    isSubmitting.value = false;

    await result.fold<Future<void>>(
      (failure) async {
        AppSnackbar.show('Erro', failure.message);
      },
      (transaction) async {
        if (scope == TransactionMutationScope.all) {
          await loadData(silent: true);
        } else {
          final index = transactions.indexWhere((t) => t.id == id);
          if (index != -1) {
            transactions[index] = transaction;
          }
        }

        dashboardRefreshNotifier.requestRefresh();

        if (closeAfterSuccess) {
          Get.back();
        }
        AppSnackbar.show('Sucesso', 'Transação atualizada.');
      },
    );
  }

  Future<void> deleteTransaction(
    int id, {
    TransactionMutationScope? scope,
  }) async {
    if (deletingTransactionIds.contains(id)) {
      return;
    }

    deletingTransactionIds.add(id);
    isLoading.value = true;
    Get.closeAllSnackbars();

    try {
      final result = await deleteTransactionUseCase(id, scope: scope);

      await result.fold(
        (failure) async {
          Get.closeAllSnackbars();
          if (Get.context != null) {
            AppSnackbar.show('Erro', failure.message);
          }
        },
        (_) async {
          if (scope == TransactionMutationScope.all) {
            await loadData(silent: true);
          } else {
            transactions.removeWhere((t) => t.id == id);
          }

          dashboardRefreshNotifier.requestRefresh();

          Get.closeAllSnackbars();
          if (Get.context != null) {
            AppSnackbar.show('Sucesso', 'Transação excluída.');
          }
        },
      );
    } finally {
      deletingTransactionIds.remove(id);
      isLoading.value = false;
    }
  }

  bool isDeletingTransaction(int id) => deletingTransactionIds.contains(id);

  bool _hasTransactionsInSelectedMonth(List<TransactionEntity> data) {
    return data.any(
      (transaction) =>
          transaction.transactionDate.year == selectedMonth.value.year &&
          transaction.transactionDate.month == selectedMonth.value.month,
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() + value.substring(1);
  }

  List<DisplayedTransactionEntry> _buildDisplayedTransactions(
    List<TransactionEntity> source,
  ) {
    final groupedInvoicePayments = <String, List<TransactionEntity>>{};
    final displayed = <DisplayedTransactionEntry>[];

    for (final transaction in source) {
      if (!transaction.isInternalInvoicePayment) {
        displayed.add(DisplayedTransactionEntry.regular(transaction));
        continue;
      }

      groupedInvoicePayments
          .putIfAbsent(transaction.description, () => <TransactionEntity>[])
          .add(transaction);
    }

    for (final group in groupedInvoicePayments.values) {
      final expense = group.firstWhereOrNull(
        (item) => item.type == TransactionType.expense,
      );
      final income = group.firstWhereOrNull(
        (item) => item.type == TransactionType.income,
      );

      if (expense != null && income != null) {
        displayed.add(
          DisplayedTransactionEntry.invoicePayment(
            transaction: expense,
            pairedTransaction: income,
          ),
        );
        continue;
      }

      for (final item in group) {
        displayed.add(DisplayedTransactionEntry.regular(item));
      }
    }

    displayed.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return displayed;
  }
}
