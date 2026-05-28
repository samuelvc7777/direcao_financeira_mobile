import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionSettings {
  const LocationPermissionSettings();

  static const MethodChannel _platform = MethodChannel(
    'com.direcao_financeira/location_permissions',
  );

  Future<bool> openBackgroundLocationPermissionSettings() async {
    try {
      final opened = await _platform.invokeMethod<bool>(
        'openBackgroundLocationPermissionSettings',
      );
      return opened ?? false;
    } on MissingPluginException {
      return Geolocator.openAppSettings();
    } on PlatformException catch (e) {
      developer.log(
        'Erro ao abrir permissao de localizacao em segundo plano: ${e.message}',
      );
      return Geolocator.openAppSettings();
    }
  }
}
