import '../../domain/entities/active_shift_entity.dart';
import '../shared/journey_datetime_parser.dart';

class ActiveShiftModel extends ActiveShiftEntity {
  const ActiveShiftModel({
    required super.id,
    super.remoteShiftId,
    required super.startTime,
    required super.createdAt,
    required super.currentDrivenKm,
    required super.idleTimeSeconds,
    super.pausedAt,
    super.lowSpeedSince,
    super.lastMotionIdleCheckpointAt,
  });

  @override
  ActiveShiftModel copyWith({
    int? id,
    int? remoteShiftId,
    DateTime? startTime,
    DateTime? createdAt,
    double? currentDrivenKm,
    int? idleTimeSeconds,
    DateTime? pausedAt,
    DateTime? lowSpeedSince,
    DateTime? lastMotionIdleCheckpointAt,
    bool clearPausedAt = false,
    bool clearLowSpeedSince = false,
    bool clearLastMotionIdleCheckpointAt = false,
  }) {
    return ActiveShiftModel(
      id: id ?? this.id,
      remoteShiftId: remoteShiftId ?? this.remoteShiftId,
      startTime: startTime ?? this.startTime,
      createdAt: createdAt ?? this.createdAt,
      currentDrivenKm: currentDrivenKm ?? this.currentDrivenKm,
      idleTimeSeconds: idleTimeSeconds ?? this.idleTimeSeconds,
      pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
      lowSpeedSince: clearLowSpeedSince
          ? null
          : (lowSpeedSince ?? this.lowSpeedSince),
      lastMotionIdleCheckpointAt: clearLastMotionIdleCheckpointAt
          ? null
          : (lastMotionIdleCheckpointAt ?? this.lastMotionIdleCheckpointAt),
    );
  }

  factory ActiveShiftModel.fromJson(Map<String, dynamic> json) {
    return ActiveShiftModel(
      id: json['id'] as int,
      remoteShiftId: json['remoteShiftId'] as int?,
      startTime: parseJourneyDateTimeToLocal(json['startTime'] as String),
      createdAt: parseJourneyDateTimeToLocal(json['createdAt'] as String),
      currentDrivenKm: (json['currentDrivenKm'] as num?)?.toDouble() ?? 0.0,
      idleTimeSeconds: json['idleTime'] as int? ?? 0,
      pausedAt: json['pausedAt'] != null
          ? parseJourneyDateTimeToLocal(json['pausedAt'] as String)
          : null,
      lowSpeedSince: json['lowSpeedSince'] != null
          ? parseJourneyDateTimeToLocal(json['lowSpeedSince'] as String)
          : null,
      lastMotionIdleCheckpointAt: json['lastMotionIdleCheckpointAt'] != null
          ? parseJourneyDateTimeToLocal(
              json['lastMotionIdleCheckpointAt'] as String,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'remoteShiftId': remoteShiftId,
      'startTime': startTime.toUtc().toIso8601String(),
      'createdAt': createdAt.toUtc().toIso8601String(),
      'currentDrivenKm': currentDrivenKm,
      'idleTime': idleTimeSeconds,
      'pausedAt': pausedAt?.toUtc().toIso8601String(),
      'lowSpeedSince': lowSpeedSince?.toUtc().toIso8601String(),
      'lastMotionIdleCheckpointAt': lastMotionIdleCheckpointAt
          ?.toUtc()
          .toIso8601String(),
    };
  }
}
