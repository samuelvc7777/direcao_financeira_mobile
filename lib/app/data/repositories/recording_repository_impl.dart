import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/preferences/app_preferences.dart';
import '../../core/recording/recording_settings.dart';
import '../../domain/entities/paged_result_entity.dart';
import '../../domain/entities/recording_entity.dart';
import '../../domain/repositories/i_recording_repository.dart';
import '../datasources/recording_local_datasource.dart';
import '../datasources/recording_native_datasource.dart';
import '../models/recording_model.dart';

class RecordingRepositoryImpl implements IRecordingRepository {
  RecordingRepositoryImpl({
    required this.localDataSource,
    required this.nativeDataSource,
    this.preferences,
  });

  final IRecordingLocalDataSource localDataSource;
  final IRecordingNativeDataSource nativeDataSource;
  final AppPreferences? preferences;

  @override
  Future<Either<Failure, PagedResultEntity<RecordingEntity>>> getRecordings({
    String period = 'day',
    String? date,
    String? endDate,
    String? status,
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final range = _resolveTimeRange(
        period: period,
        date: date,
        endDate: endDate,
      );
      final normalizedStatus = status?.trim().toUpperCase();
      final all = await localDataSource.getRecordings();
      final filtered = all.where((recording) {
        final startedAt = recording.startedAt;
        final matchesPeriod =
            !startedAt.isBefore(range.start) &&
            startedAt.isBefore(range.endExclusive);
        final matchesStatus =
            normalizedStatus == null ||
            normalizedStatus.isEmpty ||
            recording.status.toUpperCase() == normalizedStatus;
        return matchesPeriod && matchesStatus;
      }).toList()..sort((a, b) => b.startedAt.compareTo(a.startedAt));

      final start = offset.clamp(0, filtered.length);
      final end = (offset + limit).clamp(0, filtered.length);
      return Right(
        PagedResultEntity(
          items: filtered.sublist(start, end),
          totalCount: filtered.length,
          offset: offset,
          limit: limit,
        ),
      );
    } catch (e) {
      return Left(DatabaseFailure('Erro ao buscar gravacoes: $e'));
    }
  }

  @override
  Future<Either<Failure, RecordingEntity?>> getActiveRecording() async {
    try {
      final localActive = await localDataSource.getActiveRecording();
      final nativeActive = await nativeDataSource.isRecording();
      if (nativeActive) {
        return Right(localActive);
      }

      if (localActive != null) {
        final finished = RecordingModel.fromEntity(
          localActive,
        ).mergeNativeStop(const {'status': RecordingStatus.completed});
        await localDataSource.upsertRecording(finished);
      }

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Erro ao consultar gravacao ativa: $e'));
    }
  }

  @override
  Future<Either<Failure, RecordingEntity>> startRecording() async {
    try {
      final permissionGranted = await nativeDataSource.requestPermissions();
      if (!permissionGranted) {
        return Left(
          ValidationFailure(
            'Permita camera, microfone e notificacoes para iniciar a gravacao.',
          ),
        );
      }

      final active = await localDataSource.getActiveRecording();
      if (active != null && await nativeDataSource.isRecording()) {
        return Right(active);
      }

      final payload = await nativeDataSource.startRecording(
        settings: _resolveSettings().toNativeArguments(),
      );
      final recording = RecordingModel.fromNativeStart(payload);
      await localDataSource.upsertRecording(recording);
      return Right(recording);
    } catch (e) {
      return Left(ServerFailure('Erro ao iniciar gravacao: $e'));
    }
  }

  RecordingSettingsSnapshot _resolveSettings() {
    final currentPreferences = preferences;
    if (currentPreferences == null) {
      return RecordingSettingsSnapshot.defaults();
    }

    return RecordingSettingsSnapshot.fromPreferences(currentPreferences);
  }

  @override
  Future<Either<Failure, RecordingEntity?>> stopRecording() async {
    try {
      final active = await localDataSource.getActiveRecording();
      final payload = await nativeDataSource.stopRecording();
      if (active == null) {
        return const Right(null);
      }

      final finished = RecordingModel.fromEntity(
        active,
      ).mergeNativeStop(payload ?? const {'status': RecordingStatus.completed});
      await localDataSource.upsertRecording(finished);
      return Right(finished);
    } catch (e) {
      return Left(ServerFailure('Erro ao parar gravacao: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteRecording(String id) async {
    try {
      final active = await localDataSource.getActiveRecording();
      if (active?.id == id) {
        await nativeDataSource.stopRecording();
      }
      await localDataSource.deleteRecording(id);
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Erro ao excluir gravacao: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> openRecording(RecordingEntity recording) async {
    try {
      if (recording.filePath.trim().isEmpty) {
        return Left(ValidationFailure('Arquivo da gravacao nao encontrado.'));
      }
      await nativeDataSource.openRecording(recording.filePath);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure('Erro ao abrir gravacao: $e'));
    }
  }

  _RecordingTimeRange _resolveTimeRange({
    required String period,
    required String? date,
    required String? endDate,
  }) {
    final parsedDate = _parseDate(date) ?? DateTime.now();

    switch (period) {
      case 'custom':
        final customStart = _parseDate(date) ?? parsedDate;
        final customEnd = _parseDate(endDate) ?? customStart;
        return _RecordingTimeRange(
          start: DateTime(customStart.year, customStart.month, customStart.day),
          endExclusive: DateTime(
            customEnd.year,
            customEnd.month,
            customEnd.day,
          ).add(const Duration(days: 1)),
        );
      case 'week':
        final startOfWeek = parsedDate.subtract(
          Duration(days: parsedDate.weekday - 1),
        );
        return _RecordingTimeRange(
          start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          endExclusive: DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day,
          ).add(const Duration(days: 7)),
        );
      case 'month':
        return _RecordingTimeRange(
          start: DateTime(parsedDate.year, parsedDate.month),
          endExclusive: DateTime(parsedDate.year, parsedDate.month + 1),
        );
      case 'year':
        return _RecordingTimeRange(
          start: DateTime(parsedDate.year),
          endExclusive: DateTime(parsedDate.year + 1),
        );
      case 'day':
      default:
        return _RecordingTimeRange(
          start: DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
          endExclusive: DateTime(
            parsedDate.year,
            parsedDate.month,
            parsedDate.day,
          ).add(const Duration(days: 1)),
        );
    }
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value)?.toLocal();
  }
}

class _RecordingTimeRange {
  const _RecordingTimeRange({required this.start, required this.endExclusive});

  final DateTime start;
  final DateTime endExclusive;
}
