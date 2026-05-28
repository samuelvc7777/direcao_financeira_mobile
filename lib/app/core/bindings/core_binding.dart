import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_bubble/app_bubble_controller.dart';
import '../app_bubble/app_bubble_action_controller.dart';
import '../app_bubble/app_bubble_service.dart';
import '../accessibility/accessibility_service.dart';
import '../../data/local/get_storage_session_store.dart';
import '../../data/local/get_storage_user_cache.dart';
import '../accessibility/accessibility_controller.dart';
import '../config/app_environment.dart';
import '../dashboard/dashboard_refresh_notifier.dart';
import '../network/api_error_mapper.dart';
import '../network/api_request_logger.dart';
import '../preferences/app_preferences.dart';
import '../session/session_coordinator.dart';
import '../session/session_store.dart';
import '../session/user_cache.dart';

class CoreBinding extends Bindings {
  CoreBinding({required this.environment, required this.storage});

  final AppEnvironment environment;
  final GetStorage storage;

  @override
  void dependencies() {
    if (!Get.isRegistered<AppEnvironment>()) {
      Get.put(environment, permanent: true);
    }
    if (!Get.isRegistered<GetStorage>()) {
      Get.put(storage, permanent: true);
    }
    if (!Get.isRegistered<AppPreferences>()) {
      Get.put<AppPreferences>(
        GetStorageAppPreferences(storage: storage),
        permanent: true,
      );
    }
    if (!Get.isRegistered<AppBubbleService>()) {
      Get.put<AppBubbleService>(NativeAppBubbleController(), permanent: true);
    }
    if (!Get.isRegistered<AppBubbleActionController>()) {
      Get.put<AppBubbleActionController>(
        AppBubbleActionController(),
        permanent: true,
      );
    }
    if (!Get.isRegistered<SessionStore>()) {
      Get.put<SessionStore>(
        GetStorageSessionStore(storage: storage),
        permanent: true,
      );
    }
    if (!Get.isRegistered<UserCache>()) {
      Get.put<UserCache>(
        GetStorageUserCache(storage: storage),
        permanent: true,
      );
    }
    final accessibilityController = Get.isRegistered<AccessibilityController>()
        ? Get.find<AccessibilityController>()
        : Get.put<AccessibilityController>(
            AccessibilityController(storage: storage),
            permanent: true,
          );
    if (!Get.isRegistered<AccessibilityService>()) {
      Get.put<AccessibilityService>(accessibilityController, permanent: true);
    }
    if (!Get.isRegistered<AccessibilityController>()) {
      Get.put<AccessibilityController>(
        accessibilityController,
        permanent: true,
      );
    }
    if (!Get.isRegistered<DashboardRefreshNotifier>()) {
      Get.put<DashboardRefreshNotifier>(
        DefaultDashboardRefreshNotifier(),
        permanent: true,
      );
    }
    if (!Get.isRegistered<ApiErrorMapper>()) {
      Get.put<ApiErrorMapper>(const ApiErrorMapper(), permanent: true);
    }
    if (!Get.isRegistered<ApiRequestLogger>()) {
      Get.put<ApiRequestLogger>(
        ApiRequestLogger(apiErrorMapper: Get.find<ApiErrorMapper>()),
        permanent: true,
      );
    }
    Get.lazyPut<SessionCoordinator>(
      () => DefaultSessionCoordinator(
        sessionStore: Get.find(),
        userCache: Get.find(),
        realtimeClient: Get.find(),
        restoreRemoteSession:
            environment.backendProvider == BackendProviderKind.supabase
            ? (token) async {
                final auth = Get.find<SupabaseClient>().auth;
                if (auth.currentSession != null) {
                  return;
                }

                await auth.setSession(token);
              }
            : null,
        remoteLogout:
            environment.backendProvider == BackendProviderKind.supabase
            ? () => Get.find<SupabaseClient>().auth.signOut()
            : null,
      ),
      fenix: true,
    );
  }
}
