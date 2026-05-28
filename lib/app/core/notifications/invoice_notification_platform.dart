import 'package:flutter/services.dart';

abstract class InvoiceNotificationPlatform {
  Future<String?> getLocalTimeZoneName();
}

class NativeInvoiceNotificationPlatform implements InvoiceNotificationPlatform {
  const NativeInvoiceNotificationPlatform({
    MethodChannel channel = const MethodChannel(
      'com.direcao_financeira/invoice_notifications',
    ),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<String?> getLocalTimeZoneName() async {
    try {
      return await _channel.invokeMethod<String>('getLocalTimeZoneName');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
