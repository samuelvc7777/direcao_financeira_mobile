import 'package:direcao_financeira_mobile/app/domain/repositories/i_auth_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/usecases/update_password_use_case.dart';
import 'package:get/get.dart';

import 'reset_password_controller.dart';

class ResetPasswordBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<UpdatePasswordUseCase>()) {
      Get.lazyPut(
        () => UpdatePasswordUseCase(Get.find<IAuthRepository>()),
        fenix: true,
      );
    }

    Get.lazyPut<ResetPasswordController>(
      () => ResetPasswordController(
        updatePasswordUseCase: Get.find<UpdatePasswordUseCase>(),
      ),
      fenix: true,
    );
  }
}
