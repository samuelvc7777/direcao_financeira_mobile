import 'package:get/get.dart';

import '../../../core/preferences/app_preferences.dart';
import 'recording_settings_controller.dart';

class RecordingSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RecordingSettingsController>(
      () =>
          RecordingSettingsController(preferences: Get.find<AppPreferences>()),
    );
  }
}
