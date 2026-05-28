import 'package:get/get.dart';

import '../../../domain/usecases/costs_gains_settings_use_cases.dart';
import 'costs_gains_wizard_controller.dart';

class CostsGainsWizardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CostsGainsWizardController>(
      () => CostsGainsWizardController(
        saveCostsGainsSettingsUseCase:
            Get.find<SaveCostsGainsSettingsUseCase>(),
      ),
    );
  }
}
