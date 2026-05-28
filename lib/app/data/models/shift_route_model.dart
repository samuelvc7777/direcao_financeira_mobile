import '../../domain/entities/shift_route_entity.dart';
import '../shared/journey_datetime_parser.dart';
import 'tracked_route_point_model.dart';

class ShiftRouteModel extends ShiftRouteEntity {
  const ShiftRouteModel({
    required super.localShiftId,
    required super.remoteShiftId,
    required super.startedAt,
    required super.endedAt,
    required super.totalDistanceMeters,
    required super.pointCount,
    required super.isFinished,
    required super.points,
  });

  factory ShiftRouteModel.fromRemoteJson(Map<String, dynamic> json) {
    final rawPoints = json['points'];
    final points = rawPoints is List
        ? rawPoints
              .whereType<Map>()
              .map(
                (item) => TrackedRoutePointModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <TrackedRoutePointModel>[];

    return ShiftRouteModel(
      localShiftId: json['localShiftId'] as int?,
      remoteShiftId: json['shiftId'] as int? ?? json['remoteShiftId'] as int?,
      startedAt: parseJourneyDateTimeToLocal(json['startedAt'] as String),
      endedAt: parseJourneyDateTimeToLocal(json['endedAt'] as String),
      totalDistanceMeters:
          (json['totalDistanceMeters'] as num?)?.toDouble() ?? 0,
      pointCount: json['pointCount'] as int? ?? points.length,
      isFinished: true,
      points: points,
    );
  }

  factory ShiftRouteModel.fromDb({
    required Map<String, Object?> routeRow,
    required List<TrackedRoutePointModel> points,
  }) {
    return ShiftRouteModel(
      localShiftId: routeRow['local_shift_id'] as int?,
      remoteShiftId: routeRow['remote_shift_id'] as int?,
      startedAt: parseJourneyDateTimeToLocal(routeRow['started_at'] as String),
      endedAt: parseJourneyDateTimeToLocal(routeRow['ended_at'] as String),
      totalDistanceMeters:
          (routeRow['total_distance_meters'] as num?)?.toDouble() ?? 0,
      pointCount: routeRow['point_count'] as int? ?? points.length,
      isFinished: (routeRow['is_finished'] as int? ?? 0) == 1,
      points: points,
    );
  }

  Map<String, Object?> toRouteDb() {
    return {
      'local_shift_id': localShiftId,
      'remote_shift_id': remoteShiftId,
      'started_at': startedAt.toUtc().toIso8601String(),
      'ended_at': endedAt.toUtc().toIso8601String(),
      'total_distance_meters': totalDistanceMeters,
      'point_count': pointCount,
      'is_finished': isFinished ? 1 : 0,
    };
  }
}
