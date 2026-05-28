import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/feedback/app_snackbar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/address_autocomplete_service.dart';
import '../../../data/services/ride_route_estimator.dart';
import '../../../domain/entities/detected_ride_draft_entity.dart';
import '../../../domain/entities/ride_entity.dart';
import '../../../domain/entities/ride_screenshot_import_entity.dart';
import '../../../domain/services/auto_ride_screenshot_parser.dart';
import '../../../domain/services/movesj_history_screenshot_parser.dart';
import '../../../domain/usecases/create_detected_ride_usecase.dart';
import '../../../domain/usecases/get_rides_usecase.dart';
import 'widgets/ride_details_models.dart';

class ImportRidePhotoController extends GetxController {
  ImportRidePhotoController({
    required this.createFinishedRideUseCase,
    required this.updateFinishedRideUseCase,
    required this.getRidesUseCase,
    required this.parser,
    required this.addressAutocompleteService,
    required this.routeEstimator,
    ImagePicker? imagePicker,
  }) : _imagePicker = imagePicker ?? ImagePicker();

  final CreateFinishedRideUseCase createFinishedRideUseCase;
  final UpdateFinishedRideUseCase updateFinishedRideUseCase;
  final GetRidesUseCase getRidesUseCase;
  final AutoRideScreenshotParser parser;
  final AddressAutocompleteService addressAutocompleteService;
  final RideRouteEstimator routeEstimator;
  final ImagePicker _imagePicker;

  final amountController = TextEditingController();
  final originController = TextEditingController();
  final destinationController = TextEditingController();
  final distanceKmController = TextEditingController();
  final durationMinutesController = TextEditingController();
  final pickupDistanceKmController = TextEditingController(text: '1,0');
  final pickupDurationMinutesController = TextEditingController(text: '5');
  final passengerController = TextEditingController();
  final passengerRatingController = TextEditingController();

  final selectedImagePath = RxnString();
  final selectedPaymentOption = Rxn<RidePaymentOption>();
  final totalsRevision = 0.obs;
  final recognizedText = ''.obs;
  final parsedRide = Rxn<RideScreenshotImportEntity>();
  final parsedDateTime = Rxn<DateTime>();
  final selectedRide = Rxn<RideEntity>();
  final availableRides = <RideEntity>[].obs;
  final isReadingImage = false.obs;
  final isEstimatingRoute = false.obs;
  final isLoadingRides = false.obs;
  final isSaving = false.obs;
  final routeProviderLabel = ''.obs;

  File? get selectedImageFile {
    final path = selectedImagePath.value;
    return path == null ? null : File(path);
  }

  String get parsedDateTimeLabel {
    final value = parsedDateTime.value;
    if (value == null) {
      return 'Data/hora nao encontrada';
    }

    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} ${two(value.hour)}:${two(value.minute)}';
  }

  String get selectedRideLabel {
    final ride = selectedRide.value;
    if (ride == null) {
      return 'Nenhuma corrida selecionada';
    }

    return '${ride.date} ${ride.time} - ${_formatCents(ride.grossValueCents)}';
  }

  String get saveButtonLabel {
    if (isSaving.value) {
      return 'SALVANDO...';
    }
    return selectedRide.value == null ? 'SALVAR CORRIDA' : 'SALVAR ALTERACOES';
  }

  String get totalDistanceLabel =>
      '${_totalKmForSave().toStringAsFixed(1).replaceAll('.', ',')} km';

  String get totalDurationLabel => '${_totalDurationMinutesForSave()} min';

  String get gainPerKmLabel {
    final value = _calculateGainPerKmCents(
      grossValueCents: _parseCurrencyToCents(amountController.text),
      totalKm: _totalKmForSave(),
    );
    return _formatCents(value);
  }

  String get gainPerHourLabel {
    final value = _calculateGainPerHourCents(
      grossValueCents: _parseCurrencyToCents(amountController.text),
      totalMinutes: _totalDurationMinutesForSave(),
    );
    return _formatCents(value);
  }

  @override
  void onInit() {
    super.onInit();
    amountController.addListener(_notifyTotalsChanged);
    distanceKmController.addListener(_notifyTotalsChanged);
    durationMinutesController.addListener(_notifyTotalsChanged);
    pickupDistanceKmController.addListener(_notifyTotalsChanged);
    pickupDurationMinutesController.addListener(_notifyTotalsChanged);
  }

  Future<void> pickImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    }

    selectedImagePath.value = image.path;
    selectedPaymentOption.value = null;
    await readSelectedImage();
  }

  Future<void> loadAvailableRides() async {
    isLoadingRides.value = true;
    try {
      final now = DateTime.now();
      final result = await getRidesUseCase(
        period: 'custom',
        date: '2020-01-01',
        endDate:
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        offset: 0,
        limit: 200,
      );

      result.fold(
        (failure) {
          AppSnackbar.show(
            'Erro',
            failure.message,
            backgroundColor: AppColors.rose.withValues(alpha: 0.18),
          );
        },
        (page) {
          final rides = page.items.where((ride) => ride.id > 0).toList()
            ..sort((a, b) {
              final aDate = a.createdAt;
              final bDate = b.createdAt;
              if (aDate == null && bDate == null) {
                return 0;
              }
              if (aDate == null) {
                return 1;
              }
              if (bDate == null) {
                return -1;
              }
              return bDate.compareTo(aDate);
            });
          availableRides.assignAll(rides);
        },
      );
    } finally {
      isLoadingRides.value = false;
    }
  }

  void selectRide(RideEntity ride) {
    selectedRide.value = ride;
    _applyRide(ride);
  }

  Future<void> readSelectedImage() async {
    final imagePath = selectedImagePath.value;
    if (imagePath == null) {
      _showWarning('Selecione um print da corrida primeiro.');
      return;
    }

    isReadingImage.value = true;
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );

      recognizedText.value = result.text;
      final parsed = parser.parsePositioned(_extractOcrLines(result));
      parsedRide.value = parsed;
      _applyParsedRide(parsed);
      await estimateRoute();
    } catch (_) {
      _showWarning('Nao foi possivel ler esse print. Tente outra imagem.');
    } finally {
      await recognizer.close();
      isReadingImage.value = false;
    }
  }

  Future<void> estimateRoute() async {
    final origin = originController.text.trim();
    final destination = destinationController.text.trim();
    if (origin.isEmpty || destination.isEmpty) {
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
          'Nao consegui calcular a rota. Confira os enderecos e preencha km/min manualmente.',
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
        'Nao consegui calcular a rota agora. Confira os enderecos e preencha km/min manualmente.',
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

  Future<void> saveRide() async {
    final grossValueCents = _parseCurrencyToCents(amountController.text);
    final rideKm = _parseDecimal(distanceKmController.text);
    final rideDurationMinutes = _parseInt(durationMinutesController.text);
    final pickupKm = _parseDecimal(pickupDistanceKmController.text);
    final pickupDurationMinutes = _parseInt(
      pickupDurationMinutesController.text,
    );
    final totalKm = rideKm + pickupKm;
    final durationMinutes = rideDurationMinutes + pickupDurationMinutes;
    final validationMessage = _validate(
      grossValueCents: grossValueCents,
      rideKm: rideKm,
      rideDurationMinutes: rideDurationMinutes,
      pickupKm: pickupKm,
      pickupDurationMinutes: pickupDurationMinutes,
    );

    if (validationMessage != null) {
      _showWarning(validationMessage);
      return;
    }

    isSaving.value = true;
    try {
      final ride = DetectedRideDraftEntity(
        platformName: parsedRide.value?.platformName ?? 'MoveSJ',
        detectedAt: parsedDateTime.value ?? DateTime.now(),
        paymentMethod: selectedPaymentOption.value!.code,
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
        passengerRating: _parseOptionalRating(passengerRatingController.text),
        originAddress: originController.text.trim(),
        destinationAddress: destinationController.text.trim(),
      );

      final selectedRideId = selectedRide.value?.id;
      final result = selectedRideId == null
          ? await createFinishedRideUseCase(ride)
          : await updateFinishedRideUseCase(rideId: selectedRideId, ride: ride);
      final saved = result.fold((failure) {
        AppSnackbar.show(
          'Erro',
          failure.message,
          backgroundColor: AppColors.rose.withValues(alpha: 0.18),
        );
        return false;
      }, (_) => true);

      if (saved) {
        isSaving.value = false;
        Get.back(result: true);
        Future<void>.delayed(const Duration(milliseconds: 120), () {
          try {
            AppSnackbar.show(
              'Sucesso',
              selectedRideId == null
                  ? 'Corrida importada do print e adicionada ao historico.'
                  : 'Corrida atualizada com os dados do print.',
              backgroundColor: AppColors.emerald.withValues(alpha: 0.18),
            );
          } catch (_) {
            debugPrint(
              '[ImportRidePhotoController] Feedback de sucesso suprimido.',
            );
          }
        });
      }
    } catch (error, stackTrace) {
      debugPrint('[ImportRidePhotoController] Erro ao salvar corrida: $error');
      debugPrintStack(stackTrace: stackTrace);
      AppSnackbar.show(
        'Erro',
        'Nao foi possivel salvar a corrida do print agora.',
        backgroundColor: AppColors.rose.withValues(alpha: 0.18),
      );
    } finally {
      isSaving.value = false;
    }
  }

  void _applyParsedRide(RideScreenshotImportEntity parsed) {
    parsedDateTime.value = parsed.detectedAt;
    passengerController.text = parsed.passengerName ?? '';
    passengerRatingController.text = parsed.passengerRating == null
        ? ''
        : _formatRating(parsed.passengerRating!);
    originController.text = parsed.originAddress ?? '';
    destinationController.text = parsed.destinationAddress ?? '';
    amountController.text = parsed.grossValueCents == null
        ? ''
        : _formatCents(parsed.grossValueCents!);
  }

  void _applyRide(RideEntity ride) {
    parsedDateTime.value = ride.createdAt;
    passengerController.text = ride.passenger == 'Nao informado'
        ? ''
        : ride.passenger;
    passengerRatingController.text = '';
    originController.text = ride.origin == 'Origem nao informada'
        ? ''
        : ride.origin;
    destinationController.text = ride.destination == 'Destino nao informado'
        ? ''
        : ride.destination;
    amountController.text = ride.grossValueCents <= 0
        ? ''
        : _formatCents(ride.grossValueCents);
    distanceKmController.text = ride.totalKm <= 0
        ? ''
        : ride.totalKm.toStringAsFixed(1).replaceAll('.', ',');
    durationMinutesController.text = ride.durationMinutes <= 0
        ? ''
        : ride.durationMinutes.toString();
    pickupDistanceKmController.text = '0,0';
    pickupDurationMinutesController.text = '0';
    final paymentMethod = ride.paymentMethod;
    selectedPaymentOption.value = null;
    if (paymentMethod != null) {
      for (final option in RidePaymentOption.all) {
        if (option.code == paymentMethod) {
          selectedPaymentOption.value = option;
          break;
        }
      }
    }
    routeProviderLabel.value = '';
  }

  List<OcrTextLine> _extractOcrLines(RecognizedText result) {
    return [
      for (final block in result.blocks)
        for (final line in block.lines)
          OcrTextLine(
            text: line.text,
            left: line.boundingBox.left,
            top: line.boundingBox.top,
            right: line.boundingBox.right,
            bottom: line.boundingBox.bottom,
          ),
    ];
  }

  String? _validate({
    required int grossValueCents,
    required double rideKm,
    required int rideDurationMinutes,
    required double pickupKm,
    required int pickupDurationMinutes,
  }) {
    if (grossValueCents <= 0) {
      return 'Confira o valor da corrida.';
    }
    if (selectedPaymentOption.value == null) {
      return 'Selecione a forma de pagamento.';
    }
    if (originController.text.trim().isEmpty) {
      return 'Confira o endereco de origem.';
    }
    if (destinationController.text.trim().isEmpty) {
      return 'Confira o endereco de destino.';
    }
    if (rideKm <= 0) {
      return 'Informe a distancia da corrida em km.';
    }
    if (rideDurationMinutes <= 0) {
      return 'Informe a duracao da corrida em minutos.';
    }
    if (pickupKm < 0) {
      return 'Informe uma distancia de deslocamento valida.';
    }
    if (pickupDurationMinutes < 0) {
      return 'Informe um tempo de deslocamento valido.';
    }
    return null;
  }

  String _formatCents(int cents) {
    final value = cents / 100;
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
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

  double? _parseOptionalRating(String input) {
    final normalized = input.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }
    final value = double.tryParse(normalized);
    if (value == null || value < 0 || value > 5) {
      return null;
    }
    return value;
  }

  String _formatRating(double value) {
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  double _totalKmForSave() {
    return _parseDecimal(distanceKmController.text) +
        _parseDecimal(pickupDistanceKmController.text);
  }

  int _totalDurationMinutesForSave() {
    return _parseInt(durationMinutesController.text) +
        _parseInt(pickupDurationMinutesController.text);
  }

  void _notifyTotalsChanged() {
    totalsRevision.value++;
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
    amountController.dispose();
    originController.dispose();
    destinationController.dispose();
    distanceKmController.dispose();
    durationMinutesController.dispose();
    pickupDistanceKmController.dispose();
    pickupDurationMinutesController.dispose();
    passengerController.dispose();
    passengerRatingController.dispose();
    super.onClose();
  }
}
