import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../subscription/subscription_access_gate.dart';
import '../../presentation/modules/journey/journey_binding.dart';
import '../../presentation/modules/initial/initial_controller.dart';
import '../../routes/app_pages.dart';
import '../../presentation/modules/journey/journey_controller.dart';

class AppBubbleActionController extends GetxController {
  static const MethodChannel _platform = MethodChannel(
    'com.direcao_financeira/app_bubble_actions',
  );

  @override
  void onInit() {
    super.onInit();
    _platform.setMethodCallHandler(_handleMethodCall);
    unawaited(_consumePendingAction());
  }

  Future<void> _consumePendingAction() async {
    try {
      final payload = await _platform.invokeMapMethod<String, dynamic>(
        'consumePendingAction',
      );
      if (payload == null || payload.isEmpty) {
        return;
      }
      await _handleAction(payload);
    } on MissingPluginException {
      // Em testes e em ambientes sem o bridge nativo, nao ha acao pendente para consumir.
    } on PlatformException catch (e) {
      developer.log('Erro ao consumir acao pendente da bolinha: ${e.message}');
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onBubbleAction':
        final rawArgs = call.arguments;
        if (rawArgs is Map) {
          await _handleAction(Map<String, dynamic>.from(rawArgs));
        }
        break;
      default:
        developer.log('Acao da bolinha nao implementada: ${call.method}');
    }
  }

  Future<void> _handleAction(Map<String, dynamic> payload) async {
    await _waitForNavigationReady();

    final action = payload['action']?.toString();
    if (action == null || action.isEmpty) {
      return;
    }

    switch (action) {
      case 'open_journey_shifts':
        await _openJourney(initialTabIndex: 0);
        break;
      case 'open_journey_rides':
        await _openJourney(initialTabIndex: 1);
        break;
      case 'open_journey_recordings':
        await _openJourney(initialTabIndex: 2);
        break;
      case 'toggle_traffic_light':
        await _toggleTrafficLight();
        break;
      case 'toggle_recording':
        await _toggleRecording();
        break;
      default:
        developer.log('Acao da bolinha desconhecida: $action');
    }
  }

  Future<void> _openJourney({required int initialTabIndex}) async {
    if (!await SubscriptionAccessGate.ensureAccess()) {
      return;
    }

    JourneyBinding().dependencies();

    if (Get.isRegistered<InitialController>()) {
      Get.until(
        (route) => route.settings.name == AppRoutes.initial || route.isFirst,
      );
      Get.find<InitialController>().changeTab(2);
      await _activateJourneyShortcut(initialTabIndex);
      return;
    }

    Get.offAllNamed<dynamic>(
      AppRoutes.initial,
      arguments: {'initialIndex': 2, 'journeyInitialTabIndex': initialTabIndex},
    );

    await _activateJourneyShortcut(initialTabIndex);
  }

  Future<void> _activateJourneyShortcut(int initialTabIndex) async {
    await Future<void>.delayed(const Duration(milliseconds: 40));

    for (var attempt = 0; attempt < 8; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (Get.isRegistered<JourneyController>()) {
        final journeyController = Get.find<JourneyController>();
        journeyController.selectJourneyTab(initialTabIndex);
        await journeyController.refreshRuntimeStateAfterForegroundOpen();
        return;
      }
    }
  }

  Future<void> _toggleTrafficLight() async {
    await _openJourney(initialTabIndex: 0);

    if (!Get.isRegistered<JourneyController>()) {
      return;
    }

    await Get.find<JourneyController>().ensureTrafficLightActive();
  }

  Future<void> _toggleRecording() async {
    await _openJourney(initialTabIndex: 2);

    if (!Get.isRegistered<JourneyController>()) {
      return;
    }

    await Get.find<JourneyController>().toggleRecording();
  }

  Future<void> _waitForNavigationReady() async {
    if (Get.context != null) {
      return;
    }

    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    await completer.future;
  }
}
