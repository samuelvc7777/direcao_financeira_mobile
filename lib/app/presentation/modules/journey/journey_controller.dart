import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../../core/feedback/app_snackbar.dart';
import '../../../core/location/location_permission_settings.dart';
import '../../../domain/entities/active_shift_entity.dart';
import '../../../domain/entities/costs_gains_settings_entity.dart';
import '../../../domain/entities/journey_statistics_entity.dart';
import '../../../domain/entities/location_tracking_status_entity.dart';
import '../../../domain/entities/manual_shift_draft_entity.dart';
import '../../../domain/entities/online_hourly_projection_entity.dart';
import '../../../domain/entities/recording_entity.dart';
import '../../../domain/entities/ride_entity.dart';
import '../../../domain/entities/shift_entity.dart';
import '../../../domain/services/online_hourly_projection_calculator.dart';
import '../../../domain/usecases/costs_gains_settings_use_cases.dart';
import '../../../domain/usecases/get_rides_usecase.dart';
import '../../../domain/usecases/journey_use_cases.dart';
import '../../../domain/usecases/recording_use_cases.dart';
import '../../../domain/usecases/ride_status_use_cases.dart';
import 'journey_runtime_coordinator.dart';
import 'journey_statistics_display_data.dart';
import 'shift_lifecycle_coordinator.dart';

class JourneyController extends GetxController with WidgetsBindingObserver {
  static const int _historyPageSize = 20;
  static const int _statisticsCacheLimit = 12;
  static const double _trackingUiRefreshDistanceMeters = 100.0;
  static const Duration _trackingUiRefreshInterval = Duration(seconds: 15);

  final GetActiveShiftUseCase getActiveShift;
  final GetDailyStatisticsUseCase getDailyStatistics;
  final GetShiftHistoryUseCase getShiftHistory;
  final CreateManualShiftUseCase createManualShift;
  final DeleteShiftUseCase deleteShiftUseCase;
  final GetRidesUseCase getRidesUseCase;
  final DeleteRideUseCase deleteRideUseCase;
  final GetRecordingsUseCase getRecordingsUseCase;
  final DeleteRecordingUseCase deleteRecordingUseCase;
  final OpenRecordingUseCase openRecordingUseCase;
  final GetCostsGainsSettingsUseCase? getCostsGainsSettings;
  final ShiftLifecycleCoordinator shiftLifecycleCoordinator;
  final JourneyRuntimeCoordinator runtimeCoordinator;

  JourneyController({
    required this.getActiveShift,
    required this.getDailyStatistics,
    required this.getShiftHistory,
    required this.createManualShift,
    required this.deleteShiftUseCase,
    required this.getRidesUseCase,
    required this.deleteRideUseCase,
    required this.getRecordingsUseCase,
    required this.deleteRecordingUseCase,
    required this.openRecordingUseCase,
    required this.getCostsGainsSettings,
    required this.shiftLifecycleCoordinator,
    required this.runtimeCoordinator,
  });

  final isLoading = false.obs;
  final isStartingShift = false.obs;
  final isAddingManualShift = false.obs;
  final deletingShiftKey = RxnString();
  final deletingRideId = RxnInt();
  final deletingRecordingId = RxnString();
  final isPauseShiftLoading = false.obs;
  final isFinishingShift = false.obs;
  final isLoadingMoreShifts = false.obs;
  final isLoadingMoreRides = false.obs;
  final isLoadingMoreRecordings = false.obs;
  final hasMoreShifts = false.obs;
  final hasMoreRides = false.obs;
  final hasMoreRecordings = false.obs;
  final selectedFilter = 'day'.obs; // day, week, month, year, custom
  final customStartDate = Rxn<DateTime>();
  final customEndDate = Rxn<DateTime>();
  final activeShift = Rxn<ActiveShiftEntity>();
  final activeShiftError = RxnString();
  final metricsError = RxnString();
  final historyError = RxnString();
  final ridesError = RxnString();
  final recordingsError = RxnString();

  Timer? _timer;
  Worker? _journeyMetricsWorker;
  int _periodRefreshGeneration = 0;
  final _statisticsCache = <String, JourneyStatisticsEntity>{};
  final elapsedSeconds = 0.obs;
  final startTimeStr = '--:--'.obs;
  final currentKm = 0.0.obs;
  final isWaitingAccessibilityActivation = false.obs;
  final pendingShiftSyncCount = 0.obs;
  final trackingStatus = Rxn<LocationTrackingStatusEntity>();
  DateTime? _lastTrackingUiRefreshAt;
  double? _lastTrackingUiDistanceMeters;

  String get formattedElapsed {
    final hours = elapsedSeconds.value ~/ 3600;
    final minutes = (elapsedSeconds.value % 3600) ~/ 60;
    final seconds = elapsedSeconds.value % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  final ridesList = <RideEntity>[].obs;
  final recordingsList = <RecordingEntity>[].obs;
  final paymentMethodSummary = <PaymentMethodSummaryItem>[].obs;
  final isPaymentMethodSectionExpanded = false.obs;
  final selectedRideStatusFilter = 'Todos'.obs;
  final selectedRecordingStatusFilter = 'Todos'.obs;
  final shiftsTotalCount = 0.obs;
  final ridesHistoryTotalCount = 0.obs;
  final recordingsHistoryTotalCount = 0.obs;
  final paymentMethodFinishedRidesCount = 0.obs;

  List<RideEntity> get filteredRidesList =>
      ridesList.where(_matchesSelectedRideStatus).toList(growable: false);
  int get filteredRidesCount => filteredRidesList.length;
  List<RecordingEntity> get filteredRecordingsList => recordingsList
      .where(_matchesSelectedRecordingStatus)
      .toList(growable: false);
  int get filteredRecordingsCount => filteredRecordingsList.length;
  int get mappedPaymentMethodCount =>
      paymentMethodSummary.fold(0, (total, item) => total + item.count);

  void togglePaymentMethodSection() {
    isPaymentMethodSectionExpanded.toggle();
  }

  void changeRideStatusFilter(String filter) {
    if (selectedRideStatusFilter.value == filter) {
      return;
    }
    selectedRideStatusFilter.value = filter;
    ridesHistoryTotalCount.value = filteredRidesCount;
  }

  void changeRecordingStatusFilter(String filter) {
    if (selectedRecordingStatusFilter.value == filter) {
      return;
    }
    selectedRecordingStatusFilter.value = filter;
    recordingsHistoryTotalCount.value = filteredRecordingsCount;
  }

  void openRideDetails(RideEntity ride) {
    Get.toNamed('/journey/ride-details', arguments: ride);
  }

  Future<void> requestDeleteRide(RideEntity ride) async {
    if (deletingRideId.value == ride.id) {
      return;
    }

    final shouldDelete = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Excluir corrida'),
        content: Text(
          'Deseja excluir a corrida de ${ride.date} ${ride.time}? Esta acao nao pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Get.back(result: true),
            child: const Text('Excluir'),
          ),
        ],
      ),
      barrierDismissible: true,
    );

    if (shouldDelete == true) {
      await deleteRide(ride);
    }
  }

  Future<bool> deleteRide(RideEntity ride) async {
    deletingRideId.value = ride.id;
    try {
      final result = await deleteRideUseCase(rideId: ride.id);
      return await result.fold(
        (failure) async {
          _showError('Nao foi possivel excluir', failure.message);
          return false;
        },
        (_) async {
          _showSuccess('Corrida excluida com sucesso.');
          await refreshJourneyData(silent: true);
          return true;
        },
      );
    } finally {
      if (deletingRideId.value == ride.id) {
        deletingRideId.value = null;
      }
    }
  }

  Future<void> requestDeleteRecording(RecordingEntity recording) async {
    if (deletingRecordingId.value == recording.id) {
      return;
    }

    final shouldDelete = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Excluir gravacao'),
        content: Text(
          'Deseja excluir a gravacao de ${_formatRecordingDate(recording.startedAt)}? Esta acao nao pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Get.back(result: true),
            child: const Text('Excluir'),
          ),
        ],
      ),
      barrierDismissible: true,
    );

    if (shouldDelete == true) {
      await deleteRecording(recording);
    }
  }

  Future<bool> deleteRecording(RecordingEntity recording) async {
    deletingRecordingId.value = recording.id;
    try {
      final result = await deleteRecordingUseCase(recording.id);
      return await result.fold(
        (failure) async {
          _showError('Nao foi possivel excluir', failure.message);
          return false;
        },
        (_) async {
          _showSuccess('Gravacao excluida com sucesso.');
          await refreshJourneyData(silent: true);
          return true;
        },
      );
    } finally {
      if (deletingRecordingId.value == recording.id) {
        deletingRecordingId.value = null;
      }
    }
  }

  Future<void> openRecording(RecordingEntity recording) async {
    final result = await openRecordingUseCase(recording);
    result.fold(
      (failure) => _showError('Nao foi possivel abrir', failure.message),
      (_) {},
    );
  }

  final totalShifts = '0'.obs;
  final totalTime = '00:00:00'.obs;
  final averageTime = '00:00:00'.obs;
  final drivenKm = '0.0 km'.obs;

  final totalRides = 0.obs;
  final grossEarningsCents = 0.obs;
  final netEarningsCents = 0.obs;
  final totalCostsCents = 0.obs;
  final ridesTotalKm = 0.0.obs;
  final ridesTotalTime = 0.obs;
  final totalShiftDrivenKm = 0.0.obs;
  final costsGainsSettings = Rxn<CostsGainsSettingsEntity>();
  final isOperationalCostBreakdownExpanded = false.obs;

  final shiftsCount = 0.obs;
  final shiftsList = <ShiftEntity>[].obs;

  final selectedDate = DateTime.now().obs;
  final selectedJourneyTabIndex = 0.obs;
  final isTrafficLightActive = false.obs;
  final isAssistantActive = false.obs;
  final isAssistantBusy = false.obs;
  final activeRecording = Rxn<RecordingEntity>();
  final isRecordingBusy = false.obs;
  int _statisticsTotalTimeBaseSeconds = 0;

  bool get hasActiveShift => activeShift.value != null;
  bool get isAccessibilityServiceEnabled =>
      runtimeCoordinator.accessibilityService.isServiceEnabled.value;
  String get status => hasActiveShift ? 'Ativo' : 'Inativo';
  bool get isOnline => runtimeCoordinator.journeyRealtimeBridge.isOnline.value;
  bool get canRetry =>
      activeShiftError.value != null ||
      metricsError.value != null ||
      historyError.value != null ||
      ridesError.value != null ||
      recordingsError.value != null;
  bool get isRecordingActive => activeRecording.value?.isActive ?? false;
  bool get canStartShift =>
      !isLoading.value && !isStartingShift.value && !hasActiveShift;
  bool get canAddManualShift =>
      !isLoading.value && !isAddingManualShift.value && !hasActiveShift;
  bool get canFinishShift =>
      !isLoading.value && !isFinishingShift.value && hasActiveShift;
  bool get canPauseOrResumeShift =>
      !isLoading.value && !isPauseShiftLoading.value && hasActiveShift;
  bool get isShiftPaused => activeShift.value?.isPaused ?? false;
  bool get canOpenTrackingSettings {
    final status = trackingStatus.value;
    if (!hasActiveShift || status == null) {
      return false;
    }

    return !status.isLocationServiceEnabled ||
        !status.hasForegroundPermission ||
        !status.hasBackgroundPermission ||
        !status.isPreciseLocation;
  }

  String get trackingSettingsLabel {
    final status = trackingStatus.value;
    if (status == null) {
      return 'Abrir ajustes';
    }

    if (!status.isLocationServiceEnabled) {
      return 'Ativar GPS';
    }

    return 'Abrir ajustes';
  }

  String? get bannerMessage {
    if (!isOnline) {
      return 'Voce esta offline. O turno continua funcionando no aparelho e sera sincronizado quando a internet voltar.';
    }

    if (pendingShiftSyncCount.value > 0) {
      return pendingShiftSyncCount.value == 1
          ? 'Existe 1 turno pendente de sincronizacao com o servidor.'
          : 'Existem ${pendingShiftSyncCount.value} turnos pendentes de sincronizacao com o servidor.';
    }

    final trackingIssue = trackingStatus.value?.issueMessage;
    if (hasActiveShift && trackingIssue != null) {
      return trackingIssue;
    }

    return activeShiftError.value ??
        metricsError.value ??
        historyError.value ??
        ridesError.value ??
        recordingsError.value;
  }

  JourneyHistorySectionState get historySectionState =>
      JourneyHistorySectionState(
        shifts: List<ShiftEntity>.unmodifiable(shiftsList),
        totalCount: shiftsTotalCount.value,
        isLoadingMore: isLoadingMoreShifts.value,
        hasMore: hasMoreShifts.value,
        errorMessage: historyError.value,
      );

  JourneyRidesSectionState get ridesSectionState => JourneyRidesSectionState(
    selectedStatusFilter: selectedRideStatusFilter.value,
    visibleRides: List<RideEntity>.unmodifiable(filteredRidesList),
    totalVisibleCount: ridesHistoryTotalCount.value,
    periodLabel: dateLabel,
    isLoadingMore: isLoadingMoreRides.value,
    errorMessage: ridesError.value,
  );

  JourneyRecordingsSectionState get recordingsSectionState =>
      JourneyRecordingsSectionState(
        selectedStatusFilter: selectedRecordingStatusFilter.value,
        visibleRecordings: List<RecordingEntity>.unmodifiable(
          filteredRecordingsList,
        ),
        totalVisibleCount: recordingsHistoryTotalCount.value,
        periodLabel: dateLabel,
        isLoadingMore: isLoadingMoreRecordings.value,
        errorMessage: recordingsError.value,
      );

  JourneyPaymentMethodsSectionState get paymentMethodsSectionState =>
      JourneyPaymentMethodsSectionState(
        items: List<PaymentMethodSummaryItem>.unmodifiable(
          paymentMethodSummary,
        ),
        totalFinishedRides: paymentMethodFinishedRidesCount.value,
        mappedCount: mappedPaymentMethodCount,
        isExpanded: isPaymentMethodSectionExpanded.value,
      );

  JourneyOperationalSummaryData get operationalSummaryData =>
      JourneyOperationalSummaryData(
        netEarningsCents: operationalNetEarningsCents,
        grossEarningsCents: operationalGrossEarningsCents,
        totalCostsCents: operationalTotalCostsCents,
        totalRides: totalRides.value,
        margin: operationalMargin,
        isCostBreakdownExpanded: isOperationalCostBreakdownExpanded.value,
      );

  JourneyOperationalCostBreakdownData get operationalCostBreakdownData =>
      JourneyOperationalCostBreakdownData(
        variableCostsCents: operationalVariableCostsCents,
        fixedCostsCents: operationalFixedCostsCents,
        variableItems: List<OperationalCostBreakdownItem>.unmodifiable(
          operationalVariableCostItems,
        ),
        fixedItems: List<OperationalCostBreakdownItem>.unmodifiable(
          operationalFixedCostItems,
        ),
      );

  JourneyRideAnalysisData get rideAnalysisData => JourneyRideAnalysisData(
    totalRides: totalRides.value,
    totalTimeSeconds: rideAnalysisTotalTimeSeconds,
    totalKm: rideAnalysisTotalKm,
    grossEarningsCents: rideAnalysisGrossEarningsCents,
    variableCostsCents: rideAnalysisVariableCostsCents,
    profitCents: rideAnalysisProfitCents,
  );

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    isTrafficLightActive.value =
        runtimeCoordinator.accessibilityService.persistedTrafficLightActive;
    _journeyMetricsWorker = everAll([
      activeShift,
      currentKm,
      elapsedSeconds,
      totalShifts,
      selectedFilter,
      selectedDate,
      customStartDate,
      customEndDate,
      totalShiftDrivenKm,
    ], (_) => _syncDisplayedJourneyMetrics());
    runtimeCoordinator.bind(
      onConnectionChanged: _handleConnectionStatusChanged,
      onTrackingStatusChanged: _handleTrackingStatusUpdated,
      onRideChanged: () {
        unawaited(refreshJourneyData(silent: true, showErrors: false));
      },
      onAccessibilityChanged: _handleAccessibilityStatusChanged,
    );
    refreshJourneyData(showErrors: false);
    _loadTrackingStatus();
    runtimeCoordinator.loadAssistantStatus(
      onAssistantStateChanged: (isActive) => isAssistantActive.value = isActive,
    );
    runtimeCoordinator.loadRecordingStatus(
      onRecordingStateChanged: (recording) => activeRecording.value = recording,
    );
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    runtimeCoordinator.unbind();
    _timer?.cancel();
    _journeyMetricsWorker?.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    unawaited(refreshRuntimeStateAfterForegroundOpen());
  }

  Future<void> refreshRuntimeStateAfterForegroundOpen() async {
    _syncSelectedDateWithTodayIfNeeded();

    final currentShift = activeShift.value;
    if (currentShift != null) {
      _syncActiveShiftPresentation(currentShift);
    }

    await _loadActiveShift(showErrors: false);
  }

  void selectJourneyTab(int index) {
    selectedJourneyTabIndex.value = index.clamp(0, 2).toInt();
  }

  String get dateLabel {
    if (selectedFilter.value == 'custom' &&
        customStartDate.value != null &&
        customEndDate.value != null) {
      final start = customStartDate.value!;
      final end = customEndDate.value!;
      final startDay = start.day.toString().padLeft(2, '0');
      final startMonth = start.month.toString().padLeft(2, '0');
      final endDay = end.day.toString().padLeft(2, '0');
      final endMonth = end.month.toString().padLeft(2, '0');
      return '$startDay/$startMonth - $endDay/$endMonth';
    }

    final date = selectedDate.value;
    if (selectedFilter.value == 'day') {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    if (selectedFilter.value == 'month') {
      const months = [
        'Janeiro',
        'Fevereiro',
        'Marco',
        'Abril',
        'Maio',
        'Junho',
        'Julho',
        'Agosto',
        'Setembro',
        'Outubro',
        'Novembro',
        'Dezembro',
      ];
      return '${months[date.month - 1]} ${date.year}';
    }

    if (selectedFilter.value == 'year') {
      return '${date.year}';
    }

    if (selectedFilter.value == 'week') {
      final weekDay = date.weekday;
      final startOfWeek = date.subtract(Duration(days: weekDay - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      final startDay = startOfWeek.day.toString().padLeft(2, '0');
      final startMonth = startOfWeek.month.toString().padLeft(2, '0');
      final endDay = endOfWeek.day.toString().padLeft(2, '0');
      final endMonth = endOfWeek.month.toString().padLeft(2, '0');

      return '$startDay/$startMonth - $endDay/$endMonth';
    }

    return 'Semana de ${date.day}/${date.month}';
  }

  void nextDate() {
    if (selectedFilter.value == 'day') {
      selectedDate.value = selectedDate.value.add(const Duration(days: 1));
    } else if (selectedFilter.value == 'week') {
      selectedDate.value = selectedDate.value.add(const Duration(days: 7));
    } else if (selectedFilter.value == 'month') {
      selectedDate.value = DateTime(
        selectedDate.value.year,
        selectedDate.value.month + 1,
        1,
      );
    } else if (selectedFilter.value == 'year') {
      selectedDate.value = DateTime(selectedDate.value.year + 1, 1, 1);
    }
    refreshSelectedPeriodData(showErrors: false);
  }

  void previousDate() {
    if (selectedFilter.value == 'day') {
      selectedDate.value = selectedDate.value.subtract(const Duration(days: 1));
    } else if (selectedFilter.value == 'week') {
      selectedDate.value = selectedDate.value.subtract(const Duration(days: 7));
    } else if (selectedFilter.value == 'month') {
      selectedDate.value = DateTime(
        selectedDate.value.year,
        selectedDate.value.month - 1,
        1,
      );
    } else if (selectedFilter.value == 'year') {
      selectedDate.value = DateTime(selectedDate.value.year - 1, 1, 1);
    }
    refreshSelectedPeriodData(showErrors: false);
  }

  void changeFilter(String filter) {
    if (selectedFilter.value != filter) {
      selectedFilter.value = filter;
      refreshSelectedPeriodData(showErrors: false);
    }
  }

  void applyQuickFilter(String filter) {
    final now = DateTime.now();
    selectedDate.value = DateTime(now.year, now.month, now.day);
    customStartDate.value = null;
    customEndDate.value = null;
    selectedFilter.value = filter;
    refreshSelectedPeriodData(showErrors: false);
  }

  bool get isCurrentPeriodTodayFilter {
    if (selectedFilter.value != 'day') {
      return false;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = selectedDate.value;
    final selectedDay = DateTime(selected.year, selected.month, selected.day);
    return selectedDay == today;
  }

  void resetToTodayFilter() {
    applyQuickFilter('day');
  }

  void _syncSelectedDateWithTodayIfNeeded() {
    if (selectedFilter.value != 'day') {
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = selectedDate.value;
    final selectedDay = DateTime(selected.year, selected.month, selected.day);

    if (selectedDay == today) {
      return;
    }

    selectedDate.value = today;
    refreshJourneyData(silent: true, showErrors: false);
  }

  void setCustomRange(DateTime start, DateTime end) {
    selectedFilter.value = 'custom';
    customStartDate.value = start;
    customEndDate.value = end;
    refreshSelectedPeriodData(showErrors: false);
  }

  String formatCurrency(int cents) {
    final value = cents / 100;
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  double get margin {
    if (grossEarningsCents.value == 0) return 0.0;
    return (netEarningsCents.value / grossEarningsCents.value) * 100;
  }

  int get operationalGrossEarningsCents => grossEarningsCents.value;

  int get operationalTotalCostsCents {
    final settings = costsGainsSettings.value;
    if (settings == null) {
      return totalCostsCents.value;
    }

    return operationalFixedCostsCents + operationalVariableCostsCents;
  }

  int get operationalNetEarningsCents =>
      operationalGrossEarningsCents - operationalTotalCostsCents;

  double get operationalMargin {
    if (operationalGrossEarningsCents == 0) {
      return 0.0;
    }

    return (operationalNetEarningsCents / operationalGrossEarningsCents) * 100;
  }

  int get operationalFixedCostsCents {
    final settings = costsGainsSettings.value;
    if (settings == null) {
      return 0;
    }

    return _operationalFixedCostItems(
      settings,
    ).fold(0, (total, item) => total + item.amountCents);
  }

  int get operationalFuelCostsCents {
    final settings = costsGainsSettings.value;
    if (settings == null || settings.kmPerLiter <= 0) {
      return 0;
    }

    final litersUsed = operationalDrivenKm / settings.kmPerLiter;
    return (litersUsed * settings.fuelPricePerLiterCents).round();
  }

  int get rideAnalysisFuelCostsCents {
    final settings = costsGainsSettings.value;
    if (settings == null || settings.kmPerLiter <= 0) {
      return 0;
    }

    final litersUsed = rideAnalysisTotalKm / settings.kmPerLiter;
    return (litersUsed * settings.fuelPricePerLiterCents).round();
  }

  int get rideAnalysisPlatformFeeCents {
    final settings = costsGainsSettings.value;
    if (settings == null || settings.platformFeeValue <= 0) {
      return 0;
    }

    switch (settings.platformFeeType) {
      case PlatformFeeType.percentage:
        return (grossEarningsCents.value * (settings.platformFeeValue / 100))
            .round();
      case PlatformFeeType.fixed:
        return _diluteMonthlyCostForSelectedPeriod(
          monthlyCostCents: (settings.platformFeeValue * 100).round(),
          settings: settings,
        );
    }
  }

  int get rideAnalysisVariableCostsCents =>
      rideAnalysisFuelCostsCents + rideAnalysisPlatformFeeCents;

  int get rideAnalysisGrossEarningsCents => grossEarningsCents.value;

  int get rideAnalysisProfitCents =>
      rideAnalysisGrossEarningsCents - rideAnalysisVariableCostsCents;

  int get operationalVariablePlatformFeeCents {
    final settings = costsGainsSettings.value;
    if (settings == null ||
        settings.platformFeeType != PlatformFeeType.percentage ||
        settings.platformFeeValue <= 0) {
      return 0;
    }

    return (operationalGrossEarningsCents * (settings.platformFeeValue / 100))
        .round();
  }

  int get operationalVariableCostsCents =>
      operationalFuelCostsCents + operationalVariablePlatformFeeCents;

  double get operationalDrivenKm {
    var km = totalShiftDrivenKm.value;
    if (_shouldUseLiveJourneyKm) {
      km += currentKm.value;
    }
    return km;
  }

  bool get isRideAnalysisAvailable =>
      hasActiveShift ||
      _statisticsTotalTimeBaseSeconds > 0 ||
      totalShiftDrivenKm.value > 0 ||
      (int.tryParse(totalShifts.value) ?? 0) > 0;

  int get rideAnalysisTotalTimeSeconds => onlineAnalysisTotalTimeSeconds;

  double get rideAnalysisTotalKm => operationalDrivenKm;

  int get onlineAnalysisTotalTimeSeconds {
    var seconds = _statisticsTotalTimeBaseSeconds;
    if (_shouldUseLiveJourneyTime) {
      seconds += _statisticsLiveElapsedSeconds;
    }
    return seconds;
  }

  int get operationalGrossEarningsPerOnlineHourCents =>
      OnlineHourlyProjectionCalculator.calculateHourlyCents(
        earningsCents: operationalGrossEarningsCents,
        onlineTimeSeconds: onlineAnalysisTotalTimeSeconds,
      );

  int get operationalCostsPerOnlineHourCents =>
      OnlineHourlyProjectionCalculator.calculateHourlyCents(
        earningsCents: operationalTotalCostsCents,
        onlineTimeSeconds: onlineAnalysisTotalTimeSeconds,
      );

  int get operationalNetEarningsPerOnlineHourCents =>
      OnlineHourlyProjectionCalculator.calculateHourlyCents(
        earningsCents: operationalNetEarningsCents,
        onlineTimeSeconds: onlineAnalysisTotalTimeSeconds,
      );

  OnlineHourlyProjectionEntity projectGrossOnlineHourlyWithRide({
    required int offeredRideEarningsCents,
    required int offeredRideDurationSeconds,
  }) {
    return OnlineHourlyProjectionCalculator.project(
      historicalEarningsCents: operationalGrossEarningsCents,
      historicalOnlineTimeSeconds: onlineAnalysisTotalTimeSeconds,
      offeredRideEarningsCents: offeredRideEarningsCents,
      offeredRideDurationSeconds: offeredRideDurationSeconds,
    );
  }

  String get operationalCostBreakdownLabel {
    final settings = costsGainsSettings.value;
    if (settings == null) {
      return 'Baseado no custo atual das corridas';
    }

    return 'Fixos ${formatCurrency(operationalFixedCostsCents)} + variáveis ${formatCurrency(operationalVariableCostsCents)}';
  }

  List<OperationalCostBreakdownItem> get operationalVariableCostItems {
    final settings = costsGainsSettings.value;
    if (settings == null) {
      return operationalFuelCostsCents <= 0
          ? const []
          : [
              OperationalCostBreakdownItem(
                label: 'Combustível',
                amountCents: operationalFuelCostsCents,
              ),
            ];
    }

    final items = <OperationalCostBreakdownItem>[];

    if (operationalFuelCostsCents > 0) {
      items.add(
        OperationalCostBreakdownItem(
          label: 'Combustível',
          amountCents: operationalFuelCostsCents,
        ),
      );
    }

    if (operationalVariablePlatformFeeCents > 0) {
      items.add(
        OperationalCostBreakdownItem(
          label: settings.platformFeeType == PlatformFeeType.percentage
              ? 'Taxa da Plataforma'
              : 'Taxa Variável Plataforma',
          amountCents: operationalVariablePlatformFeeCents,
        ),
      );
    }

    return items;
  }

  List<OperationalCostBreakdownItem> get operationalFixedCostItems {
    final settings = costsGainsSettings.value;
    if (settings == null) {
      return const [];
    }

    return _operationalFixedCostItems(settings);
  }

  void toggleOperationalCostBreakdown() {
    isOperationalCostBreakdownExpanded.toggle();
  }

  Future<void> refreshJourneyData({
    bool silent = false,
    bool includeRides = true,
    bool showErrors = false,
    bool includeTrackingStatus = true,
  }) async {
    final generation = ++_periodRefreshGeneration;
    if (!silent) {
      isLoading.value = true;
    }

    final params = _buildQueryParams();

    try {
      await Future.wait([
        _loadActiveShift(
          showErrors: showErrors,
          includeTrackingStatus: includeTrackingStatus,
        ),
        _loadCostsGainsSettings(showErrors: showErrors),
        _loadStatistics(
          startDateParam: params.startDateParam,
          endDateParam: params.endDateParam,
          showErrors: showErrors,
          generation: generation,
        ),
        _loadHistory(
          startDateParam: params.startDateParam,
          endDateParam: params.endDateParam,
          showErrors: showErrors,
          reset: true,
          generation: generation,
        ),
        if (includeRides)
          _loadRidesData(
            startDateParam: params.startDateParam,
            endDateParam: params.endDateParam,
            showErrors: showErrors,
            generation: generation,
          ),
        _loadRecordingsData(
          startDateParam: params.startDateParam,
          endDateParam: params.endDateParam,
          showErrors: showErrors,
          generation: generation,
        ),
      ]);
    } catch (error, stackTrace) {
      _debugLog('[JourneyController] Erro inesperado ao carregar: $error');
      _debugStack(stackTrace);
    } finally {
      if (generation == _periodRefreshGeneration &&
          (!silent || isLoading.value)) {
        isLoading.value = false;
      }
    }

    if (_isCurrentPeriodRefresh(generation)) {
      unawaited(_prefetchAdjacentStatistics());
    }
  }

  Future<void> refreshSelectedPeriodData({required bool showErrors}) async {
    final generation = ++_periodRefreshGeneration;
    final params = _buildQueryParams();
    final cacheKey = _statisticsCacheKey(
      filter: selectedFilter.value,
      startDateParam: params.startDateParam,
      endDateParam: params.endDateParam,
    );
    final cachedStatistics = _statisticsCache[cacheKey];

    if (cachedStatistics != null) {
      metricsError.value = null;
      _applyStatistics(cachedStatistics);
    }

    await _loadStatistics(
      startDateParam: params.startDateParam,
      endDateParam: params.endDateParam,
      showErrors: showErrors,
      generation: generation,
    );

    if (!_isCurrentPeriodRefresh(generation)) {
      return;
    }

    unawaited(
      _refreshPeriodSupportData(
        params,
        showErrors: showErrors,
        generation: generation,
      ),
    );
    unawaited(_prefetchAdjacentStatistics());
  }

  Future<void> startShift() async {
    isStartingShift.value = true;
    final started = await shiftLifecycleCoordinator.startShift(
      onTrackingStatusResolved: (status) => trackingStatus.value = status,
      askToOpenTrackingSettings: _showStartShiftLocationDialog,
      openTrackingSettings: (status, {bool showFollowUpWarning = true}) =>
          _openTrackingSettings(
            status: status,
            showFollowUpWarning: showFollowUpWarning,
          ),
      showSuccess: _showSuccess,
      showError: _showError,
      normalizeErrorMessage: _normalizeErrorMessage,
    );
    if (started) {
      await refreshJourneyData(silent: true);
      await _loadTrackingStatus();
    }
    isStartingShift.value = false;
  }

  Future<bool> addManualShift({
    required double drivenKm,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    _debugLog(
      '[JourneyController] addManualShift solicitado: '
      'canAdd=$canAddManualShift isLoading=${isLoading.value} '
      'isAdding=${isAddingManualShift.value} hasActiveShift=$hasActiveShift '
      'km=$drivenKm start=$startTime end=$endTime.',
    );
    if (!canAddManualShift) {
      _debugLog(
        '[JourneyController] addManualShift bloqueado por canAddManualShift=false.',
      );
      return false;
    }

    isAddingManualShift.value = true;
    try {
      final result = await createManualShift(
        ManualShiftDraftEntity(
          totalDrivenKm: drivenKm,
          startTime: startTime,
          endTime: endTime,
        ),
      );

      return await result.fold(
        (failure) async {
          _debugLog(
            '[JourneyController] addManualShift falhou: '
            '${failure.runtimeType} ${failure.message}',
          );
          _showError('Nao foi possivel adicionar', failure.message);
          return false;
        },
        (finishResult) async {
          _debugLog(
            '[JourneyController] addManualShift sucesso: '
            'synced=${finishResult.synced} '
            'pending=${finishResult.pendingSyncCount}.',
          );
          if (finishResult.pendingSyncCount > 0) {
            _showWarning(
              'Turno salvo no aparelho',
              'O turno manual foi adicionado e sera sincronizado quando a internet voltar.',
            );
          } else {
            _showSuccess('Turno manual adicionado ao historico.');
          }

          await refreshJourneyData(silent: true, includeTrackingStatus: false);
          _debugLog(
            '[JourneyController] Historico atualizado apos turno manual.',
          );
          return true;
        },
      );
    } catch (error, stackTrace) {
      _debugLog('[JourneyController] addManualShift erro inesperado: $error');
      _debugStack(stackTrace);
      _showError(
        'Nao foi possivel adicionar',
        'Erro inesperado ao salvar turno manual.',
      );
      return false;
    } finally {
      isAddingManualShift.value = false;
      _debugLog('[JourneyController] addManualShift finalizado.');
    }
  }

  bool isDeletingShift(ShiftEntity shift) =>
      deletingShiftKey.value == _shiftActionKey(shift);

  Future<void> requestDeleteShift(ShiftEntity shift) async {
    if (isDeletingShift(shift)) {
      return;
    }

    final shouldDelete = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Excluir turno'),
        content: Text(
          'Deseja excluir o turno de ${shift.date}, das ${shift.startTime} as ${shift.endTime}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Get.back(result: true),
            child: const Text('Excluir'),
          ),
        ],
      ),
      barrierDismissible: true,
    );

    if (shouldDelete == true) {
      await deleteShift(shift);
    }
  }

  Future<bool> deleteShift(ShiftEntity shift) async {
    final key = _shiftActionKey(shift);
    deletingShiftKey.value = key;
    try {
      final result = await deleteShiftUseCase(shift);
      return await result.fold(
        (failure) async {
          _showError('Nao foi possivel excluir', failure.message);
          return false;
        },
        (_) async {
          _showSuccess('Turno excluido com sucesso.');
          await refreshJourneyData(silent: true);
          return true;
        },
      );
    } finally {
      if (deletingShiftKey.value == key) {
        deletingShiftKey.value = null;
      }
    }
  }

  Future<void> pauseShift() async {
    isPauseShiftLoading.value = true;
    final completed = await shiftLifecycleCoordinator.pauseOrResumeShift(
      isPaused: isShiftPaused,
      showSuccess: _showSuccess,
      showError: _showError,
      normalizeErrorMessage: _normalizeErrorMessage,
    );
    if (completed) {
      await refreshJourneyData(silent: true, includeRides: false);
      await _loadTrackingStatus();
    }
    isPauseShiftLoading.value = false;
  }

  Future<void> finishShift() async {
    isFinishingShift.value = true;
    final result = await shiftLifecycleCoordinator.finishShift(
      showSuccess: _showSuccess,
      showWarning: _showWarning,
      showError: _showError,
      normalizeErrorMessage: _normalizeErrorMessage,
    );
    if (result != null) {
      await refreshJourneyData(silent: true);
      await _loadTrackingStatus();
    }
    isFinishingShift.value = false;
  }

  Future<void> retryJourneyData() async {
    await refreshJourneyData(showErrors: false);
  }

  Future<void> loadMoreShifts() async {
    if (isLoadingMoreShifts.value || !hasMoreShifts.value) {
      return;
    }

    isLoadingMoreShifts.value = true;
    final params = _buildQueryParams();
    await _loadHistory(
      startDateParam: params.startDateParam,
      endDateParam: params.endDateParam,
      showErrors: false,
      reset: false,
    );
    isLoadingMoreShifts.value = false;
  }

  Future<void> loadMoreRides() async {}

  Future<void> loadMoreRecordings() async {}

  Future<void> openTrackingSettings() async {
    final status = trackingStatus.value;
    if (status == null) {
      return;
    }

    await _openTrackingSettings(status: status);
  }

  Future<void> _loadActiveShift({
    required bool showErrors,
    bool includeTrackingStatus = true,
  }) async {
    final result = await getActiveShift();
    result.fold(
      (failure) => _handleLoadFailure(
        context: 'turno ativo',
        message: failure.message,
        showErrors: showErrors,
      ),
      (shift) {
        activeShiftError.value = null;
        activeShift.value = shift;
        runtimeCoordinator.accessibilityService.setJourneyActive(shift != null);
        _syncActiveShiftPresentation(shift);
      },
    );
    if (includeTrackingStatus) {
      await _loadTrackingStatus();
    }
  }

  Future<void> _loadStatistics({
    required String? startDateParam,
    required String? endDateParam,
    required bool showErrors,
    int? generation,
  }) async {
    final filter = selectedFilter.value;
    final statsResult = await getDailyStatistics(
      filter: filter,
      date: startDateParam,
      endDate: endDateParam,
    );

    if (!_isCurrentPeriodRefresh(generation)) {
      return;
    }

    statsResult.fold(
      (failure) => _handleLoadFailure(
        context: 'metricas',
        message: failure.message,
        showErrors: showErrors,
      ),
      (stats) {
        metricsError.value = null;
        _rememberStatistics(
          filter: filter,
          startDateParam: startDateParam,
          endDateParam: endDateParam,
          statistics: stats,
        );
        _applyStatistics(stats);
      },
    );
  }

  Future<void> _refreshPeriodSupportData(
    ({String? startDateParam, String? endDateParam}) params, {
    required bool showErrors,
    required int generation,
  }) async {
    await Future.wait([
      _loadHistory(
        startDateParam: params.startDateParam,
        endDateParam: params.endDateParam,
        showErrors: showErrors,
        reset: true,
        generation: generation,
      ),
      _loadRidesData(
        startDateParam: params.startDateParam,
        endDateParam: params.endDateParam,
        showErrors: showErrors,
        generation: generation,
      ),
      _loadRecordingsData(
        startDateParam: params.startDateParam,
        endDateParam: params.endDateParam,
        showErrors: showErrors,
        generation: generation,
      ),
    ]);
  }

  void _applyStatistics(JourneyStatisticsEntity stats) {
    totalShifts.value = stats.totalShifts.toString();
    _statisticsTotalTimeBaseSeconds =
        JourneyStatisticsDisplayComposer.parseHmsToSeconds(stats.totalTime);
    totalShiftDrivenKm.value = stats.totalDrivenKmValue > 0
        ? stats.totalDrivenKmValue
        : JourneyStatisticsDisplayComposer.parseKmLabelToDouble(stats.drivenKm);

    totalRides.value = stats.rideStats.totalRides;
    grossEarningsCents.value = stats.rideStats.grossEarningsCents;
    netEarningsCents.value = stats.rideStats.netEarningsCents;
    totalCostsCents.value = stats.rideStats.totalCostsCents;
    ridesTotalKm.value = stats.rideStats.ridesTotalKm;
    ridesTotalTime.value = stats.rideStats.ridesTotalTime;
    _syncDisplayedJourneyMetrics();
  }

  Future<void> _loadCostsGainsSettings({required bool showErrors}) async {
    final useCase = getCostsGainsSettings;
    if (useCase == null) {
      costsGainsSettings.value = null;
      return;
    }

    final result = await useCase();
    result.fold((failure) {
      costsGainsSettings.value = null;
      _debugLog(
        '[JourneyController] Erro ao carregar configuracoes de custos: ${failure.message}',
      );
    }, (settings) => costsGainsSettings.value = settings);
  }

  Future<void> _loadHistory({
    required String? startDateParam,
    required String? endDateParam,
    required bool showErrors,
    required bool reset,
    int? generation,
  }) async {
    _debugLog(
      '[JourneyController] _loadHistory inicio: '
      'filter=${selectedFilter.value} date=$startDateParam '
      'endDate=$endDateParam reset=$reset offset=${reset ? 0 : shiftsList.length} '
      'limit=$_historyPageSize generation=$generation.',
    );
    final historyResult = await getShiftHistory(
      filter: selectedFilter.value,
      date: startDateParam,
      endDate: endDateParam,
      offset: reset ? 0 : shiftsList.length,
      limit: _historyPageSize,
    );

    if (!_isCurrentPeriodRefresh(generation)) {
      return;
    }

    historyResult.fold(
      (failure) => _handleLoadFailure(
        context: 'historico',
        message: failure.message,
        showErrors: showErrors,
      ),
      (shiftsPage) {
        _debugLog(
          '[JourneyController] _loadHistory sucesso: '
          'items=${shiftsPage.items.length} total=${shiftsPage.totalCount} '
          'hasMore=${shiftsPage.hasMore} ids=${shiftsPage.items.map((shift) => shift.remoteShiftId ?? shift.localId).toList()} '
          'datas=${shiftsPage.items.map((shift) => '${shift.date} ${shift.startTime}-${shift.endTime}').toList()}.',
        );
        historyError.value = null;
        if (reset) {
          shiftsList.assignAll(shiftsPage.items);
        } else {
          shiftsList.addAll(shiftsPage.items);
        }
        shiftsCount.value = shiftsList.length;
        shiftsTotalCount.value = shiftsPage.totalCount;
        hasMoreShifts.value = shiftsPage.hasMore;
        pendingShiftSyncCount.value = shiftsList
            .where((shift) => shift.isPendingSync)
            .length;
      },
    );
  }

  Future<void> _loadRidesData({
    required String? startDateParam,
    required String? endDateParam,
    required bool showErrors,
    int? generation,
  }) async {
    const limit = 100;
    var offset = 0;
    final allRides = <RideEntity>[];

    while (true) {
      final ridesResult = await getRidesUseCase(
        period: selectedFilter.value,
        date: startDateParam,
        endDate: endDateParam,
        status: null,
        offset: offset,
        limit: limit,
      );

      if (!_isCurrentPeriodRefresh(generation)) {
        return;
      }

      final shouldContinue = await ridesResult.fold<Future<bool>>(
        (failure) async {
          ridesList.clear();
          ridesHistoryTotalCount.value = 0;
          hasMoreRides.value = false;
          paymentMethodSummary.clear();
          paymentMethodFinishedRidesCount.value = 0;
          _handleLoadFailure(
            context: 'corridas',
            message: failure.message,
            showErrors: showErrors,
          );
          return false;
        },
        (ridesPage) async {
          ridesError.value = null;
          allRides.addAll(ridesPage.items);
          offset += ridesPage.items.length;
          return ridesPage.hasMore && ridesPage.items.isNotEmpty;
        },
      );

      if (!shouldContinue) {
        break;
      }
    }

    if (!_isCurrentPeriodRefresh(generation)) {
      return;
    }

    if (ridesError.value != null) {
      return;
    }

    ridesList.assignAll(_sortRidesForPresentation(allRides));
    hasMoreRides.value = false;
    ridesHistoryTotalCount.value = filteredRidesCount;
    _rebuildPaymentMethodSummary();
  }

  Future<void> _loadRecordingsData({
    required String? startDateParam,
    required String? endDateParam,
    required bool showErrors,
    int? generation,
  }) async {
    const limit = 100;
    var offset = 0;
    final allRecordings = <RecordingEntity>[];

    while (true) {
      final recordingsResult = await getRecordingsUseCase(
        period: selectedFilter.value,
        date: startDateParam,
        endDate: endDateParam,
        status: null,
        offset: offset,
        limit: limit,
      );

      if (!_isCurrentPeriodRefresh(generation)) {
        return;
      }

      final shouldContinue = await recordingsResult.fold<Future<bool>>(
        (failure) async {
          recordingsList.clear();
          recordingsHistoryTotalCount.value = 0;
          hasMoreRecordings.value = false;
          _handleLoadFailure(
            context: 'gravacoes',
            message: failure.message,
            showErrors: showErrors,
          );
          return false;
        },
        (recordingsPage) async {
          recordingsError.value = null;
          allRecordings.addAll(recordingsPage.items);
          offset += recordingsPage.items.length;
          return recordingsPage.hasMore && recordingsPage.items.isNotEmpty;
        },
      );

      if (!shouldContinue) {
        break;
      }
    }

    if (!_isCurrentPeriodRefresh(generation) || recordingsError.value != null) {
      return;
    }

    allRecordings.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    recordingsList.assignAll(allRecordings);
    hasMoreRecordings.value = false;
    recordingsHistoryTotalCount.value = filteredRecordingsCount;
  }

  List<RideEntity> _sortRidesForPresentation(List<RideEntity> rides) {
    final sorted = List<RideEntity>.from(rides);
    sorted.sort((a, b) {
      final statusComparison = _rideStatusPriority(
        a.status,
      ).compareTo(_rideStatusPriority(b.status));
      if (statusComparison != 0) {
        return statusComparison;
      }

      final arrivalComparison = _rideArrivalRank(
        b,
      ).compareTo(_rideArrivalRank(a));
      if (arrivalComparison != 0) {
        return arrivalComparison;
      }

      return b.id.compareTo(a.id);
    });
    return sorted;
  }

  int _rideStatusPriority(String status) {
    switch (status.trim().toUpperCase()) {
      case 'PENDING':
        return 0;
      case 'FINISHED':
        return 1;
      case 'CANCELED':
      case 'CANCELLED':
        return 2;
      default:
        return 3;
    }
  }

  int _rideArrivalRank(RideEntity ride) {
    return ride.id.isNegative ? -ride.id : ride.id;
  }

  String? _normalizePaymentMethod(String? paymentMethod) {
    final normalized = paymentMethod?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    switch (normalized) {
      case 'CARD':
      case 'CREDIT_CARD':
      case 'DEBIT_CARD':
      case 'CREDIT_OR_DEBIT_CARD':
        return 'CARD';
      case 'CASH':
      case 'MONEY':
        return 'CASH';
      case 'PIX':
        return 'PIX';
      case 'VOUCHER':
        return 'VOUCHER';
      default:
        return normalized;
    }
  }

  bool _matchesSelectedRideStatus(RideEntity ride) {
    final selectedStatus = _selectedRideStatusQuery;
    if (selectedStatus == null) {
      return true;
    }

    return ride.status.trim().toUpperCase() == selectedStatus;
  }

  bool _matchesSelectedRecordingStatus(RecordingEntity recording) {
    final selectedStatus = _selectedRecordingStatusQuery;
    if (selectedStatus == null) {
      return true;
    }

    return recording.status.trim().toUpperCase() == selectedStatus;
  }

  void _rebuildPaymentMethodSummary() {
    final counts = <String, int>{};

    for (final ride in ridesList) {
      if (ride.status.trim().toUpperCase() != 'FINISHED') {
        continue;
      }

      final normalizedPaymentMethod = _normalizePaymentMethod(
        ride.paymentMethod,
      );
      if (normalizedPaymentMethod == null) {
        continue;
      }

      counts.update(
        normalizedPaymentMethod,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    paymentMethodFinishedRidesCount.value = ridesList
        .where((ride) => ride.status.trim().toUpperCase() == 'FINISHED')
        .length;
    paymentMethodSummary.assignAll(
      counts.entries
          .map(
            (entry) =>
                PaymentMethodSummaryItem(code: entry.key, count: entry.value),
          )
          .toList()
        ..sort((a, b) => b.count.compareTo(a.count)),
    );
  }

  String? get _selectedRideStatusQuery {
    switch (selectedRideStatusFilter.value) {
      case 'Pendentes':
        return 'PENDING';
      case 'Finalizados':
        return 'FINISHED';
      case 'Cancelados':
        return 'CANCELED';
      default:
        return null;
    }
  }

  String? get _selectedRecordingStatusQuery {
    switch (selectedRecordingStatusFilter.value) {
      case 'Gravando':
        return RecordingStatus.recording;
      case 'Concluidas':
        return RecordingStatus.completed;
      case 'Falhas':
        return RecordingStatus.failed;
      default:
        return null;
    }
  }

  ({String? startDateParam, String? endDateParam}) _buildQueryParams() {
    if (selectedFilter.value == 'custom' &&
        customStartDate.value != null &&
        customEndDate.value != null) {
      return (
        startDateParam: customStartDate.value!.toIso8601String(),
        endDateParam: customEndDate.value!.toIso8601String(),
      );
    }

    return (
      startDateParam: selectedDate.value.toIso8601String(),
      endDateParam: null,
    );
  }

  bool _isCurrentPeriodRefresh(int? generation) {
    return generation == null || generation == _periodRefreshGeneration;
  }

  void _rememberStatistics({
    required String filter,
    required String? startDateParam,
    required String? endDateParam,
    required JourneyStatisticsEntity statistics,
  }) {
    final key = _statisticsCacheKey(
      filter: filter,
      startDateParam: startDateParam,
      endDateParam: endDateParam,
    );
    _statisticsCache.remove(key);
    _statisticsCache[key] = statistics;

    while (_statisticsCache.length > _statisticsCacheLimit) {
      _statisticsCache.remove(_statisticsCache.keys.first);
    }
  }

  String _statisticsCacheKey({
    required String filter,
    required String? startDateParam,
    required String? endDateParam,
  }) {
    return '$filter|${startDateParam ?? ''}|${endDateParam ?? ''}';
  }

  Future<void> _prefetchAdjacentStatistics() async {
    if (selectedFilter.value == 'custom') {
      return;
    }

    final filter = selectedFilter.value;
    final currentDate = selectedDate.value;
    final adjacentDates = [
      _resolveAdjacentDate(currentDate, previous: true, filter: filter),
      _resolveAdjacentDate(currentDate, previous: false, filter: filter),
    ];

    for (final date in adjacentDates) {
      final startDateParam = date.toIso8601String();
      final cacheKey = _statisticsCacheKey(
        filter: filter,
        startDateParam: startDateParam,
        endDateParam: null,
      );

      if (_statisticsCache.containsKey(cacheKey)) {
        continue;
      }

      final result = await getDailyStatistics(
        filter: filter,
        date: startDateParam,
        endDate: null,
      );
      result.fold(
        (_) {},
        (statistics) => _rememberStatistics(
          filter: filter,
          startDateParam: startDateParam,
          endDateParam: null,
          statistics: statistics,
        ),
      );
    }
  }

  DateTime _resolveAdjacentDate(
    DateTime date, {
    required bool previous,
    required String filter,
  }) {
    final direction = previous ? -1 : 1;

    switch (filter) {
      case 'week':
        return date.add(Duration(days: 7 * direction));
      case 'month':
        return DateTime(date.year, date.month + direction, 1);
      case 'year':
        return DateTime(date.year + direction, 1, 1);
      case 'day':
      default:
        return date.add(Duration(days: direction));
    }
  }

  void _syncActiveShiftPresentation(ActiveShiftEntity? shift) {
    if (shift == null) {
      _timer?.cancel();
      elapsedSeconds.value = 0;
      startTimeStr.value = '--:--';
      currentKm.value = 0.0;
      _syncDisplayedJourneyMetrics();
      return;
    }

    startTimeStr.value =
        '${shift.startTime.hour.toString().padLeft(2, '0')}:${shift.startTime.minute.toString().padLeft(2, '0')}';
    currentKm.value = shift.currentDrivenKm;

    if (shift.isPaused) {
      _timer?.cancel();
      final pausedReference = shift.pausedAt ?? DateTime.now();
      elapsedSeconds.value = _computeElapsedSeconds(
        startTime: shift.startTime,
        reference: pausedReference,
      );
      _syncDisplayedJourneyMetrics();
      return;
    }

    _startElapsedTimer(shift.startTime);
    _syncDisplayedJourneyMetrics();
  }

  void _startElapsedTimer(DateTime startTime) {
    _timer?.cancel();
    _updateElapsed(startTime);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateElapsed(startTime);
    });
  }

  void _updateElapsed(DateTime startTime) {
    elapsedSeconds.value = _computeElapsedSeconds(
      startTime: startTime,
      reference: DateTime.now(),
    );
  }

  int _computeElapsedSeconds({
    required DateTime startTime,
    required DateTime reference,
  }) {
    final total = reference.difference(startTime).inSeconds;
    return total < 0 ? 0 : total;
  }

  Future<void> _handleConnectionStatusChanged(bool isOnlineNow) async {
    if (!isOnlineNow) {
      return;
    }

    final syncedCount = await runtimeCoordinator.syncPendingShifts();
    if (syncedCount > 0) {
      _showSuccess(
        syncedCount == 1
            ? '1 turno pendente foi sincronizado.'
            : '$syncedCount turnos pendentes foram sincronizados.',
      );
    }
    if (syncedCount > 0 || pendingShiftSyncCount.value > 0) {
      await refreshJourneyData(silent: true, showErrors: false);
    }
  }

  Future<void> _loadTrackingStatus() async {
    final status = await runtimeCoordinator.loadTrackingStatus();
    if (status != null) {
      _handleTrackingStatusUpdated(status);
    }
  }

  void _handleLoadFailure({
    required String context,
    required String message,
    required bool showErrors,
  }) {
    final normalizedMessage = _normalizeErrorMessage(message);

    switch (context) {
      case 'turno ativo':
        activeShiftError.value =
            'Nao foi possivel atualizar o turno atual. $normalizedMessage';
        break;
      case 'metricas':
        metricsError.value =
            'Nao foi possivel carregar as metricas. $normalizedMessage';
        break;
      case 'historico':
        historyError.value =
            'Nao foi possivel carregar o historico de turnos. $normalizedMessage';
        break;
      case 'corridas':
        ridesError.value =
            'Nao foi possivel carregar as corridas. $normalizedMessage';
        break;
      case 'gravacoes':
        recordingsError.value =
            'Nao foi possivel carregar as gravacoes. $normalizedMessage';
        break;
    }

    if (showErrors) {
      _showError('Erro', normalizedMessage);
      return;
    }

    _debugLog(
      '[JourneyController] Erro ao carregar $context: $normalizedMessage',
    );
  }

  void _handleTrackingStatusUpdated(LocationTrackingStatusEntity status) {
    final now = DateTime.now();
    final shouldRefreshDistanceUi =
        _lastTrackingUiRefreshAt == null ||
        _lastTrackingUiDistanceMeters == null ||
        (status.totalDistanceMeters - _lastTrackingUiDistanceMeters!).abs() >=
            _trackingUiRefreshDistanceMeters ||
        now.difference(_lastTrackingUiRefreshAt!) >= _trackingUiRefreshInterval;

    final previousStatus = trackingStatus.value;
    final shouldRefreshStatusUi =
        previousStatus == null ||
        previousStatus.issueMessage != status.issueMessage ||
        previousStatus.isTrackingActive != status.isTrackingActive ||
        previousStatus.isPaused != status.isPaused ||
        previousStatus.idleTimeSeconds != status.idleTimeSeconds ||
        previousStatus.isLocationServiceEnabled !=
            status.isLocationServiceEnabled ||
        previousStatus.hasForegroundPermission !=
            status.hasForegroundPermission ||
        previousStatus.hasBackgroundPermission !=
            status.hasBackgroundPermission ||
        previousStatus.isPreciseLocation != status.isPreciseLocation;

    if (shouldRefreshStatusUi || shouldRefreshDistanceUi) {
      trackingStatus.value = status;
      _lastTrackingUiRefreshAt = now;
      _lastTrackingUiDistanceMeters = status.totalDistanceMeters;
    }

    if (!hasActiveShift) {
      return;
    }

    final trackedKm = status.totalDistanceMeters / 1000;
    if (shouldRefreshDistanceUi || shouldRefreshStatusUi) {
      currentKm.value = trackedKm;
    }

    final shift = activeShift.value;
    if (shift != null && (shouldRefreshDistanceUi || shouldRefreshStatusUi)) {
      activeShift.value = shift.copyWith(
        currentDrivenKm: trackedKm,
        idleTimeSeconds: status.idleTimeSeconds,
      );
      _syncDisplayedJourneyMetrics();
    }
  }

  void _syncDisplayedJourneyMetrics() {
    final displayData = JourneyStatisticsDisplayComposer.compose(
      baseTotalTimeSeconds: _statisticsTotalTimeBaseSeconds,
      baseDrivenKm: totalShiftDrivenKm.value,
      shiftsCount: int.tryParse(totalShifts.value) ?? 0,
      liveElapsedSeconds: _statisticsLiveElapsedSeconds,
      liveDrivenKm: currentKm.value,
      includeLiveTime: _shouldUseLiveJourneyTime,
      includeLiveKm: _shouldUseLiveJourneyKm,
    );

    totalTime.value = displayData.totalTime;
    averageTime.value = displayData.averageTime;
    drivenKm.value = displayData.drivenKm;
  }

  String _normalizeErrorMessage(String message) {
    final normalized = message.trim();
    final lower = normalized.toLowerCase();

    if (lower.contains('socketexception') ||
        lower.contains('connection error') ||
        lower.contains('connection timed out') ||
        lower.contains('connection aborted') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable')) {
      return 'Verifique sua conexao e tente novamente.';
    }

    if (lower.contains('timeout')) {
      return 'O servidor demorou para responder. Tente novamente em instantes.';
    }

    if (normalized.isEmpty) {
      return 'Ocorreu um erro inesperado. Tente novamente.';
    }

    return normalized;
  }

  double _selectedPeriodWorkDays(CostsGainsSettingsEntity settings) {
    final totalDays = _selectedPeriodDayCount;
    if (totalDays <= 0 || settings.workDaysPerWeek <= 0) {
      return 0;
    }

    if (selectedFilter.value == 'day') {
      return 1;
    }

    return totalDays * (settings.workDaysPerWeek / 7);
  }

  List<OperationalCostBreakdownItem> _operationalFixedCostItems(
    CostsGainsSettingsEntity settings,
  ) {
    final items = <OperationalCostBreakdownItem>[
      OperationalCostBreakdownItem(
        label: 'Prestação/Aluguel',
        amountCents: _diluteMonthlyCostForSelectedPeriod(
          monthlyCostCents: settings.financeOrRentMonthlyCents,
          settings: settings,
        ),
      ),
      OperationalCostBreakdownItem(
        label: 'Seguro',
        amountCents: _diluteMonthlyCostForSelectedPeriod(
          monthlyCostCents: settings.insuranceMonthlyCents,
          settings: settings,
        ),
      ),
      OperationalCostBreakdownItem(
        label: 'Manutenção',
        amountCents: _diluteMonthlyCostForSelectedPeriod(
          monthlyCostCents: settings.maintenanceMonthlyCents,
          settings: settings,
        ),
      ),
      OperationalCostBreakdownItem(
        label: 'Impostos',
        amountCents: _diluteMonthlyCostForSelectedPeriod(
          monthlyCostCents: (settings.annualTaxesCents / 12).round(),
          settings: settings,
        ),
      ),
    ];

    if (settings.platformFeeType == PlatformFeeType.fixed &&
        settings.platformFeeValue > 0) {
      items.add(
        OperationalCostBreakdownItem(
          label: 'Taxa Fixa Plataforma',
          amountCents: _diluteMonthlyCostForSelectedPeriod(
            monthlyCostCents: (settings.platformFeeValue * 100).round(),
            settings: settings,
          ),
        ),
      );
    }

    return items.where((item) => item.amountCents > 0).toList();
  }

  int _diluteMonthlyCostForSelectedPeriod({
    required int monthlyCostCents,
    required CostsGainsSettingsEntity settings,
  }) {
    if (monthlyCostCents <= 0) {
      return 0;
    }

    final monthlyWorkDays = settings.workDaysPerWeek * 4.33;
    if (monthlyWorkDays <= 0) {
      return 0;
    }

    final fixedCostPerWorkDayCents = monthlyCostCents / monthlyWorkDays;
    return (fixedCostPerWorkDayCents * _selectedPeriodWorkDays(settings))
        .round();
  }

  int get _selectedPeriodDayCount {
    final range = _selectedRange;
    return range.endExclusive.difference(range.start).inDays;
  }

  bool get _selectedRangeIncludesActiveShift {
    final shift = activeShift.value;
    if (shift == null) {
      return false;
    }

    final now = DateTime.now();
    final range = _selectedRange;
    final shiftStart = shift.startTime;
    final includesNow =
        !now.isBefore(range.start) && now.isBefore(range.endExclusive);
    final includesShiftStart =
        !shiftStart.isBefore(range.start) &&
        shiftStart.isBefore(range.endExclusive);

    return includesNow || includesShiftStart;
  }

  bool get _shouldUseLiveJourneyKm =>
      hasActiveShift && _selectedRangeIncludesActiveShift;

  bool get _shouldUseLiveJourneyTime =>
      hasActiveShift && _selectedRangeIncludesActiveShift;

  int get _statisticsLiveElapsedSeconds {
    if (elapsedSeconds.value <= 0) {
      return 0;
    }
    return elapsedSeconds.value;
  }

  ({DateTime start, DateTime endExclusive}) get _selectedRange {
    DateTime startOfDay(DateTime value) =>
        DateTime(value.year, value.month, value.day);

    if (selectedFilter.value == 'custom' &&
        customStartDate.value != null &&
        customEndDate.value != null) {
      final start = startOfDay(customStartDate.value!);
      final endExclusive = startOfDay(
        customEndDate.value!,
      ).add(const Duration(days: 1));
      return (start: start, endExclusive: endExclusive);
    }

    final date = selectedDate.value;

    switch (selectedFilter.value) {
      case 'week':
        final start = startOfDay(
          date.subtract(Duration(days: date.weekday - 1)),
        );
        return (start: start, endExclusive: start.add(const Duration(days: 7)));
      case 'month':
        final start = DateTime(date.year, date.month);
        return (
          start: start,
          endExclusive: DateTime(date.year, date.month + 1),
        );
      case 'year':
        final start = DateTime(date.year);
        return (start: start, endExclusive: DateTime(date.year + 1));
      case 'day':
      default:
        final start = startOfDay(date);
        return (start: start, endExclusive: start.add(const Duration(days: 1)));
    }
  }

  Future<bool?> _showStartShiftLocationDialog(
    LocationTrackingStatusEntity status,
  ) {
    return Get.dialog<bool>(
      AlertDialog(
        title: Text(_locationDialogTitle(status)),
        content: Text(_locationDialogMessage(status)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Agora nao'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text(_locationDialogConfirmLabel(status)),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  String _locationDialogTitle(LocationTrackingStatusEntity status) {
    if (!status.isLocationServiceEnabled) {
      return 'Ativar localizacao';
    }

    if (!status.hasBackgroundPermission) {
      return 'Permitir o tempo todo';
    }

    if (!status.hasForegroundPermission) {
      return 'Liberar localizacao';
    }

    if (!status.isPreciseLocation) {
      return 'Ativar localizacao precisa';
    }

    return 'Revisar localizacao';
  }

  String _locationDialogMessage(LocationTrackingStatusEntity status) {
    if (!status.isLocationServiceEnabled) {
      return 'Para iniciar o turno, ative o GPS do aparelho. O rastreamento da jornada depende da localizacao ligada durante todo o turno.';
    }

    if (!status.hasBackgroundPermission) {
      return 'Para iniciar o turno, abra as configuracoes do app e marque a localizacao como "Permitir o tempo todo". Assim a jornada continua sendo rastreada mesmo com o app fechado.';
    }

    if (!status.hasForegroundPermission) {
      return 'Para iniciar o turno, libere a localizacao do app nas configuracoes e volte para tentar novamente.';
    }

    if (!status.isPreciseLocation) {
      return 'Para iniciar o turno, troque a localizacao aproximada para precisa nas configuracoes do app.';
    }

    return 'Revise as configuracoes de localizacao antes de iniciar o turno.';
  }

  String _locationDialogConfirmLabel(LocationTrackingStatusEntity status) {
    if (!status.isLocationServiceEnabled) {
      return 'Ir para GPS';
    }

    return 'Ir para config';
  }

  Future<void> _openTrackingSettings({
    required LocationTrackingStatusEntity status,
    bool showFollowUpWarning = true,
  }) async {
    final opened = await _openRequiredLocationSettings(status);

    if (!opened) {
      _showWarning(
        'Nao foi possivel abrir os ajustes',
        'Abra manualmente as configuracoes do app e revise permissao de localizacao, GPS e localizacao precisa.',
      );
      return;
    }

    if (!showFollowUpWarning) {
      return;
    }

    _showWarning(
      'Revise a localizacao',
      !status.isLocationServiceEnabled
          ? 'Ative o GPS do aparelho e volte para continuar o turno.'
          : 'Marque "Permitir o tempo todo" e mantenha a localizacao precisa ativada.',
    );
  }

  Future<bool> _openRequiredLocationSettings(
    LocationTrackingStatusEntity status,
  ) {
    if (!status.isLocationServiceEnabled) {
      return Geolocator.openLocationSettings();
    }

    if (status.hasForegroundPermission && !status.hasBackgroundPermission) {
      return const LocationPermissionSettings()
          .openBackgroundLocationPermissionSettings();
    }

    return Geolocator.openAppSettings();
  }

  void _showSuccess(String message) {
    _showSnackbar(
      title: 'Sucesso',
      message: message,
      backgroundColor: const Color(0xFF03A696),
    );
  }

  void _showWarning(String title, String message) {
    _showSnackbar(
      title: title,
      message: message,
      backgroundColor: Colors.orangeAccent,
    );
  }

  void _showError(String title, String message) {
    _showSnackbar(
      title: title,
      message: message,
      backgroundColor: Colors.redAccent,
    );
  }

  void _showSnackbar({
    required String title,
    required String message,
    required Color backgroundColor,
  }) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    AppSnackbar.show(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      margin: const EdgeInsets.all(8),
      borderRadius: 8,
    );
  }

  Future<void> toggleTrafficLight() async {
    if (runtimeCoordinator.accessibilityService.isServiceEnabled.value) {
      isTrafficLightActive.value = !isTrafficLightActive.value;
      await runtimeCoordinator.accessibilityService.setTrafficLightActive(
        isTrafficLightActive.value,
      );
      if (!isTrafficLightActive.value) {
        isWaitingAccessibilityActivation.value = false;
      }
      return;
    }

    if (isTrafficLightActive.value) {
      isTrafficLightActive.value = false;
      isWaitingAccessibilityActivation.value = false;
      await runtimeCoordinator.accessibilityService.setTrafficLightActive(
        false,
      );
      return;
    }

    final shouldOpenSettings = await _showAccessibilityDialog();
    if (shouldOpenSettings == true) {
      isWaitingAccessibilityActivation.value = true;
      await runtimeCoordinator.accessibilityService
          .requestAccessibilityPermission();
    }
  }

  Future<void> ensureTrafficLightActive() async {
    if (isTrafficLightActive.value ||
        runtimeCoordinator.accessibilityService.persistedTrafficLightActive) {
      isTrafficLightActive.value = true;
      if (runtimeCoordinator.accessibilityService.isServiceEnabled.value) {
        await runtimeCoordinator.accessibilityService.setTrafficLightActive(
          true,
        );
      }
      return;
    }

    if (runtimeCoordinator.accessibilityService.isServiceEnabled.value) {
      isTrafficLightActive.value = true;
      await runtimeCoordinator.accessibilityService.setTrafficLightActive(true);
      return;
    }

    final shouldOpenSettings = await _showAccessibilityDialog();
    if (shouldOpenSettings == true) {
      isWaitingAccessibilityActivation.value = true;
      await runtimeCoordinator.accessibilityService
          .requestAccessibilityPermission();
    }
  }

  void _handleAccessibilityStatusChanged(bool isEnabled) {
    if (isEnabled && isWaitingAccessibilityActivation.value) {
      isTrafficLightActive.value = true;
      isWaitingAccessibilityActivation.value = false;
      runtimeCoordinator.accessibilityService.setTrafficLightActive(true);
      AppSnackbar.show(
        'Semaforo ativado',
        'A acessibilidade foi habilitada e o semaforo ja esta pronto para uso.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (isEnabled &&
        runtimeCoordinator.accessibilityService.persistedTrafficLightActive) {
      isTrafficLightActive.value = true;
    }
  }

  Future<bool?> _showAccessibilityDialog() {
    return Get.dialog<bool>(
      AlertDialog(
        title: const Text('Ativar acessibilidade'),
        content: const Text(
          'Para ativar o semaforo, habilite o servico de acessibilidade nas configuracoes do Android.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Ir para config'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  void activateTrafficLight() {
    unawaited(ensureTrafficLightActive());
  }

  Future<void> toggleAssistant() async {
    if (isAssistantBusy.value) return;
    await runtimeCoordinator.toggleAssistant(
      isAssistantActive: isAssistantActive.value,
      onAssistantStateChanged: (isActive) => isAssistantActive.value = isActive,
      onBusyStateChanged: (isBusy) => isAssistantBusy.value = isBusy,
      showSuccess: (title, message) => _showSnackbar(
        title: title,
        message: message,
        backgroundColor: const Color(0xFF03A696),
      ),
      showWarning: (title, message) => _showSnackbar(
        title: title,
        message: message,
        backgroundColor: Colors.orangeAccent,
      ),
      showError: (title, message) => _showSnackbar(
        title: title,
        message: message,
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> toggleRecording() async {
    if (isRecordingBusy.value) return;
    await runtimeCoordinator.toggleRecording(
      isRecordingActive: isRecordingActive,
      onRecordingStateChanged: (recording) => activeRecording.value = recording,
      onBusyStateChanged: (isBusy) => isRecordingBusy.value = isBusy,
      showSuccess: (title, message) {
        _showSnackbar(
          title: title,
          message: message,
          backgroundColor: const Color(0xFF03A696),
        );
        refreshJourneyData(silent: true, showErrors: false);
      },
      showWarning: (title, message) => _showSnackbar(
        title: title,
        message: message,
        backgroundColor: Colors.orangeAccent,
      ),
      showError: (title, message) => _showSnackbar(
        title: title,
        message: message,
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  void _debugStack(StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

class OperationalCostBreakdownItem {
  const OperationalCostBreakdownItem({
    required this.label,
    required this.amountCents,
  });

  final String label;
  final int amountCents;
}

class JourneyHistorySectionState {
  const JourneyHistorySectionState({
    required this.shifts,
    required this.totalCount,
    required this.isLoadingMore,
    required this.hasMore,
    required this.errorMessage,
  });

  final List<ShiftEntity> shifts;
  final int totalCount;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;

  int get loadedCount => shifts.length;
  bool get isEmpty => shifts.isEmpty;
}

class JourneyRidesSectionState {
  const JourneyRidesSectionState({
    required this.selectedStatusFilter,
    required this.visibleRides,
    required this.totalVisibleCount,
    required this.periodLabel,
    required this.isLoadingMore,
    required this.errorMessage,
  });

  final String selectedStatusFilter;
  final List<RideEntity> visibleRides;
  final int totalVisibleCount;
  final String periodLabel;
  final bool isLoadingMore;
  final String? errorMessage;

  int get visibleCount => visibleRides.length;
  bool get isEmpty => visibleRides.isEmpty;
}

class JourneyPaymentMethodsSectionState {
  const JourneyPaymentMethodsSectionState({
    required this.items,
    required this.totalFinishedRides,
    required this.mappedCount,
    required this.isExpanded,
  });

  final List<PaymentMethodSummaryItem> items;
  final int totalFinishedRides;
  final int mappedCount;
  final bool isExpanded;

  int get unmappedCount => totalFinishedRides - mappedCount;
  bool get hasUnmappedRides => unmappedCount > 0;
}

class JourneyRecordingsSectionState {
  const JourneyRecordingsSectionState({
    required this.selectedStatusFilter,
    required this.visibleRecordings,
    required this.totalVisibleCount,
    required this.periodLabel,
    required this.isLoadingMore,
    required this.errorMessage,
  });

  final String selectedStatusFilter;
  final List<RecordingEntity> visibleRecordings;
  final int totalVisibleCount;
  final String periodLabel;
  final bool isLoadingMore;
  final String? errorMessage;

  int get visibleCount => visibleRecordings.length;
  bool get isEmpty => visibleRecordings.isEmpty;
}

String _formatRecordingDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

class JourneyOperationalSummaryData {
  const JourneyOperationalSummaryData({
    required this.netEarningsCents,
    required this.grossEarningsCents,
    required this.totalCostsCents,
    required this.totalRides,
    required this.margin,
    required this.isCostBreakdownExpanded,
  });

  final int netEarningsCents;
  final int grossEarningsCents;
  final int totalCostsCents;
  final int totalRides;
  final double margin;
  final bool isCostBreakdownExpanded;

  bool get isPositive => netEarningsCents >= 0;
}

class JourneyOperationalCostBreakdownData {
  const JourneyOperationalCostBreakdownData({
    required this.variableCostsCents,
    required this.fixedCostsCents,
    required this.variableItems,
    required this.fixedItems,
  });

  final int variableCostsCents;
  final int fixedCostsCents;
  final List<OperationalCostBreakdownItem> variableItems;
  final List<OperationalCostBreakdownItem> fixedItems;
}

class JourneyRideAnalysisData {
  const JourneyRideAnalysisData({
    required this.totalRides,
    required this.totalTimeSeconds,
    required this.totalKm,
    required this.grossEarningsCents,
    required this.variableCostsCents,
    required this.profitCents,
  });

  final int totalRides;
  final int totalTimeSeconds;
  final double totalKm;
  final int grossEarningsCents;
  final int variableCostsCents;
  final int profitCents;

  bool get hasRides => totalRides > 0;
  bool get hasHours => totalTimeSeconds >= 60;
  bool get hasKm => totalKm >= 1;

  double get totalHours => totalTimeSeconds / 3600;

  double? get grossPerRide =>
      hasRides ? grossEarningsCents / 100 / totalRides : null;

  double? get grossPerHour =>
      hasRides && hasHours ? grossEarningsCents / 100 / totalHours : null;

  double? get grossPerKm =>
      hasRides && hasKm ? grossEarningsCents / 100 / totalKm : null;

  double? get costsPerRide =>
      hasRides ? variableCostsCents / 100 / totalRides : null;

  double? get costsPerHour =>
      hasRides && hasHours ? variableCostsCents / 100 / totalHours : null;

  double? get costsPerKm =>
      hasRides && hasKm ? variableCostsCents / 100 / totalKm : null;

  double? get profitPerRide => hasRides ? profitCents / 100 / totalRides : null;

  double? get profitPerHour =>
      hasRides && hasHours ? profitCents / 100 / totalHours : null;

  double? get profitPerKm =>
      hasRides && hasKm ? profitCents / 100 / totalKm : null;
}

String _shiftActionKey(ShiftEntity shift) {
  if (shift.localId != null) {
    return 'local:${shift.localId}';
  }
  if (shift.remoteShiftId != null) {
    return 'remote:${shift.remoteShiftId}';
  }
  return 'index:${shift.index}:${shift.date}:${shift.startTime}:${shift.endTime}';
}

class PaymentMethodSummaryItem {
  const PaymentMethodSummaryItem({required this.code, required this.count});

  final String code;
  final int count;
}
