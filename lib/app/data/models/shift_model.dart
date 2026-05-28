import '../../domain/entities/shift_entity.dart';

class ShiftModel extends ShiftEntity {
  const ShiftModel({
    required super.index,
    super.localId,
    super.remoteShiftId,
    required super.date,
    required super.startTime,
    required super.endTime,
    required super.duration,
    super.drivenKm,
    super.isPendingSync,
    super.hasRoute,
    super.trackedDistanceKm,
    super.routePointCount,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      index: json['index'] as int,
      localId: json['localId'] as int?,
      remoteShiftId: json['remoteShiftId'] as int?,
      date: json['date'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      duration: json['duration'] as String,
      drivenKm: json['drivenKm'] as String?,
      isPendingSync: json['isPendingSync'] as bool? ?? false,
      hasRoute: json['hasRoute'] as bool? ?? false,
      trackedDistanceKm:
          (json['trackedDistanceKm'] as num?)?.toDouble() ?? 0,
      routePointCount: json['routePointCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'localId': localId,
      'remoteShiftId': remoteShiftId,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'duration': duration,
      if (drivenKm != null) 'drivenKm': drivenKm,
      'isPendingSync': isPendingSync,
      'hasRoute': hasRoute,
      'trackedDistanceKm': trackedDistanceKm,
      'routePointCount': routePointCount,
    };
  }
}
