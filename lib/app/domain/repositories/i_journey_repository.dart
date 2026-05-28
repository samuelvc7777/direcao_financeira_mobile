import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/active_shift_entity.dart';
import '../entities/finish_shift_result_entity.dart';
import '../entities/journey_statistics_entity.dart';
import '../entities/location_tracking_status_entity.dart';
import '../entities/manual_shift_draft_entity.dart';
import '../entities/paged_result_entity.dart';
import '../entities/shift_route_entity.dart';
import '../entities/shift_entity.dart';

abstract class IJourneyRepository {
  Future<Either<Failure, ActiveShiftEntity?>> getActiveShift();
  Future<Either<Failure, JourneyStatisticsEntity>> getDailyStatistics({
    String filter = 'day',
    String? date,
    String? endDate,
  });
  Future<Either<Failure, PagedResultEntity<ShiftEntity>>> getShiftHistory({
    String filter = 'day',
    String? date,
    String? endDate,
    int offset = 0,
    int limit = 20,
  });
  Future<Either<Failure, void>> startShift();
  Future<Either<Failure, void>> pauseShift();
  Future<Either<Failure, void>> resumeShift();
  Future<Either<Failure, FinishShiftResultEntity>> finishShift();
  Future<Either<Failure, FinishShiftResultEntity>> addManualShift(
    ManualShiftDraftEntity shift,
  );
  Future<Either<Failure, void>> deleteShift(ShiftEntity shift);
  Future<Either<Failure, int>> syncPendingShifts();
  Future<Either<Failure, LocationTrackingStatusEntity>>
  ensureReadyForShiftStart();
  Future<Either<Failure, LocationTrackingStatusEntity>>
  getLocationTrackingStatus();
  Stream<LocationTrackingStatusEntity> watchLocationTrackingStatus();
  Future<Either<Failure, ShiftRouteEntity>> getShiftRoute({
    int? localShiftId,
    int? remoteShiftId,
  });
}
