class ActiveShiftEntity {
  final int id;
  final int? remoteShiftId;
  final DateTime startTime;
  final DateTime createdAt;
  final double currentDrivenKm;
  final int idleTimeSeconds;
  final DateTime? pausedAt;
  final DateTime? lowSpeedSince;
  final DateTime? lastMotionIdleCheckpointAt;

  const ActiveShiftEntity({
    required this.id,
    this.remoteShiftId,
    required this.startTime,
    required this.createdAt,
    required this.currentDrivenKm,
    required this.idleTimeSeconds,
    this.pausedAt,
    this.lowSpeedSince,
    this.lastMotionIdleCheckpointAt,
  });

  bool get isPaused => pausedAt != null;
  bool get isLocalOnly => remoteShiftId == null;

  ActiveShiftEntity copyWith({
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
    return ActiveShiftEntity(
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
}
