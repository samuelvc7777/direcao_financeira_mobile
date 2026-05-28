import 'package:get/get.dart';

import '../../../domain/usecases/costs_gains_settings_use_cases.dart';
import '../../../routes/app_pages.dart';
import 'costs_gains_draft.dart';
import 'costs_gains_flow_coordinator.dart';

class CostsGainsSettingsController extends GetxController {
  CostsGainsSettingsController({required this.getCostsGainsSettingsUseCase});

  final GetCostsGainsSettingsUseCase getCostsGainsSettingsUseCase;
  final isLoading = false.obs;
  final draft = CostsGainsDraft.empty().obs;

  @override
  void onInit() {
    super.onInit();
    final argument = Get.arguments;
    if (argument is CostsGainsDraft) {
      draft.value = argument;
      return;
    }

    _loadSettings();
  }

  double get monthlyGoal => draft.value.grossMonthlyGoal;
  double get targetNetProfit => draft.value.desiredNetProfit;
  double get weeklyTarget => draft.value.weeklyTarget;
  double get dailyTarget => draft.value.dailyTarget;
  double get perKmTarget => draft.value.perKmTarget;
  double get perHourTarget => draft.value.perHourTarget;
  double get fixedMonthlyCosts => draft.value.fixedMonthlyCosts;
  double get estimatedFuel => draft.value.estimatedFuel;
  double get platformFee => draft.value.platformFeeAmount;
  double get totalCosts => draft.value.totalCosts;
  String get platformLabel => draft.value.platformLabel;

  void applyToTrafficLight() {
    Get.toNamed(AppRoutes.trafficLightSettings, arguments: draft.value);
  }

  void openTrafficLightSettings() {
    Get.toNamed(AppRoutes.trafficLightSettings);
  }

  Future<void> openAdjustCosts() async {
    final updatedDraft = await CostsGainsFlowCoordinator.openWizard(
      draft.value,
      returnResult: true,
    );
    if (updatedDraft != null) {
      draft.value = updatedDraft;
      return;
    }

    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    isLoading.value = true;
    final result = await getCostsGainsSettingsUseCase();
    result.fold(
      (failure) => CostsGainsFlowCoordinator.showLoadFailure(failure.message),
      (entity) {
        if (entity != null) {
          draft.value = CostsGainsDraft.fromEntity(entity);
        }
      },
    );
    isLoading.value = false;
  }
}
