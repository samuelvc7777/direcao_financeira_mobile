import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/accessibility/accessibility_service.dart';
import '../../../core/feedback/app_snackbar.dart';
import '../../../domain/entities/traffic_light_settings_entity.dart';
import '../../../domain/usecases/traffic_light_settings_use_cases.dart';
import '../../../routes/app_pages.dart';
import '../costs_gains_settings/costs_gains_draft.dart';

class TrafficLightSettingsController extends GetxController {
  final GetTrafficLightSettingsUseCase getSettingsUseCase;
  final SaveTrafficLightSettingsUseCase saveSettingsUseCase;
  final AccessibilityService accessibilityService;

  TrafficLightSettingsController({
    required this.getSettingsUseCase,
    required this.saveSettingsUseCase,
    required this.accessibilityService,
  });

  final selectedPosition = TrafficLightPosition.topo.obs;
  final selectedTheme = TrafficLightTheme.escuro.obs;

  final indicators = <String, bool>{
    'R\$/Km': true,
    'R\$/Hora': true,
    'Lucro/H': true,
    'Nota': true,
  }.obs;
  final monitoredApps = <String, bool>{
    'Uber': true,
    '99': true,
    'inDrive': true,
    'MoveSj': false,
    'MeLevaSJ': false,
    'GooglePhotos': false,
  }.obs;
  final gainPerKmBad = 1.57.obs;
  final gainPerKmGood = 2.60.obs;
  final gainPerHourBad = 19.67.obs;
  final gainPerHourGood = 32.50.obs;
  final passengerRatingBad = 4.6.obs;
  final passengerRatingGood = 5.0.obs;
  final passengerRatingCustomized = false.obs;

  final fontSize = 12.0.obs;
  final opacity = 100.0.obs;
  final cardDuration = 10.0.obs;
  final colorBlindMode = false.obs;

  final isLoading = false.obs;
  late final TextEditingController gainPerKmBadController;
  late final TextEditingController gainPerKmGoodController;
  late final TextEditingController gainPerHourBadController;
  late final TextEditingController gainPerHourGoodController;
  late final TextEditingController passengerRatingBadController;
  late final TextEditingController passengerRatingGoodController;

  @override
  void onInit() {
    super.onInit();
    gainPerKmBadController = TextEditingController();
    gainPerKmGoodController = TextEditingController();
    gainPerHourBadController = TextEditingController();
    gainPerHourGoodController = TextEditingController();
    passengerRatingBadController = TextEditingController();
    passengerRatingGoodController = TextEditingController();
    _loadSettings();
  }

  @override
  void onClose() {
    gainPerKmBadController.dispose();
    gainPerKmGoodController.dispose();
    gainPerHourBadController.dispose();
    gainPerHourGoodController.dispose();
    passengerRatingBadController.dispose();
    passengerRatingGoodController.dispose();
    super.onClose();
  }

  Future<void> _loadSettings() async {
    isLoading.value = true;
    final result = await getSettingsUseCase();
    result.fold((failure) => AppSnackbar.show('Erro', failure.message), (
      settings,
    ) {
      selectedPosition.value = settings.position;
      selectedTheme.value = settings.theme;
      fontSize.value = settings.fontSize;
      opacity.value = settings.opacity;
      cardDuration.value = settings.cardDuration;
      colorBlindMode.value = settings.colorBlindMode;
      indicators.assignAll(settings.indicators);
      monitoredApps.assignAll(settings.monitoredApps);
      gainPerKmBad.value = settings.gainPerKmBad;
      gainPerKmGood.value = settings.gainPerKmGood;
      gainPerHourBad.value = settings.gainPerHourBad;
      gainPerHourGood.value = settings.gainPerHourGood;
      passengerRatingBad.value = settings.passengerRatingBad;
      passengerRatingGood.value = settings.passengerRatingGood;
      passengerRatingCustomized.value = settings.passengerRatingCustomized;
      _applyCostsGainsArgumentIfAny();
      _syncThresholdControllers();
    });
    isLoading.value = false;
  }

  Future<void> saveSettings() async {
    isLoading.value = true;

    final settings = TrafficLightSettingsEntity(
      position: selectedPosition.value,
      theme: selectedTheme.value,
      indicators: Map<String, bool>.from(indicators),
      monitoredApps: Map<String, bool>.from(monitoredApps),
      fontSize: fontSize.value,
      opacity: opacity.value,
      cardDuration: cardDuration.value,
      colorBlindMode: colorBlindMode.value,
      gainPerKmBad: gainPerKmBad.value,
      gainPerKmGood: gainPerKmGood.value,
      gainPerHourBad: gainPerHourBad.value,
      gainPerHourGood: gainPerHourGood.value,
      passengerRatingBad: passengerRatingBad.value,
      passengerRatingGood: passengerRatingGood.value,
      passengerRatingCustomized: passengerRatingCustomized.value,
    );

    final result = await saveSettingsUseCase(settings);
    result.fold((failure) => AppSnackbar.show('Erro', failure.message), (_) {
      accessibilityService.syncSettingsWithNative();
      _goBackToSettings();
    });
    isLoading.value = false;
  }

  void toggleIndicator(String name) {
    indicators[name] = !(indicators[name] ?? false);
  }

  void toggleMonitoredApp(String name) {
    monitoredApps[name] = !(monitoredApps[name] ?? false);
  }

  String displayMonitoredAppLabel(String name) {
    switch (name) {
      case 'GooglePhotos':
        return 'Google Fotos';
      case 'MeLevaSJ':
        return 'Me Leva SJ';
      case 'MoveSj':
        return 'MoveSJ';
      default:
        return name;
    }
  }

  void incrementGainPerKmBad() => _changeValue(gainPerKmBad, 0.1);

  void decrementGainPerKmBad() => _changeValue(gainPerKmBad, -0.1);

  void incrementGainPerKmGood() => _changeValue(gainPerKmGood, 0.1);

  void decrementGainPerKmGood() => _changeValue(gainPerKmGood, -0.1);

  void incrementGainPerHourBad() => _changeValue(gainPerHourBad, 0.1);

  void decrementGainPerHourBad() => _changeValue(gainPerHourBad, -0.1);

  void incrementGainPerHourGood() => _changeValue(gainPerHourGood, 0.1);

  void decrementGainPerHourGood() => _changeValue(gainPerHourGood, -0.1);

  void incrementPassengerRatingBad() => _changeRating(passengerRatingBad, 0.1);

  void decrementPassengerRatingBad() => _changeRating(passengerRatingBad, -0.1);

  void incrementPassengerRatingGood() =>
      _changeRating(passengerRatingGood, 0.1);

  void decrementPassengerRatingGood() =>
      _changeRating(passengerRatingGood, -0.1);

  int get selectedIndicatorsCount => indicators.values.where((v) => v).length;

  int get selectedMonitoredAppsCount =>
      monitoredApps.values.where((v) => v).length;

  List<String> get orderedActiveIndicators {
    const order = ['R\$/Km', 'R\$/Hora', 'Nota', 'Lucro/H'];
    return order.where((name) => indicators[name] ?? false).toList();
  }

  void _applyCostsGainsArgumentIfAny() {
    final argument = Get.arguments;
    if (argument is! CostsGainsDraft) return;

    final kmBadSuggestion = argument.monthlyKm <= 0
        ? 0.0
        : (argument.totalCosts / argument.monthlyKm).toDouble();
    final hourBadSuggestion = argument.monthlyWorkHours <= 0
        ? 0.0
        : (argument.totalCosts / argument.monthlyWorkHours).toDouble();

    gainPerKmGood.value = argument.perKmTarget;
    gainPerKmBad.value = kmBadSuggestion;
    gainPerHourGood.value = argument.perHourTarget;
    gainPerHourBad.value = hourBadSuggestion;

    if (!passengerRatingCustomized.value) {
      passengerRatingBad.value = 4.6;
      passengerRatingGood.value = 5.0;
    }

    _syncThresholdControllers();
  }

  void _changeValue(RxDouble target, double delta) {
    final next = (target.value + delta).clamp(0.0, 999999.0).toDouble();
    target.value = double.parse(next.toStringAsFixed(2));
    _syncThresholdControllers();
  }

  void _changeRating(RxDouble target, double delta) {
    final next = (target.value + delta).clamp(0.0, 5.0).toDouble();
    target.value = double.parse(next.toStringAsFixed(1));
    passengerRatingCustomized.value = true;
    _syncThresholdControllers();
  }

  void updateGainPerKmBad(String value) =>
      _updateThresholdFromInput(value, gainPerKmBad);

  void updateGainPerKmGood(String value) =>
      _updateThresholdFromInput(value, gainPerKmGood);

  void updateGainPerHourBad(String value) =>
      _updateThresholdFromInput(value, gainPerHourBad);

  void updateGainPerHourGood(String value) =>
      _updateThresholdFromInput(value, gainPerHourGood);

  void updatePassengerRatingBad(String value) {
    passengerRatingCustomized.value = true;
    _updateThresholdFromInput(value, passengerRatingBad, max: 5.0);
  }

  void updatePassengerRatingGood(String value) {
    passengerRatingCustomized.value = true;
    _updateThresholdFromInput(value, passengerRatingGood, max: 5.0);
  }

  void _updateThresholdFromInput(
    String rawValue,
    RxDouble target, {
    double min = 0.0,
    double max = 999999.0,
  }) {
    final normalized = rawValue.replaceAll(',', '.').trim();
    final parsed = double.tryParse(normalized);
    if (parsed == null) return;

    target.value = parsed.clamp(min, max).toDouble();
    _syncThresholdControllers();
  }

  void _syncThresholdControllers() {
    gainPerKmBadController.text = gainPerKmBad.value.toStringAsFixed(2);
    gainPerKmGoodController.text = gainPerKmGood.value.toStringAsFixed(2);
    gainPerHourBadController.text = gainPerHourBad.value.toStringAsFixed(2);
    gainPerHourGoodController.text = gainPerHourGood.value.toStringAsFixed(2);
    passengerRatingBadController.text = passengerRatingBad.value
        .toStringAsFixed(1);
    passengerRatingGoodController.text = passengerRatingGood.value
        .toStringAsFixed(1);
  }

  void _goBackToSettings() {
    // A tela de configuracoes vive na aba 3 de /initial no fluxo real do app.
    // Recriar esse estado evita esvaziar a pilha procurando uma rota /settings
    // que muitas vezes nao existe no navigator atual.
    Future<void>.microtask(() {
      if (Get.key.currentState == null) return;

      Get.offAllNamed(AppRoutes.initial, arguments: const {'initialIndex': 3});
    });
  }
}
