import 'package:get/get.dart';

import '../../../core/app_bubble/app_bubble_service.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../domain/repositories/i_auth_repository.dart';
import '../../../domain/usecases/auth_session_use_cases.dart';
import '../../../domain/repositories/i_subscription_repository.dart';
import '../../../domain/usecases/subscription_use_cases.dart';
import 'settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<GetStoredUserUseCase>()) {
      Get.lazyPut(
        () => GetStoredUserUseCase(Get.find<IAuthRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<LogoutUseCase>()) {
      Get.lazyPut(
        () => LogoutUseCase(Get.find<IAuthRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<UpdateProfilePhotoUseCase>()) {
      Get.lazyPut(
        () => UpdateProfilePhotoUseCase(Get.find<IAuthRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<GetMySubscriptionUseCase>()) {
      Get.lazyPut(
        () => GetMySubscriptionUseCase(Get.find<ISubscriptionRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<SyncStoredUserSubscriptionUseCase>()) {
      Get.lazyPut(
        () => SyncStoredUserSubscriptionUseCase(
          Get.find<ISubscriptionRepository>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<SettingsController>()) {
      Get.lazyPut<SettingsController>(
        () => SettingsController(
          appBubbleService: Get.find<AppBubbleService>(),
          preferences: Get.find<AppPreferences>(),
          getStoredUserUseCase: Get.find<GetStoredUserUseCase>(),
          logoutUseCase: Get.find<LogoutUseCase>(),
          updateProfilePhotoUseCase: Get.find<UpdateProfilePhotoUseCase>(),
          getMySubscriptionUseCase: Get.find<GetMySubscriptionUseCase>(),
          syncStoredUserSubscriptionUseCase:
              Get.find<SyncStoredUserSubscriptionUseCase>(),
        ),
        fenix: true,
      );
    }
  }
}
