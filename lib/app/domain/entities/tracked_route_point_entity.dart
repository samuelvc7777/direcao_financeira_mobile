class TrackedRoutePointEntity {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime recordedAt;

  const TrackedRoutePointEntity({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.recordedAt,
  });
}
