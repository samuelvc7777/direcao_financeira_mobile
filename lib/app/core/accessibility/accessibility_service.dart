import 'package:get/get.dart';

abstract class AccessibilityService {
  RxBool get isServiceEnabled;

  bool get persistedTrafficLightActive;

  Future<void> requestAccessibilityPermission();

  Future<void> setJourneyActive(bool isActive);

  Future<void> setTrafficLightActive(bool isActive);

  Future<void> syncSettingsWithNative();
}
