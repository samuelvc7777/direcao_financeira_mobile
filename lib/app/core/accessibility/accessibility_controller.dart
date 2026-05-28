import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../config/app_environment.dart';
import '../../domain/entities/detected_ride_draft_entity.dart';
import '../../domain/entities/costs_gains_settings_entity.dart';
import '../../domain/services/resolved_google_api_key_service.dart';
import '../../domain/usecases/create_detected_ride_usecase.dart';
import '../../domain/usecases/costs_gains_settings_use_cases.dart';
import '../../presentation/modules/journey/journey_controller.dart';
import 'accessibility_service.dart';

class AccessibilityController extends GetxController
    with WidgetsBindingObserver
    implements AccessibilityService {
  AccessibilityController({required this.storage});

  static const _duplicateRideWindow = Duration(seconds: 15);

  static const _platform = MethodChannel(
    'com.direcao_financeira/accessibility',
  );
  static const _trafficLightActiveKey = 'traffic_light_active';
  static const _journeyActiveShiftKey = 'journey_local_active_shift';

  final GetStorage storage;
  final lastRaceData = <String, dynamic>{}.obs;
  String? _lastPersistedRideSignature;
  DateTime? _lastPersistedRideAt;
  @override
  final isServiceEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initChannel();
    checkServiceStatus();
    syncSettingsWithNative();
    syncRuntimeStateWithNative();
    unawaited(_consumePendingDetectedRides());
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshServiceStatus();
      unawaited(_consumePendingDetectedRides());
    }
  }

  void _initChannel() {
    _platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onRaceDetected':
          await _handleRaceDetected(call.arguments);
          return true;
        default:
          _debugLog('Metodo nao implementado: ${call.method}');
          return null;
      }
    });
  }

  Future<void> _consumePendingDetectedRides() async {
    try {
      final rawItems = await _platform.invokeMethod<List<dynamic>>(
        'consumePendingDetectedRides',
      );
      if (rawItems == null || rawItems.isEmpty) {
        return;
      }

      for (final item in rawItems) {
        if (item is! Map) {
          continue;
        }
        await _handleRaceDetected(Map<String, dynamic>.from(item));
      }
    } on MissingPluginException {
      // Em testes e plataformas sem o canal nativo, nao ha fila pendente.
    } catch (error) {
      developer.log('Erro ao consumir corridas pendentes nativas: $error');
    }
  }

  @override
  Future<void> syncSettingsWithNative() async {
    try {
      final storedSettings = storage.read('traffic_light_settings');
      final settingsMap = storedSettings is Map
          ? Map<String, dynamic>.from(storedSettings)
          : <String, dynamic>{};
      final costsSettings = await _loadCostsGainsSettings();

      final settings = <String, dynamic>{
        'position': settingsMap['position'] ?? storage.read('tl_position') ?? 0,
        'theme': settingsMap['theme'] ?? storage.read('tl_theme') ?? 1,
        'font_size':
            settingsMap['fontSize'] ?? storage.read('tl_font_size') ?? 12.0,
        'opacity':
            settingsMap['opacity'] ?? storage.read('tl_opacity') ?? 100.0,
        'duration':
            settingsMap['cardDuration'] ?? storage.read('tl_duration') ?? 10.0,
        'color_blind':
            settingsMap['colorBlindMode'] ??
            storage.read('tl_color_blind') ??
            false,
        'indicators': _normalizeIndicators(
          settingsMap['indicators'] ?? storage.read('tl_indicators'),
        ),
        'monitored_apps': _normalizeMonitoredApps(settingsMap['monitoredApps']),
        'gain_per_km_bad': (settingsMap['gainPerKmBad'] ?? 1.57).toDouble(),
        'gain_per_km_good': (settingsMap['gainPerKmGood'] ?? 2.60).toDouble(),
        'gain_per_hour_bad': (settingsMap['gainPerHourBad'] ?? 19.67)
            .toDouble(),
        'gain_per_hour_good': (settingsMap['gainPerHourGood'] ?? 32.50)
            .toDouble(),
        'passenger_rating_bad': (settingsMap['passengerRatingBad'] ?? 4.6)
            .toDouble(),
        'passenger_rating_good': (settingsMap['passengerRatingGood'] ?? 5.0)
            .toDouble(),
        'passenger_rating_customized':
            settingsMap['passengerRatingCustomized'] ?? false,
      };

      if (costsSettings != null) {
        settings['fuel_price_per_liter_cents'] =
            costsSettings.fuelPricePerLiterCents;
        settings['km_per_liter'] = costsSettings.kmPerLiter;
      }
      settings['google_maps_api_key'] = await _loadResolvedGoogleMapsApiKey();
      await _platform.invokeMethod('updateSettings', settings);
    } catch (e) {
      developer.log('Erro ao sincronizar configuracoes com o nativo: $e');
    }
  }

  Future<String> _loadResolvedGoogleMapsApiKey() async {
    if (Get.isRegistered<ResolvedGoogleApiKeyService>()) {
      final resolved = await Get.find<ResolvedGoogleApiKeyService>().resolve(
        forceRefresh: true,
      );
      return resolved.value;
    }

    if (Get.isRegistered<AppEnvironment>()) {
      return Get.find<AppEnvironment>().googleMapsApiKey.trim();
    }

    return '';
  }

  Future<CostsGainsSettingsEntity?> _loadCostsGainsSettings() async {
    if (!Get.isRegistered<GetCostsGainsSettingsUseCase>()) {
      return null;
    }

    final result = await Get.find<GetCostsGainsSettingsUseCase>()();
    return result.fold((_) => null, (entity) => entity);
  }

  @override
  bool get persistedTrafficLightActive {
    try {
      return storage.read(_trafficLightActiveKey) == true;
    } catch (_) {
      return false;
    }
  }

  bool get persistedJourneyActive {
    try {
      final raw = storage.read(_journeyActiveShiftKey);
      return raw is Map;
    } catch (_) {
      return false;
    }
  }

  Future<void> syncRuntimeStateWithNative() async {
    await updateRuntimeState(
      trafficLightActive: persistedTrafficLightActive,
      journeyActive: persistedJourneyActive,
    );
  }

  @override
  Future<void> setTrafficLightActive(bool isActive) async {
    try {
      await storage.write(_trafficLightActiveKey, isActive);
      await updateRuntimeState(trafficLightActive: isActive);
    } catch (e) {
      developer.log('Erro ao persistir estado do semaforo: $e');
    }
  }

  @override
  Future<void> setJourneyActive(bool isActive) async {
    await updateRuntimeState(journeyActive: isActive);
  }

  Future<void> updateRuntimeState({
    bool? trafficLightActive,
    bool? journeyActive,
  }) async {
    try {
      final payload = <String, dynamic>{};

      if (trafficLightActive != null) {
        payload['traffic_light_active'] = trafficLightActive;
      }

      if (journeyActive != null) {
        payload['journey_active'] = journeyActive;
      }

      await _platform.invokeMethod('updateRuntimeState', payload);
    } on PlatformException catch (e) {
      developer.log("Erro ao atualizar estado runtime nativo: '${e.message}'.");
    }
  }

  Map<String, bool> _normalizeIndicators(dynamic rawIndicators) {
    if (rawIndicators is Map) {
      return rawIndicators.map(
        (key, value) => MapEntry(key.toString(), value == true),
      );
    }

    return {'R\$/Km': true, 'R\$/Hora': true, 'Lucro/H': true, 'Nota': true};
  }

  Map<String, bool> _normalizeMonitoredApps(dynamic rawMonitoredApps) {
    if (rawMonitoredApps is Map) {
      return rawMonitoredApps.map(
        (key, value) => MapEntry(key.toString(), value == true),
      );
    }

    return {
      'Uber': true,
      '99': true,
      'inDrive': true,
      'MoveSj': true,
      'MeLevaSJ': false,
      'GooglePhotos': false,
    };
  }

  Future<void> _handleRaceDetected(dynamic arguments) async {
    if (arguments is Map) {
      final data = Map<String, dynamic>.from(arguments);
      lastRaceData.value = data;

      _debugLog(
        'Corrida detectada pelo Accessibility Service: ${_rideLogSummary(data)}',
      );
      await _persistDetectedRide(data);
    }
  }

  Future<void> _persistDetectedRide(Map<String, dynamic> data) async {
    if (!Get.isRegistered<CreateDetectedRideUseCase>()) {
      return;
    }

    _debugLog(
      'Payload bruto recebido para persistencia da corrida: ${_rideLogSummary(data)}',
    );
    final ride = _mapDetectedRide(data);
    if (ride == null) {
      _debugLog(
        'Corrida detectada descartada no mapeamento. '
        'valor=${data['valor_bruto']} km=${data['km_total']} '
        'min=${data['minutos_total']} origem=${data['origin_address']} '
        'destino=${data['destination_address']}',
      );
      return;
    }

    _debugLog(
      'Draft mapeado para persistencia: '
      'platform=${ride.platformName} '
      'passenger=${ride.passengerName} '
      'origin=${ride.originAddress} '
      'destination=${ride.destinationAddress} '
      'km=${ride.totalKm} '
      'seconds=${ride.totalTimeSeconds}',
    );

    if (_isDuplicateRide(ride)) {
      _debugLog('Corrida detectada ignorada por dedupe local.');
      return;
    }

    final result = await Get.find<CreateDetectedRideUseCase>()(ride);
    result.fold(
      (failure) => developer.log(
        'Erro ao salvar corrida detectada localmente: ${failure.message}',
      ),
      (_) {
        _rememberPersistedRide(ride);
        _debugLog('Corrida detectada salva localmente como PENDING.');
        _refreshJourneyRides();
      },
    );
  }

  void _refreshJourneyRides() {
    if (!Get.isRegistered<JourneyController>()) {
      _debugLog(
        'JourneyController nao registrado no momento da persistencia da corrida.',
      );
      return;
    }

    final controller = Get.find<JourneyController>();
    controller.refreshJourneyData(silent: true, showErrors: false);
    _debugLog('Refresh local da jornada disparado apos salvar corrida.');
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      developer.log(message);
    }
  }

  Map<String, dynamic> _rideLogSummary(Map<String, dynamic> data) {
    return {
      'app': data['platform_name'] ?? data['app'],
      'valor': data['valor_bruto'],
      'km': data['km_total'],
      'min': data['minutos_total'],
    };
  }

  DetectedRideDraftEntity? _mapDetectedRide(Map<String, dynamic> data) {
    final grossValueCents = _parseCurrencyToCents(data['valor_bruto']);
    final totalKm = _toDouble(data['km_total']);
    final totalMinutes = _toInt(data['minutos_total']);
    final platformName = _resolvePlatformName(data);

    if (grossValueCents <= 0 || (totalKm <= 0 && totalMinutes <= 0)) {
      return null;
    }

    return DetectedRideDraftEntity(
      platformName: platformName,
      detectedAt: _resolveDetectedAt(data),
      paymentMethod: _mapPaymentMethod(data['forma_pagamento']),
      grossValueCents: grossValueCents,
      netProfitCents: 0,
      totalKm: totalKm,
      totalTimeSeconds: totalMinutes * 60,
      gainPerKmCents: _calculateGainPerKmCents(
        grossValueCents: grossValueCents,
        totalKm: totalKm,
      ),
      gainPerHourCents: _calculateGainPerHourCents(
        grossValueCents: grossValueCents,
        totalMinutes: totalMinutes,
      ),
      passengerName: _resolvePassengerName(data, platformName: platformName),
      originAddress: _resolveTextField(data['origin_address']),
      destinationAddress: _resolveTextField(data['destination_address']),
      rideType: _resolveTextField(data['tipo_corrida']),
    );
  }

  DateTime _resolveDetectedAt(Map<String, dynamic> data) {
    final epochMs = data['detected_at_epoch_ms'];
    if (epochMs is int) {
      return DateTime.fromMillisecondsSinceEpoch(epochMs).toLocal();
    }
    if (epochMs is num) {
      return DateTime.fromMillisecondsSinceEpoch(epochMs.round()).toLocal();
    }

    final isoValue =
        _resolveTextField(data['detected_at']) ??
        _resolveTextField(data['created_at']);
    final parsed = DateTime.tryParse(isoValue ?? '');
    return parsed?.toLocal() ?? DateTime.now();
  }

  int _parseCurrencyToCents(dynamic rawValue) {
    final text = rawValue?.toString().trim() ?? '';
    if (text.isEmpty) {
      return 0;
    }

    final normalized = text
        .replaceAll(RegExp(r'[^0-9,\.]'), '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final value = double.tryParse(normalized) ?? 0.0;
    return (value * 100).round();
  }

  double _toDouble(dynamic rawValue) {
    if (rawValue is num) {
      return rawValue.toDouble();
    }

    final text = rawValue?.toString().trim().replaceAll(',', '.') ?? '';
    return double.tryParse(text) ?? 0.0;
  }

  int _toInt(dynamic rawValue) {
    if (rawValue is int) {
      return rawValue;
    }

    if (rawValue is num) {
      return rawValue.round();
    }

    final text = rawValue?.toString().trim().replaceAll(',', '.') ?? '';
    return double.tryParse(text)?.round() ?? 0;
  }

  int _calculateGainPerKmCents({
    required int grossValueCents,
    required double totalKm,
  }) {
    if (grossValueCents <= 0 || totalKm <= 0) {
      return 0;
    }

    return (grossValueCents / totalKm).round();
  }

  int _calculateGainPerHourCents({
    required int grossValueCents,
    required int totalMinutes,
  }) {
    if (grossValueCents <= 0 || totalMinutes <= 0) {
      return 0;
    }

    return ((grossValueCents * 60) / totalMinutes).round();
  }

  String _mapPaymentMethod(dynamic rawValue) {
    final normalized = rawValue?.toString().trim().toLowerCase() ?? '';

    if (normalized.contains('pix')) {
      return 'PIX';
    }
    if (normalized.contains('dinheiro') || normalized.contains('cash')) {
      return 'CASH';
    }
    if (normalized.contains('cart')) {
      return 'CARD';
    }

    return 'APP';
  }

  String? _resolvePassengerName(
    Map<String, dynamic> data, {
    String? platformName,
  }) {
    final passengerName = _resolveTextField(data['passenger_name']);
    if (_isValidPassengerName(passengerName, platformName: platformName)) {
      return passengerName;
    }

    final profile = data['perfil_passageiro']?.toString().trim();
    if (_isValidPassengerName(profile, platformName: platformName)) {
      return profile;
    }

    return null;
  }

  String? _resolvePlatformName(Map<String, dynamic> data) {
    final rawValue =
        _resolveTextField(data['platform_name']) ??
        _resolveTextField(data['app']);
    if (rawValue == null) {
      return null;
    }

    final normalized = rawValue.toLowerCase();
    if (normalized.contains('movesj') || normalized == 'move') {
      return 'MoveSj';
    }
    if (normalized.contains('99')) {
      return '99';
    }

    return rawValue;
  }

  String? _resolveTextField(dynamic rawValue) {
    final text = rawValue?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }

  bool _isValidPassengerName(String? value, {String? platformName}) {
    if (value == null) {
      return false;
    }

    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }

    final blockedValues = <String>{
      'move',
      'movesj',
      '99',
      'app',
      'passageiro',
      'motorista',
    };

    if (blockedValues.contains(normalized)) {
      return false;
    }

    if (platformName != null &&
        normalized == platformName.trim().toLowerCase()) {
      return false;
    }

    return true;
  }

  bool _isDuplicateRide(DetectedRideDraftEntity ride) {
    final signature = _buildRideSignature(ride);
    final lastAt = _lastPersistedRideAt;

    if (_lastPersistedRideSignature != signature || lastAt == null) {
      return false;
    }

    return DateTime.now().difference(lastAt) <= _duplicateRideWindow;
  }

  void _rememberPersistedRide(DetectedRideDraftEntity ride) {
    _lastPersistedRideSignature = _buildRideSignature(ride);
    _lastPersistedRideAt = DateTime.now();
  }

  String _buildRideSignature(DetectedRideDraftEntity ride) {
    return [
      ride.paymentMethod,
      ride.grossValueCents,
      ride.platformName ?? '',
      ride.totalKm.toStringAsFixed(2),
      ride.totalTimeSeconds,
      ride.passengerName ?? '',
      ride.originAddress ?? '',
      ride.destinationAddress ?? '',
    ].join('|');
  }

  Future<void> checkServiceStatus() async {
    try {
      final enabled = await _platform.invokeMethod<bool>('isServiceEnabled');
      isServiceEnabled.value = enabled ?? false;
    } on PlatformException catch (e) {
      developer.log("Erro ao verificar status do servico: '${e.message}'.");
    }
  }

  Future<void> refreshServiceStatus() async {
    final wasEnabled = isServiceEnabled.value;
    await checkServiceStatus();

    if (!wasEnabled && isServiceEnabled.value) {
      await syncSettingsWithNative();
      await syncRuntimeStateWithNative();
    }
  }

  @override
  Future<void> requestAccessibilityPermission() async {
    try {
      await _platform.invokeMethod('openAccessibilitySettings');
      developer.log('Abrindo configuracoes de acessibilidade');
    } on PlatformException catch (e) {
      developer.log(
        "Erro ao abrir configuracoes de acessibilidade: '${e.message}'.",
      );
    }
  }
}
