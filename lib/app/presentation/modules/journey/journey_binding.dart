import 'package:get/get.dart';

import '../../../core/network/journey_realtime_bridge.dart';
import '../../../domain/usecases/costs_gains_settings_use_cases.dart';
import '../../../domain/usecases/get_rides_usecase.dart';
import '../../../domain/usecases/journey_use_cases.dart';
import '../../../domain/usecases/recording_use_cases.dart';
import '../../../domain/usecases/ride_status_use_cases.dart';
import 'journey_controller.dart';
import 'journey_runtime_coordinator.dart';
import 'shift_lifecycle_coordinator.dart';

class JourneyBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<JourneyRealtimeBridge>()) {
      Get.lazyPut<JourneyRealtimeBridge>(
        () => DefaultJourneyRealtimeBridge(realtimeClient: Get.find()),
        fenix: true,
      );
    }

    Get.lazyPut(() => GetActiveShiftUseCase(Get.find()));
    Get.lazyPut(() => GetDailyStatisticsUseCase(Get.find()));
    Get.lazyPut(() => GetShiftHistoryUseCase(Get.find()));
    Get.lazyPut(() => StartShiftUseCase(Get.find()));
    Get.lazyPut(() => PauseShiftUseCase(Get.find()));
    Get.lazyPut(() => ResumeShiftUseCase(Get.find()));
    Get.lazyPut(() => FinishShiftUseCase(Get.find()));
    Get.lazyPut(() => CreateManualShiftUseCase(Get.find()));
    Get.lazyPut(() => DeleteShiftUseCase(Get.find()));
    Get.lazyPut(() => SyncPendingJourneyUseCase(Get.find()));
    Get.lazyPut(() => EnsureReadyForShiftStartUseCase(Get.find()));
    Get.lazyPut(() => GetLocationTrackingStatusUseCase(Get.find()));
    Get.lazyPut(() => WatchLocationTrackingStatusUseCase(Get.find()));
    Get.lazyPut(() => GetShiftRouteUseCase(Get.find()));
    Get.lazyPut(() => GetRidesUseCase(Get.find()));
    Get.lazyPut(() => DeleteRideUseCase(Get.find()));
    Get.lazyPut(() => GetRecordingsUseCase(Get.find()));
    Get.lazyPut(() => GetActiveRecordingUseCase(Get.find()));
    Get.lazyPut(() => StartRecordingUseCase(Get.find()));
    Get.lazyPut(() => StopRecordingUseCase(Get.find()));
    Get.lazyPut(() => DeleteRecordingUseCase(Get.find()));
    Get.lazyPut(() => OpenRecordingUseCase(Get.find()));
    Get.lazyPut(
      () => ShiftLifecycleCoordinator(
        startShiftUseCase: Get.find(),
        pauseShiftUseCase: Get.find(),
        resumeShiftUseCase: Get.find(),
        finishShiftUseCase: Get.find(),
        ensureReadyForShiftStartUseCase: Get.find(),
      ),
    );
    Get.lazyPut(
      () => JourneyRuntimeCoordinator(
        journeyRealtimeBridge: Get.find(),
        getLocationTrackingStatusUseCase: Get.find(),
        watchLocationTrackingStatusUseCase: Get.find(),
        syncPendingJourneyUseCase: Get.find(),
        accessibilityService: Get.find(),
        appBubbleService: Get.find(),
        getActiveRecordingUseCase: Get.find(),
        startRecordingUseCase: Get.find(),
        stopRecordingUseCase: Get.find(),
      ),
    );

    Get.lazyPut<JourneyController>(
      () => JourneyController(
        getActiveShift: Get.find(),
        getDailyStatistics: Get.find(),
        getShiftHistory: Get.find(),
        createManualShift: Get.find(),
        deleteShiftUseCase: Get.find(),
        getRidesUseCase: Get.find(),
        deleteRideUseCase: Get.find(),
        getRecordingsUseCase: Get.find(),
        deleteRecordingUseCase: Get.find(),
        openRecordingUseCase: Get.find(),
        getCostsGainsSettings: Get.isRegistered<GetCostsGainsSettingsUseCase>()
            ? Get.find<GetCostsGainsSettingsUseCase>()
            : null,
        shiftLifecycleCoordinator: Get.find(),
        runtimeCoordinator: Get.find(),
      ),
    );
  }
}
