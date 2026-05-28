import 'package:dartz/dartz.dart';
import 'package:direcao_financeira_mobile/app/core/errors/failures.dart';
import 'package:direcao_financeira_mobile/app/data/datasources/recording_local_datasource.dart';
import 'package:direcao_financeira_mobile/app/data/datasources/recording_native_datasource.dart';
import 'package:direcao_financeira_mobile/app/data/models/recording_model.dart';
import 'package:direcao_financeira_mobile/app/data/repositories/recording_repository_impl.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/recording_entity.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRecordingLocalDataSource implements IRecordingLocalDataSource {
  final recordings = <RecordingModel>[];
  final deletedIds = <String>[];

  @override
  Future<void> deleteRecording(String id) async {
    deletedIds.add(id);
    recordings.removeWhere((recording) => recording.id == id);
  }

  @override
  Future<RecordingModel?> getActiveRecording() async {
    for (final recording in recordings) {
      if (recording.isActive) {
        return recording;
      }
    }
    return null;
  }

  @override
  Future<RecordingModel?> getRecordingById(String id) async {
    for (final recording in recordings) {
      if (recording.id == id) {
        return recording;
      }
    }
    return null;
  }

  @override
  Future<List<RecordingModel>> getRecordings() async => recordings;

  @override
  Future<void> upsertRecording(RecordingModel recording) async {
    final index = recordings.indexWhere((item) => item.id == recording.id);
    if (index >= 0) {
      recordings[index] = recording;
    } else {
      recordings.add(recording);
    }
  }
}

class _FakeRecordingNativeDataSource implements IRecordingNativeDataSource {
  bool permissionGranted = true;
  bool recording = false;
  String? openedFilePath;

  @override
  Future<bool> isRecording() async => recording;

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openRecording(String filePath) async {
    openedFilePath = filePath;
  }

  @override
  Future<bool> requestPermissions() async => permissionGranted;

  @override
  Future<Map<String, dynamic>> startRecording({
    Map<String, dynamic>? settings,
  }) async {
    recording = true;
    return {
      'id': 'native-1',
      'status': RecordingStatus.recording,
      'filePath': '/tmp/native-1.mp4',
      'startedAt': DateTime(2026, 5, 18, 8).toUtc().toIso8601String(),
    };
  }

  @override
  Future<Map<String, dynamic>?> stopRecording() async {
    recording = false;
    return {
      'status': RecordingStatus.completed,
      'finishedAt': DateTime(2026, 5, 18, 8, 1).toUtc().toIso8601String(),
      'durationSeconds': 60,
      'fileSizeBytes': 1024,
    };
  }
}

void main() {
  late _FakeRecordingLocalDataSource localDataSource;
  late _FakeRecordingNativeDataSource nativeDataSource;
  late RecordingRepositoryImpl repository;

  setUp(() {
    localDataSource = _FakeRecordingLocalDataSource();
    nativeDataSource = _FakeRecordingNativeDataSource();
    repository = RecordingRepositoryImpl(
      localDataSource: localDataSource,
      nativeDataSource: nativeDataSource,
    );
  });

  test(
    'startRecording retorna ValidationFailure quando permissao falta',
    () async {
      nativeDataSource.permissionGranted = false;

      final result = await repository.startRecording();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Nao deveria iniciar sem permissao.'),
      );
    },
  );

  test(
    'startRecording salva ativo local e stopRecording conclui metadados',
    () async {
      final started = await repository.startRecording();
      final active = await repository.getActiveRecording();

      expect(started.isRight(), isTrue);
      expect(active.getOrElse(() => null)?.isActive, isTrue);

      final stopped = await repository.stopRecording();

      expect(stopped.isRight(), isTrue);
      final recording = stopped.getOrElse(() => null);
      expect(recording?.status, RecordingStatus.completed);
      expect(recording?.durationSeconds, 60);
      expect(recording?.fileSizeBytes, 1024);
    },
  );

  test('getRecordings filtra por periodo e status', () async {
    localDataSource.recordings.addAll([
      RecordingModel(
        id: '1',
        status: RecordingStatus.completed,
        filePath: '/tmp/1.mp4',
        startedAt: DateTime(2026, 5, 18, 10),
      ),
      RecordingModel(
        id: '2',
        status: RecordingStatus.failed,
        filePath: '/tmp/2.mp4',
        startedAt: DateTime(2026, 5, 17, 10),
      ),
    ]);

    final result = await repository.getRecordings(
      period: 'day',
      date: DateTime(2026, 5, 18).toIso8601String(),
      status: RecordingStatus.completed,
    );

    final page = result.getOrElse(
      () => fail('Listagem deveria retornar sucesso.'),
    );
    expect(page.items, hasLength(1));
    expect(page.items.single.id, '1');
  });

  test(
    'deleteRecording para nativo quando item ativo e remove local',
    () async {
      localDataSource.recordings.add(
        RecordingModel(
          id: '1',
          status: RecordingStatus.recording,
          filePath: '/tmp/1.mp4',
          startedAt: DateTime(2026, 5, 18, 10),
        ),
      );
      nativeDataSource.recording = true;

      final result = await repository.deleteRecording('1');

      expect(result, const Right(unit));
      expect(nativeDataSource.recording, isFalse);
      expect(localDataSource.deletedIds, ['1']);
    },
  );

  test('openRecording delega abertura ao datasource nativo', () async {
    final recording = RecordingEntity(
      id: '1',
      status: RecordingStatus.completed,
      filePath: '/tmp/1.mp4',
      startedAt: DateTime(2026, 5, 18, 10),
    );

    final result = await repository.openRecording(recording);

    expect(result, const Right(unit));
    expect(nativeDataSource.openedFilePath, '/tmp/1.mp4');
  });
}
