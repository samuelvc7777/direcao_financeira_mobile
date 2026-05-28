import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/network/api_error_mapper.dart';
import '../../core/network/api_request_logger.dart';
import '../../domain/entities/detected_ride_draft_entity.dart';
import '../../domain/entities/paged_result_entity.dart';
import '../../domain/entities/ride_import_entity.dart';
import '../../domain/entities/ride_entity.dart';
import '../../domain/repositories/i_ride_repository.dart';
import '../datasources/i_ride_datasource.dart';
import '../datasources/ride_local_datasource.dart';

class RideRepositoryImpl implements IRideRepository {
  RideRepositoryImpl(
    this.remoteDataSource, {
    required this.localDataSource,
    required this.apiErrorMapper,
    required this.apiRequestLogger,
  });

  final IRideDataSource remoteDataSource;
  final IRideLocalDataSource localDataSource;
  final ApiErrorMapper apiErrorMapper;
  final ApiRequestLogger apiRequestLogger;

  @override
  Future<Either<Failure, PagedResultEntity<RideEntity>>> getRides({
    String period = 'day',
    String? date,
    String? endDate,
    String? status,
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final localPendingRides = await _loadEligibleLocalPendingRides(
        period: period,
        date: date,
        endDate: endDate,
        status: status,
      );

      final localCount = localPendingRides.length;
      final includeLocal = localCount > 0;

      final localSliceStart = includeLocal ? offset.clamp(0, localCount) : 0;
      final localSliceEnd = includeLocal
          ? (offset + limit).clamp(0, localCount)
          : 0;
      final localItems = includeLocal
          ? localPendingRides.sublist(localSliceStart, localSliceEnd)
          : const <RideEntity>[];

      final remainingLimit = limit - localItems.length;
      final remoteOffset = offset > localCount ? offset - localCount : 0;

      final PagedResultEntity<RideEntity> remotePage = await remoteDataSource
          .getRides(
            period: period,
            date: date,
            endDate: endDate,
            status: status,
            offset: remoteOffset,
            limit: remainingLimit > 0 ? remainingLimit : 1,
          );

      return Right(
        PagedResultEntity(
          items: [...localItems, if (remainingLimit > 0) ...remotePage.items],
          totalCount: remotePage.totalCount + localCount,
          offset: offset,
          limit: limit,
        ),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'RideRepositoryImpl.getRides',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(e, fallback: 'Erro ao buscar corridas.'),
      );
    }
  }

  @override
  Future<Either<Failure, PagedResultEntity<RideImportEntity>>>
  getImportableRides({
    String period = 'month',
    String? date,
    String? endDate,
    String? status = 'FINISHED',
    int offset = 0,
    int limit = 100,
  }) async {
    try {
      final rides = await remoteDataSource.getRides(
        period: period,
        date: date,
        endDate: endDate,
        status: status,
        offset: offset,
        limit: limit,
      );

      final eligible = rides.items
          .map(
            (ride) => RideImportEntity(
              rideId: ride.id,
              status: ride.status,
              appName: ride.appName,
              paymentMethod: ride.paymentMethod,
              grossValueCents: ride.grossValueCents,
              date: ride.date,
              time: ride.time,
              isAlreadyImported: false,
            ),
          )
          .where((ride) => ride.isEligible)
          .toList();

      return Right(
        PagedResultEntity(
          items: eligible,
          totalCount: eligible.length,
          offset: rides.offset,
          limit: rides.limit,
        ),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'RideRepositoryImpl.getImportableRides',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao buscar corridas elegiveis.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> createDetectedRide(
    DetectedRideDraftEntity ride,
  ) async {
    try {
      await localDataSource.savePendingRide(ride);
      return const Right(unit);
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'RideRepositoryImpl.createDetectedRide',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao salvar corrida detectada.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> createFinishedRide(
    DetectedRideDraftEntity ride,
  ) async {
    try {
      await remoteDataSource.createRideWithStatus(
        ride: ride,
        status: 'FINISHED',
        paymentMethod: ride.paymentMethod,
      );
      return const Right(unit);
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'RideRepositoryImpl.createFinishedRide',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao salvar corrida finalizada.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> updateFinishedRide({
    required int rideId,
    required DetectedRideDraftEntity ride,
  }) async {
    try {
      await remoteDataSource.updateFinishedRide(rideId: rideId, ride: ride);
      return const Right(unit);
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'RideRepositoryImpl.updateFinishedRide',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao atualizar corrida finalizada.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> finishRide({
    required int rideId,
    required String paymentMethod,
  }) async {
    try {
      if (_isLocalRideId(rideId)) {
        final localRide = await localDataSource.getPendingRideById(rideId);
        if (localRide == null) {
          throw StateError('Corrida pendente local nao encontrada.');
        }

        await remoteDataSource.createRideWithStatus(
          ride: localRide.toDetectedRideDraft(
            paymentMethodOverride: paymentMethod,
          ),
          status: 'FINISHED',
          paymentMethod: paymentMethod,
        );
        await localDataSource.removePendingRide(rideId);
      } else {
        await remoteDataSource.finishRide(
          rideId: rideId,
          paymentMethod: paymentMethod,
        );
      }
      return const Right(unit);
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'RideRepositoryImpl.finishRide',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(e, fallback: 'Erro ao finalizar corrida.'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> cancelRide({
    required int rideId,
    required String cancelReason,
  }) async {
    try {
      if (_isLocalRideId(rideId)) {
        final localRide = await localDataSource.getPendingRideById(rideId);
        if (localRide == null) {
          throw StateError('Corrida pendente local nao encontrada.');
        }

        await remoteDataSource.createRideWithStatus(
          ride: localRide.toDetectedRideDraft(),
          status: 'CANCELED',
          cancelReason: cancelReason,
        );
        await localDataSource.removePendingRide(rideId);
      } else {
        await remoteDataSource.cancelRide(
          rideId: rideId,
          cancelReason: cancelReason,
        );
      }
      return const Right(unit);
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'RideRepositoryImpl.cancelRide',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(e, fallback: 'Erro ao cancelar corrida.'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteRide({required int rideId}) async {
    try {
      if (_isLocalRideId(rideId)) {
        await localDataSource.removePendingRide(rideId);
      } else {
        await remoteDataSource.deleteRide(rideId: rideId);
      }
      return const Right(unit);
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'RideRepositoryImpl.deleteRide',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(e, fallback: 'Erro ao excluir corrida.'),
      );
    }
  }

  Future<List<RideEntity>> _loadEligibleLocalPendingRides({
    required String period,
    required String? date,
    required String? endDate,
    required String? status,
  }) async {
    final normalizedStatus = status?.trim().toUpperCase();
    if (normalizedStatus != null &&
        normalizedStatus.isNotEmpty &&
        normalizedStatus != 'PENDING') {
      return const [];
    }

    final range = _resolveTimeRange(
      period: period,
      date: date,
      endDate: endDate,
    );
    final rides = await localDataSource.getPendingRides();

    return rides.where((ride) {
      final createdAt = ride.createdAt ?? _createdAtFromLocalRideId(ride.id);
      if (createdAt == null) {
        return false;
      }

      return !createdAt.isBefore(range.start) &&
          createdAt.isBefore(range.endExclusive);
    }).toList();
  }

  bool _isLocalRideId(int rideId) => rideId < 0;

  DateTime? _createdAtFromLocalRideId(int rideId) {
    if (!_isLocalRideId(rideId)) {
      return null;
    }

    final micros = -rideId;
    return DateTime.fromMicrosecondsSinceEpoch(micros);
  }

  _RideTimeRange _resolveTimeRange({
    required String period,
    required String? date,
    required String? endDate,
  }) {
    final parsedDate = _parseDate(date) ?? DateTime.now();

    switch (period) {
      case 'custom':
        final customStart = _parseDate(date) ?? parsedDate;
        final customEnd = _parseDate(endDate) ?? customStart;
        return _RideTimeRange(
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
        return _RideTimeRange(
          start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          endExclusive: DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day,
          ).add(const Duration(days: 7)),
        );
      case 'month':
        return _RideTimeRange(
          start: DateTime(parsedDate.year, parsedDate.month),
          endExclusive: DateTime(parsedDate.year, parsedDate.month + 1),
        );
      case 'year':
        return _RideTimeRange(
          start: DateTime(parsedDate.year),
          endExclusive: DateTime(parsedDate.year + 1),
        );
      case 'day':
      default:
        return _RideTimeRange(
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

class _RideTimeRange {
  const _RideTimeRange({required this.start, required this.endExclusive});

  final DateTime start;
  final DateTime endExclusive;
}
