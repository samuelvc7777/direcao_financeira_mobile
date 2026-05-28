import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/detected_ride_draft_entity.dart';
import '../entities/paged_result_entity.dart';
import '../entities/ride_import_entity.dart';
import '../entities/ride_entity.dart';

abstract class IRideRepository {
  Future<Either<Failure, PagedResultEntity<RideEntity>>> getRides({
    String period = 'day',
    String? date,
    String? endDate,
    String? status,
    int offset = 0,
    int limit = 20,
  });

  Future<Either<Failure, PagedResultEntity<RideImportEntity>>>
  getImportableRides({
    String period = 'month',
    String? date,
    String? endDate,
    String? status = 'FINISHED',
    int offset = 0,
    int limit = 100,
  });

  Future<Either<Failure, Unit>> createDetectedRide(
    DetectedRideDraftEntity ride,
  );

  Future<Either<Failure, Unit>> createFinishedRide(
    DetectedRideDraftEntity ride,
  );

  Future<Either<Failure, Unit>> updateFinishedRide({
    required int rideId,
    required DetectedRideDraftEntity ride,
  });

  Future<Either<Failure, Unit>> finishRide({
    required int rideId,
    required String paymentMethod,
  });

  Future<Either<Failure, Unit>> cancelRide({
    required int rideId,
    required String cancelReason,
  });

  Future<Either<Failure, Unit>> deleteRide({required int rideId});
}
