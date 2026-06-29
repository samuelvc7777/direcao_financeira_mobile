import 'package:direcao_financeira_mobile/app/core/update/app_update_controller.dart';
import 'package:direcao_financeira_mobile/app/core/update/play_store_update_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeAppUpdateService implements AppUpdateService {
  bool available = false;
  bool openStoreResult = true;
  bool throwOnCheck = false;
  bool throwOnOpenStore = false;
  int checkCalls = 0;
  int openStoreCalls = 0;

  @override
  Future<bool> hasUpdateAvailable() async {
    checkCalls++;
    if (throwOnCheck) {
      throw StateError('falha de verificacao');
    }
    return available;
  }

  @override
  Future<bool> openStorePage() async {
    openStoreCalls++;
    if (throwOnOpenStore) {
      throw StateError('falha ao abrir loja');
    }
    return openStoreResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAppUpdateService service;
  late AppUpdateController controller;

  setUp(() {
    Get.testMode = true;
    service = _FakeAppUpdateService();
    controller = AppUpdateController(appUpdateService: service);
  });

  tearDown(Get.reset);

  test('checkForUpdate marca update disponivel', () async {
    service.available = true;

    await controller.checkForUpdate();

    expect(controller.isUpdateAvailable.value, isTrue);
    expect(controller.shouldShowBanner, isTrue);
    expect(controller.lastCheckError.value, isNull);
  });

  test('checkForUpdate mantem banner oculto sem update', () async {
    await controller.checkForUpdate();

    expect(controller.isUpdateAvailable.value, isFalse);
    expect(controller.shouldShowBanner, isFalse);
  });

  test('checkForUpdate trata falha sem bloquear o app', () async {
    service.throwOnCheck = true;

    await controller.checkForUpdate();

    expect(controller.isCheckingUpdate.value, isFalse);
    expect(controller.isUpdateAvailable.value, isFalse);
    expect(controller.shouldShowBanner, isFalse);
    expect(controller.lastCheckError.value, contains('falha de verificacao'));
  });

  test('expoe estados derivados da verificacao', () async {
    expect(controller.isCheckingUpdate.value, isFalse);
    expect(controller.lastCheckError.value, isNull);
    expect(controller.shouldShowBanner, isFalse);

    service.available = true;
    await controller.checkForUpdate();

    expect(controller.isUpdateAvailable.value, isTrue);
    expect(controller.isDismissedForSession.value, isFalse);
    expect(controller.shouldShowBanner, isTrue);
  });

  test('openStore chama servico com sucesso', () async {
    await controller.openStore();

    expect(service.openStoreCalls, 1);
  });

  test('openStore trata retorno falso e excecao', () async {
    service.openStoreResult = false;
    await controller.openStore();

    service.throwOnOpenStore = true;
    await controller.openStore();

    expect(service.openStoreCalls, 2);
  });

  test('dismiss esconde o banner na sessao atual', () async {
    service.available = true;
    await controller.checkForUpdate();

    controller.dismiss();

    expect(controller.isDismissedForSession.value, isTrue);
    expect(controller.shouldShowBanner, isFalse);
  });
}
