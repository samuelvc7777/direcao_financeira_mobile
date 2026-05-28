import 'package:get/get.dart';

import '../../../domain/repositories/i_help_repository.dart';
import '../../../domain/usecases/help_use_cases.dart';
import 'help_controller.dart';

class HelpBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LoadHelpVideosUseCase>()) {
      Get.lazyPut(
        () => LoadHelpVideosUseCase(Get.find<IHelpRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<GetHelpSupportContactUseCase>()) {
      Get.lazyPut(
        () => GetHelpSupportContactUseCase(Get.find<IHelpRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<OpenHelpSupportContactUseCase>()) {
      Get.lazyPut(
        () => OpenHelpSupportContactUseCase(Get.find<IHelpRepository>()),
        fenix: true,
      );
    }

    Get.lazyPut(
      () => HelpController(
        loadHelpVideosUseCase: Get.find<LoadHelpVideosUseCase>(),
        getHelpSupportContactUseCase: Get.find<GetHelpSupportContactUseCase>(),
        openHelpSupportContactUseCase:
            Get.find<OpenHelpSupportContactUseCase>(),
      ),
    );
  }
}
