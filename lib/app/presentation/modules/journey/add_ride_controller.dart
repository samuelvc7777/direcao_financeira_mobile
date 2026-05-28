import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/feedback/app_snackbar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/address_autocomplete_service.dart';
import '../../../data/services/ride_route_estimator.dart';
import '../../../domain/entities/detected_ride_draft_entity.dart';
import '../../../domain/usecases/create_detected_ride_usecase.dart';

class AddRideController extends GetxController {
  AddRideController({
    required this.createDetectedRideUseCase,
    required this.addressAutocompleteService,
    required this.routeEstimator,
  });

  final CreateDetectedRideUseCase createDetectedRideUseCase;
  final AddressAutocompleteService addressAutocompleteService;
  final RideRouteEstimator routeEstimator;

  final passengerController = TextEditingController();
  final ratingController = TextEditingController();
  final amountController = TextEditingController();
  final originController = TextEditingController();
  final destinationController = TextEditingController();
  final distanceKmController = TextEditingController();
  final durationMinutesController = TextEditingController();

  final stopControllers = <TextEditingController>[].obs;
  final selectedPlatform = 'Uber'.obs;
  final selectedPaymentMethod = 'Dinheiro'.obs;
  final isSubmitting = false.obs;
  final isEstimatingRoute = false.obs;
  final routeProviderLabel = ''.obs;

  void addStop() {
    stopControllers.add(TextEditingController());
  }

  void removeStop(int index) {
    final controller = stopControllers.removeAt(index);
    controller.dispose();
  }

  Future<void> saveRide() async {
    final grossValueCents = _parseCurrencyToCents(amountController.text);
    final totalKm = _parseDecimal(distanceKmController.text);
    final durationMinutes = _parseInt(durationMinutesController.text);

    final validationMessage = _validate(
      grossValueCents: grossValueCents,
      totalKm: totalKm,
      durationMinutes: durationMinutes,
    );

    if (validationMessage != null) {
      _showWarning(validationMessage);
      return;
    }

    isSubmitting.value = true;

    final ride = DetectedRideDraftEntity(
      platformName: selectedPlatform.value,
      detectedAt: DateTime.now(),
      paymentMethod: selectedPaymentMethod.value,
      grossValueCents: grossValueCents,
      netProfitCents: 0,
      totalKm: totalKm,
      totalTimeSeconds: durationMinutes * 60,
      gainPerKmCents: _calculateGainPerKmCents(
        grossValueCents: grossValueCents,
        totalKm: totalKm,
      ),
      gainPerHourCents: _calculateGainPerHourCents(
        grossValueCents: grossValueCents,
        totalMinutes: durationMinutes,
      ),
      passengerName: passengerController.text.trim().isEmpty
          ? null
          : passengerController.text.trim(),
      originAddress: originController.text.trim(),
      destinationAddress: _composeDestination(),
    );

    final result = await createDetectedRideUseCase(ride);

    result.fold(
      (failure) {
        AppSnackbar.show(
          'Erro',
          failure.message,
          backgroundColor: AppColors.rose.withValues(alpha: 0.18),
        );
      },
      (_) {
        AppSnackbar.show(
          'Sucesso',
          'Corrida manual adicionada ao historico.',
          backgroundColor: AppColors.emerald.withValues(alpha: 0.18),
        );
        Get.back(result: true);
      },
    );

    isSubmitting.value = false;
  }

  Future<void> estimateRoute() async {
    final origin = originController.text.trim();
    final destination = destinationController.text.trim();
    if (origin.isEmpty || destination.isEmpty) {
      _showWarning('Informe origem e destino para calcular a rota.');
      return;
    }

    isEstimatingRoute.value = true;
    routeProviderLabel.value = 'Calculando rota...';
    try {
      final estimate = await routeEstimator.estimate(
        originAddress: origin,
        destinationAddress: destination,
      );
      if (estimate == null) {
        _showWarning(
          'Nao consegui calcular a rota. Confira os enderecos ou preencha manualmente.',
        );
        return;
      }

      distanceKmController.text = estimate.distanceKm
          .toStringAsFixed(1)
          .replaceAll('.', ',');
      durationMinutesController.text = estimate.durationMinutes.toString();
      routeProviderLabel.value = 'Rota calculada por ${estimate.provider}';
    } catch (_) {
      _showWarning(
        'Nao consegui calcular a rota agora. Confira os enderecos ou preencha manualmente.',
      );
    } finally {
      isEstimatingRoute.value = false;
      if (distanceKmController.text.trim().isEmpty ||
          durationMinutesController.text.trim().isEmpty) {
        routeProviderLabel.value = '';
      }
    }
  }

  Future<List<AddressSuggestion>> searchAddressSuggestions(String input) {
    return addressAutocompleteService.search(input);
  }

  String get estimatedDistanceLabel {
    final totalKm = _parseDecimal(distanceKmController.text);
    if (totalKm <= 0) {
      return '-- km';
    }
    return '${totalKm.toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  String get estimatedDurationLabel {
    final durationMinutes = _parseInt(durationMinutesController.text);
    if (durationMinutes <= 0) {
      return '-- min';
    }
    return '$durationMinutes min';
  }

  String? _validate({
    required int grossValueCents,
    required double totalKm,
    required int durationMinutes,
  }) {
    if (grossValueCents <= 0) {
      return 'Informe um valor valido para a corrida.';
    }

    if (originController.text.trim().isEmpty) {
      return 'Informe o endereco de origem.';
    }

    if (destinationController.text.trim().isEmpty) {
      return 'Informe o endereco de destino.';
    }

    if (totalKm <= 0) {
      return 'Informe a distancia da corrida em km.';
    }

    if (durationMinutes <= 0) {
      return 'Informe a duracao da corrida em minutos.';
    }

    return null;
  }

  String _composeDestination() {
    final stops = stopControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final destination = destinationController.text.trim();
    if (stops.isEmpty) {
      return destination;
    }

    return '${stops.join(' | ')} | $destination';
  }

  int _parseCurrencyToCents(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  double _parseDecimal(String input) {
    final normalized = input.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  int _parseInt(String input) {
    final normalized = input.trim().replaceAll(',', '.');
    return double.tryParse(normalized)?.round() ?? 0;
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

    return (grossValueCents * 60 / totalMinutes).round();
  }

  void _showWarning(String message) {
    AppSnackbar.show(
      'Atencao',
      message,
      backgroundColor: AppColors.amber.withValues(alpha: 0.18),
    );
  }

  @override
  void onClose() {
    passengerController.dispose();
    ratingController.dispose();
    amountController.dispose();
    originController.dispose();
    destinationController.dispose();
    distanceKmController.dispose();
    durationMinutesController.dispose();
    for (final controller in stopControllers) {
      controller.dispose();
    }
    super.onClose();
  }
}
