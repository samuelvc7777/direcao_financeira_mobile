import 'package:direcao_financeira_mobile/app/domain/repositories/i_auth_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/usecases/login_use_case.dart';
import 'package:direcao_financeira_mobile/app/domain/usecases/send_password_reset_email_use_case.dart';
import 'package:get/get.dart';

import 'login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LoginUseCase>()) {
      Get.lazyPut(() => LoginUseCase(Get.find<IAuthRepository>()), fenix: true);
    }
    if (!Get.isRegistered<SendPasswordResetEmailUseCase>()) {
      Get.lazyPut(
        () => SendPasswordResetEmailUseCase(Get.find<IAuthRepository>()),
        fenix: true,
      );
    }

    Get.lazyPut<LoginController>(
      () => LoginController(
        loginUseCase: Get.find<LoginUseCase>(),
        sendPasswordResetEmailUseCase:
            Get.find<SendPasswordResetEmailUseCase>(),
      ),
      fenix: true,
    );
  }
}
