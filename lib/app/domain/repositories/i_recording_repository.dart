import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/paged_result_entity.dart';
import '../entities/recording_entity.dart';

abstract class IRecordingRepository {
  Future<Either<Failure, PagedResultEntity<RecordingEntity>>> getRecordings({
    String period = 'day',
    String? date,
    String? endDate,
    String? status,
    int offset = 0,
    int limit = 20,
  });

  Future<Either<Failure, RecordingEntity?>> getActiveRecording();

  Future<Either<Failure, RecordingEntity>> startRecording();

  Future<Either<Failure, RecordingEntity?>> stopRecording();

  Future<Either<Failure, Unit>> openRecording(RecordingEntity recording);

  Future<Either<Failure, Unit>> deleteRecording(String id);
}
