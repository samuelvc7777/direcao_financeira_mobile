import 'dart:developer' as developer;

import 'package:flutter/services.dart';

import 'app_bubble_service.dart';

class NativeAppBubbleController implements AppBubbleService {
  NativeAppBubbleController();

  static const MethodChannel _platform = MethodChannel(
    'com.direcao_financeira/app_bubble',
  );

  @override
  Future<bool> isOverlayPermissionGranted() async {
    try {
      final isGranted = await _platform.invokeMethod<bool>(
        'isOverlayPermissionGranted',
      );
      return isGranted ?? false;
    } on PlatformException catch (e) {
      developer.log(
        'Erro ao consultar permissao do balao flutuante: ${e.message}',
      );
      return false;
    }
  }

  @override
  Future<void> openOverlayPermissionSettings() async {
    try {
      await _platform.invokeMethod('openOverlayPermissionSettings');
    } on PlatformException catch (e) {
      developer.log(
        'Erro ao abrir configuracoes de sobreposicao: ${e.message}',
      );
      rethrow;
    }
  }

  @override
  Future<bool> isBubbleRunning() async {
    try {
      final isRunning = await _platform.invokeMethod<bool>('isBubbleRunning');
      return isRunning ?? false;
    } on PlatformException catch (e) {
      developer.log('Erro ao consultar status do balao: ${e.message}');
      return false;
    }
  }

  @override
  Future<void> startBubble() async {
    try {
      await _platform.invokeMethod('startBubble');
    } on PlatformException catch (e) {
      developer.log('Erro ao iniciar balao flutuante: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> stopBubble() async {
    try {
      await _platform.invokeMethod('stopBubble');
    } on PlatformException catch (e) {
      developer.log('Erro ao parar balao flutuante: ${e.message}');
      rethrow;
    }
  }
}
