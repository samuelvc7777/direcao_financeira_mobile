import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/paged_result_entity.dart';
import '../entities/recording_entity.dart';
import '../repositories/i_recording_repository.dart';

class GetRecordingsUseCase {
  const GetRecordingsUseCase(this.repository);

  final IRecordingRepository repository;

  Future<Either<Failure, PagedResultEntity<RecordingEntity>>> call({
    String period = 'day',
    String? date,
    String? endDate,
    String? status,
    int offset = 0,
    int limit = 20,
  }) {
    return repository.getRecordings(
      period: period,
      date: date,
      endDate: endDate,
      status: status,
      offset: offset,
      limit: limit,
    );
  }
}

class GetActiveRecordingUseCase {
  const GetActiveRecordingUseCase(this.repository);

  final IRecordingRepository repository;

  Future<Either<Failure, RecordingEntity?>> call() {
    return repository.getActiveRecording();
  }
}

class StartRecordingUseCase {
  const StartRecordingUseCase(this.repository);

  final IRecordingRepository repository;

  Future<Either<Failure, RecordingEntity>> call() {
    return repository.startRecording();
  }
}

class StopRecordingUseCase {
  const StopRecordingUseCase(this.repository);

  final IRecordingRepository repository;

  Future<Either<Failure, RecordingEntity?>> call() {
    return repository.stopRecording();
  }
}

class DeleteRecordingUseCase {
  const DeleteRecordingUseCase(this.repository);

  final IRecordingRepository repository;

  Future<Either<Failure, Unit>> call(String id) {
    return repository.deleteRecording(id);
  }
}

class OpenRecordingUseCase {
  const OpenRecordingUseCase(this.repository);

  final IRecordingRepository repository;

  Future<Either<Failure, Unit>> call(RecordingEntity recording) {
    return repository.openRecording(recording);
  }
}
