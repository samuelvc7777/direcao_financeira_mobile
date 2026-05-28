import 'package:get/get.dart';

abstract class RealtimeClient {
  RxBool get isOnline;

  void connect({required String token});
  void disconnect();
  void on(String event, void Function(dynamic payload) handler);
  void off(String event, [void Function(dynamic payload)? handler]);
  Future<void> dispose();
}
