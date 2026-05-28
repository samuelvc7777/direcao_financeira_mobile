import 'dart:io';

import 'package:get_storage/get_storage.dart';

import '../models/recording_model.dart';

abstract class IRecordingLocalDataSource {
  Future<List<RecordingModel>> getRecordings();

  Future<RecordingModel?> getRecordingById(String id);

  Future<RecordingModel?> getActiveRecording();

  Future<void> upsertRecording(RecordingModel recording);

  Future<void> deleteRecording(String id);
}

class RecordingLocalDataSourceImpl implements IRecordingLocalDataSource {
  RecordingLocalDataSourceImpl({required this.storage});

  final GetStorage storage;

  static const _recordingsKey = 'journey_recordings';

  @override
  Future<List<RecordingModel>> getRecordings() async {
    final raw = storage.read(_recordingsKey);
    if (raw is! List) {
      return [];
    }

    return raw
        .whereType<Map>()
        .map(
          (entry) => RecordingModel.fromJson(Map<String, dynamic>.from(entry)),
        )
        .where((recording) => recording.id.isNotEmpty)
        .toList();
  }

  @override
  Future<RecordingModel?> getRecordingById(String id) async {
    final recordings = await getRecordings();
    for (final recording in recordings) {
      if (recording.id == id) {
        return recording;
      }
    }
    return null;
  }

  @override
  Future<RecordingModel?> getActiveRecording() async {
    final recordings = await getRecordings();
    for (final recording in recordings) {
      if (recording.isActive) {
        return recording;
      }
    }
    return null;
  }

  @override
  Future<void> upsertRecording(RecordingModel recording) async {
    final recordings = await getRecordings();
    final index = recordings.indexWhere((item) => item.id == recording.id);
    if (index >= 0) {
      recordings[index] = recording;
    } else {
      recordings.add(recording);
    }
    recordings.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    await storage.write(
      _recordingsKey,
      recordings.map((recording) => recording.toJson()).toList(),
    );
  }

  @override
  Future<void> deleteRecording(String id) async {
    final recordings = await getRecordings();
    RecordingModel? recording;
    for (final item in recordings) {
      if (item.id == id) {
        recording = item;
        break;
      }
    }
    final updated = recordings.where((item) => item.id != id).toList();
    await storage.write(
      _recordingsKey,
      updated.map((recording) => recording.toJson()).toList(),
    );

    final filePath = recording?.filePath;
    if (filePath != null && filePath.isNotEmpty) {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
