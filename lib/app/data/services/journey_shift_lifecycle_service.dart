import '../../core/errors/failures.dart';
import '../datasources/journey_local_datasource.dart';
import '../datasources/journey_route_local_datasource.dart';
import '../datasources/location_tracking_datasource.dart';
import '../models/pending_finished_shift_model.dart';

class JourneyShiftLifecycleService {
  JourneyShiftLifecycleService({
    required this.localDataSource,
    required this.routeLocalDataSource,
    required this.locationTrackingDataSource,
  });

  final IJourneyLocalDataSource localDataSource;
  final IJourneyRouteLocalDataSource routeLocalDataSource;
  final ILocationTrackingDataSource locationTrackingDataSource;

  Future<void> startShift() async {
    final trackingStatus = await locationTrackingDataSource
        .ensureReadyForShiftStart();
    if (trackingStatus.issueMessage != null) {
      throw ValidationFailure(trackingStatus.issueMessage!);
    }

    final shift = await localDataSource.startShift();
    await routeLocalDataSource.ensureRoute(
      localShiftId: shift.id,
      startedAt: shift.startTime,
    );

    try {
      await locationTrackingDataSource.startTracking(
        localShiftId: shift.id,
        startedAt: shift.startTime,
      );
    } catch (_) {
      await localDataSource.clearActiveShift();
      await routeLocalDataSource.deleteRoute(shift.id);
      rethrow;
    }
  }

  Future<void> pauseShift() async {
    final pausedShift = await localDataSource.pauseShift();

    try {
      await locationTrackingDataSource.pauseTracking();
    } catch (_) {
      await localDataSource.resumeShift();
      rethrow;
    }

    await routeLocalDataSource.ensureRoute(
      localShiftId: pausedShift.id,
      startedAt: pausedShift.startTime,
    );
  }

  Future<void> resumeShift() async {
    final trackingStatus = await locationTrackingDataSource
        .ensureReadyForShiftStart();
    if (trackingStatus.issueMessage != null) {
      throw ValidationFailure(trackingStatus.issueMessage!);
    }

    final resumedShift = await localDataSource.resumeShift();

    try {
      await locationTrackingDataSource.resumeTracking(
        localShiftId: resumedShift.id,
        startedAt: resumedShift.startTime,
      );
    } catch (_) {
      await localDataSource.pauseShift();
      rethrow;
    }
  }

  Future<PendingFinishedShiftModel> finishShift() async {
    final activeShift = await localDataSource.getActiveShift();
    if (activeShift == null) {
      throw StateError('Nao ha turno ativo para finalizar.');
    }

    final endTime = DateTime.now();
    if (!activeShift.isPaused) {
      await locationTrackingDataSource.stopTracking(endedAt: endTime);
    }

    final route = await routeLocalDataSource.getRouteByLocalShiftId(
      activeShift.id,
      includePoints: false,
    );
    final totalDrivenKm = route?.totalDistanceKm ?? 0;

    final pendingShift = await localDataSource.finishShift(
      totalDrivenKm: totalDrivenKm,
    );
    await routeLocalDataSource.markRouteFinished(
      localShiftId: activeShift.id,
      endedAt: pendingShift.endTime,
    );

    return pendingShift;
  }
}
