import 'package:flutter/services.dart';

abstract class IRecordingNativeDataSource {
  Future<Map<String, dynamic>> startRecording({Map<String, dynamic>? settings});

  Future<Map<String, dynamic>?> stopRecording();

  Future<bool> isRecording();

  Future<bool> requestPermissions();

  Future<void> openAppSettings();

  Future<void> openRecording(String filePath);
}

class RecordingNativeDataSourceImpl implements IRecordingNativeDataSource {
  RecordingNativeDataSourceImpl({
    MethodChannel channel = const MethodChannel(
      'com.direcao_financeira/recording',
    ),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<bool> requestPermissions() async {
    final granted = await _channel.invokeMethod<bool>('requestPermissions');
    return granted ?? false;
  }

  @override
  Future<bool> isRecording() async {
    final isActive = await _channel.invokeMethod<bool>('isRecording');
    return isActive ?? false;
  }

  @override
  Future<Map<String, dynamic>> startRecording({
    Map<String, dynamic>? settings,
  }) async {
    final payload = await _channel.invokeMapMethod<String, dynamic>(
      'startRecording',
      settings,
    );
    if (payload == null) {
      throw StateError('A gravacao nao retornou metadados.');
    }
    return payload;
  }

  @override
  Future<Map<String, dynamic>?> stopRecording() {
    return _channel.invokeMapMethod<String, dynamic>('stopRecording');
  }

  @override
  Future<void> openAppSettings() {
    return _channel.invokeMethod<void>('openAppSettings');
  }

  @override
  Future<void> openRecording(String filePath) {
    return _channel.invokeMethod<void>('openRecording', {'filePath': filePath});
  }
}
