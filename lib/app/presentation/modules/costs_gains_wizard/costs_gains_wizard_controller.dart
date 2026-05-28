import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/feedback/app_snackbar.dart';
import '../../../core/accessibility/accessibility_service.dart';
import '../../../domain/usecases/costs_gains_settings_use_cases.dart';
import '../costs_gains_settings/costs_gains_draft.dart';
import '../costs_gains_settings/costs_gains_flow_coordinator.dart';

enum CostsGainsWizardStep { goal, journey, mileage, vehicle, fuel, platform }

class CostsGainsWizardController extends GetxController {
  CostsGainsWizardController({required this.saveCostsGainsSettingsUseCase});

  final SaveCostsGainsSettingsUseCase saveCostsGainsSettingsUseCase;
  final currentStep = 0.obs;
  final selectedPlatformFeeType = PlatformFeeType.fixed.obs;
  final isSubmitting = false.obs;
  var _returnResultOnSave = false;

  late final TextEditingController desiredProfitController;
  late final TextEditingController workDaysController;
  late final TextEditingController workHoursController;
  late final TextEditingController kmPerDayController;
  late final TextEditingController financeController;
  late final TextEditingController insuranceController;
  late final TextEditingController maintenanceController;
  late final TextEditingController annualTaxesController;
  late final TextEditingController fuelPriceController;
  late final TextEditingController kmPerLiterController;
  late final TextEditingController platformFeeController;

  late final CurrencyTextInputFormatter currencyFormatter;
  late final List<TextInputFormatter> integerFormatters;
  late final List<TextInputFormatter> decimalFormatters;
  late final List<TextInputFormatter> currencyFormatters;

  final steps = const [
    CostsGainsWizardStep.goal,
    CostsGainsWizardStep.journey,
    CostsGainsWizardStep.mileage,
    CostsGainsWizardStep.vehicle,
    CostsGainsWizardStep.fuel,
    CostsGainsWizardStep.platform,
  ];

  @override
  void onInit() {
    super.onInit();
    currencyFormatter = CurrencyTextInputFormatter.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    integerFormatters = [FilteringTextInputFormatter.digitsOnly];
    decimalFormatters = [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d{0,2}')),
    ];
    currencyFormatters = [currencyFormatter];

    final argument = Get.arguments;
    final draft = argument is CostsGainsWizardArguments
        ? argument.draft ?? CostsGainsDraft.empty()
        : argument is CostsGainsDraft
        ? argument
        : CostsGainsDraft.empty();
    _returnResultOnSave =
        argument is CostsGainsWizardArguments && argument.returnResult;

    desiredProfitController = TextEditingController(
      text: _formatCurrencyFromCents(draft.desiredNetProfitCents),
    );
    workDaysController = TextEditingController(
      text: _formatInt(draft.workDaysPerWeek),
    );
    workHoursController = TextEditingController(
      text: _formatDecimal(draft.workHoursPerDay),
    );
    kmPerDayController = TextEditingController(
      text: _formatWholeNumber(draft.kmPerDay),
    );
    financeController = TextEditingController(
      text: _formatCurrencyFromCents(draft.financeOrRentMonthlyCents),
    );
    insuranceController = TextEditingController(
      text: _formatCurrencyFromCents(draft.insuranceMonthlyCents),
    );
    maintenanceController = TextEditingController(
      text: _formatCurrencyFromCents(draft.maintenanceMonthlyCents),
    );
    annualTaxesController = TextEditingController(
      text: _formatCurrencyFromCents(draft.annualTaxesCents),
    );
    fuelPriceController = TextEditingController(
      text: _formatCurrencyFromCents(draft.fuelPricePerLiterCents),
    );
    kmPerLiterController = TextEditingController(
      text: _formatDecimal(draft.kmPerLiter),
    );
    selectedPlatformFeeType.value = draft.platformFeeType;
    platformFeeController = TextEditingController(
      text: draft.platformFeeValue <= 0
          ? ''
          : draft.platformFeeType == PlatformFeeType.fixed
          ? _formatCurrencyValue(draft.platformFeeValue)
          : _formatDecimal(draft.platformFeeValue),
    );
  }

  @override
  void onClose() {
    desiredProfitController.dispose();
    workDaysController.dispose();
    workHoursController.dispose();
    kmPerDayController.dispose();
    financeController.dispose();
    insuranceController.dispose();
    maintenanceController.dispose();
    annualTaxesController.dispose();
    fuelPriceController.dispose();
    kmPerLiterController.dispose();
    platformFeeController.dispose();
    super.onClose();
  }

  CostsGainsWizardStep get activeStep => steps[currentStep.value];

  double get progress => (currentStep.value + 1) / steps.length;

  int get progressPercent => (progress * 100).round();

  bool get isFirstStep => currentStep.value == 0;

  bool get isLastStep => currentStep.value == steps.length - 1;

  void goBack() {
    if (isFirstStep) {
      Get.back();
      return;
    }

    currentStep.value -= 1;
  }

  Future<void> continueOrFinish() async {
    if (!_validateCurrentStep()) return;

    if (!isLastStep) {
      currentStep.value += 1;
      return;
    }

    isSubmitting.value = true;
    final draft = buildDraft();
    final result = await saveCostsGainsSettingsUseCase(
      draft.toEntity(userId: 0),
    );
    isSubmitting.value = false;
    result.fold(
      (failure) => AppSnackbar.show(
        'Erro ao salvar',
        failure.message,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      ),
      (entity) {
        final savedDraft = CostsGainsDraft.fromEntity(entity);
        if (Get.isRegistered<AccessibilityService>()) {
          Get.find<AccessibilityService>().syncSettingsWithNative();
        }
        if (_returnResultOnSave) {
          Get.back(result: savedDraft);
          return;
        }

        CostsGainsFlowCoordinator.openResult(savedDraft);
      },
    );
  }

  void updatePlatformFeeType(PlatformFeeType type) {
    if (selectedPlatformFeeType.value == type) return;
    selectedPlatformFeeType.value = type;
    platformFeeController.clear();
  }

  CostsGainsDraft buildDraft() {
    return CostsGainsDraft(
      desiredNetProfitCents: _parseCurrencyToCents(
        desiredProfitController.text,
      ),
      workDaysPerWeek: _parseInt(workDaysController.text),
      workHoursPerDay: _parseDouble(workHoursController.text),
      kmPerDay: _parseDouble(kmPerDayController.text),
      financeOrRentMonthlyCents: _parseCurrencyToCents(financeController.text),
      insuranceMonthlyCents: _parseCurrencyToCents(insuranceController.text),
      maintenanceMonthlyCents: _parseCurrencyToCents(
        maintenanceController.text,
      ),
      annualTaxesCents: _parseCurrencyToCents(annualTaxesController.text),
      fuelPricePerLiterCents: _parseCurrencyToCents(fuelPriceController.text),
      kmPerLiter: _parseDouble(kmPerLiterController.text),
      platformFeeType: selectedPlatformFeeType.value,
      platformFeeValue: selectedPlatformFeeType.value == PlatformFeeType.fixed
          ? _parseCurrencyToCents(platformFeeController.text) / 100
          : _parseDouble(platformFeeController.text),
    );
  }

  bool _validateCurrentStep() {
    switch (activeStep) {
      case CostsGainsWizardStep.goal:
        return _validateRules([
          _ValidationRule(
            _parseCurrencyToCents(desiredProfitController.text) > 0,
            'Informe o lucro desejado.',
          ),
        ]);
      case CostsGainsWizardStep.journey:
        return _validateRules([
          _ValidationRule(
            _parseInt(workDaysController.text) > 0,
            'Informe quantos dias por semana voce vai trabalhar.',
          ),
          _ValidationRule(
            _parseDouble(workHoursController.text) > 0,
            'Informe quantas horas por dia voce pretende trabalhar.',
          ),
        ]);
      case CostsGainsWizardStep.mileage:
        return _validateRules([
          _ValidationRule(
            _parseDouble(kmPerDayController.text) > 0,
            'Informe a quilometragem diaria planejada.',
          ),
        ]);
      case CostsGainsWizardStep.vehicle:
        return _validateRules([
          _ValidationRule(
            _parseCurrencyToCents(financeController.text) > 0,
            'Informe o valor de financiamento ou aluguel.',
          ),
        ]);
      case CostsGainsWizardStep.fuel:
        return _validateRules([
          _ValidationRule(
            _parseCurrencyToCents(fuelPriceController.text) > 0,
            'Informe o preco do combustivel.',
          ),
          _ValidationRule(
            _parseDouble(kmPerLiterController.text) > 0,
            'Informe o consumo do veiculo em km por litro.',
          ),
        ]);
      case CostsGainsWizardStep.platform:
        return true;
    }
  }

  bool _validateRules(List<_ValidationRule> rules) {
    for (final rule in rules) {
      if (!rule.isValid) {
        AppSnackbar.show(
          'Campo obrigatorio',
          rule.message,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
        return false;
      }
    }

    return true;
  }

  int _parseCurrencyToCents(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  int _parseInt(String value) {
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  double _parseDouble(String value) {
    final normalized = value.replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0;
  }

  String _formatCurrencyFromCents(int cents) {
    if (cents <= 0) return '';
    return currencyFormatter.formatString((cents / 100).toStringAsFixed(2));
  }

  String _formatCurrencyValue(double value) {
    if (value <= 0) return '';
    return currencyFormatter.formatString(value.toStringAsFixed(2));
  }

  String _formatDecimal(double value) {
    if (value <= 0) return '';
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  String _formatWholeNumber(double value) {
    if (value <= 0) return '';
    return value.toStringAsFixed(0);
  }

  String _formatInt(int value) {
    if (value <= 0) return '';
    return '$value';
  }
}

class _ValidationRule {
  const _ValidationRule(this.isValid, this.message);

  final bool isValid;
  final String message;
}
