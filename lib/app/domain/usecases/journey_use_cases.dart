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
import '../repositories/i_journey_repository.dart';

class GetActiveShiftUseCase {
  final IJourneyRepository repository;
  GetActiveShiftUseCase(this.repository);

  Future<Either<Failure, ActiveShiftEntity?>> call() async {
    return await repository.getActiveShift();
  }
}

class GetDailyStatisticsUseCase {
  final IJourneyRepository repository;
  GetDailyStatisticsUseCase(this.repository);

  Future<Either<Failure, JourneyStatisticsEntity>> call({
    String filter = 'day',
    String? date,
    String? endDate,
  }) async {
    return await repository.getDailyStatistics(
      filter: filter,
      date: date,
      endDate: endDate,
    );
  }
}

class GetShiftHistoryUseCase {
  final IJourneyRepository repository;
  GetShiftHistoryUseCase(this.repository);

  Future<Either<Failure, PagedResultEntity<ShiftEntity>>> call({
    String filter = 'day',
    String? date,
    String? endDate,
    int offset = 0,
    int limit = 20,
  }) async {
    return await repository.getShiftHistory(
      filter: filter,
      date: date,
      endDate: endDate,
      offset: offset,
      limit: limit,
    );
  }
}

class StartShiftUseCase {
  final IJourneyRepository repository;
  StartShiftUseCase(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.startShift();
  }
}

class FinishShiftUseCase {
  final IJourneyRepository repository;
  FinishShiftUseCase(this.repository);

  Future<Either<Failure, FinishShiftResultEntity>> call() async {
    return await repository.finishShift();
  }
}

class CreateManualShiftUseCase {
  final IJourneyRepository repository;
  CreateManualShiftUseCase(this.repository);

  Future<Either<Failure, FinishShiftResultEntity>> call(
    ManualShiftDraftEntity shift,
  ) async {
    return await repository.addManualShift(shift);
  }
}

class DeleteShiftUseCase {
  final IJourneyRepository repository;
  DeleteShiftUseCase(this.repository);

  Future<Either<Failure, void>> call(ShiftEntity shift) async {
    return await repository.deleteShift(shift);
  }
}

class PauseShiftUseCase {
  final IJourneyRepository repository;
  PauseShiftUseCase(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.pauseShift();
  }
}

class ResumeShiftUseCase {
  final IJourneyRepository repository;
  ResumeShiftUseCase(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.resumeShift();
  }
}

class SyncPendingJourneyUseCase {
  final IJourneyRepository repository;
  SyncPendingJourneyUseCase(this.repository);

  Future<Either<Failure, int>> call() async {
    return await repository.syncPendingShifts();
  }
}

class EnsureReadyForShiftStartUseCase {
  final IJourneyRepository repository;
  EnsureReadyForShiftStartUseCase(this.repository);

  Future<Either<Failure, LocationTrackingStatusEntity>> call() async {
    return await repository.ensureReadyForShiftStart();
  }
}

class GetLocationTrackingStatusUseCase {
  final IJourneyRepository repository;
  GetLocationTrackingStatusUseCase(this.repository);

  Future<Either<Failure, LocationTrackingStatusEntity>> call() async {
    return await repository.getLocationTrackingStatus();
  }
}

class WatchLocationTrackingStatusUseCase {
  final IJourneyRepository repository;
  WatchLocationTrackingStatusUseCase(this.repository);

  Stream<LocationTrackingStatusEntity> call() {
    return repository.watchLocationTrackingStatus();
  }
}

class GetShiftRouteUseCase {
  final IJourneyRepository repository;
  GetShiftRouteUseCase(this.repository);

  Future<Either<Failure, ShiftRouteEntity>> call({
    int? localShiftId,
    int? remoteShiftId,
  }) async {
    return await repository.getShiftRoute(
      localShiftId: localShiftId,
      remoteShiftId: remoteShiftId,
    );
  }
}
