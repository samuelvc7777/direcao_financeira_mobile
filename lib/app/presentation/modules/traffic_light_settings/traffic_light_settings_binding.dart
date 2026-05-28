import 'package:get/get.dart';

import '../../../core/accessibility/accessibility_service.dart';
import '../../../domain/usecases/traffic_light_settings_use_cases.dart';
import 'traffic_light_settings_controller.dart';

class TrafficLightSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GetTrafficLightSettingsUseCase(Get.find()));
    Get.lazyPut(() => SaveTrafficLightSettingsUseCase(Get.find()));

    Get.lazyPut<TrafficLightSettingsController>(
      () => TrafficLightSettingsController(
        getSettingsUseCase: Get.find(),
        saveSettingsUseCase: Get.find(),
        accessibilityService: Get.find<AccessibilityService>(),
      ),
    );
  }
}
