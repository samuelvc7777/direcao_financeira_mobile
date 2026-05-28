import 'package:direcao_financeira_mobile/app/core/preferences/app_preferences.dart';
import 'package:direcao_financeira_mobile/app/core/recording/recording_settings.dart';
import 'package:direcao_financeira_mobile/app/presentation/modules/recording_settings/recording_settings_binding.dart';
import 'package:direcao_financeira_mobile/app/presentation/modules/recording_settings/recording_settings_view.dart';
import 'package:direcao_financeira_mobile/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakePreferences implements AppPreferences {
  _FakePreferences({this.initialResolution});

  final String? initialResolution;
  String? lastWrittenResolution;

  @override
  bool? readBool(String key) => null;

  @override
  double? readDouble(String key) => null;

  @override
  int? readInt(String key) => null;

  @override
  String? readString(String key) {
    if (key == RecordingSettingsSnapshot.resolutionKey) {
      return initialResolution;
    }
    return null;
  }

  @override
  Future<void> writeBool(String key, bool value) async {}

  @override
  Future<void> writeDouble(String key, double value) async {}

  @override
  Future<void> writeInt(String key, int value) async {}

  @override
  Future<void> writeString(String key, String value) async {
    if (key == RecordingSettingsSnapshot.resolutionKey) {
      lastWrittenResolution = value;
    }
  }
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  tearDown(Get.reset);

  testWidgets('salvar volta para a tela de ajustes', (tester) async {
    final preferences = _FakePreferences(initialResolution: '720p');
    Get.put<AppPreferences>(preferences);

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.settings,
        getPages: [
          GetPage(
            name: AppRoutes.settings,
            page: () => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Get.toNamed(AppRoutes.recordingSettings),
                  child: const Text('Abrir gravação'),
                ),
              ),
            ),
          ),
          GetPage(
            name: AppRoutes.recordingSettings,
            page: () => const RecordingSettingsView(),
            binding: RecordingSettingsBinding(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abrir gravação'));
    await tester.pumpAndSettle();

    expect(find.text('Configurar gravação'), findsOneWidget);

    await tester.ensureVisible(find.text('Salvar configurações'));
    await tester.tap(find.text('Salvar configurações'));
    await tester.pumpAndSettle();

    expect(find.text('Abrir gravação'), findsOneWidget);
    expect(Get.currentRoute, AppRoutes.settings);
  });
}
