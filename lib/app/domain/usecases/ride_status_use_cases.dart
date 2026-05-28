import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../repositories/i_ride_repository.dart';

class FinishRideUseCase {
  FinishRideUseCase(this.repository);

  final IRideRepository repository;

  Future<Either<Failure, Unit>> call({
    required int rideId,
    required String paymentMethod,
  }) {
    return repository.finishRide(rideId: rideId, paymentMethod: paymentMethod);
  }
}

class CancelRideUseCase {
  CancelRideUseCase(this.repository);

  final IRideRepository repository;

  Future<Either<Failure, Unit>> call({
    required int rideId,
    required String cancelReason,
  }) {
    return repository.cancelRide(rideId: rideId, cancelReason: cancelReason);
  }
}

class DeleteRideUseCase {
  DeleteRideUseCase(this.repository);

  final IRideRepository repository;

  Future<Either<Failure, Unit>> call({required int rideId}) {
    return repository.deleteRide(rideId: rideId);
  }
}
