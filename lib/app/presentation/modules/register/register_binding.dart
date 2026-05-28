import 'package:direcao_financeira_mobile/app/domain/repositories/i_auth_repository.dart';
import 'package:get/get.dart';

import '../../../domain/repositories/i_category_repository.dart';
import '../../../domain/usecases/category_use_cases.dart';
import '../../../domain/usecases/register_use_case.dart';
import 'register_controller.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<RegisterUseCase>()) {
      Get.lazyPut(
        () => RegisterUseCase(Get.find<IAuthRepository>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<EnsureDefaultCategoriesUseCase>()) {
      Get.lazyPut(
        () => EnsureDefaultCategoriesUseCase(Get.find<ICategoryRepository>()),
        fenix: true,
      );
    }

    Get.lazyPut<RegisterController>(
      () => RegisterController(
        registerUseCase: Get.find<RegisterUseCase>(),
        ensureDefaultCategoriesUseCase:
            Get.find<EnsureDefaultCategoriesUseCase>(),
      ),
      fenix: true,
    );
  }
}
