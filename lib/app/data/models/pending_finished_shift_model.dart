import '../../domain/entities/shift_entity.dart';
import '../../domain/entities/shift_route_entity.dart';
import '../shared/journey_datetime_parser.dart';
import 'shift_model.dart';

class PendingFinishedShiftModel {
  static const maxDatabaseInt = 2147483647;
  final int localId;
  final int? remoteShiftId;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime createdAt;
  final int idleTimeSeconds;
  final double totalDrivenKm;

  const PendingFinishedShiftModel({
    required this.localId,
    required this.remoteShiftId,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
    required this.idleTimeSeconds,
    required this.totalDrivenKm,
  });

  factory PendingFinishedShiftModel.fromJson(Map<String, dynamic> json) {
    final parsedRemoteShiftId = json['remoteShiftId'] as int?;

    return PendingFinishedShiftModel(
      localId: json['localId'] as int,
      remoteShiftId:
          parsedRemoteShiftId != null && parsedRemoteShiftId <= maxDatabaseInt
          ? parsedRemoteShiftId
          : null,
      startTime: parseJourneyDateTimeToLocal(json['startTime'] as String),
      endTime: parseJourneyDateTimeToLocal(json['endTime'] as String),
      createdAt: parseJourneyDateTimeToLocal(json['createdAt'] as String),
      idleTimeSeconds: json['idleTimeSeconds'] as int? ?? 0,
      totalDrivenKm: (json['totalDrivenKm'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'localId': localId,
      'remoteShiftId': remoteShiftId,
      'startTime': startTime.toUtc().toIso8601String(),
      'endTime': endTime.toUtc().toIso8601String(),
      'createdAt': createdAt.toUtc().toIso8601String(),
      'idleTimeSeconds': idleTimeSeconds,
      'totalDrivenKm': totalDrivenKm,
    };
  }

  ShiftEntity toShiftEntity({required int index, ShiftRouteEntity? route}) {
    String two(int value) => value.toString().padLeft(2, '0');

    String formatDate(DateTime value) =>
        '${two(value.day)}/${two(value.month)}/${value.year}';
    String formatTime(DateTime value) =>
        '${two(value.hour)}:${two(value.minute)}';
    final totalSeconds = endTime.difference(startTime).inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final duration = '${two(hours)}:${two(minutes)}:${two(seconds)}';

    return ShiftModel(
      index: index,
      localId: localId,
      remoteShiftId: remoteShiftId,
      date: formatDate(startTime),
      startTime: formatTime(startTime),
      endTime: formatTime(endTime),
      duration: duration,
      drivenKm: totalDrivenKm > 0 ? totalDrivenKm.toStringAsFixed(1) : null,
      isPendingSync: true,
      hasRoute: route != null && route.pointCount > 0,
      trackedDistanceKm: route?.totalDistanceKm ?? 0,
      routePointCount: route?.pointCount ?? 0,
    );
  }
}
