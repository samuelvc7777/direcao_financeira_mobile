import 'package:direcao_financeira_mobile/app/core/errors/failures.dart';
import 'package:direcao_financeira_mobile/app/core/network/api_error_mapper.dart';
import 'package:direcao_financeira_mobile/app/core/network/api_request_logger.dart';
import 'package:direcao_financeira_mobile/app/core/network/realtime_client.dart';
import 'package:direcao_financeira_mobile/app/data/datasources/i_journey_datasource.dart';
import 'package:direcao_financeira_mobile/app/data/datasources/journey_local_datasource.dart';
import 'package:direcao_financeira_mobile/app/data/datasources/journey_route_local_datasource.dart';
import 'package:direcao_financeira_mobile/app/data/datasources/location_tracking_datasource.dart';
import 'package:direcao_financeira_mobile/app/data/models/active_shift_model.dart';
import 'package:direcao_financeira_mobile/app/data/models/journey_statistics_model.dart';
import 'package:direcao_financeira_mobile/app/data/models/location_tracking_status_model.dart';
import 'package:direcao_financeira_mobile/app/data/models/pending_finished_shift_model.dart';
import 'package:direcao_financeira_mobile/app/data/models/shift_model.dart';
import 'package:direcao_financeira_mobile/app/data/models/shift_route_model.dart';
import 'package:direcao_financeira_mobile/app/data/models/tracked_route_point_model.dart';
import 'package:direcao_financeira_mobile/app/data/repositories/journey_repository_impl.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/manual_shift_draft_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/paged_result_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  test(
    'addManualShift mantem turno local quando sincronizacao imediata falha',
    () async {
      final localDataSource = _FakeJourneyLocalDataSource();
      final repository = JourneyRepositoryImpl(
        remoteDataSource: _FailingJourneyRemoteDataSource(),
        localDataSource: localDataSource,
        routeLocalDataSource: _FakeJourneyRouteLocalDataSource(),
        locationTrackingDataSource: _FakeLocationTrackingDataSource(),
        realtimeClient: _FakeRealtimeClient(isOnline: true),
        apiErrorMapper: const ApiErrorMapper(),
        apiRequestLogger: ApiRequestLogger(
          apiErrorMapper: const ApiErrorMapper(),
          enabled: false,
        ),
      );

      final result = await repository.addManualShift(
        ManualShiftDraftEntity(
          totalDrivenKm: 12.5,
          startTime: DateTime(2026, 5, 12, 8),
          endTime: DateTime(2026, 5, 12, 10),
        ),
      );

      expect(result.isRight(), isTrue);
      expect(localDataSource.pendingShifts, hasLength(1));
      expect(localDataSource.pendingShifts.single.totalDrivenKm, 12.5);
      result.fold(
        (_) => fail('Nao deveria falhar quando o turno foi salvo localmente.'),
        (finishResult) => expect(finishResult.pendingSyncCount, 1),
      );
    },
  );
}

class _FailingJourneyRemoteDataSource implements IJourneyDataSource {
  @override
  Future<ActiveShiftModel?> getActiveShift() async => null;

  @override
  Future<JourneyStatisticsModel> getDailyStatistics({
    String filter = 'day',
    String? date,
    String? endDate,
  }) async => throw UnimplementedError();

  @override
  Future<PagedResultEntity<ShiftModel>> getShiftHistory({
    String filter = 'day',
    String? date,
    String? endDate,
    int offset = 0,
    int limit = 20,
  }) async => throw UnimplementedError();

  @override
  Future<int> syncFinishedShift(
    PendingFinishedShiftModel shift,
    ShiftRouteModel? trackedRoute,
  ) async {
    throw ServerFailure('Falha simulada ao sincronizar.');
  }

  @override
  Future<void> deleteShift(int shiftId) async {}

  @override
  Future<ShiftRouteModel> getShiftRoute(int shiftId) async =>
      throw UnimplementedError();
}

class _FakeJourneyLocalDataSource implements IJourneyLocalDataSource {
  final pendingShifts = <PendingFinishedShiftModel>[];

  @override
  Future<ActiveShiftModel?> getActiveShift() async => null;

  @override
  Future<PendingFinishedShiftModel> addManualFinishedShift({
    required double totalDrivenKm,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final shift = PendingFinishedShiftModel(
      localId: 1,
      remoteShiftId: null,
      startTime: startTime,
      endTime: endTime,
      createdAt: DateTime(2026, 5, 12, 10),
      idleTimeSeconds: 0,
      totalDrivenKm: totalDrivenKm,
    );
    pendingShifts.add(shift);
    return shift;
  }

  @override
  Future<List<PendingFinishedShiftModel>> getPendingFinishedShifts() async =>
      pendingShifts;

  @override
  Future<void> removePendingFinishedShift(int localId) async {
    pendingShifts.removeWhere((shift) => shift.localId == localId);
  }

  @override
  Future<void> clearActiveShift() async {}

  @override
  Future<PendingFinishedShiftModel> finishShift({
    required double totalDrivenKm,
  }) async => throw UnimplementedError();

  @override
  Future<ActiveShiftModel> pauseShift() async => throw UnimplementedError();

  @override
  Future<ActiveShiftModel> resumeShift() async => throw UnimplementedError();

  @override
  Future<void> saveActiveShift(ActiveShiftModel shift) async {}

  @override
  Future<ActiveShiftModel> startShift() async => throw UnimplementedError();
}

class _FakeJourneyRouteLocalDataSource implements IJourneyRouteLocalDataSource {
  @override
  Future<ShiftRouteModel?> getRouteByLocalShiftId(
    int localShiftId, {
    bool includePoints = true,
  }) async => null;

  @override
  Future<void> assignRemoteShiftId({
    required int localShiftId,
    required int remoteShiftId,
  }) async {}

  @override
  Future<ShiftRouteModel?> appendPoint({
    required int localShiftId,
    required TrackedRoutePointModel point,
    bool forceRecord = false,
  }) async => null;

  @override
  Future<void> deleteRoute(int localShiftId) async {}

  @override
  Future<void> ensureRoute({
    required int localShiftId,
    required DateTime startedAt,
  }) async {}

  @override
  Future<ShiftRouteModel?> getRouteByRemoteShiftId(
    int remoteShiftId, {
    bool includePoints = true,
  }) async => null;

  @override
  Future<void> markRouteFinished({
    required int localShiftId,
    required DateTime endedAt,
  }) async {}
}

class _FakeLocationTrackingDataSource implements ILocationTrackingDataSource {
  static const _status = LocationTrackingStatusModel(
    isTrackingActive: false,
    isLocationServiceEnabled: true,
    hasForegroundPermission: true,
    hasBackgroundPermission: true,
    isPreciseLocation: true,
    isPaused: false,
    totalDistanceMeters: 0,
    idleTimeSeconds: 0,
  );

  @override
  Future<LocationTrackingStatusModel> ensureReadyForShiftStart() async =>
      _status;

  @override
  Future<LocationTrackingStatusModel> getCurrentStatus({
    int? localShiftId,
    bool isPaused = false,
  }) async => _status;

  @override
  Future<void> pauseTracking() async {}

  @override
  Future<void> resumeTracking({
    required int localShiftId,
    required DateTime startedAt,
  }) async {}

  @override
  Future<void> startTracking({
    required int localShiftId,
    required DateTime startedAt,
  }) async {}

  @override
  Future<void> stopTracking({required DateTime endedAt}) async {}

  @override
  Stream<LocationTrackingStatusModel> watchStatus() => const Stream.empty();
}

class _FakeRealtimeClient implements RealtimeClient {
  _FakeRealtimeClient({required bool isOnline}) : isOnline = isOnline.obs;

  @override
  final RxBool isOnline;

  @override
  void connect({required String token}) {}

  @override
  void disconnect() {}

  @override
  Future<void> dispose() async {}

  @override
  void off(String event, [void Function(dynamic payload)? handler]) {}

  @override
  void on(String event, void Function(dynamic payload) handler) {}
}
