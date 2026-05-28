import 'package:dartz/dartz.dart';
import 'package:direcao_financeira_mobile/app/core/errors/failures.dart';
import 'package:direcao_financeira_mobile/app/data/services/address_autocomplete_service.dart';
import 'package:direcao_financeira_mobile/app/data/services/ride_route_estimator.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/detected_ride_draft_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/paged_result_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/ride_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/ride_import_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/repositories/i_ride_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/services/auto_ride_screenshot_parser.dart';
import 'package:direcao_financeira_mobile/app/domain/usecases/create_detected_ride_usecase.dart';
import 'package:direcao_financeira_mobile/app/domain/usecases/get_rides_usecase.dart';
import 'package:direcao_financeira_mobile/app/presentation/modules/journey/import_ride_photo_controller.dart';
import 'package:direcao_financeira_mobile/app/presentation/modules/journey/widgets/ride_details_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  tearDown(Get.reset);

  testWidgets(
    'salva corrida importada no horario lido do print e fecha a tela',
    (tester) async {
      final repository = _FakeRideRepository();
      final controller = ImportRidePhotoController(
        createFinishedRideUseCase: CreateFinishedRideUseCase(repository),
        updateFinishedRideUseCase: UpdateFinishedRideUseCase(repository),
        getRidesUseCase: GetRidesUseCase(repository),
        parser: const AutoRideScreenshotParser(),
        addressAutocompleteService: AddressAutocompleteService(),
        routeEstimator: _FakeRideRouteEstimator(),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () => const SizedBox.shrink()),
            GetPage(name: '/import', page: () => const SizedBox.shrink()),
          ],
        ),
      );
      Get.toNamed('/import');
      await tester.pumpAndSettle();

      controller.parsedDateTime.value = DateTime(2026, 5, 12, 19);
      controller.amountController.text = 'R\$ 17,51';
      controller.passengerController.text = 'Carolina';
      controller.passengerRatingController.text = '5,0';
      controller.originController.text = 'Rua A, 123';
      controller.destinationController.text = 'Rua B, 456';
      controller.distanceKmController.text = '8,5';
      controller.durationMinutesController.text = '19';
      controller.selectedPaymentOption.value = RidePaymentOption.pix;

      await controller.saveRide();
      await tester.pumpAndSettle();

      expect(
        repository.lastFinishedRide?.detectedAt,
        DateTime(2026, 5, 12, 19),
      );
      expect(repository.lastFinishedRide?.paymentMethod, 'PIX');
      expect(repository.lastFinishedRide?.passengerRating, 5.0);
      expect(repository.lastFinishedRide?.totalKm, 9.5);
      expect(repository.lastFinishedRide?.totalTimeSeconds, 24 * 60);
      expect(repository.lastFinishedRide?.gainPerKmCents, 184);
      expect(repository.lastFinishedRide?.gainPerHourCents, 4378);
      expect(Get.currentRoute, '/');

      controller.onClose();
    },
  );

  testWidgets('atualiza corrida selecionada ao salvar dados importados', (
    tester,
  ) async {
    final repository = _FakeRideRepository();
    final controller = ImportRidePhotoController(
      createFinishedRideUseCase: CreateFinishedRideUseCase(repository),
      updateFinishedRideUseCase: UpdateFinishedRideUseCase(repository),
      getRidesUseCase: GetRidesUseCase(repository),
      parser: const AutoRideScreenshotParser(),
      addressAutocompleteService: AddressAutocompleteService(),
      routeEstimator: _FakeRideRouteEstimator(),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const SizedBox.shrink()),
          GetPage(name: '/import', page: () => const SizedBox.shrink()),
        ],
      ),
    );
    Get.toNamed('/import');
    await tester.pumpAndSettle();

    controller.selectRide(
      RideEntity(
        id: 42,
        status: 'FINISHED',
        appName: 'MoveSJ',
        paymentMethod: 'PIX',
        createdAt: DateTime(2026, 5, 11, 18),
        grossValueCents: 1000,
        date: '11/05',
        time: '18:00',
        origin: 'Origem antiga',
        destination: 'Destino antigo',
        passenger: 'Cliente antigo',
        totalKm: 4,
        totalTimeSeconds: 12 * 60,
        durationMinutes: 12,
        gainPerKmCents: 250,
        gainPerHourCents: 5000,
      ),
    );
    controller.parsedDateTime.value = DateTime(2026, 5, 12, 20);
    controller.amountController.text = 'R\$ 25,00';
    controller.passengerController.text = 'Cliente novo';
    controller.originController.text = 'Origem nova';
    controller.destinationController.text = 'Destino novo';
    controller.distanceKmController.text = '10';
    controller.durationMinutesController.text = '25';
    controller.pickupDistanceKmController.text = '0';
    controller.pickupDurationMinutesController.text = '0';
    controller.selectedPaymentOption.value = RidePaymentOption.pix;

    await controller.saveRide();
    await tester.pumpAndSettle();

    expect(repository.lastFinishedRide, isNull);
    expect(repository.lastUpdatedRideId, 42);
    expect(repository.lastUpdatedRide?.detectedAt, DateTime(2026, 5, 12, 20));
    expect(repository.lastUpdatedRide?.grossValueCents, 2500);
    expect(repository.lastUpdatedRide?.originAddress, 'Origem nova');
    expect(Get.currentRoute, '/');

    controller.onClose();
  });
}

class _FakeRideRouteEstimator extends RideRouteEstimator {
  @override
  Future<RideRouteEstimate?> estimate({
    required String originAddress,
    required String destinationAddress,
  }) async => null;
}

class _FakeRideRepository implements IRideRepository {
  DetectedRideDraftEntity? lastFinishedRide;
  DetectedRideDraftEntity? lastUpdatedRide;
  int? lastUpdatedRideId;

  @override
  Future<Either<Failure, Unit>> createDetectedRide(
    DetectedRideDraftEntity ride,
  ) async => const Right(unit);

  @override
  Future<Either<Failure, Unit>> createFinishedRide(
    DetectedRideDraftEntity ride,
  ) async {
    lastFinishedRide = ride;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> updateFinishedRide({
    required int rideId,
    required DetectedRideDraftEntity ride,
  }) async {
    lastUpdatedRideId = rideId;
    lastUpdatedRide = ride;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> cancelRide({
    required int rideId,
    required String cancelReason,
  }) async => const Right(unit);

  @override
  Future<Either<Failure, Unit>> deleteRide({required int rideId}) async =>
      const Right(unit);

  @override
  Future<Either<Failure, Unit>> finishRide({
    required int rideId,
    required String paymentMethod,
  }) async => const Right(unit);

  @override
  Future<Either<Failure, PagedResultEntity<RideImportEntity>>>
  getImportableRides({
    String period = 'month',
    String? date,
    String? endDate,
    String? status = 'FINISHED',
    int offset = 0,
    int limit = 100,
  }) async => Right(
    PagedResultEntity(
      items: const [],
      totalCount: 0,
      offset: offset,
      limit: limit,
    ),
  );

  @override
  Future<Either<Failure, PagedResultEntity<RideEntity>>> getRides({
    String period = 'day',
    String? date,
    String? endDate,
    String? status,
    int offset = 0,
    int limit = 20,
  }) async => Right(
    PagedResultEntity(
      items: const [],
      totalCount: 0,
      offset: offset,
      limit: limit,
    ),
  );
}
