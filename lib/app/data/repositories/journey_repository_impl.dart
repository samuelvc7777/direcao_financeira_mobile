import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/network/api_error_mapper.dart';
import '../../core/network/api_request_logger.dart';
import '../../core/network/realtime_client.dart';
import '../../domain/entities/active_shift_entity.dart';
import '../../domain/entities/finish_shift_result_entity.dart';
import '../../domain/entities/journey_statistics_entity.dart';
import '../../domain/entities/location_tracking_status_entity.dart';
import '../../domain/entities/manual_shift_draft_entity.dart';
import '../../domain/entities/paged_result_entity.dart';
import '../../domain/entities/shift_route_entity.dart';
import '../../domain/entities/shift_entity.dart';
import '../../domain/repositories/i_journey_repository.dart';
import '../datasources/i_journey_datasource.dart';
import '../datasources/journey_local_datasource.dart';
import '../datasources/journey_route_local_datasource.dart';
import '../datasources/location_tracking_datasource.dart';
import '../services/journey_shift_lifecycle_service.dart';
import '../services/journey_sync_service.dart';

class JourneyRepositoryImpl implements IJourneyRepository {
  JourneyRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.routeLocalDataSource,
    required this.locationTrackingDataSource,
    required this.realtimeClient,
    required this.apiErrorMapper,
    required this.apiRequestLogger,
  }) : syncService = JourneySyncService(
         remoteDataSource: remoteDataSource,
         localDataSource: localDataSource,
         routeLocalDataSource: routeLocalDataSource,
         realtimeClient: realtimeClient,
       ),
       shiftLifecycleService = JourneyShiftLifecycleService(
         localDataSource: localDataSource,
         routeLocalDataSource: routeLocalDataSource,
         locationTrackingDataSource: locationTrackingDataSource,
       );

  final IJourneyDataSource remoteDataSource;
  final IJourneyLocalDataSource localDataSource;
  final IJourneyRouteLocalDataSource routeLocalDataSource;
  final ILocationTrackingDataSource locationTrackingDataSource;
  final RealtimeClient realtimeClient;
  final ApiErrorMapper apiErrorMapper;
  final ApiRequestLogger apiRequestLogger;
  final JourneySyncService syncService;
  final JourneyShiftLifecycleService shiftLifecycleService;

  @override
  Future<Either<Failure, ActiveShiftEntity?>> getActiveShift() async {
    try {
      final localShift = await localDataSource.getActiveShift();
      if (localShift != null) {
        return Right(await syncService.enrichLocalActiveShift(localShift));
      }

      await syncService.syncPendingShiftsIfOnline();

      final activeShift = await remoteDataSource.getActiveShift();
      if (activeShift != null) {
        await localDataSource.saveActiveShift(activeShift);
      }

      return Right(activeShift);
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'JourneyRepositoryImpl.getActiveShift',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao carregar o turno ativo.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, JourneyStatisticsEntity>> getDailyStatistics({
    String filter = 'day',
    String? date,
    String? endDate,
  }) async {
    try {
      final statistics = await remoteDataSource.getDailyStatistics(
        filter: filter,
        date: date,
        endDate: endDate,
      );
      return Right(statistics);
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'JourneyRepositoryImpl.getDailyStatistics',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao carregar as metricas da jornada.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, PagedResultEntity<ShiftEntity>>> getShiftHistory({
    String filter = 'day',
    String? date,
    String? endDate,
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      apiRequestLogger.logInfo(
        source: 'JourneyRepositoryImpl.getShiftHistory',
        message:
            'inicio filter=$filter date=$date endDate=$endDate offset=$offset limit=$limit',
      );
      await syncService.syncPendingShiftsIfOnline();
      final pendingShifts = await syncService.getPendingShiftHistoryEntities();
      final pendingCount = pendingShifts.length;
      apiRequestLogger.logInfo(
        source: 'JourneyRepositoryImpl.getShiftHistory',
        message:
            'pendencias apos sync=$pendingCount ids=${pendingShifts.map((shift) => shift.localId).toList()}',
      );

      final pendingStart = offset.clamp(0, pendingCount);
      final pendingEnd = (offset + limit).clamp(0, pendingCount);
      final pendingSlice = pendingStart < pendingEnd
          ? pendingShifts.sublist(pendingStart, pendingEnd)
          : const <ShiftEntity>[];

      final remainingLimit = limit - pendingSlice.length;
      final remoteOffset = offset > pendingCount ? offset - pendingCount : 0;

      final remotePage = await remoteDataSource.getShiftHistory(
        filter: filter,
        date: date,
        endDate: endDate,
        offset: remoteOffset,
        limit: remainingLimit <= 0 ? 0 : remainingLimit,
      );
      apiRequestLogger.logInfo(
        source: 'JourneyRepositoryImpl.getShiftHistory',
        message:
            'remoto items=${remotePage.items.length} total=${remotePage.totalCount} ids=${remotePage.items.map((shift) => shift.remoteShiftId).toList()}',
      );

      final mergedItems = <ShiftEntity>[...pendingSlice, ...remotePage.items]
          .asMap()
          .entries
          .map((entry) {
            final shift = entry.value;
            return ShiftEntity(
              index: offset + entry.key + 1,
              localId: shift.localId,
              remoteShiftId: shift.remoteShiftId,
              date: shift.date,
              startTime: shift.startTime,
              endTime: shift.endTime,
              duration: shift.duration,
              drivenKm: shift.drivenKm,
              isPendingSync: shift.isPendingSync,
              hasRoute: shift.hasRoute,
              trackedDistanceKm: shift.trackedDistanceKm,
              routePointCount: shift.routePointCount,
            );
          })
          .toList();

      return Right(
        PagedResultEntity<ShiftEntity>(
          items: mergedItems,
          totalCount: pendingCount + remotePage.totalCount,
          offset: offset,
          limit: limit,
        ),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'JourneyRepositoryImpl.getShiftHistory',
        error: e,
      );
      final pendingShifts = await localDataSource.getPendingFinishedShifts();
      if (pendingShifts.isNotEmpty) {
        final pendingEntities = await syncService
            .getPendingShiftHistoryEntities();
        final start = offset.clamp(0, pendingEntities.length);
        final end = (offset + limit).clamp(0, pendingEntities.length);
        final items = start < end
            ? pendingEntities.sublist(start, end)
            : const <ShiftEntity>[];
        return Right(
          PagedResultEntity<ShiftEntity>(
            items: items.asMap().entries.map((entry) {
              final shift = entry.value;
              return ShiftEntity(
                index: offset + entry.key + 1,
                localId: shift.localId,
                remoteShiftId: shift.remoteShiftId,
                date: shift.date,
                startTime: shift.startTime,
                endTime: shift.endTime,
                duration: shift.duration,
                drivenKm: shift.drivenKm,
                isPendingSync: shift.isPendingSync,
                hasRoute: shift.hasRoute,
                trackedDistanceKm: shift.trackedDistanceKm,
                routePointCount: shift.routePointCount,
              );
            }).toList(),
            totalCount: pendingEntities.length,
            offset: offset,
            limit: limit,
          ),
        );
      }

      apiRequestLogger.logRepositoryFailure(
        source: 'JourneyRepositoryImpl.getShiftHistory',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao carregar o historico da jornada.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> startShift() async {
    try {
      await shiftLifecycleService.startShift();
      return const Right(null);
    } on ValidationFailure catch (e) {
      return Left(e);
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'JourneyRepositoryImpl.startShift',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(e, fallback: 'Erro ao iniciar o turno.'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> pauseShift() async {
    try {
      await shiftLifecycleService.pauseShift();
      return const Right(null);
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'JourneyRepositoryImpl.pauseShift',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(e, fallback: 'Erro ao pausar o turno.'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> resumeShift() async {
    try {
      await shiftLifecycleService.resumeShift();
      return const Right(null);
    } on ValidationFailure catch (e) {
      return Left(e);
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'JourneyRepositoryImpl.resumeShift',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(e, fallback: 'Erro ao retomar o turno.'),
      );
    }
  }

  @override
  Future<Either<Failure, FinishShiftResultEntity>> finishShift() async {
    try {
      await shiftLifecycleService.finishShift();

      final syncedCount = realtimeClient.isOnline.value
          ? await syncService.syncPendingShifts()
          : 0;
      final pendingCount =
          (await localDataSource.getPendingFinishedShifts()).length;

      return Right(
        FinishShiftResultEntity(
          synced: pendingCount == 0 && syncedCount > 0,
          pendingSyncCount: pendingCount,
        ),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'JourneyRepositoryImpl.finishShift',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(e, fallback: 'Erro ao finalizar o turno.'),
      );
    }
  }

  @override
  Future<Either<Failure, FinishShiftResultEntity>> addManualShift(
    ManualShiftDraftEntity shift,
  ) async {
    apiRequestLogger.logInfo(
      source: 'JourneyRepositoryImpl.addManualShift',
      message:
          'inicio km=${shift.totalDrivenKm} start=${shift.startTime} end=${shift.endTime}',
    );
    if (shift.totalDrivenKm <= 0) {
      apiRequestLogger.logInfo(
        source: 'JourneyRepositoryImpl.addManualShift',
        message: 'validacao falhou: km <= 0',
      );
      return Left(
        ValidationFailure('Informe uma quilometragem maior que zero.'),
      );
    }
    if (!shift.endTime.isAfter(shift.startTime)) {
      apiRequestLogger.logInfo(
        source: 'JourneyRepositoryImpl.addManualShift',
        message: 'validacao falhou: endTime nao e depois de startTime',
      );
      return Left(
        ValidationFailure('O horario final precisa ser depois do inicial.'),
      );
    }

    try {
      final activeShift = await localDataSource.getActiveShift();
      if (activeShift != null) {
        apiRequestLogger.logInfo(
          source: 'JourneyRepositoryImpl.addManualShift',
          message: 'bloqueado: existe turno ativo localId=${activeShift.id}',
        );
        return Left(
          ValidationFailure(
            'Finalize o turno em andamento antes de adicionar um turno manual.',
          ),
        );
      }

      await localDataSource.addManualFinishedShift(
        totalDrivenKm: shift.totalDrivenKm,
        startTime: shift.startTime,
        endTime: shift.endTime,
      );
      apiRequestLogger.logInfo(
        source: 'JourneyRepositoryImpl.addManualShift',
        message: 'turno salvo localmente',
      );

      var syncedCount = 0;
      if (realtimeClient.isOnline.value) {
        apiRequestLogger.logInfo(
          source: 'JourneyRepositoryImpl.addManualShift',
          message: 'online=true, tentando sincronizar pendencias',
        );
        try {
          syncedCount = await syncService.syncPendingShifts();
          apiRequestLogger.logInfo(
            source: 'JourneyRepositoryImpl.addManualShift',
            message: 'sincronizacao concluida syncedCount=$syncedCount',
          );
        } catch (e) {
          apiRequestLogger.logRepositoryFailure(
            source: 'JourneyRepositoryImpl.addManualShift.syncPendingShifts',
            error: e,
          );
        }
      } else {
        apiRequestLogger.logInfo(
          source: 'JourneyRepositoryImpl.addManualShift',
          message: 'online=false, mantendo pendente local',
        );
      }
      final pendingCount =
          (await localDataSource.getPendingFinishedShifts()).length;
      apiRequestLogger.logInfo(
        source: 'JourneyRepositoryImpl.addManualShift',
        message:
            'resultado syncedCount=$syncedCount pendingCount=$pendingCount',
      );

      return Right(
        FinishShiftResultEntity(
          synced: pendingCount == 0 && syncedCount > 0,
          pendingSyncCount: pendingCount,
        ),
      );
    } on ValidationFailure catch (e) {
      return Left(e);
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'JourneyRepositoryImpl.addManualShift',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao adicionar o turno manual.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteShift(ShiftEntity shift) async {
    try {
      if (shift.isPendingSync && shift.localId != null) {
        await localDataSource.removePendingFinishedShift(shift.localId!);
        await routeLocalDataSource.deleteRoute(shift.localId!);
        return const Right(null);
      }

      final remoteShiftId = shift.remoteShiftId;
      if (remoteShiftId != null) {
        if (!realtimeClient.isOnline.value) {
          return Left(
            NetworkFailure(
              'Conecte-se a internet para excluir um turno sincronizado.',
            ),
          );
        }

        await remoteDataSource.deleteShift(remoteShiftId);
        if (shift.localId != null) {
          await routeLocalDataSource.deleteRoute(shift.localId!);
        }
        return const Right(null);
      }

      if (shift.localId != null) {
        await localDataSource.removePendingFinishedShift(shift.localId!);
        await routeLocalDataSource.deleteRoute(shift.localId!);
        return const Right(null);
      }

      return Left(ValidationFailure('Nao foi possivel identificar o turno.'));
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'JourneyRepositoryImpl.deleteShift',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(e, fallback: 'Erro ao excluir o turno.'),
      );
    }
  }

  @override
  Future<Either<Failure, int>> syncPendingShifts() async {
    try {
      return Right(await syncService.syncPendingShifts());
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'JourneyRepositoryImpl.syncPendingShifts',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao sincronizar turnos pendentes.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, LocationTrackingStatusEntity>>
  ensureReadyForShiftStart() async {
    try {
      final status = await locationTrackingDataSource
          .ensureReadyForShiftStart();
      return Right(status);
    } on ValidationFailure catch (e) {
      return Left(e);
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'JourneyRepositoryImpl.ensureReadyForShiftStart',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao validar a localizacao para iniciar o turno.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, LocationTrackingStatusEntity>>
  getLocationTrackingStatus() async {
    try {
      final activeShift = await localDataSource.getActiveShift();
      final status = await locationTrackingDataSource.getCurrentStatus(
        localShiftId: activeShift?.id,
        isPaused: activeShift?.isPaused ?? false,
      );
      return Right(status);
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'JourneyRepositoryImpl.getLocationTrackingStatus',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao carregar o status de rastreamento.',
        ),
      );
    }
  }

  @override
  Stream<LocationTrackingStatusEntity> watchLocationTrackingStatus() {
    return locationTrackingDataSource.watchStatus();
  }

  @override
  Future<Either<Failure, ShiftRouteEntity>> getShiftRoute({
    int? localShiftId,
    int? remoteShiftId,
  }) async {
    try {
      if (localShiftId != null) {
        final localRoute = await routeLocalDataSource.getRouteByLocalShiftId(
          localShiftId,
        );
        if (localRoute != null) {
          return Right(localRoute);
        }
      }

      if (remoteShiftId != null) {
        final cachedRoute = await routeLocalDataSource.getRouteByRemoteShiftId(
          remoteShiftId,
        );
        if (cachedRoute != null) {
          return Right(cachedRoute);
        }

        if (!realtimeClient.isOnline.value) {
          return Left(
            NetworkFailure(
              'Sem internet para carregar a rota sincronizada deste turno.',
            ),
          );
        }

        return Right(await remoteDataSource.getShiftRoute(remoteShiftId));
      }

      return Left(
        ValidationFailure(
          'O turno informado nao possui identificador de rota.',
        ),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'JourneyRepositoryImpl.getShiftRoute',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao carregar a rota do turno.',
        ),
      );
    }
  }
}
