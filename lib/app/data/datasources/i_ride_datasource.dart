import '../../domain/entities/detected_ride_draft_entity.dart';
import '../../domain/entities/paged_result_entity.dart';
import '../models/ride_model.dart';

abstract class IRideDataSource {
  Future<PagedResultEntity<RideModel>> getRides({
    String period = 'day',
    String? date,
    String? endDate,
    String? status,
    int offset = 0,
    int limit = 20,
  });

  Future<void> createDetectedRide(DetectedRideDraftEntity ride);

  Future<void> createRideWithStatus({
    required DetectedRideDraftEntity ride,
    required String status,
    String? paymentMethod,
    String? cancelReason,
  });

  Future<void> updateFinishedRide({
    required int rideId,
    required DetectedRideDraftEntity ride,
  });

  Future<void> finishRide({required int rideId, required String paymentMethod});

  Future<void> cancelRide({required int rideId, required String cancelReason});

  Future<void> deleteRide({required int rideId});
}
