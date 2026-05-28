import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';

import '../../core/location/location_tracking_service.dart';
import '../models/active_shift_model.dart';
import '../models/location_tracking_status_model.dart';
import 'journey_route_local_datasource.dart';

abstract class ILocationTrackingDataSource {
  Future<LocationTrackingStatusModel> ensureReadyForShiftStart();
  Future<LocationTrackingStatusModel> getCurrentStatus({
    int? localShiftId,
    bool isPaused = false,
  });
  Stream<LocationTrackingStatusModel> watchStatus();
  Future<void> startTracking({
    required int localShiftId,
    required DateTime startedAt,
  });
  Future<void> pauseTracking();
  Future<void> resumeTracking({
    required int localShiftId,
    required DateTime startedAt,
  });
  Future<void> stopTracking({required DateTime endedAt});
}

class LocationTrackingDataSourceImpl implements ILocationTrackingDataSource {
  LocationTrackingDataSourceImpl({
    required this.routeLocalDataSource,
    required this.storage,
  });

  final IJourneyRouteLocalDataSource routeLocalDataSource;
  final GetStorage storage;
  static const _activeShiftKey = 'journey_local_active_shift';

  @override
  Future<LocationTrackingStatusModel> ensureReadyForShiftStart() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationTrackingStatusModel(
        isTrackingActive: false,
        isLocationServiceEnabled: false,
        hasForegroundPermission: false,
        hasBackgroundPermission: false,
        isPreciseLocation: false,
        isPaused: false,
        totalDistanceMeters: 0,
        idleTimeSeconds: 0,
        issueMessage: 'Ative o GPS do aparelho para iniciar o turno.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationTrackingStatusModel(
        isTrackingActive: false,
        isLocationServiceEnabled: true,
        hasForegroundPermission: false,
        hasBackgroundPermission: false,
        isPreciseLocation: false,
        isPaused: false,
        totalDistanceMeters: 0,
        idleTimeSeconds: 0,
        issueMessage: 'Permita a localizacao para iniciar e rastrear o turno.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationTrackingStatusModel(
        isTrackingActive: false,
        isLocationServiceEnabled: true,
        hasForegroundPermission: false,
        hasBackgroundPermission: false,
        isPreciseLocation: false,
        isPaused: false,
        totalDistanceMeters: 0,
        idleTimeSeconds: 0,
        issueMessage:
            'A permissao de localizacao foi negada em definitivo. Libere nas configuracoes do app.',
      );
    }

    final hasForegroundPermission =
        permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    final isPreciseLocation =
        await Geolocator.getLocationAccuracy() ==
        LocationAccuracyStatus.precise;

    if (!isPreciseLocation) {
      return LocationTrackingStatusModel(
        isTrackingActive: false,
        isLocationServiceEnabled: true,
        hasForegroundPermission: hasForegroundPermission,
        hasBackgroundPermission: permission == LocationPermission.always,
        isPreciseLocation: false,
        isPaused: false,
        totalDistanceMeters: 0,
        idleTimeSeconds: 0,
        issueMessage:
            'Troque para localizacao precisa para rastrear a rota do turno.',
      );
    }

    if (permission != LocationPermission.always) {
      permission = await Geolocator.requestPermission();
    }

    final hasBackgroundPermission = permission == LocationPermission.always;
    if (!hasBackgroundPermission) {
      return LocationTrackingStatusModel(
        isTrackingActive: false,
        isLocationServiceEnabled: true,
        hasForegroundPermission: hasForegroundPermission,
        hasBackgroundPermission: false,
        isPreciseLocation: true,
        isPaused: false,
        totalDistanceMeters: 0,
        idleTimeSeconds: 0,
        issueMessage:
            'A localizacao ja pode estar liberada, mas ainda falta marcar "Permitir o tempo todo" nas configuracoes do app.',
      );
    }

    return const LocationTrackingStatusModel(
      isTrackingActive: false,
      isLocationServiceEnabled: true,
      hasForegroundPermission: true,
      hasBackgroundPermission: true,
      isPreciseLocation: true,
      isPaused: false,
      totalDistanceMeters: 0,
      idleTimeSeconds: 0,
    );
  }

  @override
  Future<LocationTrackingStatusModel> getCurrentStatus({
    int? localShiftId,
    bool isPaused = false,
  }) async {
    await LocationTrackingService.refreshIdleTimeIfNeeded(
      localShiftId: localShiftId,
      isPaused: isPaused,
    );

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();
    final accuracyStatus = await Geolocator.getLocationAccuracy();
    final isRunning = await LocationTrackingService.isRunning();
    final activeShift = _readActiveShift();
    final route = localShiftId != null
        ? await routeLocalDataSource.getRouteByLocalShiftId(
            localShiftId,
            includePoints: false,
          )
        : null;

    final hasForegroundPermission =
        permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    final hasBackgroundPermission = permission == LocationPermission.always;
    final isPreciseLocation = accuracyStatus == LocationAccuracyStatus.precise;

    return LocationTrackingStatusModel(
      isTrackingActive: isRunning && !isPaused && localShiftId != null,
      isLocationServiceEnabled: serviceEnabled,
      hasForegroundPermission: hasForegroundPermission,
      hasBackgroundPermission: hasBackgroundPermission,
      isPreciseLocation: isPreciseLocation,
      isPaused: isPaused,
      totalDistanceMeters: route?.totalDistanceMeters ?? 0,
      idleTimeSeconds: activeShift?.idleTimeSeconds ?? 0,
      issueMessage: _buildIssueMessage(
        serviceEnabled: serviceEnabled,
        hasForegroundPermission: hasForegroundPermission,
        hasBackgroundPermission: hasBackgroundPermission,
        isPreciseLocation: isPreciseLocation,
        hasActiveShift: localShiftId != null,
        isPaused: isPaused,
      ),
    );
  }

  @override
  Stream<LocationTrackingStatusModel> watchStatus() {
    return LocationTrackingService.watchStatus().map(
      LocationTrackingStatusModel.fromServiceEvent,
    );
  }

  @override
  Future<void> startTracking({
    required int localShiftId,
    required DateTime startedAt,
  }) async {
    await LocationTrackingService.startTracking(
      localShiftId: localShiftId,
      startedAt: startedAt,
    );
  }

  @override
  Future<void> pauseTracking() async {
    await LocationTrackingService.pauseTracking();
  }

  @override
  Future<void> resumeTracking({
    required int localShiftId,
    required DateTime startedAt,
  }) async {
    await LocationTrackingService.resumeTracking(
      localShiftId: localShiftId,
      startedAt: startedAt,
    );
  }

  @override
  Future<void> stopTracking({required DateTime endedAt}) async {
    await LocationTrackingService.stopTracking(endedAt: endedAt);
  }

  String? _buildIssueMessage({
    required bool serviceEnabled,
    required bool hasForegroundPermission,
    required bool hasBackgroundPermission,
    required bool isPreciseLocation,
    required bool hasActiveShift,
    required bool isPaused,
  }) {
    if (!hasActiveShift || isPaused) {
      return null;
    }

    if (!serviceEnabled) {
      return 'Ative o GPS do aparelho para continuar rastreando o turno.';
    }

    if (!hasForegroundPermission) {
      return 'A localizacao foi removida. Libere novamente para continuar o rastreio.';
    }

    if (!isPreciseLocation) {
      return 'A localizacao precisa foi desativada. Corrija para continuar o rastreio.';
    }

    if (!hasBackgroundPermission) {
      return 'A localizacao ja pode estar liberada, mas ainda falta marcar "Permitir o tempo todo" nas configuracoes do app.';
    }

    return null;
  }

  ActiveShiftModel? _readActiveShift() {
    final raw = storage.read(_activeShiftKey);
    if (raw is! Map) {
      return null;
    }

    return ActiveShiftModel.fromJson(Map<String, dynamic>.from(raw));
  }
}
