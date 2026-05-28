import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/dashboard/dashboard_refresh_notifier.dart';
import '../../../core/feedback/app_snackbar.dart';
import '../../../domain/entities/bank_account_entity.dart';
import '../../../domain/usecases/bank_account_use_cases.dart';

class BankAccountsController extends GetxController {
  BankAccountsController({
    required this.loadBankAccountsUseCase,
    required this.createBankAccountUseCase,
    required this.updateBankAccountUseCase,
    required this.deactivateBankAccountUseCase,
    required this.reactivateBankAccountUseCase,
    required this.dashboardRefreshNotifier,
  });

  final LoadBankAccountsUseCase loadBankAccountsUseCase;
  final CreateBankAccountUseCase createBankAccountUseCase;
  final UpdateBankAccountUseCase updateBankAccountUseCase;
  final DeactivateBankAccountUseCase deactivateBankAccountUseCase;
  final ReactivateBankAccountUseCase reactivateBankAccountUseCase;
  final DashboardRefreshNotifier dashboardRefreshNotifier;

  final isLoading = true.obs;
  final isSubmitting = false.obs;
  final errorMessage = RxnString();
  final bankAccounts = <BankAccountEntity>[].obs;

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

  List<BankAccountEntity> get activeAccounts =>
      bankAccounts.where((account) => account.isActive).toList();

  List<BankAccountEntity> get inactiveAccounts =>
      bankAccounts.where((account) => !account.isActive).toList();

  @override
  void onInit() {
    super.onInit();
    loadBankAccounts();
  }

  Future<void> loadBankAccounts() async {
    isLoading.value = true;
    errorMessage.value = null;
    final result = await loadBankAccountsUseCase();

    result.fold(
      (failure) => errorMessage.value = failure.message,
      (data) => bankAccounts.assignAll(data),
    );

    isLoading.value = false;
  }

  Future<void> createBankAccount({
    required String name,
    required String bankName,
    required String color,
    required AccountType accountType,
    required int initialBalanceCents,
  }) async {
    await _runSubmission(
      action: () => createBankAccountUseCase(
        name: name,
        bankName: bankName,
        color: color,
        accountType: accountType,
        initialBalanceCents: initialBalanceCents,
      ),
      successMessage: 'Conta bancaria criada com sucesso.',
    );
  }

  Future<void> updateBankAccount({
    required int id,
    required String name,
    required String bankName,
    required String color,
    required AccountType accountType,
    required int initialBalanceCents,
  }) async {
    await _runSubmission(
      action: () => updateBankAccountUseCase(
        id: id,
        name: name,
        bankName: bankName,
        color: color,
        accountType: accountType,
        initialBalanceCents: initialBalanceCents,
      ),
      successMessage: 'Conta bancaria atualizada com sucesso.',
    );
  }

  Future<void> toggleAccountStatus(BankAccountEntity account) async {
    final isDeactivating = account.isActive;
    final actionName = isDeactivating ? 'desativar' : 'reativar';
    final actionNameCap = isDeactivating ? 'Desativar' : 'Reativar';

    final confirmed =
        await Get.dialog<bool>(
          AlertDialog(
            backgroundColor: Get.theme.colorScheme.surface,
            title: Text(
              '$actionNameCap conta',
              style: TextStyle(color: Get.theme.colorScheme.onSurface),
            ),
            content: Text(
              'A conta "${account.name}" sera ${actionName}ada.',
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
        ? await deactivateBankAccountUseCase(account.id)
        : await reactivateBankAccountUseCase(account.id);

    await result.fold(
      (failure) async => _showFeedback('Erro', failure.message, isError: true),
      (_) async {
        await loadBankAccounts();
        dashboardRefreshNotifier.requestRefresh();
        if (Get.isBottomSheetOpen ?? false) {
          Get.back();
        }
        _showFeedback('Sucesso', 'Conta ${actionName}ada com sucesso.');
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
        await loadBankAccounts();
        dashboardRefreshNotifier.requestRefresh();
        if (Get.isBottomSheetOpen ?? false) {
          Get.back();
        }
        _showFeedback('Sucesso', successMessage);
      },
    );

    isSubmitting.value = false;
  }

  void _showFeedback(String title, String message, {bool isError = false}) {
    if (Get.testMode || Get.overlayContext == null) {
      debugPrint(
        '[BankAccountsController] Feedback suprimido: $title - $message',
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
  }

  Color colorFromHex(String colorHex) {
    final normalized = colorHex.replaceFirst('#', '');
    if (normalized.length != 6) {
      return const Color(0xFF06B6D4);
    }

    return Color(int.parse('FF$normalized', radix: 16));
  }
}
