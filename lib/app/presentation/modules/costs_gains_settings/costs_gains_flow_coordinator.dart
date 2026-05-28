import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/feedback/app_snackbar.dart';
import '../../../domain/usecases/costs_gains_settings_use_cases.dart';
import '../../../routes/app_pages.dart';
import 'costs_gains_draft.dart';

class CostsGainsWizardArguments {
  const CostsGainsWizardArguments({this.draft, this.returnResult = false});

  final CostsGainsDraft? draft;
  final bool returnResult;
}

abstract final class CostsGainsFlowCoordinator {
  static Future<bool> hasRegisteredCosts() async {
    final result = await Get.find<HasCostsGainsSettingsUseCase>()();
    return result.fold((_) => false, (value) => value);
  }

  static Future<void> openEntry([CostsGainsDraft? draft]) async {
    if (draft != null) {
      openResult(draft);
      return;
    }

    if (await hasRegisteredCosts()) {
      Get.toNamed(AppRoutes.costsGainsSettings);
      return;
    }

    openWizard(draft);
  }

  static Future<CostsGainsDraft?> openWizard(
    CostsGainsDraft? draft, {
    bool returnResult = false,
  }) async {
    final result = await Get.toNamed(
      AppRoutes.costsGainsWizard,
      arguments: CostsGainsWizardArguments(
        draft: draft,
        returnResult: returnResult,
      ),
    );
    return result is CostsGainsDraft ? result : null;
  }

  static void openResult(CostsGainsDraft draft) {
    Get.toNamed(AppRoutes.costsGainsSettings, arguments: draft);
  }

  static void showLoadFailure(String message) {
    AppSnackbar.show(
      'Custos e ganhos',
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }
}
