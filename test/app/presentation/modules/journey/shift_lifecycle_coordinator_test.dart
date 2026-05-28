import 'package:dartz/dartz.dart';
import 'package:direcao_financeira_mobile/app/core/errors/failures.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/active_shift_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/finish_shift_result_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/journey_statistics_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/location_tracking_status_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/manual_shift_draft_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/paged_result_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/shift_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/shift_route_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/repositories/i_journey_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/usecases/journey_use_cases.dart';
import 'package:direcao_financeira_mobile/app/presentation/modules/journey/shift_lifecycle_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeJourneyRepository implements IJourneyRepository {
  Either<Failure, void> startResult = const Right(null);
  Either<Failure, void> pauseResult = const Right(null);
  Either<Failure, void> resumeResult = const Right(null);
  Either<Failure, FinishShiftResultEntity> finishResult = const Right(
    FinishShiftResultEntity(synced: true, pendingSyncCount: 0),
  );
  Either<Failure, LocationTrackingStatusEntity> readinessResult = Right(
    _readyStatus,
  );

  static const _readyStatus = LocationTrackingStatusEntity(
    isTrackingActive: true,
    isLocationServiceEnabled: true,
    hasForegroundPermission: true,
    hasBackgroundPermission: true,
    isPreciseLocation: true,
    isPaused: false,
    totalDistanceMeters: 0,
    idleTimeSeconds: 0,
  );

  @override
  Future<Either<Failure, LocationTrackingStatusEntity>>
  ensureReadyForShiftStart() async => readinessResult;

  @override
  Future<Either<Failure, FinishShiftResultEntity>> finishShift() async =>
      finishResult;

  @override
  Future<Either<Failure, FinishShiftResultEntity>> addManualShift(
    ManualShiftDraftEntity shift,
  ) async =>
      const Right(FinishShiftResultEntity(synced: true, pendingSyncCount: 0));

  @override
  Future<Either<Failure, void>> deleteShift(ShiftEntity shift) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> pauseShift() async => pauseResult;

  @override
  Future<Either<Failure, void>> resumeShift() async => resumeResult;

  @override
  Future<Either<Failure, void>> startShift() async => startResult;

  @override
  Future<Either<Failure, int>> syncPendingShifts() async => const Right(0);

  @override
  Future<Either<Failure, ActiveShiftEntity?>> getActiveShift() async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, JourneyStatisticsEntity>> getDailyStatistics({
    String filter = 'day',
    String? date,
    String? endDate,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, LocationTrackingStatusEntity>>
  getLocationTrackingStatus() async => throw UnimplementedError();

  @override
  Future<Either<Failure, PagedResultEntity<ShiftEntity>>> getShiftHistory({
    String filter = 'day',
    String? date,
    String? endDate,
    int offset = 0,
    int limit = 20,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, ShiftRouteEntity>> getShiftRoute({
    int? localShiftId,
    int? remoteShiftId,
  }) async => throw UnimplementedError();

  @override
  Stream<LocationTrackingStatusEntity> watchLocationTrackingStatus() =>
      const Stream<LocationTrackingStatusEntity>.empty();
}

void main() {
  group('ShiftLifecycleCoordinator', () {
    late _FakeJourneyRepository repository;
    late ShiftLifecycleCoordinator coordinator;
    late List<String> feedbacks;

    setUp(() {
      repository = _FakeJourneyRepository();
      feedbacks = <String>[];
      coordinator = ShiftLifecycleCoordinator(
        startShiftUseCase: StartShiftUseCase(repository),
        pauseShiftUseCase: PauseShiftUseCase(repository),
        resumeShiftUseCase: ResumeShiftUseCase(repository),
        finishShiftUseCase: FinishShiftUseCase(repository),
        ensureReadyForShiftStartUseCase: EnsureReadyForShiftStartUseCase(
          repository,
        ),
      );
    });

    test('inicia turno quando localizacao esta pronta', () async {
      var resolvedStatusCalls = 0;

      final started = await coordinator.startShift(
        onTrackingStatusResolved: (_) => resolvedStatusCalls++,
        askToOpenTrackingSettings: (_) async => false,
        openTrackingSettings: (_, {showFollowUpWarning = true}) async {},
        showSuccess: (message) => feedbacks.add(message),
        showError: (title, message) => feedbacks.add('$title:$message'),
        normalizeErrorMessage: (message) => message,
      );

      expect(started, isTrue);
      expect(resolvedStatusCalls, 1);
      expect(feedbacks.single, 'Turno iniciado com sucesso.');
    });

    test('nao inicia turno quando validacao de localizacao falha', () async {
      repository.readinessResult = Left(ValidationFailure('gps desligado'));

      final started = await coordinator.startShift(
        onTrackingStatusResolved: (_) {},
        askToOpenTrackingSettings: (_) async => false,
        openTrackingSettings: (_, {showFollowUpWarning = true}) async {},
        showSuccess: (message) => feedbacks.add(message),
        showError: (title, message) => feedbacks.add('$title:$message'),
        normalizeErrorMessage: (message) => message,
      );

      expect(started, isFalse);
      expect(feedbacks.single, contains('gps desligado'));
    });

    test(
      'bloqueia inicio e oferece abrir ajustes quando tracking nao pode ficar completo',
      () async {
        repository.readinessResult = const Right(
          LocationTrackingStatusEntity(
            isTrackingActive: false,
            isLocationServiceEnabled: true,
            hasForegroundPermission: true,
            hasBackgroundPermission: false,
            isPreciseLocation: true,
            isPaused: false,
            totalDistanceMeters: 0,
            idleTimeSeconds: 0,
          ),
        );
        LocationTrackingStatusEntity? resolvedStatus;
        LocationTrackingStatusEntity? openedStatus;
        var askedToOpenSettings = 0;

        final started = await coordinator.startShift(
          onTrackingStatusResolved: (status) => resolvedStatus = status,
          askToOpenTrackingSettings: (_) async {
            askedToOpenSettings++;
            return true;
          },
          openTrackingSettings: (status, {showFollowUpWarning = true}) async {
            openedStatus = status;
            expect(showFollowUpWarning, isFalse);
          },
          showSuccess: (message) => feedbacks.add(message),
          showError: (title, message) => feedbacks.add('$title:$message'),
          normalizeErrorMessage: (message) => message,
        );

        expect(started, isFalse);
        expect(resolvedStatus, isNotNull);
        expect(resolvedStatus!.canTrackFully, isFalse);
        expect(askedToOpenSettings, 1);
        expect(openedStatus, isNotNull);
        expect(feedbacks, isEmpty);
      },
    );

    test('pausa turno com mensagem de sucesso correta', () async {
      final completed = await coordinator.pauseOrResumeShift(
        isPaused: false,
        showSuccess: (message) => feedbacks.add(message),
        showError: (title, message) => feedbacks.add('$title:$message'),
        normalizeErrorMessage: (message) => message,
      );

      expect(completed, isTrue);
      expect(feedbacks.single, 'Turno pausado com sucesso.');
    });

    test('retoma turno com mensagem de sucesso correta', () async {
      final completed = await coordinator.pauseOrResumeShift(
        isPaused: true,
        showSuccess: (message) => feedbacks.add(message),
        showError: (title, message) => feedbacks.add('$title:$message'),
        normalizeErrorMessage: (message) => message,
      );

      expect(completed, isTrue);
      expect(feedbacks.single, 'Turno retomado com sucesso.');
    });

    test('normaliza falha ao pausar turno', () async {
      repository.pauseResult = Left(ServerFailure('socketexception'));

      final completed = await coordinator.pauseOrResumeShift(
        isPaused: false,
        showSuccess: (message) => feedbacks.add(message),
        showError: (title, message) => feedbacks.add('$title:$message'),
        normalizeErrorMessage: (message) => 'normalizado: $message',
      );

      expect(completed, isFalse);
      expect(
        feedbacks.single,
        'Nao foi possivel pausar o turno:normalizado: socketexception',
      );
    });

    test('finaliza turno retornando resultado sincronizado', () async {
      final result = await coordinator.finishShift(
        showSuccess: (message) => feedbacks.add(message),
        showWarning: (title, message) => feedbacks.add('$title:$message'),
        showError: (title, message) => feedbacks.add('$title:$message'),
        normalizeErrorMessage: (message) => message,
      );

      expect(result, isNotNull);
      expect(result!.synced, isTrue);
      expect(feedbacks.single, 'Turno finalizado e sincronizado com sucesso.');
    });

    test('finaliza turno offline e informa sincronizacao pendente', () async {
      repository.finishResult = const Right(
        FinishShiftResultEntity(synced: false, pendingSyncCount: 1),
      );

      final result = await coordinator.finishShift(
        showSuccess: (message) => feedbacks.add(message),
        showWarning: (title, message) => feedbacks.add('$title:$message'),
        showError: (title, message) => feedbacks.add('$title:$message'),
        normalizeErrorMessage: (message) => message,
      );

      expect(result, isNotNull);
      expect(result!.synced, isFalse);
      expect(
        feedbacks.single,
        'Turno salvo no aparelho:O turno foi finalizado localmente e sera sincronizado quando a internet voltar.',
      );
    });
  });
}
