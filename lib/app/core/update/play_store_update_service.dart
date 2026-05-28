import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class AppUpdateService {
  Future<bool> hasUpdateAvailable();
  Future<bool> openStorePage();
}

class PlayStoreUpdateService implements AppUpdateService {
  PlayStoreUpdateService({String? androidPackageId})
    : _androidPackageId =
          androidPackageId ??
          const String.fromEnvironment(
            'PLAY_STORE_PACKAGE_ID',
            defaultValue: 'com.br.finance_direction',
          );

  final String _androidPackageId;

  Uri get _marketUri => Uri.parse('market://details?id=$_androidPackageId');

  Uri get _webUri => Uri.parse(
    'https://play.google.com/store/apps/details?id=$_androidPackageId',
  );

  @override
  Future<bool> hasUpdateAvailable() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      final info = await InAppUpdate.checkForUpdate();
      return info.updateAvailability == UpdateAvailability.updateAvailable;
    } catch (error, stackTrace) {
      debugPrint(
        '[PlayStoreUpdateService] Falha ao verificar atualizacoes: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  @override
  Future<bool> openStorePage() async {
    try {
      if (await launchUrl(_marketUri, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (error, stackTrace) {
      debugPrint('[PlayStoreUpdateService] market:// indisponivel: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    return launchUrl(_webUri, mode: LaunchMode.externalApplication);
  }
}
