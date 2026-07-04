import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/feedback/app_snackbar.dart';
import '../../../domain/entities/referral_entity.dart';
import '../../../domain/entities/referral_settings_entity.dart';
import '../../../domain/usecases/referral_settings_use_cases.dart';
import '../../../domain/usecases/referral_use_cases.dart';

class ReferralsController extends GetxController {
  ReferralsController({
    required this.getSummaryUseCase,
    required this.getReferralsUseCase,
    required this.getWithdrawalsUseCase,
    required this.requestPixWithdrawalUseCase,
    this.getReferralSettingsUseCase,
  });

  final GetReferralSummaryUseCase getSummaryUseCase;
  final GetReferralsUseCase getReferralsUseCase;
  final GetPixWithdrawalsUseCase getWithdrawalsUseCase;
  final RequestPixWithdrawalUseCase requestPixWithdrawalUseCase;
  final GetReferralSettingsUseCase? getReferralSettingsUseCase;

  final cpfController = TextEditingController();
  final pixKeyController = TextEditingController();
  final amountController = TextEditingController();

  final isLoading = false.obs;
  final isRequestingWithdrawal = false.obs;
  final summary = Rxn<ReferralSummaryEntity>();
  final settings = const ReferralSettingsEntity().obs;
  final referrals = <ReferralEntity>[].obs;
  final withdrawals = <PixWithdrawalEntity>[].obs;

  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

  bool get canRequestWithdrawal {
    return settings.value.enabled &&
        (summary.value?.approvedCents ?? 0) >=
            settings.value.minimumWithdrawalCents;
  }

  bool get isReferralProgramEnabled => settings.value.enabled;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    cpfController.dispose();
    pixKeyController.dispose();
    amountController.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    await _loadSettings();
    if (!settings.value.enabled) {
      summary.value = null;
      referrals.clear();
      withdrawals.clear();
      isLoading.value = false;
      return;
    }

    final summaryResult = await getSummaryUseCase();
    final referralsResult = await getReferralsUseCase();
    final withdrawalsResult = await getWithdrawalsUseCase();

    summaryResult.fold(_showFailure, (value) {
      summary.value = value;
      amountController.text = formatMoney(value.approvedCents);
    });
    referralsResult.fold(_showFailure, referrals.assignAll);
    withdrawalsResult.fold(_showFailure, withdrawals.assignAll);
    isLoading.value = false;
  }

  Future<void> _loadSettings() async {
    final useCase = getReferralSettingsUseCase;
    if (useCase == null) {
      settings.value = const ReferralSettingsEntity();
      return;
    }

    final result = await useCase();
    result.fold(
      (_) => settings.value = const ReferralSettingsEntity(),
      (value) => settings.value = value,
    );
  }

  Future<void> copyReferralCode() async {
    final code = summary.value?.referralCode.trim() ?? '';
    if (code.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: code));
    AppSnackbar.show('Codigo copiado', 'Compartilhe seu codigo: $code');
  }

  Future<void> requestWithdrawal() async {
    if (isRequestingWithdrawal.value) return;

    final amountCents = _moneyToCents(amountController.text);
    isRequestingWithdrawal.value = true;
    final result = await requestPixWithdrawalUseCase(
      amountCents: amountCents,
      cpf: cpfController.text,
      pixKey: pixKeyController.text,
    );

    await result.fold((failure) async => _showFailure(failure), (_) async {
      cpfController.clear();
      pixKeyController.clear();
      AppSnackbar.show(
        'Saque solicitado',
        'Seu pedido ficou pendente para pagamento manual via Pix.',
      );
      await load();
      Get.back();
    });
    isRequestingWithdrawal.value = false;
  }

  String formatMoney(int cents) => _currencyFormat.format(cents / 100);

  String get minimumWithdrawalLabel =>
      formatMoney(settings.value.minimumWithdrawalCents);

  String statusLabel(String status) {
    switch (status) {
      case 'registered':
        return 'Cadastrado';
      case 'trial':
        return 'Teste gratis';
      case 'approved':
        return 'Aprovado';
      case 'paid':
        return 'Pago';
      case 'rejected':
        return 'Rejeitado';
      case 'requested':
        return 'Solicitado';
      case 'processing':
        return 'Processando';
      default:
        return status;
    }
  }

  int _moneyToCents(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 0;
    return int.parse(digits);
  }

  void _showFailure(dynamic failure) {
    AppSnackbar.show(
      'Indicacoes',
      failure.message.toString(),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }
}
