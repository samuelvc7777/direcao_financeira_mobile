import 'dart:async';
import 'dart:developer' as developer;

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide RealtimeClient;

import '../../../../core/network/realtime_client.dart';
import '../shared/supabase_table_names.dart';
import '../shared/supabase_user_scope.dart';

class SupabaseRealtimeClient implements RealtimeClient {
  SupabaseRealtimeClient({required this.client, required this.enableRealtime})
    : userScope = SupabaseUserScope(client: client) {
    client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      _isOnline.value = session != null;
      if (session == null) {
        _isConnected = false;
        unawaited(_disposeStreams());
      }
    });
  }

  final SupabaseClient client;
  final bool enableRealtime;
  final SupabaseUserScope userScope;
  final RxBool _isOnline = false.obs;
  final Map<String, List<void Function(dynamic payload)>> _handlers = {};

  StreamSubscription<List<Map<String, dynamic>>>? _transactionsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _shiftsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _ridesSubscription;
  bool _isConnected = false;
  bool _isRecoveringFromStreamError = false;

  @override
  RxBool get isOnline => _isOnline;

  @override
  void connect({required String token}) {
    if (!enableRealtime || _isConnected) {
      _isOnline.value = client.auth.currentSession != null;
      return;
    }

    final currentSession = client.auth.currentSession;
    if (currentSession == null) {
      _isOnline.value = false;
      return;
    }

    _isConnected = true;
    _isOnline.value = true;

    unawaited(_startStreams());
  }

  @override
  void disconnect() {
    _isConnected = false;
    _isOnline.value = false;
    unawaited(_disposeStreams());
  }

  @override
  void on(String event, void Function(dynamic payload) handler) {
    final handlers = _handlers.putIfAbsent(event, () => []);
    if (!handlers.contains(handler)) {
      handlers.add(handler);
    }
  }

  @override
  void off(String event, [void Function(dynamic payload)? handler]) {
    if (handler == null) {
      _handlers.remove(event);
      return;
    }

    final handlers = _handlers[event];
    handlers?.remove(handler);
    if (handlers?.isEmpty ?? false) {
      _handlers.remove(event);
    }
  }

  @override
  Future<void> dispose() async {
    _handlers.clear();
    await _disposeStreams();
  }

  Future<void> _startStreams() async {
    try {
      final userId = await userScope.getCurrentUserId();

      _transactionsSubscription ??= client
          .from(SupabaseTableNames.transactions)
          .stream(primaryKey: ['id'])
          .eq('userId', userId)
          .listen(
            (_) {
              _emit('transaction.changed');
              _emit('transaction.created');
            },
            onError: _handleStreamError,
            onDone: _handleStreamDone,
          );

      _shiftsSubscription ??= client
          .from(SupabaseTableNames.shifts)
          .stream(primaryKey: ['id'])
          .eq('userId', userId)
          .listen(
            (_) {
              _emit('journey.shift.started');
              _emit('journey.shift.finished');
              _emit('journey.shift.paused');
              _emit('journey.shift.resumed');
            },
            onError: _handleStreamError,
            onDone: _handleStreamDone,
          );

      _ridesSubscription ??= client
          .from(SupabaseTableNames.rides)
          .stream(primaryKey: ['id'])
          .eq('userId', userId)
          .listen(
            (_) {
              _emit('journey.ride.created');
              _emit('journey.ride.updated');
            },
            onError: _handleStreamError,
            onDone: _handleStreamDone,
          );
    } catch (_) {
      _isConnected = false;
      _isOnline.value = false;
      await _disposeStreams();
    }
  }

  Future<void> _disposeStreams() async {
    await _transactionsSubscription?.cancel();
    await _shiftsSubscription?.cancel();
    await _ridesSubscription?.cancel();
    _transactionsSubscription = null;
    _shiftsSubscription = null;
    _ridesSubscription = null;
  }

  void _handleStreamError(Object error, [StackTrace? stackTrace]) {
    developer.log(
      'Supabase realtime stream error. Realtime will be marked offline.',
      name: 'SupabaseRealtimeClient',
      error: error,
      stackTrace: stackTrace,
    );
    unawaited(_recoverFromStreamFailure());
  }

  void _handleStreamDone() {
    if (!_isConnected) {
      return;
    }

    developer.log(
      'Supabase realtime stream closed. Realtime will be marked offline.',
      name: 'SupabaseRealtimeClient',
    );
    unawaited(_recoverFromStreamFailure());
  }

  Future<void> _recoverFromStreamFailure() async {
    if (_isRecoveringFromStreamError) {
      return;
    }

    _isRecoveringFromStreamError = true;
    try {
      _isConnected = false;
      _isOnline.value = false;
      await _disposeStreams();
    } finally {
      _isRecoveringFromStreamError = false;
    }
  }

  void _emit(String event, [dynamic payload]) {
    final listeners = _handlers[event];
    if (listeners == null) {
      return;
    }

    for (final listener in listeners) {
      listener(payload);
    }
  }
}
