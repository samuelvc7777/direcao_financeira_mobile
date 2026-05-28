import '../../../domain/entities/finish_shift_result_entity.dart';
import '../../../domain/entities/location_tracking_status_entity.dart';
import '../../../domain/usecases/journey_use_cases.dart';

typedef JourneySuccessCallback = void Function(String message);
typedef JourneyErrorCallback = void Function(String title, String message);
typedef JourneyWarningCallback = void Function(String title, String message);
typedef JourneyTrackingStatusCallback =
    void Function(LocationTrackingStatusEntity status);
typedef JourneyAskSettingsCallback =
    Future<bool?> Function(LocationTrackingStatusEntity status);
typedef JourneyOpenTrackingSettingsCallback =
    Future<void> Function(
      LocationTrackingStatusEntity status, {
      bool showFollowUpWarning,
    });

class ShiftLifecycleCoordinator {
  ShiftLifecycleCoordinator({
    required this.startShiftUseCase,
    required this.pauseShiftUseCase,
    required this.resumeShiftUseCase,
    required this.finishShiftUseCase,
    required this.ensureReadyForShiftStartUseCase,
  });

  final StartShiftUseCase startShiftUseCase;
  final PauseShiftUseCase pauseShiftUseCase;
  final ResumeShiftUseCase resumeShiftUseCase;
  final FinishShiftUseCase finishShiftUseCase;
  final EnsureReadyForShiftStartUseCase ensureReadyForShiftStartUseCase;

  Future<bool> startShift({
    required JourneyTrackingStatusCallback onTrackingStatusResolved,
    required JourneyAskSettingsCallback askToOpenTrackingSettings,
    required JourneyOpenTrackingSettingsCallback openTrackingSettings,
    required JourneySuccessCallback showSuccess,
    required JourneyErrorCallback showError,
    required String Function(String message) normalizeErrorMessage,
  }) async {
    String? failureMessage;
    LocationTrackingStatusEntity? status;

    final readinessResult = await ensureReadyForShiftStartUseCase();
    readinessResult.fold(
      (failure) => failureMessage = failure.message,
      (resolvedStatus) => status = resolvedStatus,
    );

    if (failureMessage != null) {
      showError(
        'Nao foi possivel validar a localizacao',
        normalizeErrorMessage(failureMessage!),
      );
      return false;
    }

    if (status == null) {
      showError(
        'Erro',
        'Nao foi possivel validar a localizacao para iniciar o turno.',
      );
      return false;
    }

    onTrackingStatusResolved(status!);
    if (!status!.canTrackFully) {
      final shouldOpenSettings = await askToOpenTrackingSettings(status!);
      if (shouldOpenSettings == true) {
        await openTrackingSettings(status!, showFollowUpWarning: false);
      }
      return false;
    }

    final startResult = await startShiftUseCase();
    return startResult.fold(
      (failure) {
        showError(
          'Nao foi possivel iniciar o turno',
          normalizeErrorMessage(failure.message),
        );
        return false;
      },
      (_) {
        showSuccess('Turno iniciado com sucesso.');
        return true;
      },
    );
  }

  Future<bool> pauseOrResumeShift({
    required bool isPaused,
    required JourneySuccessCallback showSuccess,
    required JourneyErrorCallback showError,
    required String Function(String message) normalizeErrorMessage,
  }) async {
    final result = isPaused
        ? await resumeShiftUseCase()
        : await pauseShiftUseCase();

    return result.fold(
      (failure) {
        final action = isPaused ? 'retomar o turno' : 'pausar o turno';
        showError(
          'Nao foi possivel $action',
          normalizeErrorMessage(failure.message),
        );
        return false;
      },
      (_) {
        showSuccess(
          isPaused
              ? 'Turno retomado com sucesso.'
              : 'Turno pausado com sucesso.',
        );
        return true;
      },
    );
  }

  Future<FinishShiftResultEntity?> finishShift({
    required JourneySuccessCallback showSuccess,
    required JourneyWarningCallback showWarning,
    required JourneyErrorCallback showError,
    required String Function(String message) normalizeErrorMessage,
  }) async {
    final result = await finishShiftUseCase();
    return result.fold(
      (failure) {
        showError(
          'Nao foi possivel parar o turno',
          normalizeErrorMessage(failure.message),
        );
        return null;
      },
      (finishResult) {
        if (finishResult.synced) {
          showSuccess('Turno finalizado e sincronizado com sucesso.');
        } else {
          showWarning(
            'Turno salvo no aparelho',
            'O turno foi finalizado localmente e sera sincronizado quando a internet voltar.',
          );
        }
        return finishResult;
      },
    );
  }
}
