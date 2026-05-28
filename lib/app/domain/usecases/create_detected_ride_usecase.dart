import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/detected_ride_draft_entity.dart';
import '../repositories/i_ride_repository.dart';

class CreateDetectedRideUseCase {
  CreateDetectedRideUseCase(this.repository);

  final IRideRepository repository;

  Future<Either<Failure, Unit>> call(DetectedRideDraftEntity ride) {
    return repository.createDetectedRide(ride);
  }
}

class CreateFinishedRideUseCase {
  CreateFinishedRideUseCase(this.repository);

  final IRideRepository repository;

  Future<Either<Failure, Unit>> call(DetectedRideDraftEntity ride) {
    return repository.createFinishedRide(ride);
  }
}

class UpdateFinishedRideUseCase {
  UpdateFinishedRideUseCase(this.repository);

  final IRideRepository repository;

  Future<Either<Failure, Unit>> call({
    required int rideId,
    required DetectedRideDraftEntity ride,
  }) {
    return repository.updateFinishedRide(rideId: rideId, ride: ride);
  }
}
