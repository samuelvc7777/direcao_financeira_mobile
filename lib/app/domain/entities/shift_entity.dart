class ShiftEntity {
  final int index;
  final int? localId;
  final int? remoteShiftId;
  final String date;
  final String startTime;
  final String endTime;
  final String duration;
  final String? drivenKm;
  final bool isPendingSync;
  final bool hasRoute;
  final double trackedDistanceKm;
  final int routePointCount;

  const ShiftEntity({
    required this.index,
    this.localId,
    this.remoteShiftId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.duration,
    this.drivenKm,
    this.isPendingSync = false,
    this.hasRoute = false,
    this.trackedDistanceKm = 0,
    this.routePointCount = 0,
  });
}
