import 'package:flutter/services.dart';

class MapAddressLauncherService {
  const MapAddressLauncherService({
    MethodChannel channel = const MethodChannel('com.direcao_financeira/maps'),
  }) : _channel = channel;

  final MethodChannel _channel;

  Future<bool> openAddress(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    final opened = await _channel.invokeMethod<bool>('openAddress', {
      'address': trimmed,
    });
    return opened ?? false;
  }
}
