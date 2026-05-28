import '../../domain/entities/location_tracking_status_entity.dart';

class LocationTrackingStatusModel extends LocationTrackingStatusEntity {
  const LocationTrackingStatusModel({
    required super.isTrackingActive,
    required super.isLocationServiceEnabled,
    required super.hasForegroundPermission,
    required super.hasBackgroundPermission,
    required super.isPreciseLocation,
    required super.isPaused,
    required super.totalDistanceMeters,
    required super.idleTimeSeconds,
    super.issueMessage,
  });

  factory LocationTrackingStatusModel.fromServiceEvent(
    Map<String, dynamic> json,
  ) {
    return LocationTrackingStatusModel(
      isTrackingActive: json['isTrackingActive'] == true,
      isLocationServiceEnabled: json['isLocationServiceEnabled'] == true,
      hasForegroundPermission: json['hasForegroundPermission'] == true,
      hasBackgroundPermission: json['hasBackgroundPermission'] == true,
      isPreciseLocation: json['isPreciseLocation'] == true,
      isPaused: json['isPaused'] == true,
      totalDistanceMeters:
          (json['totalDistanceMeters'] as num?)?.toDouble() ?? 0,
      idleTimeSeconds: json['idleTimeSeconds'] as int? ?? 0,
      issueMessage: json['issueMessage'] as String?,
    );
  }
}
