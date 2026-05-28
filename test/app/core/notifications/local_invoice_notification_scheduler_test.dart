import 'package:direcao_financeira_mobile/app/core/notifications/invoice_notification_platform.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'contrato de plataforma retorna timezone Android quando disponivel',
    () async {
      const channel = MethodChannel('test/invoice_notifications');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getLocalTimeZoneName') {
              return 'America/Sao_Paulo';
            }
            return null;
          });

      final platform = NativeInvoiceNotificationPlatform(channel: channel);

      expect(await platform.getLocalTimeZoneName(), 'America/Sao_Paulo');

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    },
  );
}
