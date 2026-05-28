import 'package:get/get.dart';

import '../feedback/app_snackbar.dart';
import '../../routes/app_pages.dart';
import '../network/realtime_client.dart';
import 'authenticated_session.dart';
import 'session_store.dart';
import 'user_cache.dart';

abstract class SessionCoordinator {
  Future<void> handleAuthenticatedSession(AuthenticatedSession session);
  Future<void> restoreSession();
  Future<void> logout();
  Future<void> expireSession({String? message});
}

class DefaultSessionCoordinator implements SessionCoordinator {
  DefaultSessionCoordinator({
    required this.sessionStore,
    required this.userCache,
    required this.realtimeClient,
    this.restoreRemoteSession,
    this.remoteLogout,
  });

  final SessionStore sessionStore;
  final UserCache userCache;
  final RealtimeClient realtimeClient;
  final Future<void> Function(String token)? restoreRemoteSession;
  final Future<void> Function()? remoteLogout;

  @override
  Future<void> handleAuthenticatedSession(AuthenticatedSession session) async {
    await sessionStore.saveToken(session.token);
    await userCache.saveUser(session.user);
    realtimeClient.connect(token: session.token);
  }

  @override
  Future<void> restoreSession() async {
    final token = sessionStore.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      if (restoreRemoteSession != null) {
        await restoreRemoteSession!(token);
      }

      realtimeClient.connect(token: token);
    } catch (_) {
      await _clearLocalSession();

      if (Get.currentRoute != AppRoutes.login) {
        Get.offAllNamed(AppRoutes.login);
      }
    }
  }

  @override
  Future<void> logout() async {
    if (remoteLogout != null) {
      await remoteLogout!();
    }
    await _clearLocalSession();
  }

  Future<void> _clearLocalSession() async {
    realtimeClient.disconnect();
    await sessionStore.clearToken();
    await userCache.clearUser();
  }

  @override
  Future<void> expireSession({String? message}) async {
    await logout();

    if (Get.currentRoute != AppRoutes.login) {
      Get.offAllNamed(AppRoutes.login);
    }

    if ((message ?? '').trim().isNotEmpty) {
      AppSnackbar.show(
        'Sessao encerrada',
        message!,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
