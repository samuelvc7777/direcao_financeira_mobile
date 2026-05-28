import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sqflite_android/sqflite_android.dart';

import '../../data/datasources/journey_route_local_datasource.dart';
import '../../data/models/active_shift_model.dart';
import '../../data/models/tracked_route_point_model.dart';

const _journeyActiveShiftKey = 'journey_local_active_shift';
const _notificationChannelId = 'journey_location_tracking';
const _notificationId = 4812;
const _journeyTrackingDistanceFilterMeters = 25;
const _journeyTrackingEconomyDistanceFilterMeters = 75;
const _minimumTrackedSpeedKmH = 10.0;
const _minimumTrackedSpeedMetersPerSecond = _minimumTrackedSpeedKmH / 3.6;
const _idleGracePeriod = Duration(minutes: 4);
const _idleTickInterval = Duration(seconds: 30);
const _minimumStatusEmitDistanceMeters = 100.0;
const _minimumStatusEmitInterval = Duration(seconds: 15);
const _activeLocationInterval = Duration(seconds: 10);
const _economyLocationInterval = Duration(seconds: 30);

enum _TrackingPowerMode { active, economy }

Future<void> initializeLocationTrackingService(GetStorage storage) async {
  WidgetsFlutterBinding.ensureInitialized();
  await _createTrackingNotificationChannel();

  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: journeyLocationTrackingServiceOnStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: _notificationChannelId,
      initialNotificationTitle: 'Turno em andamento',
      initialNotificationContent: 'Preparando rastreamento da rota',
      foregroundServiceNotificationId: _notificationId,
      foregroundServiceTypes: [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: journeyLocationTrackingServiceOnStart,
    ),
  );

  await restoreLocationTrackingServiceFromStorage(storage);
}

Future<void> restoreLocationTrackingServiceFromStorage(
  GetStorage storage,
) async {
  final rawShift = storage.read(_journeyActiveShiftKey);
  if (rawShift is! Map) {
    await LocationTrackingService.stopTracking(markFinished: false);
    return;
  }

  final shift = ActiveShiftModel.fromJson(Map<String, dynamic>.from(rawShift));
  if (shift.isPaused) {
    await LocationTrackingService.stopTracking(markFinished: false);
    return;
  }

  await LocationTrackingService.startTracking(
    localShiftId: shift.id,
    startedAt: shift.startTime,
  );
}

class LocationTrackingService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  static Stream<Map<String, dynamic>> watchStatus() {
    return _service.on('tracking_status').map((event) {
      if (event == null) {
        return <String, dynamic>{};
      }
      return Map<String, dynamic>.from(event);
    });
  }

  static Future<bool> isRunning() => _service.isRunning();

  static Future<void> startTracking({
    required int localShiftId,
    required DateTime startedAt,
  }) async {
    final isRunning = await _service.isRunning();
    if (!isRunning) {
      await _service.startService();
      await Future.delayed(const Duration(milliseconds: 350));
    }

    _service.invoke('start_tracking', {
      'local_shift_id': localShiftId,
      'started_at': startedAt.toUtc().toIso8601String(),
    });
  }

  static Future<void> resumeTracking({
    required int localShiftId,
    required DateTime startedAt,
  }) async {
    final isRunning = await _service.isRunning();
    if (!isRunning) {
      await _service.startService();
      await Future.delayed(const Duration(milliseconds: 350));
    }

    _service.invoke('resume_tracking', {
      'local_shift_id': localShiftId,
      'started_at': startedAt.toUtc().toIso8601String(),
    });
  }

  static Future<void> pauseTracking() async {
    if (!await _service.isRunning()) {
      return;
    }

    _service.invoke('pause_tracking');
  }

  static Future<void> stopTracking({
    bool markFinished = true,
    DateTime? endedAt,
  }) async {
    if (!await _service.isRunning()) {
      return;
    }

    _service.invoke('stop_tracking', {
      'mark_finished': markFinished,
      if (endedAt != null) 'ended_at': endedAt.toUtc().toIso8601String(),
    });
  }

  static Future<void> refreshIdleTimeIfNeeded({
    required int? localShiftId,
    required bool isPaused,
    DateTime? reference,
  }) async {
    if (localShiftId == null || isPaused) {
      return;
    }

    final storage = GetStorage();
    final rawShift = storage.read(_journeyActiveShiftKey);
    if (rawShift is! Map) {
      return;
    }

    final shift = ActiveShiftModel.fromJson(
      Map<String, dynamic>.from(rawShift),
    );
    if (shift.id != localShiftId ||
        shift.isPaused ||
        shift.lowSpeedSince == null) {
      return;
    }

    final updatedShift = _accumulateStoppedIdle(
      shift: shift,
      reference: reference ?? DateTime.now(),
      includePartialTick: false,
    );

    if (updatedShift.idleTimeSeconds == shift.idleTimeSeconds &&
        updatedShift.lastMotionIdleCheckpointAt ==
            shift.lastMotionIdleCheckpointAt) {
      return;
    }

    await storage.write(_journeyActiveShiftKey, updatedShift.toJson());
  }

  static ActiveShiftModel _accumulateStoppedIdle({
    required ActiveShiftModel shift,
    required DateTime reference,
    required bool includePartialTick,
  }) {
    final stoppedSince = shift.lowSpeedSince;
    if (stoppedSince == null) {
      return shift;
    }

    final confirmedAt = stoppedSince.add(_idleGracePeriod);
    if (reference.isBefore(confirmedAt)) {
      return shift;
    }

    final countedUntil = shift.lastMotionIdleCheckpointAt ?? stoppedSince;
    if (!reference.isAfter(countedUntil)) {
      return shift;
    }

    final elapsedSeconds = reference.difference(countedUntil).inSeconds;
    final secondsToAdd = includePartialTick
        ? elapsedSeconds
        : (elapsedSeconds ~/ _idleTickInterval.inSeconds) *
              _idleTickInterval.inSeconds;

    if (secondsToAdd <= 0) {
      return shift;
    }

    return shift.copyWith(
      idleTimeSeconds: shift.idleTimeSeconds + secondsToAdd,
      lastMotionIdleCheckpointAt: countedUntil.add(
        Duration(seconds: secondsToAdd),
      ),
    );
  }
}

Future<void> _createTrackingNotificationChannel() async {
  const channel = AndroidNotificationChannel(
    _notificationChannelId,
    'Rastreamento de turno',
    description: 'Notificacoes do rastreamento de localizacao da jornada.',
    importance: Importance.low,
  );

  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
}

@pragma('vm:entry-point')
void journeyLocationTrackingServiceOnStart(ServiceInstance service) async {
  GeolocatorAndroid.registerWith();
  SqfliteAndroid.registerWith();
  await GetStorage.init();

  final storage = GetStorage();
  final routeDataSource = JourneyRouteLocalDataSourceImpl();
  StreamSubscription<Position>? positionSubscription;
  Timer? idleRefreshTimer;
  int? currentLocalShiftId;
  DateTime? currentStartedAt;
  bool isPaused = false;
  bool isSwitchingPowerMode = false;
  var trackingPowerMode = _TrackingPowerMode.active;
  DateTime? lastStatusEmittedAt;
  double? lastEmittedDistanceMeters;
  String? lastEmittedIssueMessage;
  bool? lastEmittedTrackingActive;
  int? lastEmittedIdleTimeSeconds;
  int? lastNotificationKmMarker;
  String? lastNotificationIssueMessage;

  ActiveShiftModel? readActiveShift() {
    final rawShift = storage.read(_journeyActiveShiftKey);
    if (rawShift is! Map) {
      return null;
    }

    return ActiveShiftModel.fromJson(Map<String, dynamic>.from(rawShift));
  }

  Future<void> saveActiveShift(ActiveShiftModel shift) async {
    final nextJson = shift.toJson();
    final currentJson = storage.read(_journeyActiveShiftKey);
    if (_jsonEquals(currentJson, nextJson)) {
      return;
    }

    await storage.write(_journeyActiveShiftKey, nextJson);
  }

  Future<bool> finishStoppedPeriod({
    required DateTime observedAt,
    double? currentDrivenKm,
  }) async {
    final shift = readActiveShift();
    if (shift == null ||
        shift.id != currentLocalShiftId ||
        (shift.lowSpeedSince == null &&
            shift.lastMotionIdleCheckpointAt == null &&
            currentDrivenKm == null)) {
      return false;
    }

    final updatedShift = LocationTrackingService._accumulateStoppedIdle(
      shift: shift,
      reference: observedAt,
      includePartialTick: true,
    );

    await saveActiveShift(
      updatedShift.copyWith(
        currentDrivenKm: currentDrivenKm ?? updatedShift.currentDrivenKm,
        clearLowSpeedSince: true,
        clearLastMotionIdleCheckpointAt: true,
      ),
    );
    return true;
  }

  Future<bool> registerLowSpeedObservation({
    required DateTime observedAt,
    double? currentDrivenKm,
  }) async {
    final shift = readActiveShift();
    if (shift == null || shift.id != currentLocalShiftId || shift.isPaused) {
      return false;
    }

    final stoppedShift = shift.lowSpeedSince == null
        ? shift.copyWith(
            lowSpeedSince: observedAt,
            clearLastMotionIdleCheckpointAt: true,
          )
        : LocationTrackingService._accumulateStoppedIdle(
            shift: shift,
            reference: observedAt,
            includePartialTick: false,
          );

    await saveActiveShift(
      stoppedShift.copyWith(
        currentDrivenKm: currentDrivenKm ?? stoppedShift.currentDrivenKm,
      ),
    );

    return stoppedShift.idleTimeSeconds != shift.idleTimeSeconds;
  }

  Future<void> markPotentialIdleStart() async {
    final shift = readActiveShift();
    if (shift == null ||
        shift.id != currentLocalShiftId ||
        shift.isPaused ||
        shift.lowSpeedSince != null) {
      return;
    }

    await saveActiveShift(
      shift.copyWith(
        lowSpeedSince: DateTime.now(),
        clearLastMotionIdleCheckpointAt: true,
      ),
    );
  }

  Future<void> emitStatus({
    String? issueMessage,
    bool? isTrackingActive,
    double? totalDistanceMeters,
    bool force = false,
  }) async {
    final payload = await _buildTrackingStatusPayload(
      localShiftId: currentLocalShiftId,
      isPaused: isPaused,
      issueMessage: issueMessage,
      overrideTrackingActive: isTrackingActive,
      overrideTotalDistanceMeters: totalDistanceMeters,
      routeDataSource: routeDataSource,
    );

    final currentDistanceMeters =
        (payload['totalDistanceMeters'] as num?)?.toDouble() ?? 0;
    final currentIssueMessage = payload['issueMessage'] as String?;
    final currentTrackingActive = payload['isTrackingActive'] as bool? ?? false;
    final currentIdleTimeSeconds = payload['idleTimeSeconds'] as int? ?? 0;
    final now = DateTime.now();

    final shouldEmit =
        force ||
        lastStatusEmittedAt == null ||
        currentIssueMessage != lastEmittedIssueMessage ||
        currentTrackingActive != lastEmittedTrackingActive ||
        currentIdleTimeSeconds != lastEmittedIdleTimeSeconds ||
        lastEmittedDistanceMeters == null ||
        (currentDistanceMeters - lastEmittedDistanceMeters!).abs() >=
            _minimumStatusEmitDistanceMeters ||
        now.difference(lastStatusEmittedAt!) >= _minimumStatusEmitInterval;

    if (!shouldEmit) {
      return;
    }

    lastStatusEmittedAt = now;
    lastEmittedDistanceMeters = currentDistanceMeters;
    lastEmittedIssueMessage = currentIssueMessage;
    lastEmittedTrackingActive = currentTrackingActive;
    lastEmittedIdleTimeSeconds = currentIdleTimeSeconds;
    service.invoke('tracking_status', payload);

    if (service is AndroidServiceInstance) {
      final issueMessage = payload['issueMessage'] as String?;
      if (issueMessage != null) {
        if (issueMessage != lastNotificationIssueMessage) {
          lastNotificationIssueMessage = issueMessage;
          await service.setForegroundNotificationInfo(
            title: 'Turno em andamento',
            content: issueMessage,
          );
        }
      } else {
        lastNotificationIssueMessage = null;
        final wholeKmMarker = currentDistanceMeters ~/ 1000;
        if (lastNotificationKmMarker == null ||
            wholeKmMarker != lastNotificationKmMarker) {
          lastNotificationKmMarker = wholeKmMarker;
          await service.setForegroundNotificationInfo(
            title: 'Turno em andamento',
            content: '$wholeKmMarker km monitorados',
          );
        }
      }
    }
  }

  Future<void> startIdleRefreshTimer() async {
    idleRefreshTimer?.cancel();
    idleRefreshTimer = Timer.periodic(_idleTickInterval, (_) async {
      await LocationTrackingService.refreshIdleTimeIfNeeded(
        localShiftId: currentLocalShiftId,
        isPaused: isPaused,
      );
      await emitStatus(force: true);
    });
  }

  Future<void> cancelPositionStream() async {
    await positionSubscription?.cancel();
    positionSubscription = null;
  }

  Future<void> cancelTrackingStream() async {
    await cancelPositionStream();
    idleRefreshTimer?.cancel();
    idleRefreshTimer = null;
  }

  late Future<void> Function() startPositionStream;

  Future<void> switchTrackingPowerMode(_TrackingPowerMode mode) async {
    if (trackingPowerMode == mode || isSwitchingPowerMode) {
      return;
    }

    isSwitchingPowerMode = true;
    try {
      trackingPowerMode = mode;
      await startPositionStream();
    } finally {
      isSwitchingPowerMode = false;
    }
  }

  startPositionStream = () async {
    await cancelPositionStream();

    final locationSettings = _buildLocationSettings(mode: trackingPowerMode);
    positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (position) async {
            final observedAt = position.timestamp.toLocal();
            if (position.speed < _minimumTrackedSpeedMetersPerSecond) {
              final currentRoute = await routeDataSource.getRouteByLocalShiftId(
                currentLocalShiftId!,
                includePoints: false,
              );
              await registerLowSpeedObservation(
                observedAt: observedAt,
                currentDrivenKm:
                    (currentRoute?.totalDistanceMeters ?? 0) / 1000,
              );

              final shift = readActiveShift();
              final lowSpeedSince = shift?.lowSpeedSince;
              if (trackingPowerMode == _TrackingPowerMode.active &&
                  lowSpeedSince != null &&
                  observedAt.difference(lowSpeedSince) >= _idleGracePeriod) {
                await switchTrackingPowerMode(_TrackingPowerMode.economy);
              }

              await emitStatus(
                isTrackingActive: true,
                totalDistanceMeters: currentRoute?.totalDistanceMeters ?? 0,
              );
              return;
            }

            var movementPosition = position;
            if (trackingPowerMode == _TrackingPowerMode.economy) {
              await switchTrackingPowerMode(_TrackingPowerMode.active);
              try {
                movementPosition = await Geolocator.getCurrentPosition(
                  locationSettings: _buildLocationSettings(
                    mode: _TrackingPowerMode.active,
                  ),
                );
              } catch (_) {
                movementPosition = position;
              }
            }

            final updatedRoute = await routeDataSource.appendPoint(
              localShiftId: currentLocalShiftId!,
              point: TrackedRoutePointModel(
                latitude: movementPosition.latitude,
                longitude: movementPosition.longitude,
                accuracyMeters: movementPosition.accuracy,
                recordedAt: movementPosition.timestamp.toLocal(),
              ),
            );
            final resumedMovement = await finishStoppedPeriod(
              observedAt: movementPosition.timestamp.toLocal(),
              currentDrivenKm: (updatedRoute?.totalDistanceMeters ?? 0) / 1000,
            );

            await emitStatus(
              isTrackingActive: true,
              totalDistanceMeters: updatedRoute?.totalDistanceMeters ?? 0,
              force: resumedMovement,
            );
          },
          onError: (error) async {
            await emitStatus(
              issueMessage:
                  'Nao foi possivel continuar rastreando a localizacao do turno.',
              isTrackingActive: false,
              force: true,
            );
          },
        );
  };

  Future<void> startTrackingStream() async {
    await cancelTrackingStream();

    if (currentLocalShiftId == null || currentStartedAt == null) {
      await emitStatus(
        issueMessage: 'Nao foi possivel identificar o turno para rastrear.',
        isTrackingActive: false,
        force: true,
      );
      return;
    }

    final validationPayload = await _buildTrackingStatusPayload(
      localShiftId: currentLocalShiftId,
      isPaused: isPaused,
      routeDataSource: routeDataSource,
    );

    if (validationPayload['issueMessage'] != null) {
      await emitStatus(
        issueMessage: validationPayload['issueMessage'] as String,
        isTrackingActive: false,
        force: true,
      );
      return;
    }

    await routeDataSource.ensureRoute(
      localShiftId: currentLocalShiftId!,
      startedAt: currentStartedAt!,
    );
    trackingPowerMode = _TrackingPowerMode.active;
    await markPotentialIdleStart();
    await startIdleRefreshTimer();
    await startPositionStream();

    await emitStatus(isTrackingActive: true, force: true);
  }

  service.on('start_tracking').listen((event) async {
    if (event == null) {
      return;
    }

    currentLocalShiftId = event['local_shift_id'] as int?;
    final startedAtRaw = event['started_at'] as String?;
    currentStartedAt = startedAtRaw != null
        ? DateTime.tryParse(startedAtRaw)?.toLocal()
        : null;
    isPaused = false;
    lastStatusEmittedAt = null;
    lastEmittedDistanceMeters = null;
    lastEmittedIssueMessage = null;
    lastEmittedTrackingActive = null;
    lastEmittedIdleTimeSeconds = null;
    lastNotificationKmMarker = null;
    lastNotificationIssueMessage = null;

    await startTrackingStream();
  });

  service.on('resume_tracking').listen((event) async {
    if (event == null) {
      return;
    }

    currentLocalShiftId = event['local_shift_id'] as int?;
    final startedAtRaw = event['started_at'] as String?;
    currentStartedAt = startedAtRaw != null
        ? DateTime.tryParse(startedAtRaw)?.toLocal()
        : currentStartedAt;
    isPaused = false;
    lastStatusEmittedAt = null;
    lastEmittedDistanceMeters = null;
    lastEmittedIssueMessage = null;
    lastEmittedTrackingActive = null;
    lastEmittedIdleTimeSeconds = null;
    lastNotificationKmMarker = null;
    lastNotificationIssueMessage = null;

    await startTrackingStream();
  });

  service.on('pause_tracking').listen((_) async {
    isPaused = true;
    await cancelTrackingStream();
    await emitStatus(
      issueMessage: 'Rastreamento pausado.',
      isTrackingActive: false,
      force: true,
    );
    service.stopSelf();
  });

  service.on('stop_tracking').listen((event) async {
    await cancelTrackingStream();

    final markFinished = event?['mark_finished'] != false;
    final endedAtRaw = event?['ended_at'] as String?;
    final endedAt = endedAtRaw != null
        ? DateTime.tryParse(endedAtRaw)?.toLocal()
        : DateTime.now();

    if (markFinished && currentLocalShiftId != null && endedAt != null) {
      try {
        final finalPosition = await Geolocator.getCurrentPosition(
          locationSettings: _buildLocationSettings(),
        );
        await routeDataSource.appendPoint(
          localShiftId: currentLocalShiftId!,
          point: TrackedRoutePointModel(
            latitude: finalPosition.latitude,
            longitude: finalPosition.longitude,
            accuracyMeters: finalPosition.accuracy,
            recordedAt: finalPosition.timestamp.toLocal(),
          ),
          forceRecord: true,
        );
      } catch (_) {}

      await routeDataSource.markRouteFinished(
        localShiftId: currentLocalShiftId!,
        endedAt: endedAt,
      );
    }

    await emitStatus(isTrackingActive: false, force: true);
    service.stopSelf();
  });
}

bool _jsonEquals(Object? left, Object? right) {
  try {
    return jsonEncode(left) == jsonEncode(right);
  } catch (_) {
    return false;
  }
}

Future<Map<String, dynamic>> _buildTrackingStatusPayload({
  required IJourneyRouteLocalDataSource routeDataSource,
  required int? localShiftId,
  required bool isPaused,
  String? issueMessage,
  bool? overrideTrackingActive,
  double? overrideTotalDistanceMeters,
}) async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  final permission = await Geolocator.checkPermission();
  final accuracyStatus = await Geolocator.getLocationAccuracy();
  final hasForegroundPermission =
      permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always;
  final hasBackgroundPermission = permission == LocationPermission.always;
  final isPreciseLocation = accuracyStatus == LocationAccuracyStatus.precise;

  final route = localShiftId != null
      ? await routeDataSource.getRouteByLocalShiftId(
          localShiftId,
          includePoints: false,
        )
      : null;
  final storage = GetStorage();
  final rawShift = storage.read(_journeyActiveShiftKey);
  final activeShift = rawShift is Map
      ? ActiveShiftModel.fromJson(Map<String, dynamic>.from(rawShift))
      : null;
  final totalDistanceMeters =
      overrideTotalDistanceMeters ?? route?.totalDistanceMeters ?? 0;

  final computedIssueMessage =
      issueMessage ??
      _buildTrackingIssueMessage(
        serviceEnabled: serviceEnabled,
        hasForegroundPermission: hasForegroundPermission,
        hasBackgroundPermission: hasBackgroundPermission,
        isPreciseLocation: isPreciseLocation,
      );

  final isTrackingActive =
      overrideTrackingActive ??
      (computedIssueMessage == null && !isPaused && localShiftId != null);

  return {
    'isTrackingActive': isTrackingActive,
    'isLocationServiceEnabled': serviceEnabled,
    'hasForegroundPermission': hasForegroundPermission,
    'hasBackgroundPermission': hasBackgroundPermission,
    'isPreciseLocation': isPreciseLocation,
    'isPaused': isPaused,
    'totalDistanceMeters': totalDistanceMeters,
    'idleTimeSeconds': activeShift?.idleTimeSeconds ?? 0,
    'issueMessage': computedIssueMessage,
  };
}

String? _buildTrackingIssueMessage({
  required bool serviceEnabled,
  required bool hasForegroundPermission,
  required bool hasBackgroundPermission,
  required bool isPreciseLocation,
}) {
  if (!serviceEnabled) {
    return 'Ative o GPS do aparelho para continuar rastreando o turno.';
  }

  if (!hasForegroundPermission) {
    return 'Permita a localizacao do app para iniciar o rastreamento do turno.';
  }

  if (!isPreciseLocation) {
    return 'Troque a localizacao aproximada para precisa para rastrear o turno.';
  }

  if (!hasBackgroundPermission) {
    return 'Permita localizacao o tempo todo para continuar o turno com o app fechado.';
  }

  return null;
}

LocationSettings _buildLocationSettings({
  _TrackingPowerMode mode = _TrackingPowerMode.active,
}) {
  final isEconomyMode = mode == _TrackingPowerMode.economy;
  if (Platform.isAndroid) {
    return AndroidSettings(
      accuracy: isEconomyMode ? LocationAccuracy.medium : LocationAccuracy.high,
      distanceFilter: isEconomyMode
          ? _journeyTrackingEconomyDistanceFilterMeters
          : _journeyTrackingDistanceFilterMeters,
      intervalDuration: isEconomyMode
          ? _economyLocationInterval
          : _activeLocationInterval,
      forceLocationManager: false,
    );
  }

  return LocationSettings(
    accuracy: isEconomyMode ? LocationAccuracy.medium : LocationAccuracy.high,
    distanceFilter: isEconomyMode
        ? _journeyTrackingEconomyDistanceFilterMeters
        : _journeyTrackingDistanceFilterMeters,
  );
}
