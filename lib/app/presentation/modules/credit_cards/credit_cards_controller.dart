import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/dashboard/dashboard_refresh_notifier.dart';
import '../../../core/feedback/app_snackbar.dart';
import '../../../domain/entities/bank_account_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/credit_card_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/services/invoice_payment_validator.dart';
import '../../../domain/usecases/bank_account_use_cases.dart';
import '../../../domain/usecases/category_use_cases.dart';
import '../../../domain/usecases/credit_card_use_cases.dart';
import '../../../domain/usecases/invoice_notification_use_cases.dart';
import '../../../domain/usecases/transaction_use_cases.dart';

class CreditCardsController extends GetxController {
  CreditCardsController({
    required this.loadCreditCardsUseCase,
    required this.createCreditCardUseCase,
    required this.updateCreditCardUseCase,
    required this.deactivateCreditCardUseCase,
    required this.reactivateCreditCardUseCase,
    required this.loadBankAccountsUseCase,
    required this.loadCategoriesUseCase,
    required this.createCategoryUseCase,
    required this.createInvoicePaymentUseCase,
    required this.invoicePaymentValidator,
    this.rescheduleInvoiceNotificationsUseCase,
    required this.dashboardRefreshNotifier,
  });

  final LoadCreditCardsUseCase loadCreditCardsUseCase;
  final CreateCreditCardUseCase createCreditCardUseCase;
  final UpdateCreditCardUseCase updateCreditCardUseCase;
  final DeactivateCreditCardUseCase deactivateCreditCardUseCase;
  final ReactivateCreditCardUseCase reactivateCreditCardUseCase;
  final LoadBankAccountsUseCase loadBankAccountsUseCase;
  final LoadCategoriesUseCase loadCategoriesUseCase;
  final CreateCategoryUseCase createCategoryUseCase;
  final CreateInvoicePaymentUseCase createInvoicePaymentUseCase;
  final InvoicePaymentValidator invoicePaymentValidator;
  final RescheduleInvoiceNotificationsUseCase?
  rescheduleInvoiceNotificationsUseCase;
  final DashboardRefreshNotifier dashboardRefreshNotifier;

  final isLoading = true.obs;
  final isSubmitting = false.obs;
  final errorMessage = RxnString();
  final creditCards = <CreditCardEntity>[].obs;
  final bankAccounts = <BankAccountEntity>[].obs;
  final processingInvoiceCardIds = <int>[].obs;

  static const _invoicePaymentExpenseCategoryName =
      'Pagamento interno de fatura';
  static const _invoicePaymentIncomeCategoryName =
      'Recebimento interno de fatura';

  final colorOptions = const <String>[
    '#22c55e',
    '#06B6D4',
    '#038C8C',
    '#3b82f6',
    '#6366f1',
    '#8B5CF6',
    '#f97316',
    '#ef4444',
    '#eab308',
    '#ec4899',
  ];

  List<CreditCardEntity> get activeCards =>
      creditCards.where((card) => card.isActive).toList();

  List<CreditCardEntity> get inactiveCards =>
      creditCards.where((card) => !card.isActive).toList();

  @override
  void onInit() {
    super.onInit();
    loadCreditCards();
  }

  Future<void> loadCreditCards() async {
    isLoading.value = true;
    errorMessage.value = null;
    final cardsResult = await loadCreditCardsUseCase();
    final accountsResult = await loadBankAccountsUseCase();

    cardsResult.fold((failure) => errorMessage.value = failure.message, (data) {
      creditCards.assignAll(data);
      _rescheduleInvoiceNotifications(data);
    });
    accountsResult.fold(
      (failure) => debugPrint(
        '[CreditCardsController] Erro ao carregar contas: ${failure.message}',
      ),
      (data) => bankAccounts.assignAll(data.where((a) => a.isActive).toList()),
    );

    isLoading.value = false;
  }

  void _rescheduleInvoiceNotifications(List<CreditCardEntity> cards) {
    final useCase = rescheduleInvoiceNotificationsUseCase;
    if (useCase == null) {
      return;
    }
    unawaited(useCase(cards));
  }

  bool isProcessingInvoicePayment(int cardId) =>
      processingInvoiceCardIds.contains(cardId);

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
      final result = await createInvoicePaymentUseCase(
        bankAccountId: bankAccount.id,
        creditCardId: card.id,
        amountCents: validation.resolvedAmountCents!,
        expenseCategoryId: expenseCategoryId,
        incomeCategoryId: incomeCategoryId,
        description: description,
        transactionDate: now,
      );

      return await result.fold<Future<String?>>(
        (failure) async => failure.message,
        (_) async {
          await loadCreditCards();
          dashboardRefreshNotifier.requestRefresh();
          _showFeedback(
            'Sucesso',
            mode == InvoicePaymentMode.partial
                ? 'Pagamento parcial registrado com sucesso.'
                : 'Fatura paga com sucesso.',
          );
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

  Future<void> createCreditCard({
    required String name,
    required String brand,
    required String color,
    required int limitCents,
    required int closingDay,
    required int dueDay,
    required String lastFourDigits,
  }) async {
    await _runSubmission(
      action: () => createCreditCardUseCase(
        name: name,
        brand: brand,
        color: color,
        limitCents: limitCents,
        closingDay: closingDay,
        dueDay: dueDay,
        lastFourDigits: lastFourDigits,
      ),
      successMessage: 'Cartao de credito criado com sucesso.',
    );
  }

  Future<void> updateCreditCard({
    required int id,
    required String name,
    required String brand,
    required String color,
    required int limitCents,
    required int closingDay,
    required int dueDay,
    required String lastFourDigits,
  }) async {
    await _runSubmission(
      action: () => updateCreditCardUseCase(
        id: id,
        name: name,
        brand: brand,
        color: color,
        limitCents: limitCents,
        closingDay: closingDay,
        dueDay: dueDay,
        lastFourDigits: lastFourDigits,
      ),
      successMessage: 'Cartao de credito atualizado com sucesso.',
    );
  }

  Future<void> toggleCardStatus(CreditCardEntity card) async {
    final isDeactivating = card.isActive;
    final actionName = isDeactivating ? 'desativar' : 'reativar';
    final actionNameCap = isDeactivating ? 'Desativar' : 'Reativar';

    final confirmed =
        await Get.dialog<bool>(
          AlertDialog(
            backgroundColor: Get.theme.colorScheme.surface,
            title: Text(
              '$actionNameCap cartao',
              style: TextStyle(color: Get.theme.colorScheme.onSurface),
            ),
            content: Text(
              'O cartao "${card.name}" sera ${actionName}ado.',
              style: TextStyle(
                color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.75),
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Get.back(result: true),
                style: FilledButton.styleFrom(
                  backgroundColor: isDeactivating
                      ? const Color(0xFFBF4124)
                      : const Color(0xFF03A696),
                ),
                child: Text(actionNameCap),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    isSubmitting.value = true;
    final result = isDeactivating
        ? await deactivateCreditCardUseCase(card.id)
        : await reactivateCreditCardUseCase(card.id);

    await result.fold(
      (failure) async => _showFeedback('Erro', failure.message, isError: true),
      (_) async {
        await loadCreditCards();
        dashboardRefreshNotifier.requestRefresh();
        if (Get.isBottomSheetOpen ?? false) {
          Get.back();
        }
        _showFeedback('Sucesso', 'Cartao ${actionName}ado com sucesso.');
      },
    );

    isSubmitting.value = false;
  }

  Future<void> _runSubmission({
    required Future<dynamic> Function() action,
    required String successMessage,
  }) async {
    isSubmitting.value = true;
    final result = await action();

    await result.fold(
      (failure) async => _showFeedback('Erro', failure.message, isError: true),
      (_) async {
        await loadCreditCards();
        dashboardRefreshNotifier.requestRefresh();
        if (Get.isBottomSheetOpen ?? false) {
          Get.back();
        }
        _showFeedback('Sucesso', successMessage);
      },
    );

    isSubmitting.value = false;
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

  void _showFeedback(String title, String message, {bool isError = false}) {
    try {
      if (Get.testMode || Get.overlayContext == null) {
        debugPrint(
          '[CreditCardsController] Feedback suprimido: $title - $message',
        );
        return;
      }

      AppSnackbar.show(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: isError
            ? const Color(0xFFBF4124).withValues(alpha: 0.12)
            : const Color(0xFF03A696).withValues(alpha: 0.12),
        colorText: Get.theme.colorScheme.onSurface,
      );
    } catch (_) {
      debugPrint(
        '[CreditCardsController] Feedback suprimido: $title - $message',
      );
    }
  }

  Color colorFromHex(String colorHex) {
    final normalized = colorHex.replaceFirst('#', '');
    if (normalized.length != 6) {
      return const Color(0xFF8B5CF6);
    }

    return Color(int.parse('FF$normalized', radix: 16));
  }
}

class _InvoicePaymentException implements Exception {
  _InvoicePaymentException(this.message);

  final String message;
}
