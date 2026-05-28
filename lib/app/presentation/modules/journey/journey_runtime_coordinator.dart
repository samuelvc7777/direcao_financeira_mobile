import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/app_bubble/app_bubble_service.dart';
import '../../../core/accessibility/accessibility_service.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/journey_realtime_bridge.dart';
import '../../../domain/entities/location_tracking_status_entity.dart';
import '../../../domain/entities/recording_entity.dart';
import '../../../domain/usecases/journey_use_cases.dart';
import '../../../domain/usecases/recording_use_cases.dart';

typedef JourneyConnectionChangedCallback =
    Future<void> Function(bool isOnlineNow);
typedef JourneyTrackingChangedCallback =
    void Function(LocationTrackingStatusEntity status);
typedef JourneyAssistantStateCallback = void Function(bool isActive);
typedef JourneyTrafficLightStateCallback = void Function(bool isActive);
typedef JourneyBusyStateCallback = void Function(bool isBusy);
typedef JourneyRuntimeFeedbackCallback =
    void Function(String title, String message);
typedef JourneyRecordingStateCallback =
    void Function(RecordingEntity? recording);

class JourneyRuntimeCoordinator {
  JourneyRuntimeCoordinator({
    required this.journeyRealtimeBridge,
    required this.getLocationTrackingStatusUseCase,
    required this.watchLocationTrackingStatusUseCase,
    required this.syncPendingJourneyUseCase,
    required this.accessibilityService,
    required this.appBubbleService,
    required this.getActiveRecordingUseCase,
    required this.startRecordingUseCase,
    required this.stopRecordingUseCase,
  });

  final JourneyRealtimeBridge journeyRealtimeBridge;
  final GetLocationTrackingStatusUseCase getLocationTrackingStatusUseCase;
  final WatchLocationTrackingStatusUseCase watchLocationTrackingStatusUseCase;
  final SyncPendingJourneyUseCase syncPendingJourneyUseCase;
  final AccessibilityService accessibilityService;
  final AppBubbleService appBubbleService;
  final GetActiveRecordingUseCase getActiveRecordingUseCase;
  final StartRecordingUseCase startRecordingUseCase;
  final StopRecordingUseCase stopRecordingUseCase;

  Worker? _accessibilityWorker;
  Worker? _connectionWorker;
  StreamSubscription<LocationTrackingStatusEntity>? _trackingStatusSubscription;

  void bind({
    required JourneyConnectionChangedCallback onConnectionChanged,
    required JourneyTrackingChangedCallback onTrackingStatusChanged,
    required VoidCallback onRideChanged,
    required void Function(bool isEnabled) onAccessibilityChanged,
  }) {
    _accessibilityWorker = ever<bool>(
      accessibilityService.isServiceEnabled,
      onAccessibilityChanged,
    );
    _connectionWorker = ever<bool>(
      journeyRealtimeBridge.isOnline,
      onConnectionChanged,
    );
    _trackingStatusSubscription = watchLocationTrackingStatusUseCase().listen(
      onTrackingStatusChanged,
    );
    journeyRealtimeBridge.bind(onRideChanged: onRideChanged);
  }

  Future<void> unbind() async {
    journeyRealtimeBridge.unbind();
    _accessibilityWorker?.dispose();
    _connectionWorker?.dispose();
    await _trackingStatusSubscription?.cancel();
  }

  Future<LocationTrackingStatusEntity?> loadTrackingStatus() async {
    final result = await getLocationTrackingStatusUseCase();
    return result.fold((_) => null, (status) => status);
  }

  Future<int> syncPendingShifts() async {
    final result = await syncPendingJourneyUseCase();
    return result.fold((_) => 0, (syncedCount) => syncedCount);
  }

  Future<void> loadAssistantStatus({
    required JourneyAssistantStateCallback onAssistantStateChanged,
  }) async {
    onAssistantStateChanged(await appBubbleService.isBubbleRunning());
  }

  Future<void> loadRecordingStatus({
    required JourneyRecordingStateCallback onRecordingStateChanged,
  }) async {
    final result = await getActiveRecordingUseCase();
    result.fold((_) => onRecordingStateChanged(null), onRecordingStateChanged);
  }

  Future<void> toggleRecording({
    required bool isRecordingActive,
    required JourneyRecordingStateCallback onRecordingStateChanged,
    required JourneyBusyStateCallback onBusyStateChanged,
    required JourneyRuntimeFeedbackCallback showSuccess,
    required JourneyRuntimeFeedbackCallback showWarning,
    required JourneyRuntimeFeedbackCallback showError,
  }) async {
    onBusyStateChanged(true);
    try {
      if (isRecordingActive) {
        final result = await stopRecordingUseCase();
        result.fold(
          (failure) => showError('Nao foi possivel parar', failure.message),
          (recording) {
            onRecordingStateChanged(null);
            showSuccess(
              'Gravacao finalizada',
              'O video foi salvo na lista de gravacoes.',
            );
          },
        );
        return;
      }

      final result = await startRecordingUseCase();
      result.fold(
        (failure) {
          if (failure is ValidationFailure) {
            showWarning('Permissao necessaria', failure.message);
          } else {
            showError('Nao foi possivel gravar', failure.message);
          }
        },
        (recording) {
          onRecordingStateChanged(recording);
          showSuccess(
            'Gravacao ativa',
            'Audio e video estao sendo gravados com notificacao visivel.',
          );
        },
      );
    } catch (_) {
      showError(
        'Nao foi possivel gravar',
        'Falhou ao alternar a gravacao neste momento.',
      );
    } finally {
      onBusyStateChanged(false);
    }
  }

  Future<void> toggleAssistant({
    required bool isAssistantActive,
    required JourneyAssistantStateCallback onAssistantStateChanged,
    required JourneyBusyStateCallback onBusyStateChanged,
    required JourneyRuntimeFeedbackCallback showSuccess,
    required JourneyRuntimeFeedbackCallback showWarning,
    required JourneyRuntimeFeedbackCallback showError,
  }) async {
    onBusyStateChanged(true);
    try {
      if (isAssistantActive) {
        await appBubbleService.stopBubble();
        onAssistantStateChanged(false);
        showSuccess(
          'Assistente desativado',
          'O balao da Direcao Financeira foi removido da tela.',
        );
        return;
      }

      final hasPermission = await appBubbleService.isOverlayPermissionGranted();
      if (!hasPermission) {
        await appBubbleService.openOverlayPermissionSettings();
        showWarning(
          'Permissao necessaria',
          'Libere a permissao de sobreposicao para ativar o Assistente.',
        );
        return;
      }

      await appBubbleService.startBubble();
      onAssistantStateChanged(true);
      showSuccess(
        'Assistente ativado',
        'A logo ja esta visivel sobre outros apps.',
      );
    } catch (_) {
      showError(
        'Nao foi possivel ativar',
        'Falhou ao iniciar o Assistente neste momento.',
      );
    } finally {
      onBusyStateChanged(false);
    }
  }
}
