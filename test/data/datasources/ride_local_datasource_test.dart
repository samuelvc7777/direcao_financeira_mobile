import 'dart:io';

import 'package:direcao_financeira_mobile/app/data/datasources/ride_local_datasource.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/detected_ride_draft_entity.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  const storageName = 'ride_local_datasource_test';
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          return Directory.systemTemp.path;
        });
    await GetStorage.init(storageName);
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  setUp(() async {
    await GetStorage(storageName).erase();
  });

  tearDown(() async {
    await GetStorage(storageName).erase();
  });

  test(
    'preserva todas as corridas pendentes salvas em sequencia rapida',
    () async {
      final dataSource = RideLocalDataSourceImpl(
        storage: GetStorage(storageName),
      );
      final detectedAt = DateTime(2026, 5, 21, 10, 30);

      final saved = await Future.wait(
        List.generate(
          40,
          (index) => dataSource.savePendingRide(
            _draft(detectedAt: detectedAt, passengerName: 'Passageiro $index'),
          ),
        ),
      );

      final rides = await dataSource.getPendingRides();

      expect(saved, hasLength(40));
      expect(rides, hasLength(40));
      expect(rides.map((ride) => ride.id).toSet(), hasLength(40));
      expect(rides.map((ride) => ride.passenger), contains('Passageiro 39'));
    },
  );
}

DetectedRideDraftEntity _draft({
  required DateTime detectedAt,
  required String passengerName,
}) {
  return DetectedRideDraftEntity(
    platformName: 'MoveSj',
    detectedAt: detectedAt,
    paymentMethod: 'APP',
    grossValueCents: 2500,
    netProfitCents: 0,
    totalKm: 8.5,
    totalTimeSeconds: 900,
    gainPerKmCents: 294,
    gainPerHourCents: 10000,
    passengerName: passengerName,
    originAddress: 'Origem',
    destinationAddress: 'Destino',
  );
}
