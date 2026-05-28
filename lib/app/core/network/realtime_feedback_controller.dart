import 'package:get/get.dart';

import 'realtime_client.dart';

class RealtimeFeedbackController extends GetxController {
  RealtimeFeedbackController({required this.realtimeClient});

  final RealtimeClient realtimeClient;
  Worker? _statusWorker;

  @override
  void onInit() {
    super.onInit();
    _statusWorker = ever<bool>(realtimeClient.isOnline, _handleStatusChange);
  }

  @override
  void onClose() {
    _statusWorker?.dispose();
    super.onClose();
  }

  void _handleStatusChange(bool isOnline) {
    // Temporariamente desativado para nao bloquear a navegacao nas telas
    // de autenticacao enquanto o fluxo Supabase ainda esta sendo ajustado.
    return;
  }
}
