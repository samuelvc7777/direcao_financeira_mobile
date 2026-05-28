import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:direcao_financeira_mobile/app/core/accessibility/accessibility_controller.dart';
import 'package:direcao_financeira_mobile/app/core/errors/failures.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/costs_gains_settings_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/google_api_config_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/repositories/i_costs_gains_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/repositories/i_google_api_config_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/services/resolved_google_api_key_service.dart';
import 'package:direcao_financeira_mobile/app/domain/usecases/costs_gains_settings_use_cases.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class _FakeCostsGainsRepository implements ICostsGainsRepository {
  _FakeCostsGainsRepository(this.settings);

  final CostsGainsSettingsEntity? settings;

  @override
  Future<Either<Failure, CostsGainsSettingsEntity?>>
  getCurrentUserSettings() async {
    return Right(settings);
  }

  @override
  Future<Either<Failure, bool>> hasCurrentUserSettings() async {
    return Right(settings != null);
  }

  @override
  Future<Either<Failure, CostsGainsSettingsEntity>> saveCurrentUserSettings(
    CostsGainsSettingsEntity entity,
  ) async {
    return Right(entity);
  }
}

class _FakeGoogleApiConfigRepository implements IGoogleApiConfigRepository {
  _FakeGoogleApiConfigRepository(this.config);

  final GoogleApiConfigEntity? config;

  @override
  Future<Either<Failure, GoogleApiConfigEntity?>> getConfig() async {
    return Right(config);
  }
}

void main() {
  const storageName = 'accessibility_controller_test';
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  const accessibilityChannel = MethodChannel(
    'com.direcao_financeira/accessibility',
  );

  late List<Map<String, dynamic>> nativeSettingsPayloads;

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
    Get.reset();
    await GetStorage(storageName).erase();
    nativeSettingsPayloads = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(accessibilityChannel, (call) async {
          if (call.method == 'updateSettings') {
            nativeSettingsPayloads.add(
              Map<String, dynamic>.from(call.arguments as Map),
            );
          }
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(accessibilityChannel, null);
    await GetStorage(storageName).erase();
    Get.reset();
  });

  test(
    'syncSettingsWithNative nao zera custos quando use case ainda nao foi registrado',
    () async {
      final controller = AccessibilityController(
        storage: GetStorage(storageName),
      );

      await controller.syncSettingsWithNative();

      expect(nativeSettingsPayloads, hasLength(1));
      expect(nativeSettingsPayloads.single, isNot(contains('km_per_liter')));
      expect(
        nativeSettingsPayloads.single,
        isNot(contains('fuel_price_per_liter_cents')),
      );
    },
  );

  test('syncSettingsWithNative envia custos quando settings existem', () async {
    Get.put<GetCostsGainsSettingsUseCase>(
      GetCostsGainsSettingsUseCase(
        _FakeCostsGainsRepository(
          const CostsGainsSettingsEntity(
            userId: 1,
            desiredMonthlyProfitCents: 500000,
            workDaysPerWeek: 5,
            workHoursPerDay: 8,
            kmPerDay: 120,
            financeOrRentMonthlyCents: 0,
            insuranceMonthlyCents: 0,
            maintenanceMonthlyCents: 0,
            annualTaxesCents: 0,
            fuelPricePerLiterCents: 579,
            kmPerLiter: 10.5,
            platformFeeType: PlatformFeeType.percentage,
            platformFeeValue: 12,
          ),
        ),
      ),
    );
    final controller = AccessibilityController(
      storage: GetStorage(storageName),
    );

    await controller.syncSettingsWithNative();

    expect(nativeSettingsPayloads, hasLength(1));
    expect(nativeSettingsPayloads.single['fuel_price_per_liter_cents'], 579);
    expect(nativeSettingsPayloads.single['km_per_liter'], 10.5);
  });

  test('syncSettingsWithNative envia google_maps_api_key remota', () async {
    Get.put<ResolvedGoogleApiKeyService>(
      ResolvedGoogleApiKeyService(
        repository: _FakeGoogleApiConfigRepository(
          const GoogleApiConfigEntity(googleApiKey: ' remote-key '),
        ),
        fallbackGoogleMapsApiKey: 'fallback-key',
      ),
    );
    final controller = AccessibilityController(
      storage: GetStorage(storageName),
    );

    await controller.syncSettingsWithNative();

    expect(nativeSettingsPayloads, hasLength(1));
    expect(nativeSettingsPayloads.single['google_maps_api_key'], 'remote-key');
  });

  test(
    'syncSettingsWithNative envia fallback local quando remoto ausente',
    () async {
      Get.put<ResolvedGoogleApiKeyService>(
        ResolvedGoogleApiKeyService(
          repository: _FakeGoogleApiConfigRepository(
            const GoogleApiConfigEntity(googleApiKey: '   '),
          ),
          fallbackGoogleMapsApiKey: ' fallback-key ',
        ),
      );
      final controller = AccessibilityController(
        storage: GetStorage(storageName),
      );

      await controller.syncSettingsWithNative();

      expect(nativeSettingsPayloads, hasLength(1));
      expect(
        nativeSettingsPayloads.single['google_maps_api_key'],
        'fallback-key',
      );
    },
  );
}
