import 'package:get/get.dart';

import '../../../domain/usecases/journey_use_cases.dart';
import 'journey_binding.dart';
import 'shift_route_controller.dart';

class ShiftRouteBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<GetShiftRouteUseCase>()) {
      JourneyBinding().dependencies();
    }

    Get.lazyPut<ShiftRouteController>(
      () => ShiftRouteController(
        getShiftRouteUseCase: Get.find(),
      ),
    );
  }
}
