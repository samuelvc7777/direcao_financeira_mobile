import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/dashboard/dashboard_refresh_notifier.dart';
import '../../../core/feedback/app_snackbar.dart';
import '../../../core/network/realtime_client.dart';
import '../../../core/update/play_store_update_service.dart';
import '../../../domain/entities/bank_account_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/credit_card_entity.dart';
import '../../../domain/entities/goal_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/services/invoice_payment_validator.dart';
import '../../../domain/usecases/auth_session_use_cases.dart';
import '../../../domain/usecases/bank_account_use_cases.dart';
import '../../../domain/usecases/category_use_cases.dart';
import '../../../domain/usecases/credit_card_use_cases.dart';
import '../../../domain/usecases/goal_use_cases.dart';
import '../../../domain/usecases/transaction_use_cases.dart';
import '../../../routes/app_pages.dart';
import 'home_expense_chart_item.dart';
import 'home_tab_navigation.dart';

class HomeController extends GetxController {
  HomeController({
    required this.getStoredUserUseCase,
    required this.logoutUseCase,
    required this.loadBankAccountsUseCase,
    required this.loadCreditCardsUseCase,
    required this.loadCategoriesUseCase,
    required this.createCategoryUseCase,
    required this.getTransactionsUseCase,
    required this.createInvoicePaymentUseCase,
    this.loadGoalsUseCase,
    required this.invoicePaymentValidator,
    required this.dashboardRefreshNotifier,
    required this.homeTabNavigation,
    required this.realtimeClient,
    required this.appUpdateService,
  });

  final GetStoredUserUseCase getStoredUserUseCase;
  final LogoutUseCase logoutUseCase;
  final LoadBankAccountsUseCase loadBankAccountsUseCase;
  final LoadCreditCardsUseCase loadCreditCardsUseCase;
  final LoadCategoriesUseCase loadCategoriesUseCase;
  final CreateCategoryUseCase createCategoryUseCase;
  final GetTransactionsUseCase getTransactionsUseCase;
  final CreateInvoicePaymentUseCase createInvoicePaymentUseCase;
  final LoadGoalsUseCase? loadGoalsUseCase;
  final InvoicePaymentValidator invoicePaymentValidator;
  final DashboardRefreshNotifier dashboardRefreshNotifier;
  final HomeTabNavigation homeTabNavigation;
  final RealtimeClient realtimeClient;
  final AppUpdateService appUpdateService;

  final isLoading = true.obs;
  final userName = ''.obs;
  final selectedMonth = DateTime.now().obs;
  final isBalanceVisible = true.obs;
  final contas = <BankAccountEntity>[].obs;
  final cartoes = <CreditCardEntity>[].obs;
  final ultimasTransacoes = <TransactionEntity>[].obs;
  final gastosPorCategoria = <HomeExpenseChartItem>[].obs;
  final processingInvoiceCardIds = <int>[].obs;
  final isUpdateAvailable = false.obs;
  final isCheckingUpdate = false.obs;

  final goals = <GoalEntity>[].obs;

  final currentTabIndex = 0.obs;
  Worker? _dashboardRefreshWorker;
  Worker? _dashboardRealtimeWorker;
  final _dashboardRealtimeRefreshTick = 0.obs;
  int _dashboardLoadToken = 0;
  static const _dashboardRealtimeEvents = <String>[
    'transaction.created',
    'transaction.updated',
    'transaction.deleted',
    'transaction.changed',
  ];
  static const _invoicePaymentExpenseCategoryName =
      'Pagamento interno de fatura';
  static const _invoicePaymentIncomeCategoryName =
      'Recebimento interno de fatura';

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    loadDashboardData();
    _setupSocketListeners();
    unawaited(_checkForAppUpdate());
    _dashboardRefreshWorker = ever<int>(dashboardRefreshNotifier.refreshTick, (
      _,
    ) {
      loadDashboardData(silent: true);
    });
  }

  void _setupSocketListeners() {
    _dashboardRealtimeWorker = debounce<int>(
      _dashboardRealtimeRefreshTick,
      (_) => loadDashboardData(silent: true),
      time: const Duration(milliseconds: 800),
    );
    for (final event in _dashboardRealtimeEvents) {
      realtimeClient.on(event, _handleDashboardRealtimeEvent);
    }
  }

  @override
  void onClose() {
    _dashboardRefreshWorker?.dispose();
    _dashboardRealtimeWorker?.dispose();
    for (final event in _dashboardRealtimeEvents) {
      realtimeClient.off(event, _handleDashboardRealtimeEvent);
    }
    super.onClose();
  }

  void _handleDashboardRealtimeEvent(dynamic _) {
    _dashboardRealtimeRefreshTick.value++;
  }

  Future<void> loadDashboardData({
    bool silent = false,
    DateTime? referenceMonth,
  }) async {
    final month = referenceMonth ?? selectedMonth.value;
    final loadToken = ++_dashboardLoadToken;

    if (!silent) {
      isLoading.value = true;
    }

    try {
      final bankAccountsFuture = loadBankAccountsUseCase();
      final creditCardsFuture = loadCreditCardsUseCase();
      final transactionsFuture = getTransactionsUseCase(month);
      final goalsFuture = loadGoalsUseCase?.call();

      final bankResult = await bankAccountsFuture;
      final cardResult = await creditCardsFuture;
      final transactionResult = await transactionsFuture;
      final goalsResult = goalsFuture == null ? null : await goalsFuture;

      if (loadToken != _dashboardLoadToken) {
        return;
      }

      bankResult.fold(
        (failure) => debugPrint(
          '[HomeController] Erro ao carregar contas: ${failure.message}',
        ),
        (data) => contas.assignAll(data.where((a) => a.isActive).toList()),
      );

      cardResult.fold(
        (failure) => debugPrint(
          '[HomeController] Erro ao carregar cartoes: ${failure.message}',
        ),
        (data) => cartoes.assignAll(data.where((c) => c.isActive).toList()),
      );

      transactionResult.fold(
        (failure) => debugPrint(
          '[HomeController] Erro ao carregar transacoes: ${failure.message}',
        ),
        (data) {
          final sortedData = List<TransactionEntity>.from(data)
            ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
          final visibleTransactions = sortedData
              .where((transaction) => !transaction.isInternalInvoicePayment)
              .toList();
          ultimasTransacoes.assignAll(visibleTransactions);
          gastosPorCategoria.assignAll(
            _buildExpenseChartItems(visibleTransactions),
          );
        },
      );

      goalsResult?.fold(
        (failure) => debugPrint(
          '[HomeController] Erro ao carregar metas: ${failure.message}',
        ),
        (data) => goals.assignAll(data.where((goal) => !goal.isArchived)),
      );
    } catch (error, stackTrace) {
      debugPrint('[HomeController] Erro inesperado no dashboard: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (loadToken == _dashboardLoadToken && (!silent || isLoading.value)) {
        isLoading.value = false;
      }
    }
  }

  void _loadUserData() {
    final result = getStoredUserUseCase();
    result.fold(
      (failure) => debugPrint(
        '[HomeController] Erro ao carregar usuario: ${failure.message}',
      ),
      (user) {
        if (user != null) {
          userName.value = user.name;
        }
      },
    );
  }

  double get saldoTotal =>
      contas.fold(0.0, (total, c) => total + c.currentBalance);
  bool get isSaldoPositivo => saldoTotal >= 0;

  double get entradas => ultimasTransacoes
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (total, t) => total + t.amount);

  double get saidas => ultimasTransacoes
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (total, t) => total + t.amount);

  double get totalSaidas =>
      gastosPorCategoria.fold(0.0, (total, item) => total + item.amount);

  void toggleBalanceVisibility() => isBalanceVisible.toggle();

  bool isProcessingInvoicePayment(int cardId) =>
      processingInvoiceCardIds.contains(cardId);

  Future<void> payInvoice({
    required CreditCardEntity card,
    required BankAccountEntity bankAccount,
    InvoicePaymentMode mode = InvoicePaymentMode.total,
    int? amountCents,
  }) async {
    final validation = invoicePaymentValidator.validate(
      InvoicePaymentChoice(
        bankAccountId: bankAccount.id,
        creditCardId: card.id,
        mode: mode,
        amountCents: amountCents,
        payableInvoiceCents: card.payableInvoiceCents,
      ),
    );
    if (!validation.isValid) {
      _showFeedback(
        'Atencao',
        validation.errorMessage ?? 'Revise os dados do pagamento.',
      );
      return;
    }

    final resolvedAmountCents = validation.resolvedAmountCents!;
    final error = await _executeInvoicePayment(
      card: card,
      bankAccount: bankAccount,
      resolvedAmountCents: resolvedAmountCents,
    );
    if (error != null) {
      _showFeedback('Erro', error);
      return;
    }

    _showFeedback(
      'Sucesso',
      _buildInvoicePaymentSuccessMessage(
        card: card,
        bankAccount: bankAccount,
        mode: mode,
      ),
    );
  }

  Future<String?> submitInvoicePayment({
    required CreditCardEntity card,
    required BankAccountEntity bankAccount,
    required InvoicePaymentMode mode,
    int? amountCents,
  }) async {
    final validation = invoicePaymentValidator.validate(
      InvoicePaymentChoice(
        bankAccountId: bankAccount.id,
        creditCardId: card.id,
        mode: mode,
        amountCents: amountCents,
        payableInvoiceCents: card.payableInvoiceCents,
      ),
    );
    if (!validation.isValid) {
      return validation.errorMessage ?? 'Revise os dados do pagamento.';
    }

    final error = await _executeInvoicePayment(
      card: card,
      bankAccount: bankAccount,
      resolvedAmountCents: validation.resolvedAmountCents!,
    );
    if (error == null) {
      _showFeedback(
        'Sucesso',
        _buildInvoicePaymentSuccessMessage(
          card: card,
          bankAccount: bankAccount,
          mode: mode,
        ),
      );
    }

    return error;
  }

  Future<String?> _executeInvoicePayment({
    required CreditCardEntity card,
    required BankAccountEntity bankAccount,
    required int resolvedAmountCents,
  }) async {
    if (isProcessingInvoicePayment(card.id)) {
      return 'Pagamento ja esta em processamento.';
    }

    processingInvoiceCardIds.add(card.id);
    final now = DateTime.now();
    final description =
        '$kInternalInvoicePaymentDescriptionPrefix${card.id}:${bankAccount.id}:${now.toIso8601String()}';

    try {
      final expenseCategoryId = await _ensureInternalCategoryId(
        name: _invoicePaymentExpenseCategoryName,
        type: CategoryType.expense,
        color: '#D97706',
        icon: 'credit_card',
      );
      final incomeCategoryId = await _ensureInternalCategoryId(
        name: _invoicePaymentIncomeCategoryName,
        type: CategoryType.income,
        color: '#0891B2',
        icon: 'sync_alt',
      );
      final paymentResult = await createInvoicePaymentUseCase(
        bankAccountId: bankAccount.id,
        creditCardId: card.id,
        amountCents: resolvedAmountCents,
        expenseCategoryId: expenseCategoryId,
        incomeCategoryId: incomeCategoryId,
        description: description,
        transactionDate: now,
      );

      return await paymentResult.fold<Future<String?>>(
        (failure) async => failure.message,
        (_) async {
          await loadDashboardData(silent: true);
          dashboardRefreshNotifier.requestRefresh();
          return null;
        },
      );
    } on _InvoicePaymentException catch (error) {
      return error.message;
    } catch (_) {
      return 'Nao foi possivel pagar a fatura agora.';
    } finally {
      processingInvoiceCardIds.remove(card.id);
    }
  }

  Future<void> previousMonth() async {
    final previous = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month - 1,
    );
    selectedMonth.value = previous;
    await loadDashboardData(silent: true, referenceMonth: previous);
  }

  Future<void> nextMonth() async {
    final next = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month + 1,
    );
    selectedMonth.value = next;
    await loadDashboardData(silent: true, referenceMonth: next);
  }

  void changeTab(int index) => currentTabIndex.value = index;

  void openTransactionsTab() => homeTabNavigation.openTransactionsTab();

  Future<void> openAppStore() async {
    await appUpdateService.openStorePage();
  }

  void openGoals() => Get.toNamed(AppRoutes.goals);

  Future<void> logout() async {
    await logoutUseCase();
    Get.offAllNamed(AppRoutes.login);
  }

  List<HomeExpenseChartItem> _buildExpenseChartItems(
    List<TransactionEntity> transactions,
  ) {
    final expenses = transactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .toList();
    if (expenses.isEmpty) {
      return const [];
    }

    final totalsByCategory = <int, int>{};
    final labelsByCategory = <int, String>{};
    final colorsByCategory = <int, Color>{};

    for (final transaction in expenses) {
      totalsByCategory.update(
        transaction.categoryId,
        (current) => current + transaction.amountCents,
        ifAbsent: () => transaction.amountCents,
      );
      labelsByCategory.putIfAbsent(
        transaction.categoryId,
        () =>
            transaction.categoryName ?? 'Categoria #${transaction.categoryId}',
      );
      colorsByCategory.putIfAbsent(
        transaction.categoryId,
        () => _resolveCategoryColor(transaction),
      );
    }

    final totalExpenseCents = totalsByCategory.values.fold<int>(
      0,
      (total, amount) => total + amount,
    );

    final items =
        totalsByCategory.entries
            .map(
              (entry) => HomeExpenseChartItem(
                categoryId: entry.key,
                categoryLabel: labelsByCategory[entry.key]!,
                amountCents: entry.value,
                percentage: totalExpenseCents == 0
                    ? 0
                    : (entry.value / totalExpenseCents) * 100,
                color: colorsByCategory[entry.key]!,
              ),
            )
            .toList()
          ..sort((a, b) => b.amountCents.compareTo(a.amountCents));

    return items;
  }

  Color _resolveCategoryColor(TransactionEntity transaction) {
    final rawColor = transaction.categoryColor;
    if (rawColor != null && rawColor.isNotEmpty) {
      final normalized = rawColor.replaceFirst('#', '');
      final hex = normalized.length == 6 ? 'FF$normalized' : normalized;
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed != null) {
        return Color(parsed);
      }
    }

    const palette = [
      Color(0xFF3B82F6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
    ];
    return palette[transaction.categoryId.abs() % palette.length];
  }

  Future<int> _ensureInternalCategoryId({
    required String name,
    required CategoryType type,
    required String color,
    required String icon,
  }) async {
    final categoriesResult = await loadCategoriesUseCase();
    final categories = categoriesResult.fold<List<CategoryEntity>>(
      (_) => const [],
      (data) => data,
    );
    final existingCategory = categories.firstWhereOrNull(
      (category) => category.name == name && category.type == type,
    );
    if (existingCategory != null) {
      return existingCategory.id;
    }

    final createResult = await createCategoryUseCase(
      name: name,
      type: type,
      color: color,
      icon: icon,
    );

    return createResult.fold(
      (failure) => throw _InvoicePaymentException(failure.message),
      (category) => category.id,
    );
  }

  String _buildInvoicePaymentSuccessMessage({
    required CreditCardEntity card,
    required BankAccountEntity bankAccount,
    required InvoicePaymentMode mode,
  }) {
    if (mode == InvoicePaymentMode.partial) {
      return 'Pagamento parcial da fatura "${card.name}" registrado com ${bankAccount.name}.';
    }

    return 'Fatura do cartao "${card.name}" paga com ${bankAccount.name}.';
  }

  Future<void> _checkForAppUpdate() async {
    if (isCheckingUpdate.value) {
      return;
    }

    isCheckingUpdate.value = true;
    try {
      final available = await appUpdateService.hasUpdateAvailable();
      isUpdateAvailable.value = available;
      debugPrint(
        '[HomeController] Verificacao de update concluida -> disponivel=$available',
      );
    } catch (error, stackTrace) {
      debugPrint('[HomeController] Falha ao verificar update: $error');
      debugPrintStack(stackTrace: stackTrace);
      isUpdateAvailable.value = false;
    } finally {
      isCheckingUpdate.value = false;
    }
  }

  void _showFeedback(String title, String message) {
    if (Get.testMode) {
      debugPrint('[HomeController] Feedback teste: $title - $message');
      return;
    }

    try {
      AppSnackbar.show(title, message);
    } catch (_) {
      debugPrint('[HomeController] Feedback suprimido: $title - $message');
    }
  }
}

class _InvoicePaymentException implements Exception {
  _InvoicePaymentException(this.message);

  final String message;
}
