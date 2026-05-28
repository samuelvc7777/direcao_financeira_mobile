import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../../../../core/network/realtime_client.dart';

class SocketIoRealtimeClient implements RealtimeClient {
  SocketIoRealtimeClient({required this.baseUrl, required this.enableRealtime});

  final String baseUrl;
  final bool enableRealtime;
  final RxBool _isOnline = true.obs;
  final Map<String, List<void Function(dynamic payload)>> _handlers = {};
  socket_io.Socket? _socket;
  bool _socketLifecycleHandlersAttached = false;

  @override
  RxBool get isOnline => _isOnline;

  @override
  void connect({required String token}) {
    if (!enableRealtime || token.isEmpty) {
      return;
    }

    _socket ??= socket_io.io(
      baseUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _attachSocketLifecycleHandlers();
    _attachRegisteredHandlers();
    _socket?.auth = {'token': token};
    if (_socket?.connected != true) {
      _socket?.connect();
    }
  }

  @override
  void disconnect() {
    _socket?.disconnect();
    _isOnline.value = false;
  }

  @override
  void on(String event, void Function(dynamic payload) handler) {
    final handlers = _handlers.putIfAbsent(event, () => []);
    if (handlers.contains(handler)) {
      return;
    }

    handlers.add(handler);
    _socket?.on(event, handler);
  }

  @override
  void off(String event, [void Function(dynamic payload)? handler]) {
    if (handler == null) {
      _socket?.off(event);
      _handlers.remove(event);
      return;
    }

    _socket?.off(event, handler);
    final handlers = _handlers[event];
    handlers?.remove(handler);
    if (handlers?.isEmpty ?? false) {
      _handlers.remove(event);
    }
  }

  @override
  Future<void> dispose() async {
    _socket?.dispose();
    _socket = null;
    _socketLifecycleHandlersAttached = false;
    _handlers.clear();
    _isOnline.value = false;
  }

  void _attachSocketLifecycleHandlers() {
    if (_socketLifecycleHandlersAttached) {
      return;
    }

    _socketLifecycleHandlersAttached = true;
    _socket?.onConnect((_) {
      _isOnline.value = true;
    });
    _socket?.onDisconnect((_) {
      _isOnline.value = false;
    });
    _socket?.onConnectError((_) {
      if (_isOnline.value) {
        _isOnline.value = false;
      }
    });
  }

  void _attachRegisteredHandlers() {
    for (final entry in _handlers.entries) {
      _socket?.off(entry.key);
      for (final handler in entry.value) {
        _socket?.on(entry.key, handler);
      }
    }
  }
}
