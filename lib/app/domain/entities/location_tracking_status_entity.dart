class LocationTrackingStatusEntity {
  final bool isTrackingActive;
  final bool isLocationServiceEnabled;
  final bool hasForegroundPermission;
  final bool hasBackgroundPermission;
  final bool isPreciseLocation;
  final bool isPaused;
  final double totalDistanceMeters;
  final int idleTimeSeconds;
  final String? issueMessage;

  const LocationTrackingStatusEntity({
    required this.isTrackingActive,
    required this.isLocationServiceEnabled,
    required this.hasForegroundPermission,
    required this.hasBackgroundPermission,
    required this.isPreciseLocation,
    required this.isPaused,
    required this.totalDistanceMeters,
    required this.idleTimeSeconds,
    this.issueMessage,
  });

  bool get canTrackFully =>
      isLocationServiceEnabled &&
      hasForegroundPermission &&
      hasBackgroundPermission &&
      isPreciseLocation;
}
