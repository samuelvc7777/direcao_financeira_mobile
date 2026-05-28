import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:direcao_financeira_mobile/app/core/app_bubble/app_bubble_service.dart';
import 'package:direcao_financeira_mobile/app/core/accessibility/accessibility_service.dart';
import 'package:direcao_financeira_mobile/app/core/errors/failures.dart';
import 'package:direcao_financeira_mobile/app/core/network/journey_realtime_bridge.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/active_shift_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/finish_shift_result_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/journey_statistics_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/location_tracking_status_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/manual_shift_draft_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/paged_result_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/recording_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/shift_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/shift_route_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/repositories/i_journey_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/repositories/i_recording_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/usecases/journey_use_cases.dart';
import 'package:direcao_financeira_mobile/app/domain/usecases/recording_use_cases.dart';
import 'package:direcao_financeira_mobile/app/presentation/modules/journey/journey_runtime_coordinator.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeJourneyRepository implements IJourneyRepository {
  final trackingController =
      StreamController<LocationTrackingStatusEntity>.broadcast();
  Either<Failure, LocationTrackingStatusEntity> trackingStatusResult =
      const Right(
        LocationTrackingStatusEntity(
          isTrackingActive: true,
          isLocationServiceEnabled: true,
          hasForegroundPermission: true,
          hasBackgroundPermission: true,
          isPreciseLocation: true,
          isPaused: false,
          totalDistanceMeters: 1000,
          idleTimeSeconds: 10,
        ),
      );
  Either<Failure, int> syncResult = const Right(2);

  @override
  Future<Either<Failure, LocationTrackingStatusEntity>>
  getLocationTrackingStatus() async => trackingStatusResult;

  @override
  Future<Either<Failure, int>> syncPendingShifts() async => syncResult;

  @override
  Stream<LocationTrackingStatusEntity> watchLocationTrackingStatus() =>
      trackingController.stream;

  @override
  Future<Either<Failure, LocationTrackingStatusEntity>>
  ensureReadyForShiftStart() async => throw UnimplementedError();

  @override
  Future<Either<Failure, FinishShiftResultEntity>> finishShift() async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, FinishShiftResultEntity>> addManualShift(
    ManualShiftDraftEntity shift,
  ) async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> deleteShift(ShiftEntity shift) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, ActiveShiftEntity?>> getActiveShift() async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, JourneyStatisticsEntity>> getDailyStatistics({
    String filter = 'day',
    String? date,
    String? endDate,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, PagedResultEntity<ShiftEntity>>> getShiftHistory({
    String filter = 'day',
    String? date,
    String? endDate,
    int offset = 0,
    int limit = 20,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, ShiftRouteEntity>> getShiftRoute({
    int? localShiftId,
    int? remoteShiftId,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> pauseShift() async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> resumeShift() async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> startShift() async =>
      throw UnimplementedError();
}

class _FakeJourneyRealtimeBridge implements JourneyRealtimeBridge {
  @override
  final RxBool isOnline = true.obs;

  VoidCallback? onRideChanged;
  bool unbound = false;
  var bindCalls = 0;

  @override
  void bind({required VoidCallback onRideChanged}) {
    bindCalls++;
    this.onRideChanged = onRideChanged;
  }

  @override
  void unbind() {
    unbound = true;
  }
}

class _FakeAccessibilityService implements AccessibilityService {
  @override
  final RxBool isServiceEnabled = true.obs;

  @override
  bool persistedTrafficLightActive = false;

  @override
  Future<void> requestAccessibilityPermission() async {}

  @override
  Future<void> setJourneyActive(bool isActive) async {}

  @override
  Future<void> setTrafficLightActive(bool isActive) async {
    persistedTrafficLightActive = isActive;
  }

  @override
  Future<void> syncSettingsWithNative() async {}
}

class _FakeAppBubbleService implements AppBubbleService {
  bool bubbleRunning = false;
  bool permissionGranted = true;
  bool openedOverlaySettings = false;
  Object? startBubbleError;

  @override
  Future<bool> isBubbleRunning() async => bubbleRunning;

  @override
  Future<bool> isOverlayPermissionGranted() async => permissionGranted;

  @override
  Future<void> openOverlayPermissionSettings() async {
    openedOverlaySettings = true;
  }

  @override
  Future<void> startBubble() async {
    if (startBubbleError != null) {
      throw startBubbleError!;
    }
    bubbleRunning = true;
  }

  @override
  Future<void> stopBubble() async {
    bubbleRunning = false;
  }
}

class _FakeRecordingRepository implements IRecordingRepository {
  RecordingEntity? activeRecording;
  Either<Failure, RecordingEntity> startResult = Right(
    RecordingEntity(
      id: '1',
      status: RecordingStatus.recording,
      filePath: '/tmp/recording.mp4',
      startedAt: DateTime(2026),
    ),
  );
  Either<Failure, RecordingEntity?> stopResult = const Right(null);

  @override
  Future<Either<Failure, Unit>> deleteRecording(String id) async =>
      const Right(unit);

  @override
  Future<Either<Failure, Unit>> openRecording(
    RecordingEntity recording,
  ) async => const Right(unit);

  @override
  Future<Either<Failure, RecordingEntity?>> getActiveRecording() async =>
      Right(activeRecording);

  @override
  Future<Either<Failure, PagedResultEntity<RecordingEntity>>> getRecordings({
    String period = 'day',
    String? date,
    String? endDate,
    String? status,
    int offset = 0,
    int limit = 20,
  }) async => const Right(
    PagedResultEntity(items: [], totalCount: 0, offset: 0, limit: 20),
  );

  @override
  Future<Either<Failure, RecordingEntity>> startRecording() async {
    startResult.fold((_) {}, (recording) => activeRecording = recording);
    return startResult;
  }

  @override
  Future<Either<Failure, RecordingEntity?>> stopRecording() async {
    activeRecording = null;
    return stopResult;
  }
}

void main() {
  group('JourneyRuntimeCoordinator', () {
    late _FakeJourneyRepository repository;
    late _FakeJourneyRealtimeBridge bridge;
    late _FakeAccessibilityService accessibilityService;
    late _FakeAppBubbleService appBubbleService;
    late _FakeRecordingRepository recordingRepository;
    late JourneyRuntimeCoordinator coordinator;

    setUp(() {
      repository = _FakeJourneyRepository();
      bridge = _FakeJourneyRealtimeBridge();
      accessibilityService = _FakeAccessibilityService();
      appBubbleService = _FakeAppBubbleService();
      recordingRepository = _FakeRecordingRepository();
      coordinator = JourneyRuntimeCoordinator(
        journeyRealtimeBridge: bridge,
        getLocationTrackingStatusUseCase: GetLocationTrackingStatusUseCase(
          repository,
        ),
        watchLocationTrackingStatusUseCase: WatchLocationTrackingStatusUseCase(
          repository,
        ),
        syncPendingJourneyUseCase: SyncPendingJourneyUseCase(repository),
        accessibilityService: accessibilityService,
        appBubbleService: appBubbleService,
        getActiveRecordingUseCase: GetActiveRecordingUseCase(
          recordingRepository,
        ),
        startRecordingUseCase: StartRecordingUseCase(recordingRepository),
        stopRecordingUseCase: StopRecordingUseCase(recordingRepository),
      );
    });

    tearDown(() async {
      await repository.trackingController.close();
    });

    test('carrega status de tracking e sincroniza pendencias', () async {
      final status = await coordinator.loadTrackingStatus();
      final synced = await coordinator.syncPendingShifts();

      expect(status, isNotNull);
      expect(status!.totalDistanceMeters, 1000);
      expect(synced, 2);
    });

    test(
      'faz fallback quando tracking status e sincronizacao falham',
      () async {
        repository.trackingStatusResult = Left(ServerFailure('offline'));
        repository.syncResult = Left(ServerFailure('offline'));

        final status = await coordinator.loadTrackingStatus();
        final synced = await coordinator.syncPendingShifts();

        expect(status, isNull);
        expect(synced, 0);
      },
    );

    test(
      'bind conecta observers, stream e callback de corrida sem vazar apos unbind',
      () async {
        final connectionChanges = <bool>[];
        final accessibilityChanges = <bool>[];
        final trackingChanges = <LocationTrackingStatusEntity>[];
        var rideChanges = 0;

        coordinator.bind(
          onConnectionChanged: (isOnlineNow) async {
            connectionChanges.add(isOnlineNow);
          },
          onTrackingStatusChanged: trackingChanges.add,
          onRideChanged: () => rideChanges++,
          onAccessibilityChanged: accessibilityChanges.add,
        );

        expect(bridge.bindCalls, 1);

        bridge.isOnline.value = false;
        accessibilityService.isServiceEnabled.value = false;
        await Future<void>.delayed(Duration.zero);

        repository.trackingController.add(
          const LocationTrackingStatusEntity(
            isTrackingActive: false,
            isLocationServiceEnabled: true,
            hasForegroundPermission: true,
            hasBackgroundPermission: true,
            isPreciseLocation: true,
            isPaused: true,
            totalDistanceMeters: 250,
            idleTimeSeconds: 20,
          ),
        );
        await Future<void>.delayed(Duration.zero);

        bridge.onRideChanged?.call();
        expect(connectionChanges, [false]);
        expect(accessibilityChanges, [false]);
        expect(trackingChanges.single.totalDistanceMeters, 250);
        expect(rideChanges, 1);

        await coordinator.unbind();
        expect(bridge.unbound, isTrue);

        bridge.isOnline.value = true;
        accessibilityService.isServiceEnabled.value = true;
        repository.trackingController.add(
          const LocationTrackingStatusEntity(
            isTrackingActive: true,
            isLocationServiceEnabled: true,
            hasForegroundPermission: true,
            hasBackgroundPermission: true,
            isPreciseLocation: true,
            isPaused: false,
            totalDistanceMeters: 500,
            idleTimeSeconds: 0,
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(connectionChanges, [false]);
        expect(accessibilityChanges, [false]);
        expect(trackingChanges, hasLength(1));
      },
    );

    test('toggleAssistant ativa e desativa o overlay', () async {
      final feedbacks = <String>[];

      await coordinator.toggleAssistant(
        isAssistantActive: false,
        onAssistantStateChanged: (_) {},
        onBusyStateChanged: (_) {},
        showSuccess: (title, message) => feedbacks.add('$title:$message'),
        showWarning: (title, message) => feedbacks.add('$title:$message'),
        showError: (title, message) => feedbacks.add('$title:$message'),
      );

      expect(appBubbleService.bubbleRunning, isTrue);
      expect(feedbacks.single, contains('Assistente ativado'));

      await coordinator.toggleAssistant(
        isAssistantActive: true,
        onAssistantStateChanged: (_) {},
        onBusyStateChanged: (_) {},
        showSuccess: (title, message) => feedbacks.add('$title:$message'),
        showWarning: (title, message) => feedbacks.add('$title:$message'),
        showError: (title, message) => feedbacks.add('$title:$message'),
      );

      expect(appBubbleService.bubbleRunning, isFalse);
    });

    test(
      'toggleAssistant avisa quando permissao de overlay esta negada',
      () async {
        final feedbacks = <String>[];
        final busyStates = <bool>[];
        final assistantStates = <bool>[];
        appBubbleService.permissionGranted = false;

        await coordinator.toggleAssistant(
          isAssistantActive: false,
          onAssistantStateChanged: assistantStates.add,
          onBusyStateChanged: busyStates.add,
          showSuccess: (title, message) => feedbacks.add('$title:$message'),
          showWarning: (title, message) => feedbacks.add('$title:$message'),
          showError: (title, message) => feedbacks.add('$title:$message'),
        );

        expect(appBubbleService.openedOverlaySettings, isTrue);
        expect(assistantStates, isEmpty);
        expect(busyStates, [true, false]);
        expect(
          feedbacks.single,
          'Permissao necessaria:Libere a permissao de sobreposicao para ativar o Assistente.',
        );
      },
    );

    test('toggleAssistant informa erro quando inicializacao falha', () async {
      final feedbacks = <String>[];
      final busyStates = <bool>[];
      final assistantStates = <bool>[];
      appBubbleService.startBubbleError = StateError('falha');

      await coordinator.toggleAssistant(
        isAssistantActive: false,
        onAssistantStateChanged: assistantStates.add,
        onBusyStateChanged: busyStates.add,
        showSuccess: (title, message) => feedbacks.add('$title:$message'),
        showWarning: (title, message) => feedbacks.add('$title:$message'),
        showError: (title, message) => feedbacks.add('$title:$message'),
      );

      expect(appBubbleService.bubbleRunning, isFalse);
      expect(assistantStates, isEmpty);
      expect(busyStates, [true, false]);
      expect(
        feedbacks.single,
        'Nao foi possivel ativar:Falhou ao iniciar o Assistente neste momento.',
      );
    });

    test('toggleRecording ativa e para gravacao', () async {
      final feedbacks = <String>[];
      final busyStates = <bool>[];
      final recordingStates = <RecordingEntity?>[];

      await coordinator.toggleRecording(
        isRecordingActive: false,
        onRecordingStateChanged: recordingStates.add,
        onBusyStateChanged: busyStates.add,
        showSuccess: (title, message) => feedbacks.add('$title:$message'),
        showWarning: (title, message) => feedbacks.add('$title:$message'),
        showError: (title, message) => feedbacks.add('$title:$message'),
      );

      expect(recordingStates.single?.isActive, isTrue);
      expect(feedbacks.single, contains('Gravacao ativa'));

      await coordinator.toggleRecording(
        isRecordingActive: true,
        onRecordingStateChanged: recordingStates.add,
        onBusyStateChanged: busyStates.add,
        showSuccess: (title, message) => feedbacks.add('$title:$message'),
        showWarning: (title, message) => feedbacks.add('$title:$message'),
        showError: (title, message) => feedbacks.add('$title:$message'),
      );

      expect(recordingStates.last, isNull);
      expect(busyStates, [true, false, true, false]);
    });
  });
}
