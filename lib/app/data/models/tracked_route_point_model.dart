import '../../domain/entities/tracked_route_point_entity.dart';
import '../shared/journey_datetime_parser.dart';

class TrackedRoutePointModel extends TrackedRoutePointEntity {
  const TrackedRoutePointModel({
    required super.latitude,
    required super.longitude,
    required super.accuracyMeters,
    required super.recordedAt,
  });

  factory TrackedRoutePointModel.fromJson(Map<String, dynamic> json) {
    return TrackedRoutePointModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracyMeters: (json['accuracyMeters'] as num).toDouble(),
      recordedAt: parseJourneyDateTimeToLocal(json['recordedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracyMeters': accuracyMeters,
      'recordedAt': recordedAt.toUtc().toIso8601String(),
    };
  }

  factory TrackedRoutePointModel.fromDb(Map<String, Object?> row) {
    return TrackedRoutePointModel(
      latitude: (row['latitude'] as num).toDouble(),
      longitude: (row['longitude'] as num).toDouble(),
      accuracyMeters: (row['accuracy_meters'] as num).toDouble(),
      recordedAt: parseJourneyDateTimeToLocal(row['recorded_at'] as String),
    );
  }

  Map<String, Object?> toDb(int localShiftId) {
    return {
      'local_shift_id': localShiftId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy_meters': accuracyMeters,
      'recorded_at': recordedAt.toUtc().toIso8601String(),
    };
  }
}
