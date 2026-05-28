import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

class NotificationPermissionService {
  const NotificationPermissionService({
    MethodChannel channel = const MethodChannel(
      'com.direcao_financeira/invoice_notifications',
    ),
  }) : _channel = channel;

  final MethodChannel _channel;

  Future<bool> areAndroidNotificationsEnabled() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final plugin = FlutterLocalNotificationsPlugin();
      return await plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled() ??
          true;
    } catch (error) {
      developer.log(
        'Erro ao consultar permissao de notificacao: $error',
        name: 'NotificationPermissionService',
      );
      return true;
    }
  }

  Future<void> requestAndroidNotificationPermissionIfNeeded() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (error) {
      developer.log(
        'Erro ao solicitar permissao de notificacao: $error',
        name: 'NotificationPermissionService',
      );
    }
  }

  Future<void> openAndroidNotificationSettings() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('openNotificationSettings');
    } catch (error) {
      developer.log(
        'Erro ao abrir configuracoes de notificacao: $error',
        name: 'NotificationPermissionService',
      );
    }
  }
}
