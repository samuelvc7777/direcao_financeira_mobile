import 'tracked_route_point_entity.dart';

class ShiftRouteEntity {
  final int? localShiftId;
  final int? remoteShiftId;
  final DateTime startedAt;
  final DateTime endedAt;
  final double totalDistanceMeters;
  final int pointCount;
  final bool isFinished;
  final List<TrackedRoutePointEntity> points;

  const ShiftRouteEntity({
    required this.localShiftId,
    required this.remoteShiftId,
    required this.startedAt,
    required this.endedAt,
    required this.totalDistanceMeters,
    required this.pointCount,
    required this.isFinished,
    required this.points,
  });

  double get totalDistanceKm => totalDistanceMeters / 1000;
  bool get hasPoints => points.isNotEmpty;
}
