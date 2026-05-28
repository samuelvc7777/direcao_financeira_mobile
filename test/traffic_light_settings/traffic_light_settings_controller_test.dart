import 'package:dartz/dartz.dart';
import 'package:direcao_financeira_mobile/app/core/accessibility/accessibility_service.dart';
import 'package:direcao_financeira_mobile/app/core/errors/failures.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/traffic_light_settings_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/repositories/i_traffic_light_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/usecases/traffic_light_settings_use_cases.dart';
import 'package:direcao_financeira_mobile/app/presentation/modules/traffic_light_settings/traffic_light_settings_controller.dart';
import 'package:direcao_financeira_mobile/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeTrafficLightRepository implements ITrafficLightRepository {
  TrafficLightSettingsEntity settings = TrafficLightSettingsEntity(
    position: TrafficLightPosition.topo,
    theme: TrafficLightTheme.escuro,
    indicators: const {
      'R\$/Km': true,
      'R\$/Hora': true,
      'Lucro/H': true,
      'Nota': true,
    },
    monitoredApps: const {
      'Uber': true,
      '99': true,
      'inDrive': true,
      'MoveSj': false,
    },
    fontSize: 12,
    opacity: 100,
    cardDuration: 10,
    colorBlindMode: false,
    gainPerKmBad: 1.57,
    gainPerKmGood: 2.60,
    gainPerHourBad: 19.67,
    gainPerHourGood: 32.50,
    passengerRatingBad: 4.6,
    passengerRatingGood: 5.0,
    passengerRatingCustomized: false,
  );

  bool saveCalled = false;

  @override
  Future<Either<Failure, TrafficLightSettingsEntity>> getSettings() async =>
      Right(settings);

  @override
  Future<Either<Failure, void>> saveSettings(
    TrafficLightSettingsEntity settings,
  ) async {
    saveCalled = true;
    this.settings = settings;
    return const Right(null);
  }
}

class _FakeAccessibilityService implements AccessibilityService {
  @override
  final RxBool isServiceEnabled = true.obs;

  @override
  bool persistedTrafficLightActive = false;

  bool syncCalled = false;

  @override
  Future<void> requestAccessibilityPermission() async {}

  @override
  Future<void> setJourneyActive(bool isActive) async {}

  @override
  Future<void> setTrafficLightActive(bool isActive) async {}

  @override
  Future<void> syncSettingsWithNative() async {
    syncCalled = true;
  }
}

void main() {
  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    Get.reset();
    Get.testMode = false;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets(
    'saveSettings redireciona para /initial com a aba de configuracoes',
    (tester) async {
      final repository = _FakeTrafficLightRepository();
      final accessibilityService = _FakeAccessibilityService();
      final controller = TrafficLightSettingsController(
        getSettingsUseCase: GetTrafficLightSettingsUseCase(repository),
        saveSettingsUseCase: SaveTrafficLightSettingsUseCase(repository),
        accessibilityService: accessibilityService,
      );

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.trafficLightSettings,
          getPages: [
            GetPage(
              name: AppRoutes.initial,
              page: () => const Scaffold(body: Text('Initial Screen')),
            ),
            GetPage(
              name: AppRoutes.trafficLightSettings,
              page: () => const Scaffold(body: Text('Traffic Light Screen')),
              binding: BindingsBuilder(() {
                Get.put<TrafficLightSettingsController>(controller);
              }),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(controller.fontSize.value, 12);
      await controller.saveSettings();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(repository.saveCalled, isTrue);
      expect(accessibilityService.syncCalled, isTrue);
      expect(Get.currentRoute, AppRoutes.initial);
      expect(Get.arguments, const {'initialIndex': 3});
      expect(find.text('Initial Screen'), findsOneWidget);
    },
  );
}
