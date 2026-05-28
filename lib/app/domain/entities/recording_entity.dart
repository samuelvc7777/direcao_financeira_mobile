class RecordingEntity {
  const RecordingEntity({
    required this.id,
    required this.status,
    required this.filePath,
    required this.startedAt,
    this.finishedAt,
    this.durationSeconds = 0,
    this.fileSizeBytes = 0,
    this.errorMessage,
  });

  final String id;
  final String status;
  final String filePath;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int durationSeconds;
  final int fileSizeBytes;
  final String? errorMessage;

  bool get isActive => status.toUpperCase() == RecordingStatus.recording;

  RecordingEntity copyWith({
    String? id,
    String? status,
    String? filePath,
    DateTime? startedAt,
    DateTime? finishedAt,
    int? durationSeconds,
    int? fileSizeBytes,
    String? errorMessage,
  }) {
    return RecordingEntity(
      id: id ?? this.id,
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

abstract final class RecordingStatus {
  static const recording = 'RECORDING';
  static const completed = 'COMPLETED';
  static const failed = 'FAILED';
}
