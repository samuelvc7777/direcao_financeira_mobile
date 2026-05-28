import '../../domain/entities/recording_entity.dart';

class RecordingModel extends RecordingEntity {
  const RecordingModel({
    required super.id,
    required super.status,
    required super.filePath,
    required super.startedAt,
    super.finishedAt,
    super.durationSeconds,
    super.fileSizeBytes,
    super.errorMessage,
  });

  factory RecordingModel.fromEntity(RecordingEntity entity) {
    return RecordingModel(
      id: entity.id,
      status: entity.status,
      filePath: entity.filePath,
      startedAt: entity.startedAt,
      finishedAt: entity.finishedAt,
      durationSeconds: entity.durationSeconds,
      fileSizeBytes: entity.fileSizeBytes,
      errorMessage: entity.errorMessage,
    );
  }

  factory RecordingModel.fromJson(Map<String, dynamic> json) {
    return RecordingModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? RecordingStatus.completed,
      filePath: json['filePath']?.toString() ?? '',
      startedAt:
          DateTime.tryParse(json['startedAt']?.toString() ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      finishedAt: DateTime.tryParse(
        json['finishedAt']?.toString() ?? '',
      )?.toLocal(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  factory RecordingModel.fromNativeStart(Map<String, dynamic> json) {
    final now = DateTime.now();
    return RecordingModel(
      id: json['id']?.toString() ?? now.microsecondsSinceEpoch.toString(),
      status: RecordingStatus.recording,
      filePath: json['filePath']?.toString() ?? '',
      startedAt:
          DateTime.tryParse(json['startedAt']?.toString() ?? '')?.toLocal() ??
          now,
    );
  }

  RecordingModel mergeNativeStop(Map<String, dynamic> json) {
    final finished = DateTime.tryParse(
      json['finishedAt']?.toString() ?? '',
    )?.toLocal();

    return RecordingModel(
      id: id,
      status: json['status']?.toString() ?? RecordingStatus.completed,
      filePath: json['filePath']?.toString().isNotEmpty == true
          ? json['filePath'].toString()
          : filePath,
      startedAt: startedAt,
      finishedAt: finished ?? DateTime.now(),
      durationSeconds:
          (json['durationSeconds'] as num?)?.toInt() ??
          DateTime.now().difference(startedAt).inSeconds,
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? fileSizeBytes,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'filePath': filePath,
      'startedAt': startedAt.toUtc().toIso8601String(),
      'finishedAt': finishedAt?.toUtc().toIso8601String(),
      'durationSeconds': durationSeconds,
      'fileSizeBytes': fileSizeBytes,
      'errorMessage': errorMessage,
    };
  }
}
