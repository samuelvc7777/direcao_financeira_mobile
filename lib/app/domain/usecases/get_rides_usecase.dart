import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/paged_result_entity.dart';
import '../entities/ride_import_entity.dart';
import '../entities/ride_entity.dart';
import '../repositories/i_ride_repository.dart';

class GetRidesUseCase {
  final IRideRepository repository;

  GetRidesUseCase(this.repository);

  Future<Either<Failure, PagedResultEntity<RideEntity>>> call({
    String period = 'day',
    String? date,
    String? endDate,
    String? status,
    int offset = 0,
    int limit = 20,
  }) async {
    return await repository.getRides(
      period: period,
      date: date,
      endDate: endDate,
      status: status,
      offset: offset,
      limit: limit,
    );
  }
}

class GetImportableRidesUseCase {
  final IRideRepository repository;

  GetImportableRidesUseCase(this.repository);

  Future<Either<Failure, PagedResultEntity<RideImportEntity>>> call({
    String period = 'month',
    String? date,
    String? endDate,
    String? status = 'FINISHED',
    int offset = 0,
    int limit = 100,
  }) async {
    return repository.getImportableRides(
      period: period,
      date: date,
      endDate: endDate,
      status: status,
      offset: offset,
      limit: limit,
    );
  }
}
