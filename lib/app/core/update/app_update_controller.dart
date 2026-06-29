import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../feedback/app_snackbar.dart';
import 'play_store_update_service.dart';

class AppUpdateController extends GetxController {
  AppUpdateController({required this.appUpdateService});

  final AppUpdateService appUpdateService;

  final isCheckingUpdate = false.obs;
  final isUpdateAvailable = false.obs;
  final isDismissedForSession = false.obs;
  final RxnString lastCheckError = RxnString();

  String get badgeText => 'PLAY STORE';
  bool get forceUpdate => false;
  bool get shouldShowBanner =>
      isUpdateAvailable.value && !isDismissedForSession.value;

  @override
  void onInit() {
    super.onInit();
    unawaited(checkForUpdate());
  }

  Future<void> checkForUpdate() async {
    if (isCheckingUpdate.value) {
      return;
    }

    isCheckingUpdate.value = true;
    lastCheckError.value = null;
    try {
      isUpdateAvailable.value = await appUpdateService.hasUpdateAvailable();
    } catch (error, stackTrace) {
      debugPrint('[AppUpdateController] Falha ao verificar update: $error');
      debugPrintStack(stackTrace: stackTrace);
      lastCheckError.value = error.toString();
      isUpdateAvailable.value = false;
    } finally {
      isCheckingUpdate.value = false;
    }
  }

  Future<void> openStore() async {
    try {
      final opened = await appUpdateService.openStorePage();
      if (!opened) {
        _showOpenStoreError();
      }
    } catch (error, stackTrace) {
      debugPrint('[AppUpdateController] Falha ao abrir loja: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showOpenStoreError();
    }
  }

  void dismiss() {
    isDismissedForSession.value = true;
  }

  void _showOpenStoreError() {
    if (Get.testMode) {
      debugPrint(
        '[AppUpdateController] Nao foi possivel abrir a pagina de atualizacao.',
      );
      return;
    }

    try {
      AppSnackbar.show(
        'Atualizacao',
        'Nao foi possivel abrir a Play Store agora. Tente novamente em instantes.',
      );
    } catch (_) {
      debugPrint('[AppUpdateController] Feedback de update suprimido.');
    }
  }
}
