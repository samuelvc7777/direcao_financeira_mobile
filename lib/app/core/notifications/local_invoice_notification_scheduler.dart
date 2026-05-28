import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/invoice_notification_entity.dart';
import '../../routes/app_pages.dart';
import 'invoice_notification_platform.dart';
import 'invoice_notification_scheduler.dart';

class LocalInvoiceNotificationScheduler
    implements InvoiceNotificationScheduler {
  LocalInvoiceNotificationScheduler({
    FlutterLocalNotificationsPlugin? plugin,
    InvoiceNotificationPlatform? platform,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _platform = platform ?? const NativeInvoiceNotificationPlatform();

  static const _channelId = 'invoice_notifications';
  static const _channelName = 'Faturas';
  static const _channelDescription =
      'Avisos locais de fechamento, vencimento e atraso de faturas.';

  final FlutterLocalNotificationsPlugin _plugin;
  final InvoiceNotificationPlatform _platform;
  var _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized || !Platform.isAndroid) {
      return;
    }

    tz.initializeTimeZones();
    final timeZoneName = await _platform.getLocalTimeZoneName();
    if (timeZoneName != null && timeZoneName.isNotEmpty) {
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (error) {
        developer.log(
          'Timezone Android nao reconhecido: $timeZoneName ($error)',
          name: 'LocalInvoiceNotificationScheduler',
        );
      }
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    _initialized = true;
  }

  @override
  Future<void> schedule(InvoiceNotificationCandidate candidate) async {
    if (!Platform.isAndroid) {
      return;
    }
    await initialize();
    final scheduledDate = tz.TZDateTime.from(candidate.scheduledAt, tz.local);
    final effectiveDate = scheduledDate.isAfter(tz.TZDateTime.now(tz.local))
        ? scheduledDate
        : tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));

    await _plugin.zonedSchedule(
      id: candidate.notificationId,
      title: candidate.title,
      body: candidate.body,
      scheduledDate: effectiveDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: candidate.payload,
    );
  }

  @override
  Future<void> cancel(int notificationId) async {
    if (!Platform.isAndroid) {
      return;
    }
    await _plugin.cancel(id: notificationId);
  }

  @override
  Future<void> cancelMany(Iterable<int> notificationIds) async {
    for (final notificationId in notificationIds) {
      await cancel(notificationId);
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || !payload.startsWith('invoice:')) {
      return;
    }
    Get.toNamed(AppRoutes.creditCards);
  }
}
